@kwdef mutable struct RainTracker{T} <: SpeedyWeather.AbstractCallback
    latd::Float64 = 0.0
    lond::Float64 = 0.0

    maxsteps::Int = 10000
    accumulated_rain::Vector{T} = zeros(T, maxsteps)
end