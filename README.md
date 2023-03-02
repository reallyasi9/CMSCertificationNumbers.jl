# CMSCertificationNumbers

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://reallyasi9.github.io/CMSCertificationNumbers.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://reallyasi9.github.io/CMSCertificationNumbers.jl/dev/)
[![Build Status](https://github.com/reallyasi9/CMSCertificationNumbers.jl/actions/workflows/CI.yml/badge.svg?branch=development)](https://github.com/reallyasi9/CMSCertificationNumbers.jl/actions/workflows/CI.yml?query=branch%3Adevelopment)

A package that standardizes manipulation of CMS Certification Numbers in Julia.

CMS Certification Numbers (CCNs) uniquely identify health care providers and suppliers who interact with the United States Medicare and Medicaid programs, run out of the Centers of Medicare and Medicaid Services (CMS). CCNs are standardized in the [_State Operations Manual_, CMS publication number 100-07](https://www.cms.gov/Regulations-and-Guidance/Guidance/Manuals/Internet-Only-Manuals-IOMs-Items/CMS1201984).

Examples:

```julia
julia> c1 = ccn("123456")
MedicareProviderCCN("123456")

julia> isvalid(c1)
true

julia> decode(c1)
"123456: Medicare Provider in Hawaii [12] Rural Health Clinic (Provider-based) [3400-3499] sequence number 56"
```

See the [documentation](https://reallyasi9.github.io/CMSCertificationNumbers.jl/stable/) for more details and examples.