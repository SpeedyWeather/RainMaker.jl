using SpeedyWeather, RainMaker

ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=300)
land = ConstantLandTemperature(spectral_grid)

model = PrimitiveWetModel(spectral_grid; ocean, land)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
set!(model, land_sea_mask=0)    # all ocean!
set!(simulation, sea_surface_temperature=(λ, φ) -> (10 < φ < 20) && (50 < λ < 60) ? 5 : 0.5, add=true)

run!(simulation, period=Day(20))