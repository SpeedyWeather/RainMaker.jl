mountain_positions_canada = [
    (-3.35, 58.67), 
    (-4.87, 61.61), 
    (-6.74, 64.60), 
    (-9.12, 67.60), 
    (-12.22, 70.58), 
    (-16.39, 73.50), 
    (-22.23, 76.30), 
    (-30.76, 78.87), 
    (-43.59, 81.04), 
    (-62.35, 82.50)
]
author = "Danny Ash, Jowan Fromentin - Brain Drain"
description = "Rain Rain go away"

using SpeedyWeather, RainMaker
using CairoMakie

spectral_grid = SpectralGrid(trunc=31, nlayers=5)
time_stepping = Leapfrog(spectral_grid, Δt_at_T31=Minute(0.5))
# define aquaplanet
ocean = AquaPlanet(spectral_grid, temp_equator=200, temp_poles=305)
land_sea_mask = AquaPlanetMask(spectral_grid)
orography = NoOrography(spectral_grid)
model = PrimitiveWetModel(spectral_grid; ocean, land_sea_mask, orography, time_stepping=time_stepping)

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
set!(simulation, humid=6)

# build the wall
H, λ₀, φ₀, σ = 8000, 2, 51, 1     # height, lon, lat position, and width
H_c = 5000
set!(model, orography=(λ, φ) -> begin
orography = 0.0
for (λ₀, φ₀) in mountain_positions_canada
    orography += H_c * exp(-spherical_distance((λ, φ), (λ₀, φ₀), radius=360/2π)^2 / 2σ^2)
end
orography
end, add=true)

set!(model, orography=(λ, φ) -> begin
orography = 0.0
mountain_positions = [(0, 50), (1, 50), (2, 50), (0, 55), (1, 55), (2, 55), (0, 60), (1, 60)]
for (λ₀, φ₀) in mountain_positions
    orography += H * exp(-spherical_distance((λ, φ), (λ₀, φ₀), radius=360/2π)^2 / 2σ^2)
end
orography
end, add=true)




# dig the hole
H, λ₀, φ₀, σ = -6000, -1.25, 51.75, 100.5     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp((-(λ-λ₀)^2 - (φ-φ₀)^2)/2σ^2), add=true)


run!(simulation, period=Day(20))
total_precip = maximum(rain_gauge.accumulated_rain_large_scale) + maximum(rain_gauge.accumulated_rain_convection)

println(total_precip)
RainMaker.plot(rain_gauge)

# heatmap(model.orography.orography)
# println(maximum(simulation.prognostic_variables.ocean.sea_surface_temperature))