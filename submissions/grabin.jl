author = "George"

using SpeedyWeather, RainMaker

# create a model
spectral_grid = SpectralGrid(trunc=31, nlayers=8)
ocean = AquaPlanet(spectral_grid)
land = ConstantLandTemperature(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# run the simulation
simulation = initialize!(model, time=DateTime(2000, 10, 25))
simulation.prognostic_variables.clock

# CHANGING sea surface and land temperature
simulation = initialize!(model)
set!(model, land_sea_mask=0)    # all ocean
set!(simulation, sea_surface_temperature=(λ, φ) -> (30 < φ < 60) && (270 < λ < 360) ? 1 : 0, add=true)

simulation = initialize!(model)
set!(model, land_sea_mask=1)    # all land
set!(simulation, sea_surface_temperature=(λ, φ) -> (0 < φ < 360) && (270 < λ < 360) ? 10 : 0, add=true)

sst = simulation.prognostic_variables.ocean.sea_surface_temperature

# ADDING A mountain
H, λ₀, φmax = 2000, 15, 60

# set to a global constant
set!(model, orography=0)

# add two Gaussian mountains
λ1, λ2  = (120, 240)    # longitude positions [˚E]
φ₀ = 44                 # latitude [˚N]
σ = 7.4                  # width [˚] 

# himalayan mountains lead to more rain than ones in eastern europe...

# first mountain, radius=360/2π to have distance in ˚ again (not meters)
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ1,φ₀), radius=360/2π)^2/2σ^2), add=true)

# and add second
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ2,φ₀), radius=360/2π)^2/2σ^2), add=true)
set!(simulation, humid=0.18)
run!(simulation, period=Day(20))
