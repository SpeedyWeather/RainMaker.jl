author = "Chris Rackauckas"
description = "Global BBO optimization with hot water"

#=

using SpeedyWeather
using RainMaker
using Optimization, OptimizationBBO

PARAMETER_KEYS = (
    :orography_scale,           # [1],      default: 1, scale of global orography
    :mountain_height,           # [m],      default: 0, height of an additional azores mountain
    :mountain_size,             # [˚],      default: 1, horizontal size of an additional azores mountain
    :mountain_lon,              # [˚E],     default: -27.25, longitude of an additional azores mountain
    :mountain_lat,              # [˚N],     default: 38.7, latitude of an additional azores mountain
    :temperature_equator,       # [K],      default: 300, sea surface temperature at the equator
    :temperature_pole,          # [K],      default: 273, sea surfaec temperature at the poles
    :sea_surface_temperature,   # [K],      default: 273, sea surface temperature anomaly in the atlantic
    :zonal_wind,                # [m/s],    default: 35, zonal wind speed
    :rotation,                  # [],       default: 7.9e-5, Earth rotation
    :ocean_temp,                # [K],      default: 175,
)

function calc_precip(u)
    best_param_sample = u

    # wrap into named tuple
    parameters = NamedTuple{PARAMETER_KEYS}(best_param_sample)

    # define resolution. Use trunc=42, 63, 85, 127, ... for higher resolution, cubically slower
    spectral_grid = SpectralGrid(trunc=31, nlayers=8)

    # Define AquaPlanet ocean, for idealised sea surface temperatures
    # but don't change land-sea mask = retain real ocean basins
    ocean = AquaPlanet(spectral_grid,
                temp_equator=parameters.temperature_equator,
                temp_poles=parameters.temperature_pole)

    # add initial conditions with a stronger zonal wind matching temperature
    initial_conditions = InitialConditions(
        vordiv = ZonalWind(u₀=parameters.zonal_wind),
        temp = JablonowskiTemperature(u₀=parameters.zonal_wind),
        pres = PressureOnOrography(),
        humid = ConstantRelativeHumidity())

    # Earth's orography but scaled
    orography = EarthOrography(spectral_grid, scale=parameters.orography_scale)

    # construct model
    model = PrimitiveWetModel(spectral_grid; ocean, initial_conditions, orography, planet=Earth(Float32, rotation=parameters.rotation))

    # Add rain gauge, locate on Terceira Island
    rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
    add!(model, rain_gauge)

    # Initialize
    simulation = initialize!(model, time=DateTime(2025, 1, 10))

    # Add additional  mountain
    H = parameters.mountain_height
    λ₀, φ₀, σ = parameters.mountain_lon, parameters.mountain_lat, parameters.mountain_size
    set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2), add=true)

    set!(simulation, temp = (λ, ϕ, σ) -> parameters.ocean_temp)
    set!(simulation, sea_surface_temperature = (λ, φ) -> parameters.sea_surface_temperature)

    # Run simulation for 20 days, maybe longer for more stable statistics? Could be increased to 30, 40, ... days ?
    run!(simulation, period=Day(20))
    skip!(rain_gauge, Day(5))
    maximum(rain_gauge.accumulated_rain_convection + rain_gauge.accumulated_rain_large_scale)
end

loss(u,p) = -Float64(calc_precip(u))
f = OptimizationFunction(loss)
lb = [0, -2000, 0, -180, -90, 270, 270, 280, 5, 0.0 ,0.0]
ub = [2, 5000, 30, 180, 90, 300, 300, 305, 50, 1e-4, 305]
x0 = (lb .+ ub) ./ 2
prob = Optimization.OptimizationProblem(f, x0; lb, ub)

function callback(state, l) #callback function to observe training
    display(l)
    return false
end

sol = solve(prob, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters = 10000,
    maxtime = 10000.0, callback = callback)

loss(sol.u, nothing)

julia> @show sol.u
sol.u = [0.35189195474845386, -777.7890066578076, 14.561382886621368, 151.4405147870285, -0.8557381444610144, 296.3475643734993, 277.9450731849207, 304.0433587248594, 31.637335763119115, 6.329669836967033e-6, 169.16288037057643]
=#

using SpeedyWeather
using RainMaker

PARAMETER_KEYS = (
    :orography_scale,           # [1],      default: 1, scale of global orography
    :mountain_height,           # [m],      default: 0, height of an additional azores mountain
    :mountain_size,             # [˚],      default: 1, horizontal size of an additional azores mountain
    :mountain_lon,              # [˚E],     default: -27.25, longitude of an additional azores mountain
    :mountain_lat,              # [˚N],     default: 38.7, latitude of an additional azores mountain
    :temperature_equator,       # [K],      default: 300, sea surface temperature at the equator
    :temperature_pole,          # [K],      default: 273, sea surfaec temperature at the poles
    :sea_surface_temperature,   # [K],      default: 273, sea surface temperature anomaly in the atlantic
    :zonal_wind,                # [m/s],    default: 35, zonal wind speed
    :rotation,                  # [],       default: 7.9e-5, Earth rotation
    :ocean_temp,                # [K],      default: 175,
)

# output from the surrogate model
best_param_sample = [0.35189195474845386, 
      -777.7890066578076, 
      14.561382886621368, 
      151.4405147870285, 
      -0.8557381444610144, 
      296.3475643734993, 
      277.9450731849207, 
      304.0433587248594, 
      31.637335763119115, 
      6.329669836967033e-6,
      169.16288037057643
]

# wrap into named tuple
parameters = NamedTuple{PARAMETER_KEYS}(best_param_sample)

# define resolution. Use trunc=42, 63, 85, 127, ... for higher resolution, cubically slower
spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# Define AquaPlanet ocean, for idealised sea surface temperatures
# but don't change land-sea mask = retain real ocean basins
ocean = AquaPlanet(spectral_grid,
            temp_equator=parameters.temperature_equator,
            temp_poles=parameters.temperature_pole)

# add initial conditions with a stronger zonal wind matching temperature
initial_conditions = InitialConditions(
    vordiv = ZonalWind(u₀=parameters.zonal_wind),
    temp = JablonowskiTemperature(u₀=parameters.zonal_wind),
    pres = PressureOnOrography(),
    humid = ConstantRelativeHumidity())

# Earth's orography but scaled
orography = EarthOrography(spectral_grid, scale=parameters.orography_scale)

# construct model
model = PrimitiveWetModel(spectral_grid; ocean, initial_conditions, orography, planet=Earth(Float32, rotation=parameters.rotation))

# Add rain gauge, locate on Terceira Island
rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)

# Initialize
simulation = initialize!(model, time=DateTime(2025, 1, 10))

# Add additional  mountain
H = parameters.mountain_height
λ₀, φ₀, σ = parameters.mountain_lon, parameters.mountain_lat, parameters.mountain_size
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2), add=true)

set!(simulation, temp = (λ, ϕ, σ) -> parameters.ocean_temp)
set!(simulation, sea_surface_temperature = (λ, φ) -> parameters.sea_surface_temperature)

# Run simulation for 20 days, maybe longer for more stable statistics? Could be increased to 30, 40, ... days ?
run!(simulation, period=Day(20))
