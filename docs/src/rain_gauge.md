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
with `lond` (0...360˚E, -180...180˚E also work) and `latd` (-90...90˚N)`

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
`accumulated_rain_convection` where every entry is one measurement
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
(`<:` means "subtype of"). A
[Callback](https://speedyweather.github.io/SpeedyWeather.jl/dev/callbacks/#Callbacks)
is an object (technically a `struct` introducing a new type that belongs to the
supertype `AbstractCallback`) with methods defined that are executed after
every time step of the model. A callback therefore allows you to inject any piece
of code into a simulation. Many callbacks are "diagnostic" meaning they just read
out variables but you could also define "intrusive" callbacks
that change the model or the simulation while it is running
(not covered here but see
[Intrusive callbacks](https://speedyweather.github.io/SpeedyWeather.jl/dev/callbacks/#intrusive_callbacks)).

A `RainGauge` can be added to a model with `add!`

```@example rain_gauge
model = PrimitiveWetModel(spectral_grid)
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

You can also `delete!` a `RainGauge` (or any callback) again,
but you need to know its key for that which is printed to screen
when added or just inspect

```@example rain_gauge
model.callbacks
```

then with `delete!(model.callbacks, :callback_????)` where `:callback_????`
is a [Symbol](https://docs.julialang.org/en/v1/manual/metaprogramming/#Symbols)
(an immutable string) identifying the callback you want to delete.

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

## Skipping first days

After a `rain_gauge` has recorded one can skip the first `n` days
(or any period) using the `skip` function. 
```@example rain_gauge
rain_gauge_day10to20 = skip(rain_gauge, period=Day(10))
```
(or use `skip!` as its in-place version, changing the `rain_gauge`
directly). In this case, skipping the first 10 days is somewhat
equivalent to only measuring the second 10 days in the
example from the previous section. However, skipping does not delete
the measurements in the skipped period but normalizes the accumulated
rainfall so that it is zero at the end of the skipped period.
And consequently the accumulated rainfall is now negative at
the start of the skipped period, this is better explained through
and illustration in the next section.

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

The `RainMaker.plot` functions takes as optional keyword argument
`rate_Δt::Period` so that you can change the binwidth of the
precipitation rate. Above we have one bin every 6 hours (the default), showing
the average rate over the previous 6 hours. You can visualise
the hourly precipitation rate with

```@example rain_gauge
RainMaker.plot(rain_gauge, rate_Δt=Hour(1))
save("rain_gauge2.png", ans) # hide
nothing # hide
```
![Rain gauge plot, hourly rate](rain_gauge2.png)

which just gives you a more fine-grained picture. Arguments
can be `Hour(::Real)`, `Minute(::Real)`, `Day(::Real)`
but note that the default model time step at default resolution
is 30min, so you do not get any more information when going
lower than that.

`RainMaker.plot` also allows to skip an initial period,
see [Skipping first days](@ref), which is equivalent to calling `plot`
on a rain gauge which has already been skipped,
e.g. `RainMaker.plot(rain_gauge, skip=Day(10))`
is the same as `RainMaker.plot(skip(rain_gauge, Day(10)))`.

```@example rain_gauge
RainMaker.plot(rain_gauge, skip=Day(10))
save("rain_gauge_skip.png", ans) # hide
nothing # hide
```
![Rain gauge plot, first 10 days skipped](rain_gauge_skip.png)

This plot nicely illustrates what it means to "skip the first 10 days":
This does not delete measurements but it renormalizes the accumulated
precipitation to start in the negative, crosses zero at the end of the
skipped period. The total accumulated rainfall at the end of the
full period is then equivalent as if no measurements would have taken
place from day 0 to day 10 without actually erasing any data.

## Visualising accumulated rainfall globally

SpeedyWeather simulations diagnose the _accumulated_ rainfall internally.
Which is actually what a `RainGauge` reads out on every time step at
the specified location (but see details in [Discarding spin-up](@ref)).
This means you can also visualise a map of the accumulated rainfall since the
beginning of the simulation to better understand regional rainfall patterns.
SpeedyWeather uses largely SI units internally, but `RainGauge` converts
meters to millimeters because that is the more common unit for rainfall.
If we read out SpeedyWeather's fields manually we therefore have to do
this conversion manually too. Total precipitation is the sum of convective
and large-scale precipitation which we can calculate and visualise like this

```@example rain_gauge
# (; a, b) = struct unpacks the fields a, b in struct identified by name, equivalent to
# a = struct.a and b = struct.b
(; precip_large_scale, precip_convection) = simulation.diagnostic_variables.physics
total_precipitation = precip_large_scale + precip_convection
total_precipitation *= 1000    # convert m to mm

using CairoMakie
heatmap(total_precipitation, title="Total precipitation [mm], accumulated")
save("total_precip_map.png", ans) # hide
nothing # hide
```
![Map of total accumulated precipitation](total_precip_map.png)

You can also visualise these fields individually. The accumulation starts when
the model is initialized with `simulation = initialize!(model)` which constructs
variables, initialized with zeros, too. This means the accumulation will
continue across several `run!` calls unless you manually set it back via
```@example rain_gauge
simulation.diagnostic_variables.physics.precip_large_scale .= 0
simulation.diagnostic_variables.physics.precip_convection .= 0
nothing # hide
```
The `.` here is important to specify the broadcasting of the scalar `0` on the right
to the array on the left. This was not needed in `*= 1000` above as scalar times vector/matrix is mathematicall already well defined.

## Discarding spin-up

A `RainGauge` starts measuring accumulated rainfall relative to the
first `run!(simulation)` call after it has been added to the model with
`add!`, see [Adding RainGauge as callback](@ref). This means that
you can run a simulation without a `RainGauge` and then only start
measuring precipitation after some time has passed. You
can use this to discard any spin-up ( = adjustment after initial conditions)
of a simulation. Let us illustrate this

```@example rain_gauge
model = PrimitiveWetModel(spectral_grid)

# add one rain gauge the measures the whole simulation
rain_gauge_from_beginning  = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge_from_beginning)

simulation = initialize!(model)
run!(simulation, period=Week(1))

# add another rain gauge that only starts measuring
# after that week we already simulated
rain_gauge_after_spinup  = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge_after_spinup)
run!(simulation, period=Day(10))

# now compare them, from the beginning
rain_gauge_from_beginning
```

versus

```@example rain_gauge
# rain gauge after a 1-week spinup
rain_gauge_after_spinup
```

As you can see their clocks differ and so does the measured precipitation!


## Functions and types

```@index
```

```@autodocs
Modules = [RainMaker]
```


