author = "Milan"
description = "300K Aquaplanet"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# define 300K aquaplanet
ocean = AquaPlanet(spectral_grid, temp_equator=300, temp_poles=300)
land_sea_mask = AquaPlanetMask(spectral_grid)
model = PrimitiveWetModel(; spectral_grid, ocean, land_sea_mask)

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
run!(simulation, period=Day(20))