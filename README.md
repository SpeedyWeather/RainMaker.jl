# RainMaker.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://speedyweather.github.io/RainMaker.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://speedyweather.github.io/RainMaker.jl/dev/)
[![Build Status](https://github.com/SpeedyWeather/RainMaker.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SpeedyWeather/RainMaker.jl/actions/workflows/CI.yml?query=branch%3Amain)

A repository for the atmospheric general circulation model
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl)
to analyse and document precipitation at a given location.
In particular, this repository contains functions and a documentation
to show off and rank model setups that make it rain as much
as possible at a certain location (e.g. UK) within a certain period.
New model setups can be submitted and are automatically evaluated
and ranked in the documentation to create a leader board
for the most successful *rainmaker*.

## Analysing precipitation

```julia
using SpeedyWeather, RainMaker

# create a model
spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(;spectral_grid)

# add the rain tracker as callback
rain_tracker = RainTracker(spectral_grid, lond=-1.25, latd=51.75)
add!(model.callbacks, rain_tracker)

# run the simulation
simulation = initialize!(model)
run!(simulation, period=Day(30))

# visualise 
RainMaker.plot(rain_tracker)
```

## Submitting to the RainMaker challenge

...

## Current leader board

See the [documentation](https://speedyweather.github.io/RainMaker.jl/dev/).
