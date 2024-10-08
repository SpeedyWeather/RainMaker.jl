team_name = "Milan"
description = "PrimitiveWetModel default"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(; spectral_grid)

lond = RainMaker.DEFAULT_LOND
latd = RainMaker.DEFAULT_LATD

rain_gauge = RainGauge(spectral_grid; lond, latd)
add!(model, rain_gauge)

simulation = initialize!(model)
run!(simulation, period=RainMaker.DEFAULT_PERIOD)