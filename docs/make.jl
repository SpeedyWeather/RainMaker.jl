using SpeedyWeather
using RainMaker
using Documenter

DocMeta.setdocmeta!(RainMaker, :DocTestSetup, :(using RainMaker); recursive=true)

# GENERATE SUBMISSIONS
@info "Building submissions.md"
open(joinpath(@__DIR__, "src/submissions.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "src/submissions_header.md"), String)
    println(mdfile, header)
    println(mdfile, "## Submission 1")
    println(mdfile, "\nsomething\n")
    println(mdfile, "## Submission 2")
    println(mdfile, "\nsomething else\n")
end

# GENERATE LEADERBOARD
@info "Building leaderboard.md"
open(joinpath(@__DIR__, "src/leaderboard.md"), "w") do mdfile
    header = read(joinpath(@__DIR__, "src/leaderboard_header.md"), String)
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