# RainMaker.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://speedyweather.github.io/RainMaker.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://speedyweather.github.io/RainMaker.jl/dev/)
[![Build Status](https://github.com/SpeedyWeather/RainMaker.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SpeedyWeather/RainMaker.jl/actions/workflows/CI.yml?query=branch%3Amain)

A repository for the atmospheric general circulation model
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl)
to measure and document precipitation at a given location.
In particular, this repository contains functions and a documentation
to show off and rank model setups that make it rain as much
as possible at a certain location (e.g. UK) within a certain period.
New model setups can be submitted and are automatically evaluated
and ranked in the documentation to create a leader board
for the most successful *rainmaker*.

## Measuring precipitation with `RainGauge`

RainMaker.jl exports `RainGauge` which is fully described
in the [documentation](https://speedyweather.github.io/RainMaker.jl/dev/rain_gauge/).
In short,

```julia
using SpeedyWeather, RainMaker

# create a model
spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(;spectral_grid)

# add the rain gauge as callback
rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

# run the simulation
simulation = initialize!(model)
run!(simulation, period=Day(20))

# visualise 
RainMaker.plot(rain_gauge)
```

which will produce a [Makie.jl](https://github.com/MakieOrg/Makie.jl) plot

![Rain gauge plot](https://speedyweather.github.io/RainMaker.jl/dev/rain_gauge.png)

## Submit to the RainMaker challenge

Create a pull request with a julia script `file_name.jl` to be placed
in the folder `/submissions`. After executing this script there needs
to be in the global scope of that script the following variables defined

- a `rain_gauge::RainGauge` having measured precipitation of a SpeedyWeather.jl simulation
- an `author::String`, e.g. `author = "Kermit the Frog"`
- a `description::String` describing your model setup in a few words (<6 probably), e.g. `description = "3000m mountain in the atlantic"` or `"300K aquaplanet"`.

See 
[Submit to the RainMaker challenge](https://speedyweather.github.io/RainMaker.jl/dev/submit/#Submit-to-the-RainMaker-challenge)
and [Rules](https://speedyweather.github.io/RainMaker.jl/dev/submit/#Rules)
in the documentation for more details.

## Current leader board

See [the leaderboard](https://speedyweather.github.io/RainMaker.jl/dev/leaderboard/)
in the documentation.
