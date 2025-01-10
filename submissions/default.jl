author = "Milan"
description = "default"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(spectral_grid)

rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)

simulation = initialize!(model)
run!(simulation, period=Day(20))