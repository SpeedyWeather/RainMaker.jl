author = "Isaac Campbell"
description = "Up initial humidity and lower saturation vapour pressure."

using SpeedyWeather, RainMaker

# Create grid
spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# Alter the laws of physics... lower saturation vapour pressure to 50Pa
atm = EarthAtmosphere(spectral_grid)
clausius_clapeyron = ClausiusClapeyron(spectral_grid, atm, e₀=50)

model = PrimitiveWetModel(spectral_grid; clausius_clapeyron)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# run the simulation
simulation = initialize!(model, time=DateTime(2000, 8, 1))

# Increase initial humidity
set!(simulation, humid=0.177)
run!(simulation, period=Day(20))

# visualise 
RainMaker.plot(rain_gauge)
