# 1. All precipitation measured by the rain gauge has to be simulated by SpeedyWeather over a 20-day period.
# 2. The rain gauge must be placed at the agreed longitude and latitude coordinates.
# 3. No changes to the following physics inside SpeedyWeather: Large-scale condensation, convection, surface evaporation, or radiation.
# 4. Sea and land surface temperatures cannot exceed 305K anywhere during the simulation.
# 5. The simulation must remain stable over the 20-day period.
author = "Charlotte Merchant"
description = "The Rapture: Big Super Mega Ultra Clapped Humid North Sea Mountain HR Injection Under More Pressure Initially and Corrected"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=100, nlayers=8)
atm = EarthAtmosphere(spectral_grid)
clausius_clapeyron = ClausiusClapeyron(spectral_grid, atm, e₀=0.00001)
model = PrimitiveWetModel(spectral_grid; clausius_clapeyron)

Base.@kwdef struct inject <: SpeedyWeather.AbstractCallback
    schedule::Schedule = Schedule(every=Hour(1))
end

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
    
    set!(progn, model.geometry, humid=(λ, φ, σ) -> 0.16)
    set!(progn, model.geometry, temp=(λ, φ, σ) -> σ == 1 ? 305 : (σ > 0.8 ? 305 - 10 * (1 - σ) : (σ > 0.5 ? 290 + 5 * (1 - σ) : 250)))
	set!(progn, model.geometry, u=(λ, φ, σ) -> -5.0)
	set!(progn, model.geometry, v=(λ, φ, σ) -> 2.0)
    set!(progn, model.geometry, div=(λ, φ, σ) -> σ > 0.8 ? -0.005 : (σ > 0.5 ? 0.0 : 0.005))
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