author = "Shirin Ermis"
description = "Aqua-planet simulation with a mountain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=10)
model = PrimitiveWetModel(spectral_grid)

# Set up aqauaplanet but add large mountain in "North Sea" after initialization!
ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=300)
land_sea_mask = AquaPlanetMask(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean, land_sea_mask)

# Add rain gauge
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# Initialize and run simulation
simulation = initialize!(model, time=DateTime(2000, 9, 1))

# Add mountain now! details for mountain
H, λ₀, φ₀, σ = 4000, 2, 51, 5     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))

# Run simulation for 20 days
run!(simulation, period=Day(20))

# Plot the results (not needed for submission but doesn't hurt!)
using CairoMakie
# heatmap(model.orography.orography, title="My orogoraphy [m]") # check orography
RainMaker.plot(rain_gauge, rate_Δt=Hour(1))
