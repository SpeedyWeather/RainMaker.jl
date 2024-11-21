author = "Alex Dobra and Charlotte Wargniez"
description = "Aqua planet, change humidity to ridiculous number, add Shirin's mountain, make it cold"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=5)
model = PrimitiveWetModel(spectral_grid)

# Set up aqauaplanet but add large mountain in "North Sea" after initialization!
ocean = AquaPlanet(spectral_grid, temp_equator=305, temp_poles=305
)
land = ConstantLandTemperature(spectral_grid, temperature=275)
model = PrimitiveWetModel(spectral_grid; ocean, land)

# Add rain gauge
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# Initialize and run simulation
simulation = initialize!(model, time=DateTime(2000, 6, 21))

# Add mountain now! details for mountain
H, λ₀, φ₀, σ = 5000, 2, 51, 3     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))

# make mountain Land
set!(model, land_sea_mask=(λ, φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2), add=true)


# set humidity
set!(simulation, humid=9e-2,
# temp=275
)

# Run simulation for 20 days
run!(simulation, period=Day(20))

RainMaker.plot(rain_gauge, rate_Δt=Hour(1))