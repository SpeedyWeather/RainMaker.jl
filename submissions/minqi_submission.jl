author = "Minqi"
description = "humid & montain"

using SpeedyWeather, RainMaker
spectral_grid = SpectralGrid(trunc=25, nlayers=8)
time_stepping = Leapfrog(spectral_grid, Δt_at_T31=Minute(10))
model = PrimitiveWetModel(spectral_grid; time_stepping)

rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge)

simulation = initialize!(model)
set!(simulation, humid=0.185)
H, λ₀, φ₀, σ = 10000, 2, 51, 1  
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ₀,φ₀), radius=360/2π)^2/2σ^2))

run!(simulation, period=Day(20))