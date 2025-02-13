author = "Chris Rackauckas"
description = "XGBoost surrogate, best parameters"

#=
# Same data as the neural network, just a dead simple surrogate

using JLSO
cd(raw"/Users/chrisrackauckas/.julia/external/speedier_speedyweather_juliaEO25")
data = JLSO.load("10kdata.jlso")[:d]
X = data.inputs'
y = data.outputs

Xtrain = X[1:2:end, :]
Xtest  = X[2:2:end, :]
ytrain = y[1:2:end]
ytest  = y[2:2:end]

using XGBoost, Statistics

bst = xgboost((Xtrain, ytrain), num_round=1000, max_depth=7, objective="reg:squarederror")
# obtain model predictions
ŷ = predict(bst, Xtest)
mean(abs2,ŷ - ytest)

evaluate(x) = predict(bst, reshape(x,1,10))[1]

using Optimization, OptimizationBBO
function loss(x,p)
    -Float64(evaluate(x))
end
f = OptimizationFunction(loss)
lb = [0, -2000, 0, -180, -90, 270, 270, -5, -5, 5]
ub = [2, 5000, 30, 180, 90, 300, 300, 5, 5, 50]
x0 = Xtest[1,:]
prob = Optimization.OptimizationProblem(f, x0; lb, ub)

function callback(state, l) #callback function to observe training
    display(l)
    return false
end

sol = solve(prob, BBO_adaptive_de_rand_1_bin_radiuslimited(), maxiters = 100000,
    maxtime = 1000.0, callback = callback)
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
    :temperature_atlantic,      # [K],      default: 0, sea surface temperature anomaly in the atlantic
    :temperature_azores,        # [K],      default: 0, sea surface temperature anomaly at the azores
    :zonal_wind,                # [m/s],    default: 35, zonal wind speed
)

# output from the surrogate model
best_param_sample = [0.3705309673344287, 
  3693.5996052143146, 
  26.3392947114213, 
  -68.49507115449609, 
  75.0016456129241, 
  295.8298679043166, 
  296.00395874468376, 
  4.7262056077412495, 
  4.371020708252552, 
  46.16767297988565
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
