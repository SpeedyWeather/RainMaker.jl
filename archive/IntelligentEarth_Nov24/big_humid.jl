author = "Bradley and Lukas"
description = "big humid"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=60, nlayers=8) #60

ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=300)
model = PrimitiveWetModel(spectral_grid; ocean=ocean)

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)


H, λ₀, φ₀, σ = 4000, 2, 51, 5    # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))


set!(simulation, humid=0.12)

run!(simulation, period=Day(20))

