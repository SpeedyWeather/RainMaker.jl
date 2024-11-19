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

SpeedyWeather is a spectral model. That means it internally represents its variables
as coefficients of horizontal waves on the sphere (the [_spherical harmonics_](https://en.wikipedia.org/wiki/Spherical_harmonics))
up to a certain maximum wavenumber that is usually referred to as _truncation_.
So for a truncation of 31, SpeedyWeather would resolve wavenumbers 0 to 31,
but not 32 and larger. The higher the truncation the higher the resolution 
and automatically chosen higher resolution of the grid. You control the resolution
through the keyword argument `trunc` of the `SpectralGrid` object that defines
the resolution of a simulation

```@example instructions
spectral_grid =  SpectralGrid(trunc=42)
```

Now change `trunc` (e.g. 31, 42, 63, 85, 127) and check what happens to
precipitation when you run a simulation at that resolution. You can also change
the number of vertical layers with the keyword argument `nlayers`, e.g.

```@example instructions
spectral_grid =  SpectralGrid(trunc=31, nlayers=5)
```

Try to find out more generally, with changing `trunc` and `nlayers`

- How does the grid spacing change?
- How does the speed of the simulation change?

Bonus question

- Why 31, 42, 63, ... as given above? For more details see [Available horizontal resolutions](https://speedyweather.github.io/SpeedyWeather.jl/dev/spectral_transform/#Available-horizontal-resolutions) and [Matching spectral and grid resolution](https://speedyweather.github.io/SpeedyWeather.jl/dev/grids/#Matching-spectral-and-grid-resolution)
- How are the vertical layers spaced? Check `spectral_grid.vertical_coordinates` and read on [Sigma coordinates](https://speedyweather.github.io/SpeedyWeather.jl/dev/primitiveequation/#Sigma-coordinates)


## Change the grid

While SpeedyWeather is a spectral model not all computations are done in spectral space,
many are still done in grid space. That's why people often call this method also _pseudo_-spectral.
You can control the grid through the argument `Grid`

```@example instructions
spectral_grid =  SpectralGrid(trunc=31, Grid=FullGaussianGrid)
```

Try `FullGaussianGrid`, `FullClenshawGrid`, `OctahedralGaussianGrid`, or `HEALPixGrid`
among [others](https://speedyweather.github.io/SpeedyWeather.jl/dev/grids/). Do they
have any impact on the simulated precipitation? More generally

- Which grids have more, which fewer (horizontal) grid points at a given `trunc`?
- On each grid, are the grid cells globally of similar size or not?
- [Visualise](https://speedyweather.github.io/SpeedyWeather.jl/dev/grids/#Interactively-exploring-the-grids) the grids!

Bonus question

- A higher/lower `dealiasing` increases/decreases the grid resolution without changes the spectral resolution. Why would one do that?


## Change the time step

The time step of SpeedyWeather is controlled through the time stepping method of the model. This model component
needs to know the spatial resolution to pick a time step by default that is stable, but you can still control this.
SpeedyWeather's time integration is based on the `Leapfrog` scheme, so you create such a component like this

```julia
time_stepping = Leapfrog(spectral_grid, Δt_at_T31=Minute(20))
```

where the argument `Δt_at_T31` determines the timestep `Δt` (write `\Delta` then hit tab) relative to a truncation of
31 (called T31), the actual time step is then in `Δt_sec`, scaled linearly from T31 to whatever resolution you chose.
You can provide any `Second`, `Minute`, `Hour` (but note that there is a stability limit above which your simulation quickly blows up).

- How large a time step can you choose for a T31 resolution?
- How does the speed or simulation time change with a changed time step?

Bonus question

- How do you choose a sensible time step?

## Change the season

## Change the orography

## Change the land-sea mask

## Change the surface temperatures

## Change the initial conditions