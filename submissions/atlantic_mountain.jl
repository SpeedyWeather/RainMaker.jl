author = "Milan"
description = "Atlantic mountain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=31, nlayers=8)
model = PrimitiveWetModel(; spectral_grid)

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)

# add a massive mountain at 50°N, 35°W, *after* model initialization
H, λ₀, φ₀, σ = 4000, 325, 50, 5     # height, lon, lat position, and width
set!(model, orography=(λ,φ) -> H*exp((-(λ-λ₀)^2 - (φ-φ₀)^2)/2σ^2), add=true)

run!(simulation, period=Day(20))