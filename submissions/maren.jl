author = "Maren"
description = "Hot aqua planet with SST anomalie"

using SpeedyWeather, RainMaker
using CairoMakie

# create a model
spectral_grid = SpectralGrid(trunc=31, nlayers=8)
ocean = AquaPlanet(spectral_grid, temp_equator = 300.0, temp_poles= 300.0)
model = PrimitiveWetModel(spectral_grid; ocean)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
set!(model)
set!(simulation, sea_surface_temperature=(λ, φ) -> (50 < φ < 53) && (50 < λ < 60) ? 5 : 0, add=true)
run!(simulation, period=Day(20))