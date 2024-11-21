author = "Jordan"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)

ocean = AquaPlanet(spectral_grid, temp_equator=302, temp_poles=301)
land = ConstantLandTemperature(spectral_grid)

model = PrimitiveWetModel(spectral_grid; ocean, land)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
set!(model, land_sea_mask=0)    # all ocean!
set!(simulation, sea_surface_temperature=(λ, φ) -> (10 < φ < 20) && (52 < λ < 58) ? 3 : 0.5, add=true)

# set to a global constant
set!(model, orography=0)

# add two Gaussian mountains
λ1, λ2  = (120, 240)    # longitude positions [˚E]
φ₀ = 45                 # latitude [˚N]
σ = 5                   # width [˚]

# first mountain, radius=360/2π to have distance in ˚ again (not meters)
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ1,φ₀), radius=360/2π)^2/2σ^2), add=true)

set!(simulation, humid=0.15)

run!(simulation, period=Day(20))
