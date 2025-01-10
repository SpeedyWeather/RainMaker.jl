author = "Simone"
description = "A veeery cold atmosphere"

using SpeedyWeather
using RainMaker
using Dates

# define resolution. Use trunc=42, 63, 85, 127, ... for higher resolution, cubically slower
spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# Define AquaPlanet ocean, for idealised sea surface temperatures
# but don't change land-sea mask = retain real ocean basins
ocean = AquaPlanet(spectral_grid)

# add initial conditions with a stronger zonal wind matching temperature
initial_conditions = InitialConditions(
    vordiv = ZonalWind(u₀=50),
    temp   = JablonowskiTemperature(),
    pres   = PressureOnOrography(),
    humid  = ConstantRelativeHumidity())

# Earth's orography but scaled
orography = EarthOrography(spectral_grid, scale=0.25)

# Let's reduce the rotation rate to make the planet run slower
model = PrimitiveWetModel(spectral_grid; ocean, initial_conditions, orography, planet=Earth(Float32, rotation=1e-5))

# Pick the location of the Azores (Terceira Island)
λₒ = -27.25
φ₀ = 38.7

# Add rain gauge, locate on Terceira Island
rain_gauge = RainGauge(spectral_grid, lond=λₒ, latd=φ₀)
add!(model, rain_gauge)

# Initialize
simulation = initialize!(model, time=DateTime(2025, 1, 10))

# A hot ocean under a veeeeeeeeery cold atmosphere
set!(simulation, sea_surface_temperature=(λ, φ)->305)
set!(simulation, temp=(λ, ϕ, σ)->175)

run!(simulation, period=Day(20))

# Plot the results (not needed for submission but doesn't hurt!)
using CairoMakie
# heatmap(model.orography.orography, title="My orogoraphy [m]") # check orography
RainMaker.plot(rain_gauge, rate_Δt=Hour(1), skip=Day(5))
