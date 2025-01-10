author = "Iga"
description = "Just playing around"

using SpeedyWeather    # v0.13 (or #main)
using RainMaker        # v0.2 (or #main)

spectral_grid = SpectralGrid(trunc=31, nlayers=8)

model = PrimitiveWetModel(spectral_grid)

rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)    # add to model.callbacks
rain_gauge

simulation = initialize!(model)

model = PrimitiveWetModel(spectral_grid)
rain_gauge101 = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge101)
simulation = initialize!(model, time=DateTime(2000, 2, 1))

H = 8000           # height [m]
λ_azores = -27.25  # longitude [˚E]
φ_azores = 37.3   # latitude [˚N] 
σ = 4             # size [˚]

# define bigger azores as anonymous function, Gaussian mountain, use radius=360/2π for distance in [˚]
bigger_azores = (λ, φ) -> H*exp(-spherical_distance((λ, φ), (λ_azores, φ_azores), radius=360/2π)^2/2σ^2)

# add to default orography, don't replace
set!(model, orography=bigger_azores, land_sea_mask=0, add=true)
set!(simulation, temp=0, sea_surface_temperature=(λ, φ) -> (30 < φ < 60) && (270 < λ < 360) ? 2 : 0, add=true)

run!(simulation, period=Day(20))
