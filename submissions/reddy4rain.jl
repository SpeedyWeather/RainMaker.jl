author = "Reddy4rain"

using SpeedyWeather, RainMaker

# 1. define the resolution
spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# 2. create a model
model = PrimitiveWetModel(spectral_grid)

# 3. initialize the model
simulation = initialize!(model)

# 4. run the model
run!(simulation, period=Day(10))