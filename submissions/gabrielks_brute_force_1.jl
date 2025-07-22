author = "Gabriel Konar-Steenberg"
description = "Brute force built on Anas surrogate"

using SpeedyWeather, RainMaker

"""
Quickly written code based on
https://github.com/AnasAbdelR/RainMakerChallenge2025.jl/blob/main/examples/surrogate_nn_ex.jl.
We load the pretrained surrogate model and do a brute force search over many optimization
starting points for the one that results in the best performance on the real model.
"""
#=
using JLSO
using LinearAlgebra
using Distributions
using NNlib
using Random
using Optimization
using OptimizationOptimJL
using Flux
using SpeedyWeather
using RainMaker
using RainMakerChallenge2025
using Logging

minmaxnorm(data, lb, ub, norm_min=0., norm_max=1.) = @. norm_min + (data - lb) * (norm_max - norm_min) / (ub - lb)
minmaxdenorm(data, lb, ub, norm_min=0., norm_max=1.) = @. lb + (data - norm_min) * (ub - lb) / (norm_max - norm_min)

function outer_iter(seed)
    path = joinpath(@__DIR__, "data", "10kdata.jlso")
    data = JLSO.load(path)
    output_data = data[:d][:outputs]

    inputs_lb = [0., -2000., 0., -180., -90., 270., 270., -5., -5., 5.]
    inputs_ub = [2., 5000., 30., 180., 90., 300., 300., 5., 5., 50.]

    output_data = reshape(output_data, (1,:))
    outputs_lb, outputs_ub = extrema(output_data)

    # Load the surrogate model
    path = joinpath(@__DIR__, "models", "surrogate_nn_ex_128_500-v2.jlso")
    surrogate = JLSO.load(path)[:surrogate]

    # Simple SciML Optimization equivalent
    function objective_func_simple(x, p)
        X = reshape(x, 10, :) |> gpu  # Same as your Flux code
        y_pred = surrogate(X)
        obj = -sum(y_pred)  # Same objective
        λ = 100.0f0
        lower_violation = max.(0.0f0, -x)
        upper_violation = max.(0.0f0, x .- 1.0f0)
        penalty = λ * (sum(lower_violation.^2) + sum(upper_violation.^2))
        return obj + penalty
    end

    # Same initial setup as your Flux code
    Random.seed!(seed)
    x0 = vec(rand(Float32, 10, 10))  # Flatten to vector for Optimization.jl
    optf = Optimization.OptimizationFunction(objective_func_simple, Optimization.AutoZygote())
    prob = Optimization.OptimizationProblem(optf, x0)

    # println("Starting SciML optimization (1000 samples)...")
    sol = solve(prob, LBFGS(), maxiters=20000)

    # Extract results exactly like your Flux code
    X_candidate_sciml = reshape(sol.u, 10, :) |> gpu
    idx = argmax(surrogate(X_candidate_sciml))
    best_param_sample_sciml = minmaxdenorm(X_candidate_sciml[:,idx[2]]|>cpu, inputs_lb, inputs_ub)
    # @show best_param_sample_sciml
    pred_vals_sciml = minmaxdenorm(surrogate(X_candidate_sciml)[:,idx[2]]|>cpu, outputs_lb, outputs_ub)
    # @show pred_vals_sciml
    actual_precip_sciml = max_precipitation(best_param_sample_sciml)
    # @show actual_precip_sciml
    return best_param_sample_sciml, pred_vals_sciml, actual_precip_sciml
end

function main()
    global_logger(SimpleLogger(stderr, Logging.Warn))
    Threads.@threads for i in 1:1000
        best_param_sample_sciml, pred_vals_sciml, actual_precip_sciml = outer_iter(i)
        println("Iteration $i")
        if actual_precip_sciml > 210.0
            println("Best Parameters: $best_param_sample_sciml\nPredicted Values: $pred_vals_sciml\nActual Precipitation: $actual_precip_sciml")
        end
    end
end

main()
=#


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

final_params = 
[2.0163488388061523,
 5013.733625411987,
 -0.017316662706434727,
 -22.202972173690796,
 -19.587678909301758,
 282.97233670949936,
 300.200936794281,
 2.133525013923645,
 4.704113602638245,
 34.923005402088165]

rain_gauge, total_precip = max_precipitation(final_params)

total_precip  # produces 212.7933 on RainMakerChallenge2025.jl's evaluator, 211.040 on this evaluator -- TODO investigate the discrepancy
