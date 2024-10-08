using RainMaker
using Documenter

DocMeta.setdocmeta!(RainMaker, :DocTestSetup, :(using RainMaker); recursive=true)

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
    ],
)

deploydocs(;
    repo="github.com/SpeedyWeather/RainMaker.jl",
    devbranch="main",
)
