# Submit to the RainMaker challenge

The easiest is to have a look a existing submissions listed in
[List of submissions](@ref). Submit by creating a pull request
adding a julia script `file_name.jl` in the folder `/submissions`
of the repository. This script contains your SpeedyWeather
model setup including instructions to run the model so
that the [RainGauge](@ref) records for 20 days for a 20-day challenge.

After executing this script there needs
to be in the global scope of that script the following variables defined

- a `rain_gauge::RainGauge` having measured precipitation
- an `author::String`, e.g. `author = "Kermit the Frog"`
- a `description::String` describing your model setup in a few words

with those *exact* variable names. You can define anything else you want,
e.g. `rain_gauge2` but only `rain_gauge` would be used to evaluate your
submission to the challenge.
The rain gauge `rain_gauge` needs to be added to a SpeedyWeather simulation
as outlined in [Adding RainGauge as callback](@ref).
The `author` and `description` strings are used in the [List of submissions](@ref) and
the [Leaderboard](@ref). 

## Rules

1. All precipitation measured by the rain gauge has to be simulated by SpeedyWeather.
2. No changes to the following physics inside SpeedyWeather: Large-scale condensation, convection, surface evaporation, or radiation.
3. Sea and land surface temperatures cannot exceed 305K anywhere during the simulation.