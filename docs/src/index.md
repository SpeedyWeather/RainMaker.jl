```@meta
CurrentModule = RainMaker
```

# RainMaker

Documentation for [RainMaker](https://github.com/SpeedyWeather/RainMaker.jl),
a repository to measure precipitation inside a
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl) simulation


Contents

- [Installation](@ref)
- [RainGauge](@ref), measuring precipitation inside a 
- [Submit to the RainMaker challenge](@ref)
- [RainMaker leaderboard](@ref)
- [List of submissions](@ref)

## Installation

[RainMaker.jl](https://github.com/SpeedyWeather/RainMaker.jl) is not (yet?) an official
Julia package, so you have to install it by specifying its repository url.

```julia
julia> ] add https://github.com/SpeedyWeather/RainMaker.jl#main
```

Where `]` opens Julia's package manager [Pkg.jl](https://pkgdocs.julialang.org/v1/)
which is also a package itself, so you can alternatively do

```julia
using Pkg
Pkg.add(url="https://github.com/SpeedyWeather/RainMaker.jl#main")
```

Adding `#main` will install from the current main branch. RainMaker.jl depends
on (among others)

- [SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl)
- [Makie.jl](https://github.com/MakieOrg/Makie.jl) and its backend [CairoMakie](https://docs.makie.org/stable/explanations/backends/cairomakie) for plotting

while they are automatically installed to be used *within* RainMaker.jl,
for many examples you will need to import them explicitly, i.e.

```julia
using SpeedyWeather, CairoMakie
```

so it is advised to also install them (so they are not just a dependency) via

```julia
julia> ] add SpeedyWeather, CairoMakie
```

or, again, `using Pkg; Pkg.add(["SpeedyWeather", "CairoMakie"])`.
