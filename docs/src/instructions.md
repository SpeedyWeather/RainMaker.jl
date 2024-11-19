# Instructions

While the [List of submissions](@ref) gives you some idea of what you can do make it rain
more or less in a SpeedyWeather simulation, the following provides more instructions
and serves as an introduction to atmospheric modelling with SpeedyWeather.

## General workflow to run SpeedyWeather

There's more information in the [SpeedyWeather documentation](https://speedyweather.github.io/SpeedyWeather.jl/dev/how_to_run_speedy/)
but in short there are 4 steps

```julia
# 1. define the resolution
spectral_grid = SpectralGrid(trunc=31, nlayers=8)

# 2. create a model
model = PrimitiveWetModel(spectral_grid)

# 3. initialize the model
simulation = initialize!(model)

# 4. run the model
run!(simulation, period=Day(10))
```

You can add a [RainGauge](@ref) to measure precipitation, but the following will
focus on ways you can change the model, impacting what's been simulated.
They may or may not have a large impact on the simulated precipitation but
that is up to you to figure out.

## Change the resolution

## Change the grid

## Change the time step

## Change the season

## Change the orography

## Change the land-sea mask

## Change the surface temperatures

## Change the initial conditions