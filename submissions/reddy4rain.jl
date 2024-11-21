
author = "Amy and breddy"
description = "Reddy4rain"

using SpeedyWeather, RainMaker

spectral_grid = SpectralGrid(trunc=12, nlayers=3, Grid=FullGaussianGrid)  # default resolution
rain_gauge = RainGauge(spectral_grid, lond=358.75, latd=51.75)

model = PrimitiveWetModel(spectral_grid)

model.callbacks

simulation = initialize!(model, time=DateTime(2024, 10, 1))

# (; a, b) = struct unpacks the fields a, b in struct identified by name, equivalent to
# a = struct.a and b = struct.b
(; precip_large_scale, precip_convection) = simulation.diagnostic_variables.physics
total_precipitation = precip_large_scale + precip_convection
total_precipitation *= 1000# convert m to mm

# add two Gaussian mountains
λ1, λ2 = (320, 345)    # longitude positions [˚E]
φ₀ = 50                 # latitude [˚N]\
σ = 5                 # width [˚]
H = 7000

# first mountain, radius=360/2π to have distance in ˚ again (not meters)
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ1,φ₀), radius=360/2π)^2/2σ^2), add=true)

# and add second
set!(model, orography=(λ,φ) -> H*exp(-spherical_distance((λ,φ), (λ2,φ₀), radius=360/2π)^2/2σ^2), add=true)

simulation.diagnostic_variables.physics.precip_large_scale .= 0
simulation.diagnostic_variables.physics.precip_convection .= 0

set!(simulation, sea_surface_temperature=(λ, φ) -> (30 < φ < 60) && (300 < λ < 360) ? 2 : 0, add=true)

# add one rain gauge the measures the whole simulation
rain_gauge_from_beginning  = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge_from_beginning)

run!(simulation, period=Week(1))

# add one rain gauge the measures the whole simulation
rain_gauge_from_w2 = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge_from_w2)

run!(simulation, period=Week(2))

set!(simulation, humid=0.3, pres=15.1)

# add another rain gauge that only starts measuring
# after that week we already simulated
rain_gauge_after_spinup  = RainGauge(spectral_grid, lond=-1.25, latd=51.75)
add!(model, rain_gauge_after_spinup)
add!(model, rain_gauge)
run!(simulation, period=Day(20))

# now compare them, from the beginning
rain_gauge_from_beginning