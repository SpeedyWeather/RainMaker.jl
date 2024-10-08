DEFAULT_DATE = DateTime(2000, 1, 1)
DEFAULT_ΔT = Dates.Minute(30)

export RainGauge

"""Tracks convective and large-scale precipitation across time at
one given location. No interpolation is applied, nearest grid point
is chosen. Fields are 
$(TYPEDFIELDS)"""
@kwdef mutable struct RainGauge{NF, Interpolator} <: SpeedyWeather.AbstractCallback
    
    # SPACE
    """[OPTION] Latitude [-90˚ to 90˚N] to track precipitation."""
    latd::Float64 = 0.0

    """[OPTION] Longitude [0 to 360˚E] to track precipitation."""
    lond::Float64 = 0.0

    """[OPTION] To interpolate precipitation fields onto lond, latd."""
    interpolator::Interpolator

    # TIME
    """[OPTION] Maximum number of time steps used to allocate memory."""
    max_timesteps::Int = 100_000

    """[OPTION] Time step counter, starting at 0 for un-initialized."""
    track_counter::Int = 0

    """Start time of gauge."""
    tstart::Dates.DateTime = DEFAULT_DATE

    """Spacing between time steps."""
    Δt::Dates.Second = DEFAULT_ΔT

    """Accumulated large-scale precipitation [mm]."""
    accumulated_rain_large_scale::Vector{NF} = zeros(NF, max_timesteps)
    
    """Accumulated convective precipitation [mm]."""
    accumulated_rain_convective::Vector{NF} = zeros(NF, max_timesteps)
end

# use number format NF from spectral grid if not provided
function RainGauge(SG::SpectralGrid; kwargs...)
    npoints = 1
    interpolator = RingGrids.DEFAULT_INTERPOLATOR(SG.NF, SG.Grid, SG.nlat_half, npoints)
    RainGauge{SG.NF, typeof(interpolator)}(; interpolator, kwargs...)
end

function Base.show(io::IO, gauge::RainGauge{T}) where T
    println(io, "$(typeof(gauge)) <: AbstractCallback")
    println(io, "├ latd::Float64 = $(gauge.latd)˚N")
    println(io, "├ lond::Float64 = $(gauge.lond)˚E")

    now = gauge.tstart + gauge.track_counter*gauge.Δt
    now_str = Dates.format(now, "yyyy-mm-dd HH:MM:SS")
    println(io, "├ track_counter:Int = $(gauge.track_counter)"*(gauge.track_counter == 0 ? " (uninitialized)" : " (now: $now_str)"))
    println(io, "├ tstart::DateTime = $(gauge.tstart)")
    println(io, "├ Δt::Second $(gauge.Δt)")

    years = Dates.Second(gauge.Δt * gauge.max_timesteps).value / 3600 / 24 / 365
    years_str = Printf.@sprintf("%.1f", years)
    percentage_passed = round(Int, 100*gauge.track_counter/gauge.max_timesteps)
    println(io, "├ max_timesteps::Int = $(gauge.max_timesteps) (tracking for up to ~$years_str years, $percentage_passed% recorded)")

    println(io, "├ accumulated_rain_large_scale::Vector{$T}, maximum: $(maximum(gauge.accumulated_rain_large_scale)) mm")
    println(io, "├ accumulated_rain_convective::Vector{$T}, maximum: $(maximum(gauge.accumulated_rain_convective)) mm")
    
    total_precip = maximum(gauge.accumulated_rain_large_scale) + maximum(gauge.accumulated_rain_convective)
    total_precip_str = Printf.@sprintf("%.3f", total_precip)
    print(io,   "└ accumulated total precipitation: $total_precip_str mm")
end

"""$(TYPEDSIGNATURES)
Initialize `gauge::RainGauge` by calling `reset!(::RainGauge)` but only if
`gauge` is not already initialized (`gauge.track_counter > 0`),
so that it can be re-used across several simulation runs."""
function SpeedyWeather.initialize!(gauge::RainGauge, args...)
    # skip initialization step if gauge already initialized
    gauge.track_counter > 0 && return nothing
    reset!(gauge, args...)
end

"""$(TYPEDSIGNATURES)
Reset `gauge::RainGauge` to its initial state, i.e. set `track_counter` to 0,
`tstart` to `DEFAULT_DATE`, `Δt` to `DEFAULT_ΔT`, and set accumulated precipitation
vector to zeros."""
function reset!(gauge::RainGauge)
    gauge.track_counter = 0
    RingGrids.update_locator!(gauge.interpolator, [gauge.latd], [gauge.lond])
    gauge.tstart = DEFAULT_DATE
    gauge.Δt = DEFAULT_ΔT
    fill!(gauge.accumulated_rain_convective, 0)
    fill!(gauge.accumulated_rain_large_scale, 0)
    return gauge
