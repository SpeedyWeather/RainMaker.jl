using RainMaker
using SpeedyWeather
using Test

@testset "RainMaker.jl" begin

    @testset "RainGauge in a PrimitiveWetModel" begin
        spectral_grid = SpectralGrid(truncation=32, nlayers=5)
        rain_gauge = RainGauge(spectral_grid, lond=-1.25, latd=51.75)

        model = PrimitiveWetModel(spectral_grid)
        add!(model, rain_gauge)

        simulation = initialize!(model)
        model.feedback.verbose = false
        run!(simulation, period=Day(2))

        # one measurement per time step
        @test rain_gauge.measurement_counter > 0

        # rain and snow are separate and non-negative (accumulated)
        i = rain_gauge.measurement_counter
        @test all(rain_gauge.accumulated_rain_large_scale[1:i] .>= 0)
        @test all(rain_gauge.accumulated_rain_convection[1:i] .>= 0)
        @test all(rain_gauge.accumulated_snow_large_scale[1:i] .>= 0)

        # total precipitation includes snow
        @test maximum_precipitation(rain_gauge) ==
            maximum(rain_gauge.accumulated_rain_large_scale) +
            maximum(rain_gauge.accumulated_rain_convection) +
            maximum(rain_gauge.accumulated_snow_large_scale)

        # clock information picked up from the simulation
        @test rain_gauge.Δt == Second(model.time_stepping.Δt_millisec)

        # printing doesn't error
        @test (show(devnull, rain_gauge); true)
    end

    @testset "reset! and skip!" begin
        spectral_grid = SpectralGrid(truncation=32, nlayers=5)
        rain_gauge = RainGauge(spectral_grid)

        rain_gauge.measurement_counter = 10
        rain_gauge.accumulated_rain_large_scale[1:10] .= 1:10
        rain_gauge.accumulated_rain_convection[1:10] .= 1:10
        rain_gauge.accumulated_snow_large_scale[1:10] .= 1:10

        gauge2 = skip(rain_gauge, 5*rain_gauge.Δt)
        @test gauge2.accumulated_rain_large_scale[5] == 0
        @test gauge2.accumulated_snow_large_scale[5] == 0
        @test gauge2.accumulated_rain_convection[10] == 5

        # original untouched by non-mutating skip
        @test rain_gauge.accumulated_snow_large_scale[5] == 5

        RainMaker.reset!(rain_gauge)
        @test rain_gauge.measurement_counter == 0
        @test all(rain_gauge.accumulated_rain_large_scale .== 0)
        @test all(rain_gauge.accumulated_rain_convection .== 0)
        @test all(rain_gauge.accumulated_snow_large_scale .== 0)
    end
end
