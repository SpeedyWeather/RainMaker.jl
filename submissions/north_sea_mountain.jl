author = "Tim Reichelt"
description = "North Sea mountain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(; spectral_grid)
model.feedback.verbose = false # hide

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)

# add a massive mountain at 51.75°N, 0°W, *after* model initialization
H, λ₀, φ₀, σ = 4000, 2, 51, 5     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp((-(λ-λ₀)^2 - (φ-φ₀)^2)/2σ^2), add=true)

run!(simulation, period=Day(20))