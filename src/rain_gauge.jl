const DEFAULT_DATE = Dates.DateTime(2000, 1, 1)
const DEFAULT_ΔT = Dates.Minute(30)
const DEFAULT_LOND = -1.25
const DEFAULT_LATD = 51.75
const DEFAULT_PERIOD = Dates.Day(20)

export RainGauge

"""Measures convective and large-scale precipitation across time at
one given location with linear interpolation from model grids onto
`lond`, `latd`. Fields are 
$(TYPEDFIELDS)"""
@kwdef mutable struct RainGauge{NF, Interpolator} <: SpeedyWeather.AbstractCallback
    
    # SPACE
    """[OPTION] Longitude [0 to 360˚E] where to measure precipitation."""
    lond::Float64 = DEFAULT_LOND
    
    """[OPTION] Latitude [-90˚ to 90˚N] where to measure precipitation."""
    latd::Float64 = DEFAULT_LATD

    """[OPTION] To interpolate precipitation fields onto lond, latd."""
    interpolator::Interpolator

    # TIME
    """[OPTION] Maximum number of time steps used to allocate memory."""
    max_measurements::Int = 100_000

    """[OPTION] Measurement counter (one per time step), starting at 0 for uninitialized."""
    measurement_counter::Int = 0

    """Start time of gauge."""
    tstart::Dates.DateTime = DEFAULT_DATE

    """Spacing between time steps."""
    Δt::Dates.Second = DEFAULT_ΔT

    """Accumulated large-scale precipitation [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_rain_large_scale_start::NF = 0

    """Accumulated large-scale precipitation [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_rain_convection_start::NF = 0

    """Accumulated large-scale precipitation [mm]."""
    accumulated_rain_large_scale::Vector{NF} = zeros(NF, max_measurements)
    
    """Accumulated convective precipitation [mm]."""
    accumulated_rain_convection::Vector{NF} = zeros(NF, max_measurements)
end

# use number format NF from spectral grid if not provided
function RainGauge(SG::SpectralGrid; kwargs...)
    npoints = 1
    (; NF, Grid, nlat_half) = SG
    interpolator = RingGrids.DEFAULT_INTERPOLATOR(Grid, nlat_half, npoints; NF)
    RainGauge{SG.NF, typeof(interpolator)}(; interpolator, kwargs...)
end

function Base.show(io::IO, gauge::RainGauge{T}) where T
    println(io, "$(typeof(gauge)) <: AbstractCallback")
    println(io, "├ lond::Float64 = $(gauge.lond)˚E")
    println(io, "├ latd::Float64 = $(gauge.latd)˚N")

    now = gauge.tstart + gauge.measurement_counter*gauge.Δt
    now_str = Dates.format(now, "yyyy-mm-dd HH:MM:SS")
    println(io, "├ measurement_counter:Int = $(gauge.measurement_counter)"*(gauge.measurement_counter == 0 ? " (uninitialized)" : " (now: $now_str)"))
    println(io, "├ tstart::DateTime = $(gauge.tstart)")
    println(io, "├ Δt::Second $(gauge.Δt)")

    years = Dates.Second(gauge.Δt * gauge.max_measurements).value / 3600 / 24 / 365.25
    years_str = Printf.@sprintf("%.1f", years)
    percentage_passed = round(Int, 100*gauge.measurement_counter/gauge.max_measurements)
    println(io, "├ max_measurements::Int = $(gauge.max_measurements) (measuring for up to ~$years_str years, $percentage_passed% recorded)")

    println(io, "├ accumulated_rain_large_scale::Vector{$T}, maximum: $(maximum(gauge.accumulated_rain_large_scale)) mm")
    println(io, "├ accumulated_rain_convection::Vector{$T}, maximum: $(maximum(gauge.accumulated_rain_convection)) mm")
    
    total_precip = maximum(gauge.accumulated_rain_large_scale) + maximum(gauge.accumulated_rain_convection)
    total_precip_str = Printf.@sprintf("%.3f", total_precip)
    print(io,   "└ accumulated total precipitation: $total_precip_str mm")
end

"""$(TYPEDSIGNATURES)
Initialize `gauge::RainGauge` by calling `reset!(::RainGauge)` but only if
`gauge` is not already initialized (`gauge.measurement_counter > 0`),
so that it can be re-used across several simulation runs."""
function SpeedyWeather.initialize!(gauge::RainGauge, args...)
    # skip initialization step if gauge already initialized
    gauge.measurement_counter > 0 && return nothing
    reset!(gauge, args...)
end

"""$(TYPEDSIGNATURES)
Reset `gauge::RainGauge` to its initial state, i.e. set `measurement_counter` to 0,
`tstart` to `DEFAULT_DATE`, `Δt` to `DEFAULT_ΔT`, and set accumulated precipitation
vector to zeros."""
function reset!(gauge::RainGauge)
    gauge.measurement_counter = 0
    RingGrids.update_locator!(gauge.interpolator, [gauge.lond], [gauge.latd])
    gauge.tstart = DEFAULT_DATE
    gauge.Δt = DEFAULT_ΔT
    fill!(gauge.accumulated_rain_convection, 0)
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

    p0 = zeros(1)
    RingGrids.interpolate!(p0, diagn.physics.precip_large_scale, gauge.interpolator)
    gauge.accumulated_rain_large_scale_start = p0[1]

    RingGrids.interpolate!(p0, diagn.physics.precip_convection, gauge.interpolator)
    gauge.accumulated_rain_convection_start = p0[1]

    return nothing
end

export skip!

"""$(TYPEDSIGNATURES)
Renormalize a `rain_gauge` to skip the first `period` (e.g. 5 days) of
measurements."""
function skip!(rain_gauge::RainGauge, period::Dates.Period)
    @assert period >= Second(0) "Cannot skip negative period $period"
    t_end = rain_gauge.measurement_counter*rain_gauge.Δt
    @assert period <= t_end "Cannot skip $period, more than what was recorded for: $t_end"
    
    # get index for timestep to normalize to 0, this "skips" the previous time steps
    # in the accumulated rainfall and makes their rainfall negative, doesn't affect
    # the rain rate but changes the accumulated rainfall at the last time step to
    # the accumulated rainfall since the skipped time step
    i = floor(Int, Second(period).value / Second(rain_gauge.Δt).value)
    i == 0 && return nothing

    lsc = rain_gauge.accumulated_rain_large_scale
    conv = rain_gauge.accumulated_rain_convection
    
    lsc0 = lsc[i]       # values that we will normalize with
    conv0 = conv[i]

    # set the start values first which are used in case the rain gauge is started after the simulation
    rain_gauge.accumulated_rain_large_scale_start -= lsc0
    rain_gauge.accumulated_rain_convection_start -= conv0

    # normalize, only the range of values that have already been measured
    lsc[1:rain_gauge.measurement_counter] .-= lsc0
    conv[1:rain_gauge.measurement_counter] .-= conv0

    return rain_gauge
end

# non-mutating version, allocates a (deep) copy of raingauge
function Base.skip(gauge::RainGauge, period::Dates.Period)
    gauge2 = deepcopy(gauge)
    skip!(gauge2, period)
    return gauge2
end

"""$(TYPEDSIGNATURES)
Callback definition for `gauge::RainGauge` from `RainMaker.jl`.
Interpolates large-scale and convective precipitation to the gauge's
storage vectors and converts units from m to mm. Stops measuring if the
`max_measurements` are reached which is printed only once as info."""
function SpeedyWeather.callback!(
    gauge::RainGauge,
    progn::PrognosticVariables,
    diagn::DiagnosticVariables,
    model::SpeedyWeather.AbstractModel)

    gauge.measurement_counter += 1      # always count up

    # but escape immediately if max time steps reached
    gauge.measurement_counter > gauge.max_measurements && return nothing
    i = gauge.measurement_counter

    # rain gauge measurements are relative to amount of precipitation at initial conditions
    precip_lsc_0 = gauge.accumulated_rain_large_scale_start
    precip_conv_0 = gauge.accumulated_rain_convection_start

    # interpolate! requires vector, allocate but reuse
    precip = zeros(1)
    m2mm = 1000     # model uses meters internally, convert to mm
    RingGrids.interpolate!(precip, diagn.physics.precip_large_scale, gauge.interpolator)
    gauge.accumulated_rain_large_scale[i] = (precip[1] - precip_lsc_0)*m2mm

    RingGrids.interpolate!(precip, diagn.physics.precip_convection, gauge.interpolator)
    gauge.accumulated_rain_convection[i] = (precip[1] - precip_conv_0)*m2mm

    # print info that max time steps is reached only once
    if gauge.measurement_counter == gauge.max_measurements
        print("\n")
        @info "gauge.max_measurements = $(gauge.max_measurements) reached, stopping gauge."
    end
end

# nothing to finalize
SpeedyWeather.finalize!(gauge::RainGauge, args...) = nothing

"""$(TYPEDSIGNATURES)
Plot accumulated precipitation and precipitation rate across time for
`gauge::RainGauge` from `RainMaker.jl`. `rate_Δt` specifies the interval
used to bin the precipitation rate, while units are always converted to
mm/day. Default is 6 hours."""
function plot(
    gauge::RainGauge;
    skip::Period = Day(0),
    rate_Δt::Period = Hour(6),
)
    # skip the first `skip` days if desired
    if skip > Second(0)
        # create a copy but name it the same
        gauge = Base.skip(gauge, skip)
    end

    fig = Figure(size=(800, 400))
    ax1 = Axis(fig[1,1],
        title="Precipitation at $(gauge.latd)˚N, $(gauge.lond)˚E",
        titlealign=:left,
        ylabel="Accumulated [mm]")

    ax2 = Axis(fig[2, 1],
        ylabel="Rate [mm/day]", 
        xlabel="time [days]")

    linkxaxes!(ax1, ax2)

    # time axis in Float64 days, as Makie doesn't like Dates objects on x-axis yet
    t = range(0, step=Second(gauge.Δt).value/3600/24, length=gauge.measurement_counter)

    # ACCUMULATED PRECIPITATION
    # range of recorded precipitation only
    lsca = gauge.accumulated_rain_large_scale[1:gauge.measurement_counter]
    conv = gauge.accumulated_rain_convection[1:gauge.measurement_counter]

    # band/fillbetween plot, but stack them
    band!(ax1, t, 0, lsca, label="large-scale condensation", color=:skyblue, alpha=0.8)
    band!(ax1, t, lsca, conv+lsca, label="convection", color=:purple3, alpha=0.8)
    
    # also plot total precipitation and add last value to legend
    max_precip = Printf.@sprintf("%.3f", maximum(lsca) + maximum(conv))
    lines!(ax1, t, conv+lsca, label="total: $max_precip mm", color=:black, alpha=0.8)
    
    # add dashed line to indicate skipped days
    if skip > Second(0)
        vlines!(ax1, Second(skip).value/3600/24, linestyle=:dash, color=:black, label="First $skip skipped")
    end

    axislegend(ax1, position=:lt, labelsize=10)
    
    # PRECIPITATION RATE
    # use every s-th value to reduce number of bars
    s = round(Int, Second(rate_Δt).value / Second(gauge.Δt).value)
    
    # convert from mm to mm/day
    mm2mmday = Day(1)/(s*Second(gauge.Δt))
    lsc0 = gauge.accumulated_rain_large_scale_start
    conv0 = gauge.accumulated_rain_convection_start
    lsca_rate = diff(vcat(lsc0, lsca[s:s:end]))*mm2mmday
    conv_rate = diff(vcat(conv0, conv[s:s:end]))*mm2mmday
    t_rate = t[s:s:end]     # also subset time vector

    # Makie's barplot requires stacked bars to be concatenated?!
    color = vcat(fill(:skyblue, length(t_rate)), fill(:purple3, length(t_rate)))
    barplot!(ax2, vcat(t_rate, t_rate), vcat(lsca_rate, conv_rate), stack=fill(2, 2*length(t_rate)); color, alpha=0.8)

    return fig
end