end

"""$(TYPEDSIGNATURES)
Reset `gauge::RainGauge` to its initial state, but use time and Δt from
clock."""
function reset!(
    gauge::RainGauge,
    progn::PrognosticVariables,
    diagn::DiagnosticVariables,
    model::SpeedyWeather.AbstractModel)
    
    reset!(gauge)
    gauge.tstart = progn.clock.time
    gauge.Δt = progn.clock.Δt
    return nothing
end

"""$(TYPEDSIGNATURES)
Callback definition for `gauge::RainGauge` from `RainMaker.jl`.
Interpolates large-scale and convective precipitation to the gauge's
storage vectors and converts units from m to mm. Stops tracking if the
`max_timesteps` are reached which is printed only once as info."""
function SpeedyWeather.callback!(
    gauge::RainGauge,
    progn::PrognosticVariables,
    diagn::DiagnosticVariables,
    model::SpeedyWeather.AbstractModel)

    gauge.track_counter += 1      # always count up

    # but escape immediately if max time steps reached
    gauge.track_counter > gauge.max_timesteps && return nothing
    i = gauge.track_counter

    # interpolate! requires vector, allocate but reuse
    precip = zeros(1)
    m2mm = 1000     # model uses meters internally, convert to mm
    RingGrids.interpolate!(precip, diagn.physics.precip_large_scale, gauge.interpolator)
    gauge.accumulated_rain_large_scale[i] = precip[1]*m2mm

    RingGrids.interpolate!(precip, diagn.physics.precip_convection, gauge.interpolator)
    gauge.accumulated_rain_convective[i] = precip[1]*m2mm

    # print info that max time steps is reached only once
    if gauge.track_counter == gauge.max_timesteps
        print("\n")
        @info "gauge.max_timesteps = $(gauge.max_timesteps) reached, stopping gauge."
    end
end

# nothing to finish
SpeedyWeather.finish!(gauge::RainGauge, args...) = nothing

"""$(TYPEDSIGNATURES)
Plot accumulated precipitation and precipitation rate across time for
`gauge::RainGauge` from `RainMaker.jl`. `rate_Δt` specifies the interval
used to bin the precipitation rate, while units are always converted to
mm/day. Default is 6 hours."""
function plot(
    gauge::RainGauge;
    rate_Δt::Dates.Period = Dates.Hour(6))

    fig = Figure(size=(800, 400))
    ax1 = Axis(fig[1,1],
        title="Precipitation at $(gauge.latd)˚N, $(gauge.lond)˚E",
        titlealign=:left,
        ylabel="Accumulated [mm]")

    ax2 = Axis(fig[2, 1],
        ylabel="Rate [mm/day]", 
        xlabel="time [days]")

    linkxaxes!(ax1, ax2)

    t = range(0, step=Dates.Second(gauge.Δt).value/3600/24, length=gauge.track_counter)

    # ACCUMULATED PRECIPITATION
    # range of recorded precipitation only
    lsca = gauge.accumulated_rain_large_scale[1:gauge.track_counter]
    conv = gauge.accumulated_rain_convective[1:gauge.track_counter]

    # band/fillbetween plot, but stack them
    band!(ax1, t, 0, lsca, label="large-scale condensation", color=:skyblue, alpha=0.8)
    band!(ax1, t, lsca, conv+lsca, label="convection", color=:purple3, alpha=0.8)
    
    # also plot total precipitation and add last value to legend
    max_precip = Printf.@sprintf("%.3f", maximum(lsca) + maximum(conv))
    lines!(ax1, t, conv+lsca, label="total: $max_precip mm", color=:black, alpha=0.8)
    axislegend(ax1, position=:lt, labelsize=12)

    # PRECIPITATION RATE
    # use every s-th value to reduce number of bars
    s = round(Int, Dates.Second(rate_Δt).value / Dates.Second(gauge.Δt).value)
    
    # convert from mm to mm/day
    mm2mmday = Day(1)/(s*Dates.Second(gauge.Δt))
    lsca_rate = diff(vcat(0, lsca[s:s:end]))*mm2mmday
    conv_rate = diff(vcat(0, conv[s:s:end]))*mm2mmday
    t_rate = t[s:s:end]     # also subset time vector

    # Makie's barplot requires stacked bars to be concatenated?!
    color = vcat(fill(:skyblue, length(t_rate)), fill(:purple3, length(t_rate)))
    barplot!(ax2, vcat(t_rate, t_rate), vcat(lsca_rate, conv_rate), stack=fill(2, 2*length(t_rate)); color, alpha=0.8)

    return fig
end