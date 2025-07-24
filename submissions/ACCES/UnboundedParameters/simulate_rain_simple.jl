using RainMakerChallenge2025

# Try the default parameters
if isinteractive()
    params = [1, 0, 1, -80, 40.45, 300, 273, 0, 0, 35]
else
    @show params = parse.(Float64, split(ARGS[1], ' '))
end

precipitation = max_precipitation(params)

println("Maximum precipitation (mm):")
println(precipitation)
