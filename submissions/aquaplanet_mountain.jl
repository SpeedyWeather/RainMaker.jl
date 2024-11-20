author = "Shirin Ermis"
description = "Aqua-planet simulation with a mountain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=10)
model = PrimitiveWetModel(spectral_grid)

# Details for mountain
H, λ₀, φ₀, σ = 4000, 2, 51, 5     # height, lon, lat position, and width

# Set up aqauaplanet with large mountain in "North Sea"
ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=300)
orography = NoOrography(spectral_grid)
# land_sea_mask = AquaPlanetMask(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean, orography)
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))

# Add rain gauge
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# Initialize and run simulation
simulation = initialize!(model, time=DateTime(2000, 9, 1))

# Run simulation for 20 days
run!(simulation, period=Day(20))

# Plot the results
using CairoMakie
# heatmap(model.orography.orography, title="My orogoraphy [m]") # check orography
RainMaker.plot(rain_gauge, rate_Δt=Hour(1))
