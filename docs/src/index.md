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
- [RainMaker instructions](@ref)
- [Submit to the RainMaker challenge](@ref)
- [RainMaker leaderboard](@ref)
- [List of submissions](@ref)

## Installation

[RainMaker.jl](https://github.com/SpeedyWeather/RainMaker.jl) is an official
Julia package, so to install the latest version you can simply type

```julia
julia> ] add RainMaker
```

Where `]` opens Julia's package manager [Pkg.jl](https://pkgdocs.julialang.org/v1/)
which changes the prompt to `(@v1.11) pkg>`, exit the package manager with backspace.
Pkg.jl is also a package itself, so you can alternatively do

```julia
using Pkg
Pkg.add("RainMaker")
```

RainMaker.jl depends on (among others)

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


