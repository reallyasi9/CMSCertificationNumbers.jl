```@meta
CurrentModule = CMSCertificationNumbers
DocTestSetup = quote
    using CMSCertificationNumbers
end
DocTestFilters = [r"Stacktrace:[\s\S]+"]
```

```@index
```

# CMSCertificationNumbers

[CMSCertificationNumbers](https://github.com/reallyasi9/CMSCertificationNumbers.jl) is a package that standardizes manipulation of CMS Certification Numbers in Julia.

CMS Certification Numbers (CCNs) uniquely identify health care providers and suppliers who interact with the United States Medicare and Medicaid programs, run out of the Centers of Medicare and Medicaid Services (CMS). CCNs are standardized in the [_State Operations Manual_, CMS publication number 100-07](https://www.cms.gov/Regulations-and-Guidance/Guidance/Manuals/Internet-Only-Manuals-IOMs-Items/CMS1201984).

CCNs are sequences of alphanumeric characters. Health care providers are assigned 6-character CCNs, while health care suppliers are assigned 10-character CCNs. The canonical format used by this package to represent CCNs has the following structure:

- CCNs are strings represented as sequences of UTF-8 characters.
- Only characters in the Latin Alphabet: Uppercase (`U+0041` to `U+005A`) and ASCII Digits (`U+0030` to `U+0039`) are used.
- The first two characters always represent the State Code where the health care entity is officially located (note that "State" in this context includes countries, like Canada, and territories, like Guam).
- The third character may designate the Facility Type or Supplier Type of the entity--otherwise, it is a part of the Sequence Number.
- The fourth character may designate the Parent Facility Type for entities that are subunits of other facilities--otherwise, it is a part of the Sequence Number.
- The fifth character is always a part of the Sequence Number.
- The sixth character may designate the Emergency Hospital Type--otherwise, it is a part of the Sequence Number.
- The seventh through tenth characters are only used for Suppliers, and are always part of the Sequence Number.

# Types

Because the structure of the CCN depends on the type of provider, supplier, or facility it is describing, this package defines separate types to help the user be precise about what kind of CCN the identifier represents. The types are described below:

```@docs
CCN
ProviderCCN
MedicareProviderCCN
MedicaidOnlyProviderCCN
IPPSExcludedProviderCCN
EmergencyHospitalCCN
SupplierCCN
```

# Parsing

## Constructors

You can create CCNs by calling the constructors of the concrete CCN types directly. This method of construction does no error checking: any `AbstractString` passed to the constructor is assumed to be valid. Use this method when:
1. You need to process CCNs as quickly as possible;
2. You already know what type of facility the CCNs represent; and
3. You know that the CCNs are already in canonical format.

Examples:

```jldoctest
julia> c1 = MedicareProviderCCN("123456")
MedicareProviderCCN("123456")

julia> c2 = MedicareProviderCCN("banana") # invalid, but no error checking is performed
MedicareProviderCCN("banana")

julia> c3 = MedicareProviderCCN("12345678") # too many characters to fit in String7, exception thrown
ERROR: ArgumentError: string too large (8) to convert to InlineStrings.String7
[...]
```

This package also implements `Base.convert(::Type{<:CCN}, ::AbstractString)`, which simply passes the argument to the type constructor.

## `Base.parse`

You can create CCNs by parsing `AbstractString` values using `Base.parse(::Type{<:CCN}, ::AbstractString)`. This method performs rudimentary checks on the input `AbstractString` and will throw an exception if it cannot possibly represent the given CCN type. Use this method when:
1. You already know what type of facility the CCNs represent; and
2. You have strings that need to be converted into canonical format.

Examples:

```jldoctest
julia> parse(MedicareProviderCCN, "123456")
MedicareProviderCCN("123456")

julia> parse(MedicareProviderCCN, "123") # valid values, but not in canonical format
MedicareProviderCCN("000123")

julia> parse(MedicareProviderCCN, "\t12-p456\n") # common to find dashes and lower-case letters in some representations
MedicareProviderCCN("12P456")

julia> parse(MedicareProviderCCN, "1234567") # small enough to fit in String7, but too many characters for CCN
ERROR: ArgumentError: CCN cannot be more than 6 characters in length
[...]
```

This method relies on the [`clean_ccn`](@ref) method, which is also exported for use.

```@docs
clean_ccn
```

## `ccn` method

You can create CCNs by automatically detecting the type based on the format of the code using the `ccn(::AbstractString)` method. There is no ambiguity in CCN types as long as the CCN is in canonical format. Use this method when:
1. You do not know the type of CCN represented by the code;
2. You are willing to sacrifice the processing time needed to convert the string to canonical format; and
3. You are not concerned about type-stable code.

Examples:

```jldoctest
julia> ccn("123456")
MedicareProviderCCN("123456")

julia> ccn("12A456")
MedicaidOnlyProviderCCN("12A456")

julia> ccn("\t12-p456\n")
MedicareProviderCCN("12P456")

julia> ccn("X1234567") # too long to be a provider CCN, but canonicallizes to a valid supplier CCN
SupplierCCN("00X1234567")

julia> ccn("12I456") # looks right, but is not a valid provider CCN
ERROR: ArgumentError: CCN type cannot be inferred from '12I456'
[...]
```

The package also exports `ccn(::Type{<:CCN}, ::AbstractString)`, which is type-stable and can be used like `parse(::Type{<:CCN}, ::AbstractString)` (in fact, `parse` just calls `ccn` under the hood). You can also pass numbers to `ccn`, but because most CCN types require an alphabetic character somewhere in the string, you can only convert numbers to `MedicareProviderCCN` types:

```jldoctest
julia> ccn(123456)
MedicareProviderCCN("123456")

julia> ccn(Float64(123)) # non-integers can be used if they can be exactly converted into integers
MedicareProviderCCN("000123")

julia> ccn(-12345) # negative numbers are not allowed
ERROR: ArgumentError: CCNs cannot be negative
[...]

julia> ccn(1234567) # numbers with more than 6 digits are not allowed
ERROR: ArgumentError: CCN cannot be more than 6 characters in length
[...]
```

The `ccn` method relies on [`infer_ccn_type`](@ref), which is also exported for convenience.

```@docs
ccn
infer_ccn_type
```

# Inspecting

Encoded in a CCN is information about the state where the facility is located, the type of the facility, and a sequence number assigned by CMS to the facility. You can inspect that information with the methods [`state_code`](@ref), [`facility_type_code`](@ref), and [`sequence_number`](@ref), respectively. You can also decode the State Code and Facility Type Code with the methods [`state`](@ref) and [`facility_type`](@ref), respectively, which returns an English-language description of the code as described in the CMS publications.

Examples:

```jldoctest
julia> state_code(ccn("123456"))
"12"

julia> state_code(ccn("QQ3456")) # invalid state, but the code is still returned
"QQ"

julia> state(ccn("123456"))
"Hawaii"

julia> state(ccn("QQ3456")) # invalid state string available as CMSCertificationNumbers.INVALID_STATE
"invalid state"

julia> facility_type_code(ccn("123456")) # some facility type codes are ranges of values, stylized as a string
"3400-3499"

julia> facility_type_code(ccn("12P456")) # most facility type codes are length=1 strings
"P"

julia> facility_type_code(ccn("120000")) # invalid facility code, but an attempt to parse and return something is still made
"0000"

julia> facility_type(ccn("123456"))
"Rural Health Clinic (Provider-based)"

julia> facility_type(ccn("12P456"))
"Organ Procurement Organization (OPO)"

julia> facility_type(ccn("120000")) # invalid facility type string available as CMSCertificationNumbers.INVALID_FACILITY_TYPE
"invalid facility type"

julia> sequence_number(ccn("123456")) # note that the facility type code is 3400-3499
56

julia> sequence_number(ccn("12P456"))
456

julia> sequence_number(ccn("120000"))
0
```

Also exported is a method [`decode`](@ref), which returns all the available information about the CCN as a stylized string. You can also provide an `IO` object as the first argument to `decode` to print the stylized string to a particular IO device.

Examples:

```jldoctest
julia> decode(ccn("123456"))
"123456: Medicare Provider in Hawaii [12] Rural Health Clinic (Provider-based) [3400-3499] sequence number 56"

julia> buf = IOBuffer(); decode(buf, ccn("123456")) # returns nothing: writes to buf instead

julia> String(take!(buf))
"123456: Medicare Provider in Hawaii [12] Rural Health Clinic (Provider-based) [3400-3499] sequence number 56"

julia> decode(ccn("120000"))
"120000: Medicare Provider in Hawaii [12] invalid facility type [0000] sequence number 0"
```

```@docs
state_code
state
facility_type_code
facility_type
sequence_number
decode
CMSCertificationNumbers.INVALID_STATE
CMSCertificationNumbers.INVALID_FACILITY_TYPE
```

# Manipulating

CCNs implement many `AbstractString` methods. The only caveat about the exported methods is that most of the operations return some other type of `AbstractString`, not a CCN subtype.

Examples:

```jldoctest
julia> c = ccn("123456")
MedicareProviderCCN("123456")

julia> c[3]
'3': ASCII/Unicode U+0033 (category Nd: Number, decimal digit)

julia> c[4:6]
"456"

julia> replace(c, r"(\d)3" => s"\1P")
"12P456"
```

More useful, perhaps, are the `Base.isvalid` methods, which are customized to CCN types to check whether the CCN itself is valid, or whether individual characters in the CCN string are valid.

!!! note "A note about validity"

    The `isvalid(::CCN, ::Int)` method tests whether the character a given index within a CCN string is valid _for that position only_, _not_ whether the entire CCN is valid nor whether the character is part of a valid code (i.e., a valid State Code).

```jldoctest
julia> isvalid(ccn("123456"))
true

julia> isvalid(ccn("Q23456")) # state code is invalid
false

julia> isvalid(ccn("Q23456"), 2) # '2' is a valid character for the second character of the state code
true
```

You can also use `Base.invald(::Type{<:CCN}, ::AbstractString)` to determine if a given string is valid for a given CCN subtype without actually creating the subtype in question.

```jldoctest
julia> isvalid(MedicareProviderCCN, "123456")
true

julia> isvalid(MedicaidOnlyProviderCCN, "123456")
false
```
