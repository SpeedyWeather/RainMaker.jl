# RainGauge

RainMaker.jl exports the callback `RainGauge`, a rain gauge that you
can place inside a SpeedyWeather simulation to measures precipitation
at a given location. The following explains how to use this `RainGauge` callback. 

With a `SpectralGrid` from
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl) (see
[here](https://speedyweather.github.io/SpeedyWeather.jl/dev/how_to_run_speedy/#SpectralGrid))
you can create `RainGauge` (it needs to know the spectral grid to interpolate
from gridded fields to a given location). In most cases you
will probably want to specify the rain gauge's location
with `lond` (0...360˚E) and `latd` (-90...90˚N)`

```@example rain_gauge
using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid()  # default resolution
rain_gauge = RainGauge(spectral_grid, lond=358.75, latd=51.75)
```

(also see `?RainGauge` for more information). The `measurement_counter`
starts at `0` and just counts up the number of measurements the
rain gauge has made, one per timestep -- zero also means that the gauge
is not initialized. In order to reconstruct the time axis
the fields `tstart` and `Δt` are used but they will be automatically
set when initialized given the time step in the model.
At any time you can always `reset!(rain_gauge)` in order
to reset the counter, time and all rainfall measurements.
But a `RainGauge` is also mutable, meaning you can do
this by hand too, e.g. `rain_gauge.accumulated_rain_large_scale .= 0`.

`RainGauge` has two vectors `accumulated_rain_large_scale` and
`accumulated_rain_convective` where every entry is one measurement
of the given precipitation type at the specified location.
One measurement is taken after every time step of the model simulation.
In order to preallocate these vectors we use `max_measurements`
as length, meaning those are the maximum number of measurements
that will be taken. An info is thrown when this point is reached
and also an instance of `RainGauge` printed to the terminal
shows you how many years of measurements you can take and how
much of that measurement "memory" is already used, see above.
If you want to measure for longer periods you may need
to increase `max_measurements` by setting it as a keyword
argument, e.g. `RainGauge(spectral_grid, max_measurements=1_000_000)`

## Adding RainGauge as callback

The `RainGauge` is implemented as a `<: SpeedyWeather.AbstractCallback`
so that it can be added to a model with `add!`

```@example rain_gauge
model = PrimitiveWetModel(;spectral_grid)
add!(model, rain_gauge)
```

Note that you can create many different (or same) `RainGauge`s and
add them all to your model in the same way. This way you can
place several "weather stations" across the globe and
measure simultaneously. Note that you will need to create
several independent `RainGauge`s for that, adding the same
`RainGauge` several times to the model is unlikely what
you will want to do (it will measure several times the same
precipitation after each time step).

## Continuous measurements across simulations

While you can `reset!(::RainGauge)` your rain gauge manually
every time, this will not happen automatically for a new
simulation if the rain gauge has already measured. This
is so that you can run one simulation, look at the
rain gauge measurements and then continue the simulation.
Let's try this by running two 10-day simulations.

```@example rain_gauge
simulation = initialize!(model)
model.feedback.verbose = false # hide
run!(simulation, period=Day(10))
rain_gauge
```
Yay, the rain gauge has measured precipitation, now let
us continue

```@example rain_gauge
run!(simulation, period=Day(10))
rain_gauge
```
which adds another 10 days of measurements as if we
had simulated directly 20 days.

## Visualising RainGauge measurements

While you always see a summary of a `RainGauge` printed to the REPL, we can also visualise all
measurements nicely with [Makie.jl](https://github.com/MakieOrg/Makie.jl).
Because RainMaker.jl has this package as a dependency
(particulary the [CairoMakie](https://docs.makie.org/stable/explanations/backends/cairomakie)
backend) the only thing to do is calling the `RainMaker.plot` function.
We do not export `plot` as it easily conflicts with other packages
exporting a `plot` function.

```@example rain_gauge
using CairoMakie # hide
RainMaker.plot(rain_gauge)
save("rain_gauge.png", ans) # hide
nothing # hide
```
![Rain gauge plot](rain_gauge.png)
