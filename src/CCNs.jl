module CCNs

using InlineStrings
import Base: show, print, isvalid

export MedicareProviderCCN, MedicaidOnlyProviderCCN, IPPSExcludedProviderCCN, EmergencyHospitalCCN, SupplierCCN
export ccn, infer_ccn_type, clean_ccn, decode, state, state_code, facility_type, facility_type_code, sequence_number

"""
    CCN

A representation of a CMS Certification Number.

CCNs are a uniform way of identifying providers or suppliers who currently or who ever have participated in the Medicare or Medicaid programs.
A CCN is a 6- or 10-character alphanumeric string that encodes the provider or supplier's (respectively) State and facility type.

CCNs can be constructed from `AbstractString` or `Integer` objects, but `Integer`s can only represent a subset of all possible CCNs.
For the most performant parsing of stored data, directly construct the known CCN type using constructor calls like
[`MedicareProviderCCN(s)`](@ref). For slightly less performance, use [`ccn(T<:CCN, s)`](@ref) or [`parse(T<:CCN, s)`](@ref) to canonicalize the format of `s`
and perform simple error checking. To infer what type of CCN a given value represents, use [`infer_ccn_type(s)`](@ref).

CCNs inherit from `AbstractString`, so methods like `length`, `get`, etc. are all defined and work as if the CCN were a string identifier.

CCNs are defined by CMS Manual System publication number 100-07 "State Operations Provider Certification".
"""
abstract type CCN <: AbstractString end

include("abstractstringinterface.jl")
include("statecodes.jl")
include("facilitytypecodes.jl")
include("suppliercodes.jl")

"""
    ProviderCCN

An abstract type representing the various provider types that can be represented by a CCN.

All ProviderCCNs use 6-character identifiers.
"""
abstract type ProviderCCN <: CCN end

"""
    MedicareProviderCCN
    MedicareProviderCCN(n::AbstractString)

A type representing a Medicare provider.

Medicare providers use six-character identifiers with the following format:
> `SSPQQQ`
Where:
- `SS` represent a two-character alphanumeric State Code;
- `P` represents either an a literal 'P' character (for Organ Procurement Organizations) or the most significant digit of the Sequence Number;
- `QQQ` represents the three least significant digits of the Sequence Number.

The constructor performs no error checking, but will throw an exception if `n` has more than
seven characters.
"""
struct MedicareProviderCCN <: ProviderCCN
    number::String7
end

"""
    MedicaidOnlyProviderCCN
    MedicaidOnlyProviderCCN(n::AbstractString)

A type representing a Medicaid-Only provider.

Medicid-Only providers use six-character identifiers with the following format:
> `SSTQQQ`
Where:
- `SS` represent a two-character alphanumeric State Code;
- `T` represents an alphabetical Facility Type Code;
- `QQQ` represents a three-digit Sequence Number.

The constructor performs no error checking, but will throw an exception if `n` has more than
seven characters.
"""
struct MedicaidOnlyProviderCCN <: ProviderCCN
    number::String7
end

"""
    IPPSExcludedProviderCCN
    IPPSExcludedProviderCCN(n::AbstractString)

A type representing a Medicare or Medicaid provider excluded from the Inpatient Prospective Payment System (IPPS).

IPPS-Excluded providers use six-character identifiers with the following format:
> `SSTAQQ`
Where:
- `SS` represent a two-character alphanumeric State Code;
- `T` represents an alphabetical Facility Type Code;
- `A` represents either an alphabetical Parent Facility Type Code (for IPPS-Excluded units of IPPS-Excluded parent facilities) or the most significant digit of the Sequence Number;
- `QQ` represents the two least significant digits of the Sequence Number.

!!! note
    IPPS-Excluded providers are always subunits of parent facilities, and as such they are
    not assigned their own CCN Sequence Number. The Sequence Number in the CCN will match
    the least significant digits of the parent facility.

The constructor performs no error checking, but will throw an exception if `n` has more than
seven characters.
"""
struct IPPSExcludedProviderCCN <: ProviderCCN
    number::String7
end

