using SpeedyWeather
using RainMaker
using Documenter
using Printf
using Dates

DocMeta.setdocmeta!(RainMaker, :DocTestSetup, :(using RainMaker); recursive=true)

# READ ALL SUBMISSIONS CODE
submissions = filter(x -> endswith(x, ".jl"), readdir(joinpath(@__DIR__, "../submissions")))
sort!(submissions)  # alphabetical order

submissions_dict = Dict{String, Dict}()
for submission in submissions
    @info "Building submission $submission"
    name = split(submission, ".jl")[1]
    path = joinpath(@__DIR__, "..", "submissions", submission)
    code = read(path, String)
    submission_dict = Dict(
        "path" => path,
        "code" => code,
    )
    submissions_dict[name] = submission_dict
end

# GENERATE SUBMISSIONS LIST
@info "Building submissions.md"
open(joinpath(@__DIR__, "src/submissions.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "headers/submissions_header.md"), String)
    println(mdfile, header)

    for (name, dict) in submissions_dict
        println(mdfile, "## $name\n")
        println(mdfile, "path: /submissions/$name.jl\n")
        println(mdfile, "```@example $name")
        println(mdfile, "using CairoMakie # hide")
        println(mdfile, dict["code"])
        println(mdfile, "RainMaker.plot(rain_gauge)")
        println(mdfile, """save("submission_$name.png", ans)""")
        println(mdfile, "nothing # hide")
        println(mdfile, "```")
        println(mdfile, "![submission: $name](submission_$name.png)\n")
    end
end

# RUN SUBMISSIONS
function run_submission(path::String)
    
    # run submission
    include(path)

    # analyse/evaluate
    total_precip = maximum(rain_gauge.accumulated_rain_large_scale) + maximum(rain_gauge.accumulated_rain_convection)
    eval_dict = Dict(
        "name" => team_name,
        "description" => description,
        "location" => (rain_gauge.lond, rain_gauge.latd),
        "total precipitation" => total_precip,
        "convection share" => maximum(rain_gauge.accumulated_rain_convection) / total_precip,
        "period" => rain_gauge.measurement_counter*rain_gauge.Δt,
    )
    return eval_dict
end


# GENERATE LEADERBOARD
@info "Building leaderboard.md"
open(joinpath(@__DIR__, "src/leaderboard.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "headers/leaderboard_header.md"), String)
    println(mdfile, header)
    for (name, dict) in submissions_dict
        eval_dict = run_submission(dict["path"])

        name = eval_dict["name"]
        description = eval_dict["description"]
        loc = eval_dict["location"]
        location = Printf.@sprintf("%.2f˚N, %.2f˚E", loc[2], loc[1])
        total_precip = Printf.@sprintf("%.3f", eval_dict["total precipitation"])
        convection_share = Printf.@sprintf("%.1f", 100*eval_dict["convection share"])
        n_days = Dates.Day(eval_dict["period"]).value

        println(mdfile, "| $name | $description | $location | $total_precip | $convection_share | $n_days |")
    end
end

rainmaker_challenge = [
    "Submit" => "submit.md",
    "Leaderboard" => "leaderboard.md",
    "Submissions" => "submissions.md",
]

makedocs(;
    modules=[RainMaker],
    authors="Milan Klöwer <milankloewer@gmx.de> and contributors",
    sitename="RainMaker.jl",
    format=Documenter.HTML(;
        canonical="https://speedyweather.github.io/RainMaker.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "RainGauge" => "rain_gauge.md",
        "RainMaker challenge" => rainmaker_challenge,
    ],
)

deploydocs(;
    repo="github.com/SpeedyWeather/RainMaker.jl",
    devbranch="main",
    push_preview = true,
)