# 1. All precipitation measured by the rain gauge has to be simulated by SpeedyWeather over a 20-day period.
# 2. The rain gauge must be placed at the agreed longitude and latitude coordinates.
# 3. No changes to the following physics inside SpeedyWeather: Large-scale condensation, convection, surface evaporation, or radiation.
# 4. Sea and land surface temperatures cannot exceed 305K anywhere during the simulation.
author = "Charlotte Merchant"
description = "The Rapture: Big Super Mega Ultra Clapped Humid North Sea Mountain HR Injection Under More Pressure Initially"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=100, nlayers=8)
atm = EarthAtmosphere(spectral_grid)
clausius_clapeyron = ClausiusClapeyron(spectral_grid, atm, e₀=0.0001)
model = PrimitiveWetModel(spectral_grid; clausius_clapeyron)

Base.@kwdef struct inject <: SpeedyWeather.AbstractCallback
    schedule::Schedule = Schedule(every=Hour(1))
end

# initialize the schedule
function SpeedyWeather.initialize!(
    callback::inject,
    progn::PrognosticVariables,
    diagn::DiagnosticVariables,
    model::AbstractModel,
)
    initialize!(callback.schedule, progn.clock)
end

function SpeedyWeather.callback!(
    callback::inject,
    progn::PrognosticVariables,
    diagn::DiagnosticVariables,
    model::AbstractModel,
)
    isscheduled(callback.schedule, progn.clock) || return nothing
    
    set!(progn, model.geometry, humid=(λ, φ, z) -> if z < 2
                                                 0.16
                                              else
                                                 0.07
                                              end)
    set!(progn, model.geometry, sea_surface_temperature=(λ, φ) -> 304.5 - 0.5 * abs(φ))
    set!(progn, model.geometry, land_surface_temperature=(λ, φ) -> 304.5)
    set!(progn, model.geometry, temp=(λ, φ, z) -> 290 + (z < 5 ? 8 * z : -2 * (z - 5)))
    set!(progn, model.geometry, u=(λ, φ, z) -> if z < 2
                                            -5.0
                                           else
                                              0.0
                                           end)
    set!(progn, model.geometry, v=(λ, φ, z) -> if z < 2
                                              2.0
                                           else
                                              0.0
                                           end)
    set!(progn, model.geometry, pres=20)
end

SpeedyWeather.finalize!(::inject, args...) = nothing

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)
add!(model, inject())
simulation = initialize!(model)

H, λ₀, φ₀, σ = 4000, 2, 51, 5
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))
set!(simulation, humid=0.16)
set!(simulation, pres=20)
run!(simulation, period=Day(20))

RainMaker.plot(rain_gauge)