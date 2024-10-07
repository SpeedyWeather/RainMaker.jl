# RainTracker

RainMaker.jl exports the callback `RainTracker`, the following explains
how to use this callback. With a `SpectralGrid` from
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl)
(see [here](https://speedyweather.github.io/SpeedyWeather.jl/dev/how_to_run_speedy/#SpectralGrid)) you can create `RainTracker`. In most cases you
will probably want to specify the rain tracker's location
with `lond` (0...360˚E) and `latd` (-90...90˚N)`

```@example rain_tracker
using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid()  # default resolution
rain_tracker = RainTracker(spectral_grid, lond=358.75, latd=51.75)
```

(see `?RainTracker` for more information). The `track_counter`
starts at `0` and just counts up the number of measurements the
raintracker has made, one per timestep -- zero also means that the tracker
is not initialized. In order to reconstruct the time axis
the fields `tstart` and `Δt` are used but they will be automatically
set when initialized given the time step in the model.
At any time you can always `reset!(rain_tracker)` in order
to reset counters, time and all rainfall measurements.
But a `RainTracker` is also mutable, meaning you can do
this by hand too, e.g. `rain_tracker.accumulated_rain_large_scale .= 0`.