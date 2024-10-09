author = "Milan"
description = "default"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(; spectral_grid)
model.feedback.verbose = false # hide

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
run!(simulation, period=Day(20))