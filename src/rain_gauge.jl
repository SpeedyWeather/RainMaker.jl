const DEFAULT_DATE = Dates.DateTime(2000, 1, 1)
const DEFAULT_ΔT = Dates.Minute(30)
const DEFAULT_LOND = -1.25
const DEFAULT_LATD = 51.75
const DEFAULT_PERIOD = Dates.Day(20)

export RainGauge

"""Measures convective and large-scale rain and snow across time at
one given location with linear interpolation from model grids onto
`lond`, `latd`. Precipitation types that the model does not define
(e.g. convective snow with older SpeedyWeather versions, or any
precipitation in a dry model) are measured as zero. Fields are
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

    """Accumulated large-scale rain [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_rain_large_scale_start::NF = 0

    """Accumulated convective rain [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_rain_convection_start::NF = 0

    """Accumulated large-scale snow [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_snow_large_scale_start::NF = 0

    """Accumulated convective snow [mm] in the simulation at the beginning of rain gauge measurements."""
    accumulated_snow_convection_start::NF = 0

    """Accumulated large-scale rain [mm]."""
    accumulated_rain_large_scale::Vector{NF} = zeros(NF, max_measurements)

    """Accumulated convective rain [mm]."""
    accumulated_rain_convection::Vector{NF} = zeros(NF, max_measurements)

    """Accumulated large-scale snow [mm], as liquid water equivalent."""
    accumulated_snow_large_scale::Vector{NF} = zeros(NF, max_measurements)

    """Accumulated convective snow [mm], as liquid water equivalent."""
    accumulated_snow_convection::Vector{NF} = zeros(NF, max_measurements)
end

# use number format NF from spectral grid if not provided
function RainGauge(SG::SpectralGrid; kwargs...)
    npoints = 1
    (; NF, grid) = SG
    interpolator = RingGrids.DEFAULT_INTERPOLATOR(grid, npoints; NF)
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
    println(io, "├ accumulated_snow_large_scale::Vector{$T}, maximum: $(maximum(gauge.accumulated_snow_large_scale)) mm")
    println(io, "├ accumulated_snow_convection::Vector{$T}, maximum: $(maximum(gauge.accumulated_snow_convection)) mm")

    total_precip_str = Printf.@sprintf("%.3f", maximum_precipitation(gauge))
    print(io,   "└ accumulated total precipitation: $total_precip_str mm")
end

export maximum_precipitation

"""$(TYPEDSIGNATURES)
Total accumulated precipitation [mm] measured by `gauge`, i.e. the sum of
large-scale and convective rain and snow (snow as liquid water equivalent)
at the last measurement."""
function maximum_precipitation(gauge::RainGauge)
    return maximum(gauge.accumulated_rain_large_scale) +
        maximum(gauge.accumulated_rain_convection) +
        maximum(gauge.accumulated_snow_large_scale) +
        maximum(gauge.accumulated_snow_convection)
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
    fill!(gauge.accumulated_snow_large_scale, 0)
    fill!(gauge.accumulated_snow_convection, 0)
    return gauge
end

"""$(TYPEDSIGNATURES)
Interpolate the accumulated precipitation variable `name` (e.g. `:rain_large_scale`)
from `vars.parameterizations` onto the location of `gauge`. Returns 0 if the model
does not define that variable, e.g. a dry model without large-scale condensation,
or a SpeedyWeather version that does not diagnose convective snow yet."""
function measure(gauge::RainGauge{NF}, vars::SpeedyWeather.Variables, name::Symbol) where NF
    haskey(vars.parameterizations, name) || return zero(NF)
    precip = zeros(NF, 1)   # interpolate! requires a vector
    RingGrids.interpolate!(precip, vars.parameterizations[name], gauge.interpolator)
    return precip[1]
end

"""$(TYPEDSIGNATURES)
Reset `gauge::RainGauge` to its initial state, but use time and Δt from
clock."""
function reset!(
    gauge::RainGauge,
    vars::SpeedyWeather.Variables,
    model::SpeedyWeather.AbstractModel)

    reset!(gauge)
    gauge.tstart = vars.prognostic.clock.time
    gauge.Δt = vars.prognostic.clock.Δt

    gauge.accumulated_rain_large_scale_start = measure(gauge, vars, :rain_large_scale)
    gauge.accumulated_rain_convection_start = measure(gauge, vars, :rain_convection)
    gauge.accumulated_snow_large_scale_start = measure(gauge, vars, :snow_large_scale)
    gauge.accumulated_snow_convection_start = measure(gauge, vars, :snow_convection)

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
    snow_lsc = rain_gauge.accumulated_snow_large_scale
    snow_conv = rain_gauge.accumulated_snow_convection

    lsc0 = lsc[i]       # values that we will normalize with
    conv0 = conv[i]
    snow_lsc0 = snow_lsc[i]
    snow_conv0 = snow_conv[i]

    # set the start values first which are used in case the rain gauge is started after the simulation
    rain_gauge.accumulated_rain_large_scale_start -= lsc0
    rain_gauge.accumulated_rain_convection_start -= conv0
    rain_gauge.accumulated_snow_large_scale_start -= snow_lsc0
    rain_gauge.accumulated_snow_convection_start -= snow_conv0

    # normalize, only the range of values that have already been measured
    lsc[1:rain_gauge.measurement_counter] .-= lsc0
    conv[1:rain_gauge.measurement_counter] .-= conv0
    snow_lsc[1:rain_gauge.measurement_counter] .-= snow_lsc0
    snow_conv[1:rain_gauge.measurement_counter] .-= snow_conv0

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
Interpolates large-scale and convective rain and snow
to the gauge's storage vectors and converts units from m to mm. Stops measuring if the
`max_measurements` are reached which is printed only once as info."""
function SpeedyWeather.callback!(
    gauge::RainGauge,
    vars::SpeedyWeather.Variables,
    model::SpeedyWeather.AbstractModel)

    gauge.measurement_counter += 1      # always count up

    # but escape immediately if max time steps reached
    gauge.measurement_counter > gauge.max_measurements && return nothing
    i = gauge.measurement_counter

    m2mm = 1000     # model uses meters internally, convert to mm

    # rain gauge measurements are relative to amount of precipitation at initial conditions
    gauge.accumulated_rain_large_scale[i] =
        (measure(gauge, vars, :rain_large_scale) - gauge.accumulated_rain_large_scale_start)*m2mm
    gauge.accumulated_rain_convection[i] =
        (measure(gauge, vars, :rain_convection) - gauge.accumulated_rain_convection_start)*m2mm
    gauge.accumulated_snow_large_scale[i] =
        (measure(gauge, vars, :snow_large_scale) - gauge.accumulated_snow_large_scale_start)*m2mm
    gauge.accumulated_snow_convection[i] =
        (measure(gauge, vars, :snow_convection) - gauge.accumulated_snow_convection_start)*m2mm

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
`gauge::RainGauge` from `RainMaker.jl`. Large-scale rain, convective rain,
large-scale snow and convective snow are stacked. `rate_Δt` specifies the interval
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
    snow_lsc = gauge.accumulated_snow_large_scale[1:gauge.measurement_counter]
    snow_conv = gauge.accumulated_snow_convection[1:gauge.measurement_counter]

    # cumulative sums to stack the four components on top of each other
    stack1 = lsca
    stack2 = stack1 + conv
    stack3 = stack2 + snow_lsc
    stack4 = stack3 + snow_conv

    # band/fillbetween plot, but stack them
    band!(ax1, t, 0, stack1, label="large-scale condensation (rain)", color=:skyblue, alpha=0.8)
    band!(ax1, t, stack1, stack2, label="convection (rain)", color=:purple3, alpha=0.8)
    band!(ax1, t, stack2, stack3, label="large-scale condensation (snow)", color=:aliceblue, alpha=0.8)
    band!(ax1, t, stack3, stack4, label="convection (snow)", color=:plum, alpha=0.8)

    # also plot total precipitation and add last value to legend
    max_precip = Printf.@sprintf("%.3f", maximum_precipitation(gauge))
    lines!(ax1, t, stack4, label="total: $max_precip mm", color=:black, alpha=0.8)

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
    snow_lsc0 = gauge.accumulated_snow_large_scale_start
    snow_conv0 = gauge.accumulated_snow_convection_start
    lsca_rate = diff(vcat(lsc0, lsca[s:s:end]))*mm2mmday
    conv_rate = diff(vcat(conv0, conv[s:s:end]))*mm2mmday
    snow_lsc_rate = diff(vcat(snow_lsc0, snow_lsc[s:s:end]))*mm2mmday
    snow_conv_rate = diff(vcat(snow_conv0, snow_conv[s:s:end]))*mm2mmday
    t_rate = t[s:s:end]     # also subset time vector

    # Makie's barplot requires stacked bars to be concatenated?!
    n = length(t_rate)
    color = vcat(fill(:skyblue, n), fill(:purple3, n), fill(:aliceblue, n), fill(:plum, n))
    barplot!(ax2, vcat(t_rate, t_rate, t_rate, t_rate),
        vcat(lsca_rate, conv_rate, snow_lsc_rate, snow_conv_rate),
        stack=vcat(fill(1, n), fill(2, n), fill(3, n), fill(4, n)); color, alpha=0.8)

    return fig
end
