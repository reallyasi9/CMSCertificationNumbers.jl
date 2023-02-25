using CCNs
using Documenter

DocMeta.setdocmeta!(CCNs, :DocTestSetup, :(using CCNs); recursive=true)

makedocs(;
    modules=[CCNs],
    authors="Phil Killewald <reallyasi9@users.noreply.github.com> and contributors",
    repo="https://github.com/reallyasi9/CCNs.jl/blob/{commit}{path}#{line}",
    sitename="CCNs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://reallyasi9.github.io/CCNs.jl",
        edit_link="development",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/reallyasi9/CCNs.jl",
    devbranch="development",
)
