author = "Milan"
description = "Aquaplanet"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# define aquaplanet
ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=273)
land_sea_mask = AquaPlanetMask(spectral_grid)
orography = NoOrography(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean, land_sea_mask, orography)

rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)

simulation = initialize!(model)
run!(simulation, period=Day(20))