"""
    EmergencyHospitalCCN
    EmergencyHospitalCCN(n::AbstractString)

A type representing a designated Emergency Hospital provider.

Emergency Hospital providers use six-character identifiers with the following format:
> `SSQQQE`
Where:
- `SS` represent a two-character alphanumeric State Code;
- `E` represents an alphabetical Emergency Hospital Type Code;
- `QQQ` represents a three-digit Sequence Number.

The constructor performs no error checking, but will throw an exception if `n` has more than
seven characters.
"""
struct EmergencyHospitalCCN <: ProviderCCN
    number::String7
end

"""
    SupplierCCN
    SupplierCCN(n::AbstractString)

A type representing a Medicare or Medicaid Supplier.

Suppliers use ten-character identifiers with the following format:
> `SSTQQQQQQQ`
Where:
- `SS` represent a two-character alphanumeric State Code;
- `T` represents a Supplier Type Code;
- `QQQQQQQ` represents a seven-digit Sequence Number.

The constructor performs no error checking, but will throw an exception if `n` has more than
15 characters.
"""
struct SupplierCCN <: CCN
    number::String15
end

"""
    ccn([T::Type], s) -> CCN

Construct a CCN from input `s`.

# Arguments
- `T::Type` (optional) - The type of the CCN. If no type is given, the best guess of the type will be made based on the format of the input `s` using [`infer_ccn_type`](@ref).
- `s::Union{AbstractString,Integer}` - The input to parse to create the CCN.

# Return value
Returns a CCN of concrete type `T` if given, else the type will be inferred from format of `s`.
"""
function ccn end

function ccn(::Type{SupplierCCN}, s::AbstractString)
    c = clean_ccn(s; max_length=10)
    return SupplierCCN(c)
end

function ccn(::Type{T}, s::AbstractString) where {T <: ProviderCCN}
    c = clean_ccn(s)
    return T(c)
end

function ccn(::Type{T}, i::Integer) where {T <: ProviderCCN}
    c = clean_ccn(i)
    return T(c)
end

ccn(::Type{T}, n::Number) where {T <: CCN} = ccn(T, Integer(n))

function ccn(s)
    c = try
        clean_ccn(s; max_length=6)
    catch
        clean_ccn(s; max_length=10)
    end
    T = infer_ccn_type(c)
    return ccn(T, c)
end

"""
    clean_ccn(s; max_length=6) -> String

Clean the given value `s` and return a `String` in canonical CCN format.

Canonical CCN format is a string of uppercase alphanumeric characters left-padded with zeros
to either 6 or 10 characters. Some datasets allow CCNs to have a hyphen in position 2
separating the state code from the facility code, and some store the alphabetical characters
in lower case.

# Arguments
- `s::Union{Integer,AbstractString}` - The value to clean.
- `max_length::Integer = 6` - The maximum (and pad) length of the CCN. Should be either 6 (for providers) or 10 (for suppliers). Strings shorter than this length will be left-padded with zeros to this length.

# Return
The canonicalized form of `s`.
"""
function clean_ccn end

function clean_ccn(s::AbstractString; max_length::Integer = 6)
    ss = uppercase(strip(s))
    if length(ss) > 2 && ss[3] == '-' # dash sometimes appears between state code and remainder
        ss = ss[1:2] * ss[4:end]
    end
    length(ss) > max_length && throw(ArgumentError("CCN cannot be more than $max_length characters in length"))
    return lpad(ss, max_length, '0')
end

function clean_ccn(n::Number; max_length::Integer = 6)
    n < 0 && throw(ArgumentError("CCNs cannot be negative"))
    i = Integer(n)
    ndigits(i) > max_length && throw(ArgumentError("Integer CCN cannot be more than $max_length digits in base 10"))
    return lpad(string(i; base=10), max_length, '0')
end

"""
    infer_ccn_type(s) -> T<:CCN

Infer the type of the CCN from a string in canonical CCN format.

# Arguments
- `s::Union{AbstractString,Integer}` - A string or integer value in canonical CCN format.

# Return value
The inferred type, which will be a subtype of `CCN`. Throws if the type cannot be inferred from `s`.

See also [`clean_ccn`](@ref) to canonicalize a CCN string.
"""
function infer_ccn_type(s::AbstractString)
    length(s) ∉ (6, 10) && throw(ArgumentError("CCN must be a 6- or 10-character string"))
    tc = s[3]
    if length(s) == 10 && tc ∈ keys(_SUPPLIER_CODES)
        return SupplierCCN
    else
        tc ∈ _MEDICAID_TYPE_CODES && return MedicaidOnlyProviderCCN
        tc ∈ _IPPS_EXCLUDED_TYPE_CODES && return IPPSExcludedProviderCCN
        s[6] ∈ keys(_EMERGENCY_CODES) && return EmergencyHospitalCCN
        (tc == 'P' || isdigit(tc)) && return MedicareProviderCCN
    end
    throw(ArgumentError("CCN type cannot be inferred from '$s'"))
