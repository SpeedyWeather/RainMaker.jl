using SpeedyWeather
using RainMaker
using Documenter

DocMeta.setdocmeta!(RainMaker, :DocTestSetup, :(using RainMaker); recursive=true)

# GET ALL SUBMISSIONS
submissions = filter(x -> endswith(x, ".jl"), readdir("../submissions"))
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

# GENERATE SUBMISSIONS
@info "Building submissions.md"
open(joinpath(@__DIR__, "src/submissions.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "headers/submissions_header.md"), String)
    println(mdfile, header)

    for (name, dict) in submissions_dict
        println(mdfile, "## $name\n")
        println(mdfile, "path: /submissions/$name.jl\n")
        println(mdfile, "```@example $name")
        println(mdfile, dict["code"])
        println(mdfile, "```\n")
    end
end

# GENERATE LEADERBOARD
@info "Building leaderboard.md"
open(joinpath(@__DIR__, "src/leaderboard.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "headers/leaderboard_header.md"), String)
    println(mdfile, header)
    println(mdfile, "| Milan | Test | 1,1 | 0 | 50 | 1 |")
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