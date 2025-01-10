author = "Anas"
description = "Surrogate best parameters"

using SpeedyWeather
using RainMaker

const PARAMETER_KEYS = (
    :orography_scale,           # [1],      default: 1, scale of global orography
    :mountain_height,           # [m],      default: 0, height of an additional azores mountain
    :mountain_size,             # [˚],      default: 1, horizontal size of an additional azores mountain
    :mountain_lon,              # [˚E],     default: -27.25, longitude of an additional azores mountain
    :mountain_lat,              # [˚N],     default: 38.7, latitude of an additional azores mountain
    :temperature_equator,       # [K],      default: 300, sea surface temperature at the equator
    :temperature_pole,          # [K],      default: 273, sea surfaec temperature at the poles
    :temperature_atlantic,      # [K],      default: 0, sea surface temperature anomaly in the atlantic
    :temperature_azores,        # [K],      default: 0, sea surface temperature anomaly at the azores
    :zonal_wind,                # [m/s],    default: 35, zonal wind speed
)

# output from the surrogate model
best_param_sample = [
    0.243467,
    3456.64,
    21.2324,
    -90.1826,
    58.4064,
    287.617,
    295.99,
    4.98632,
    3.45722,
    50.0179,
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
model = PrimitiveWetModel(spectral_grid; ocean, initial_conditions, orography)

# Add rain gauge, locate on Terceira Island
rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)

# Initialize
simulation = initialize!(model, time=DateTime(2025, 1, 10))

# Add additional  mountain
H = parameters.mountain_height
λ₀, φ₀, σ = parameters.mountain_lon, parameters.mountain_lat, parameters.mountain_size  
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2), add=true)

# set sea surface temperature anomalies
# 1. Atlantic
set!(simulation, sea_surface_temperature=
    (λ, φ) -> (30 < φ < 60) && (270 < λ < 360) ? parameters.temperature_atlantic : 0, add=true)

# 2. Azores
A = parameters.temperature_azores
λ_az, φ_az, σ_az = -27.25, 38.7, 4    # location [˚], size [˚] of Azores
set!(simulation, sea_surface_temperature=
    (λ, φ) -> A*exp(-spherical_distance((λ, φ), (λ_az, φ_az), radius=360/2π)^2/2σ_az^2), add=true)

# Run simulation for 20 days, maybe longer for more stable statistics? Could be increased to 30, 40, ... days ?
run!(simulation, period=Day(20))