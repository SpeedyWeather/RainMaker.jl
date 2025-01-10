author = "Tim Reichelt"
description = "North Sea mountain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(spectral_grid)

rain_gauge = RainGauge(spectral_grid, lond=-27.25, latd=38.7)
add!(model, rain_gauge)

simulation = initialize!(model)

# add a massive mountain at 51.75°N, 0°W, *after* model initialization
# using spherical_distance for geodesic distances, use radius=360/2π for distance in degrees
H, λ₀, φ₀, σ = 4000, 2, 51, 5     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))

run!(simulation, period=Day(20))