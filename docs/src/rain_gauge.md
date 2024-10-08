# RainGauge

RainMaker.jl exports the callback `RainGauge`, the following explains
how to use this callback. With a `SpectralGrid` from
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl) (see
[here](https://speedyweather.github.io/SpeedyWeather.jl/dev/how_to_run_speedy/#SpectralGrid))
you can create `RainGauge`. In most cases you
will probably want to specify the rain gauge's location
with `lond` (0...360˚E) and `latd` (-90...90˚N)`

```@example rain_gauge
using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid()  # default resolution
rain_gauge = RainGauge(spectral_grid, lond=358.75, latd=51.75)
```

(see `?RainGauge` for more information). The `track_counter`
starts at `0` and just counts up the number of measurements the
raingauge has made, one per timestep -- zero also means that the gauge
is not initialized. In order to reconstruct the time axis
the fields `tstart` and `Δt` are used but they will be automatically
set when initialized given the time step in the model.
At any time you can always `reset!(rain_gauge)` in order
to reset counters, time and all rainfall measurements.
But a `RainGauge` is also mutable, meaning you can do
this by hand too, e.g. `rain_gauge.accumulated_rain_large_scale .= 0`.

## Adding RainGauge as Callback

The `RainGauge` is implemented as a `<: SpeedyWeather.AbstractCallback`
so that it can be added to a model with `add!`

```@example rain_gauge
model = PrimitiveWetModel(;spectral_grid)
add!(model, rain_gauge)
```

## Visualising RainGauge measurements

After running a simulation the rain gauge measurements can be visualised
with

```@example rain_gauge
simulation = initialize!(model)
run!(simulation, period=Day(20))
RainMaker.plot(rain_gauge)
save("rain_gauge.png", ans) # hide
nothing # hide
```
![Rain gauge plot](rain_gauge.png)
