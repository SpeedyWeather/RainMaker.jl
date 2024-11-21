author = "Thomas Stone"
description = "Humid"

using SpeedyWeather, RainMaker

# create a model
spectral_grid = SpectralGrid(trunc=31, nlayers=8)
ocean = AquaPlanet(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# run the simulation
simulation = initialize!(model, time=DateTime(2000,10,25))
simulation.prognostic_variables.clock

# add 2 K to N Atlantic
simulation = initialize!(model)
set!(model, land_sea_mask=0)    # all ocean!
set!(simulation, sea_surface_temperature=(λ, φ) -> (30 < φ < 60) && (270 < λ < 360) ? 10 : 0, add=true)


# set to a global constant
set!(model, orography=0)

# add two 2000m ridges at +-30˚E from 60˚S to 60˚N
H, λ₀, φmax = 20000, 15, 60

# add two Gaussian mountains
λ1, λ2  = (120, 240)    # longitude positions [˚E]
φ₀ = 44                 #latitude
σ = 7.4               # width [˚]

# first mountain, radius=360/2π to have distance in ˚ again (not meters)
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ1,φ₀), radius=360/2π)^2/2σ^2), add=true)

# and add second
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ2,φ₀), radius=360/2π)^2/2σ^2), add=true)

set!(simulation, humid=0.18)
run!(simulation, period=Day(20))


# visualise 
RainMaker.plot(rain_gauge)