end

Base.convert(::Type{T}, s::AbstractString) where {T <: CCN} = T(s)
Base.convert(::Type{T}, i::Integer) where {T <: CCN} = T(string(i, base=10))
Base.convert(::Type{T}, n::Number) where {T <: CCN} = T(string(Integer(n), base=10))

Base.parse(::Type{T}, s::AbstractString) where {T <: CCN} = ccn(T, s)
function Base.tryparse(::Type{T}, s::AbstractString) where {T <: CCN}
    try
        return parse(T, s)
    catch
        return nothing
    end
end

Base.show(io::IO, ::MIME"text/plain", n::T) where {T <: CCN} = print(io, T, "(\"", n.number, "\")")
Base.show(io::IO, n::CCN) = print(io, n.number)

function Base.isvalid(c::MedicareProviderCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(_STATE_CODES) || return false
    mapreduce(isdigit, &, n[4:6]) || return false
    n[3] == 'P' && return true
    isdigit(n[3]) || return false
    sequence = parse(Int64, n[3:6])
    return !isnothing(findfirst(x -> sequence ∈ first(x), _FACILITY_RANGES))
end

function Base.isvalid(c::MedicareProviderCCN, i::Int64)
    n = c.number
    (i < 1 || i > 6 || i > length(n)) && return false
    i <= 2 && return n[i] ∈ getindex.(keys(_STATE_CODES), i)
    i == 3 && return n[i] == 'P' || isdigit(n[i])
    return isdigit(n[i])
end

function Base.isvalid(c::MedicaidOnlyProviderCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(_STATE_CODES) || return false
    n[3] ∈ _MEDICAID_TYPE_CODES || return false
    return mapreduce(isdigit, &, n[4:6])
end

function Base.isvalid(c::MedicaidOnlyProviderCCN, i::Int64)
    n = c.number
    (i < 1 || i > 6 || i > length(n)) && return false
    i <= 2 && return n[i] ∈ getindex.(keys(_STATE_CODES), i)
    i == 3 && return n[i] ∈ _MEDICAID_TYPE_CODES
    return isdigit(n[i])
end

function Base.isvalid(c::IPPSExcludedProviderCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(_STATE_CODES) || return false
    n[3] ∈ _IPPS_EXCLUDED_TYPE_CODES || return false
    isdigit(n[4]) || n[4] ∈ keys(_IPPS_PARENT_HOSPITAL_TYPES) || return false
    return mapreduce(isdigit, &, n[5:6])
end

function Base.isvalid(c::IPPSExcludedProviderCCN, i::Int64)
    n = c.number
    (i < 1 || i > 6 || i > length(n)) && return false
    i <= 2 && return n[i] ∈ getindex.(keys(_STATE_CODES), i)
    i == 3 && return n[i] ∈ _IPPS_EXCLUDED_TYPE_CODES
    i == 4 && return isdigit(n[4]) || n[i] ∈ keys(_IPPS_PARENT_HOSPITAL_TYPES)
    return isdigit(n[i])
end

function Base.isvalid(c::EmergencyHospitalCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(_STATE_CODES) || return false
    n[6] ∈ keys(_EMERGENCY_CODES) || return false
    return mapreduce(isdigit, &, n[3:5])
end

function Base.isvalid(c::EmergencyHospitalCCN, i::Int64)
    n = c.number
    (i < 1 || i > 6 || i > length(n)) && return false
    i <= 2 && return n[i] ∈ getindex.(keys(_STATE_CODES), i)
    i == 6 && return n[i] ∈ keys(_EMERGENCY_CODES)
    return isdigit(n[i])
end

function Base.isvalid(c::SupplierCCN)
    n = c.number
    length(n) == 10 || return false
    n[1:2] ∈ keys(_STATE_CODES) || return false
    n[3] ∈ keys(_SUPPLIER_CODES) || return false
    return mapreduce(isdigit, &, n[4:10])
end

function Base.isvalid(c::SupplierCCN, i::Int64)
    n = c.number
    (i < 1 || i > 10 || i > length(n)) && return false
    i <= 2 && return n[i] ∈ getindex.(keys(_STATE_CODES), i)
    i == 3 && return n[i] ∈ keys(_SUPPLIER_CODES)
    return isdigit(n[i])
end

function Base.isvalid(::Type{T}, value) where {T <: CCN}
    try
        c = T(value)
        return isvalid(c)
    catch e
        if isa(e, ArgumentError)
            return false
        end
        rethrow()
    end
end

"""
    state_code(ccn) -> String

Return the state code of `ccn` (the first two characters) as a `String`.
"""
state_code(ccn::CCN) = String(ccn.number[1:2])

"""
    INVALID_STATE

A `String` representing an invalid state code.
"""
const INVALID_STATE = "invalid state"

"""
    state(ccn) -> String

Decode the state code of `ccn` and return it as a `String`.

The first two characters of a CCN encode the "state" where the entity is located. "State" is
interpreted loosely, as valid states include countries (like Canada) and territories (like
(Guam).

Returns `CCNs.INVALID_STATE` if the first two characters are not a valid state code.
"""
state(ccn::CCN) = get(_STATE_CODES, ccn.number[1:2], INVALID_STATE)

"""
    facility_type_code(ccn) -> String

Return the facility type code of `ccn` as a `String`.

The facility type is dependent on the type of CCN, but usually involves the 3rd character of
the code.
"""
function facility_type_code end

function facility_type_code(ccn::MedicareProviderCCN)
    if ccn.number[3] == 'P'
        return "P"
    else
        sequence = parse(Int64, ccn.number[3:6])
        idx = findfirst(x -> sequence ∈ first(x), _FACILITY_RANGES)
        if isnothing(idx)
            return ccn.number[3:6]
        else
            val = _FACILITY_RANGES[idx]
            range = first(val)
            return lpad(first(range), 4, '0') * "-" * lpad(last(range), 4, '0')
        end
    end
end

facility_type_code(ccn::Union{MedicaidOnlyProviderCCN, IPPSExcludedProviderCCN, SupplierCCN}) = String(ccn.number[3:3])

facility_type_code(ccn::EmergencyHospitalCCN) = String(ccn.number[6:6])

"""
    INVALID_FACILITY_TYPE

A `String` representing an invalid facility type code for a given CCN type.
"""
const INVALID_FACILITY_TYPE = "invalid facility type"

"""
    facility_type(ccn) -> String

Return a description of the facility type of `ccn` as a `String`.

Returns `CCNs.INVALID_FACILITY_TYPE` if the facility type code is invalid for the CCN type.
"""
function facility_type end

function facility_type(ccn::MedicareProviderCCN)
    if ccn.number[3] == 'P'
        return "Organ Procurement Organization (OPO)"
    else
        try
            sequence = parse(Int64, ccn.number[3:6])
            idx = findfirst(x -> sequence ∈ first(x), _FACILITY_RANGES)
            if isnothing(idx)
                return INVALID_FACILITY_TYPE
            else
                val = _FACILITY_RANGES[idx]
                return last(val)
            end
        catch
            return INVALID_FACILITY_TYPE
        end
    end
end

function facility_type(ccn::MedicaidOnlyProviderCCN)
    type_code = ccn.number[3]
    
    if type_code == 'J'
        try
            sequence = parse(Int64, ccn.number[4:6])
            idx = findfirst(x -> sequence ∈ first(x), _MEDICAID_HOSPITAL_RANGES)
            if isnothing(idx)
                return INVALID_FACILITY_TYPE
            else
                val = _MEDICAID_HOSPITAL_RANGES[idx]
                return last(val)
            end
        catch
            return INVALID_FACILITY_TYPE
        end
    else
        return get(_MEDICAID_FACILITY_CODES, type_code, INVALID_FACILITY_TYPE)
    end
end

facility_type(ccn::IPPSExcludedProviderCCN) = get(_MEDICAID_FACILITY_CODES, ccn.number[3], INVALID_FACILITY_TYPE)

facility_type(ccn::EmergencyHospitalCCN) = get(_EMERGENCY_CODES, ccn.number[6], INVALID_FACILITY_TYPE)

facility_type(ccn::SupplierCCN) = get(_SUPPLIER_CODES, ccn.number[3], INVALID_FACILITY_TYPE)

"""
    sequence_number(ccn) -> Int64

Decode the sequence number from a given CCN.

Sequence numbers are sometimes indefinite. If this is the case, then only the decodable
digits of the sequence number are returned (typically the last digits).
"""
function sequence_number end

function sequence_number(ccn::MedicareProviderCCN)
    if ccn.number[3] == 'P'
        return parse(Int64, ccn.number[4:6])
    else
        sequence = parse(Int64, ccn.number[3:6])
        idx = findfirst(x -> sequence ∈ first(x), _FACILITY_RANGES)
        if isnothing(idx)
            return sequence
        else
            val = _FACILITY_RANGES[idx]
            range = first(val)
            return sequence - first(range)
        end
    end
end

function sequence_number(ccn::MedicaidOnlyProviderCCN)
    sequence = parse(Int64, ccn.number[4:6])
    type_code = ccn.number[3]
    if type_code == 'J'
        idx = findfirst(x -> sequence ∈ first(x), _MEDICAID_HOSPITAL_RANGES)
        if isnothing(idx)
            return sequence
        else
            val = _MEDICAID_HOSPITAL_RANGES[idx]
            range = first(val)
            return sequence - first(range)
        end
    else
        return sequence
    end
end

function sequence_number(ccn::IPPSExcludedProviderCCN)
    sequence_code = ccn.number[4:6]
    if !isdigit(sequence_code[1])
        parent_code = sequence_code[1]
        parent_type = get(_IPPS_PARENT_HOSPITAL_TYPES, parent_code, ("invalid parent type" => ""))
        sequence_code = last(parent_type) * sequence_code[2:end]
    end
    return parse(Int64, sequence_code)
end

sequence_number(ccn::EmergencyHospitalCCN) = parse(Int64, ccn.number[3:5])

sequence_number(ccn::SupplierCCN) = parse(Int64, ccn.number[4:10])

const _TYPE_NAME = Dict(
    MedicareProviderCCN => "Medicare Provider",
    MedicaidOnlyProviderCCN => "Medicaid-only Provider",
    IPPSExcludedProviderCCN => "IPPS-Excluded Provider",
    EmergencyHospitalCCN => "Emergency Hospital",
    SupplierCCN => "Supplier"
)

"""
    decode([io::IO], ccn)

Decode `ccn` and either return the information as a `String` or print to `io`.
"""
function decode end

function decode(io::IO, ccn::T) where {T <: CCN}
    st = state(ccn)
    state_number = state_code(ccn)
    type_code = facility_type_code(ccn)
    type = facility_type(ccn)
    sequence = sequence_number(ccn)
    print(io, ccn.number, ": ", _TYPE_NAME[T], " in ", st, " [", state_number, "] ", type, " [", type_code, "] sequence number ", sequence)
end

function decode(io::IO, ccn::IPPSExcludedProviderCCN)
    st = state(ccn)
    state_number = state_code(ccn)
    type_code = facility_type_code(ccn)
    type = facility_type(ccn)

    print(io, ccn.number, ": ", _TYPE_NAME[IPPSExcludedProviderCCN], " in ", st, " [", state_number, "] ", type, " [", type_code, "]")

    sequence_code = ccn.number[4:6]
    if !isdigit(sequence_code[1])
        parent_code = sequence_code[1]
        parent_type = get(_IPPS_PARENT_HOSPITAL_TYPES, parent_code, ("invalid parent type" => ""))
        sequence = parse(Int64, last(parent_type) * sequence_code[2:end])
        print(io, " of parent ", first(parent_type), " [", parent_code, "] with sequence number ", sequence)
    else
        sequence = parse(Int64, sequence_code)
        print(io, " of parent with sequence number ", sequence)
    end
end

function decode(ccn::CCN)
    buf = IOBuffer()
    decode(buf, ccn)
    return read(seekstart(buf), String)
end

end # Module