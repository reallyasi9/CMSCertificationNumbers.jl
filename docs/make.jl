using CMSCertificationNumbers
using Documenter

DocMeta.setdocmeta!(CMSCertificationNumbers, :DocTestSetup, :(using CMSCertificationNumbers); recursive=true)

makedocs(;
    modules=[CMSCertificationNumbers],
    authors="Phil Killewald <reallyasi9@users.noreply.github.com> and contributors",
    repo="https://github.com/reallyasi9/CMSCertificationNumbers.jl/blob/{commit}{path}#{line}",
    sitename="CMSCertificationNumbers.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://reallyasi9.github.io/CMSCertificationNumbers.jl",
        edit_link="development",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/reallyasi9/CMSCertificationNumbers.jl",
    devbranch="development",
)
