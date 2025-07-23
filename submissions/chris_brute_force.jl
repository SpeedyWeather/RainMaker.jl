author = "Chris Rackauckas"
description = "Evotrees.jl Surrogate, Claude generated"

#=
using RainMakerChallenge2025
using OptimizationBBO, Optimization

function objective(params, p)
    return -max_precipitation(params)
end

lower_bounds = [0., -2000., 0., -180., -90., 270., 270., -5., -5., 5.]
upper_bounds = [2., 5000., 30., 180., 90., 300., 300., 5., 5., 50.]

optf = OptimizationFunction(objective)
prob = Optimization.OptimizationProblem(optf, [1, 0, 1, -80, 40.45, 300, 273, 0, 0, 35], 
                          lb=lower_bounds, ub=upper_bounds)

println("Starting optimization...")
sol = solve(prob, BBO_adaptive_de_rand_1_bin_radiuslimited(); maxiters=10_000)

println("Optimized parameters: ", sol.u)
println("Predicted max precipitation from surrogate: ", max_precipitation(sol.u))
=#

using SpeedyWeather, RainMaker


const PARAMETER_KEYS = (
    :orography_scale,           # [1],      default: 1, scale of global orography
    :mountain_height,           # [m],      default: 0, height of an additional azores mountain
    :mountain_size,             # [˚],      default: 1, horizontal size of mountain in Pittsburgh
    :mountain_lon,              # [˚E],     default: -80, longitude of that mountain in Pittsburgh
    :mountain_lat,              # [˚N],     default: 40.45, latitude of that mountain in Pittsburgh
    :temperature_equator,       # [K],      default: 300, sea surface temperature at the equator
    :temperature_pole,          # [K],      default: 273, sea surfaec temperature at the poles
    :temperature_usa,           # [K],      default: 0, land surface temperature anomaly over the USA
    :temperature_pa,            # [K],      default: 0, land surface temperature anomaly in Pennsylvania
    :zonal_wind,                # [m/s],    default: 35, zonal wind speed
)

const PARAMETER_DEFAULTS = [1, 0, 1, -80, 40.45, 300, 273, 0, 0, 35]

function max_precipitation(parameters::AbstractVector)
    parameter_tuple = NamedTuple{PARAMETER_KEYS}(parameters)
    return max_precipitation(parameter_tuple)
end

function max_precipitation(parameters::NamedTuple)

    # define resolution. Use trunc=42, 63, 85, 127, ... for higher resolution, cubically slower
    spectral_grid = SpectralGrid(trunc=31, nlayers=8)

    # Define AquaPlanet ocean, for idealised sea surface temperatures
    # but don't change land-sea mask = retain real ocean basins
    ocean = AquaPlanet(spectral_grid,
                temp_equator=parameters.temperature_equator,
                temp_poles=parameters.temperature_pole)

    land_temperature = ConstantLandTemperature(spectral_grid)
    land = LandModel(spectral_grid; temperature=land_temperature)

    initial_conditions = InitialConditions(
        vordiv = ZonalWind(u₀=parameters.zonal_wind),
        temp = JablonowskiTemperature(u₀=parameters.zonal_wind),
        pres = PressureOnOrography(),
        humid = ConstantRelativeHumidity())

    orography = EarthOrography(spectral_grid, scale=parameters.orography_scale)

    # construct model
    model = PrimitiveWetModel(spectral_grid; ocean, land, initial_conditions, orography)

    # Add rain gauge, locate in Pittsburgh PA
    rain_gauge = RainGauge(spectral_grid, lond=-80, latd=40.45)
    add!(model, rain_gauge)

    # Initialize
    simulation = initialize!(model, time=DateTime(2025, 7, 22))

    # Add additional  mountain
    H = parameters.mountain_height
    λ₀, φ₀, σ = parameters.mountain_lon, parameters.mountain_lat, parameters.mountain_size  
    set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2), add=true)

    # land sea surface temperature anomalies
    # 1. USA
    set!(simulation, soil_temperature=
        (λ, φ, k) -> (30 < φ < 50) && (240 < λ < 285) ? parameters.temperature_usa : 0, add=true)

    # 2. Pennsylvania
    A = parameters.temperature_pa
    λ_az, φ_az, σ_az = -80, 40.45, 4    # location [˚], size [˚] of Azores
    set!(simulation, soil_temperature=
        (λ, φ, k) -> A*exp(-spherical_distance((λ,φ), (λ_az,φ_az), radius=360/2π)^2/2σ_az^2), add=true)

    # Run simulation for 20 days
    run!(simulation, period=Day(20))

    # skip first 5 days, as is done in the RainMaker challenge
    RainMaker.skip!(rain_gauge, Day(5))

    # evaluate rain gauge
    lsc = rain_gauge.accumulated_rain_large_scale
    conv = rain_gauge.accumulated_rain_convection
    total_precip = maximum(lsc) + maximum(conv)
    return rain_gauge, total_precip
end

final_params = [1.9851412873870289, 2485.737125917869, 14.118878320714353, 73.66989910502846, -72.40588406991382, 280.9029383973223, 299.2432527466829, 4.773285514316327, 4.586811470190235, 33.398388938656204]

rain_gauge, total_precip = max_precipitation(final_params)

total_precip
