```@meta
CurrentModule = RainMaker
```

# RainMaker

Documentation for [RainMaker](https://github.com/SpeedyWeather/RainMaker.jl),
a repository to measure precipitation inside a
[SpeedyWeather.jl](https://github.com/SpeedyWeather/SpeedyWeather.jl) simulation.


Contents

- [Installation](@ref)
- [New to Julia?](@ref)
- [RainGauge](@ref)
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

While they are automatically installed, you will also want to install
SpeedyWeather explicitly via

```julia
julia> ] add SpeedyWeather
```

or, again, `using Pkg; Pkg.add("SpeedyWeather")`. So that 

```julia
using SpeedyWeather
```

also just works as dependencies are otherwise hidden for direct usage.


