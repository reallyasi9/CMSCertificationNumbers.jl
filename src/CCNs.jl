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

CCNs inherit from `AbstractString`, so methods like `length`, `get`, etc. are all defined and work as if the CCN were a string identifier.

CCNs are defined by CMS Manual System publication number 100-07 "State Operations Provider Certification".
"""
abstract type CCN <: AbstractString end

include("abstractstringinterface.jl")
include("statecodes.jl")
include("facilitytypecodes.jl")
include("suppliercodes.jl")

abstract type ProviderCCN <: CCN end

struct MedicareProviderCCN <: ProviderCCN
    number::String7
end

struct MedicaidOnlyProviderCCN <: ProviderCCN
    number::String7
end

struct IPPSExcludedProviderCCN <: ProviderCCN
    number::String7
end

struct EmergencyHospitalCCN <: ProviderCCN
    number::String7
end

struct SupplierCCN <: CCN
    number::String15
end

"""
    ccn([T::Type], s)

Construct a CCN from input `s`.

# Arguments
    - `T::Type` (optional) - The type of the CCN. If no type is given, the best guess of the type will be made based on the format of the input `s`.
    - `s::Union{AbstractString,Integer}` - The input to parse to create the CCN.

# Return value
Returns a CCN of concrete type `T` if given, else the type will be inferred from format of `s`.
"""
function ccn(::Type{SupplierCCN}, s::AbstractString)
    pad = 10
    length(s) > pad && throw(ArgumentError("SupplierCCN cannot be more than $pad characters in length"))
    return SupplierCCN(String15(lpad(uppercase(s), pad, '0')))
end

function ccn(::Type{T}, s::AbstractString) where {T <: ProviderCCN}
    pad = 6
    length(s) > pad && throw(ArgumentError("$T cannot be more than $pad characters in length"))
    return T(String7(lpad(uppercase(s), pad, '0')))
end

function ccn(::Type{T}, i::Integer) where {T <: ProviderCCN}
    i < 0 && throw(ArgumentError("$T cannot be a negative number"))
    pad = 6
    ndigits(i) > pad && throw(ArgumentError("$T cannot be more than $pad digits in base 10"))
    return T(String7(lpad(string(i), 6, '0')))
end

ccn(::Type{T}, n::Number) where {T <: CCN} = ccn(T, Integer(n))

function ccn(s::AbstractString)
    c = clean_ccn(s)
    T = infer_ccn_type(c)
    return ccn(T, c)
end

function clean_ccn(s::AbstractString)
    ss = strip(s)
    if ss[3] == "-" # dash sometimes appears between state code and remainder
        ss = ss[1:2] * ss[4:end]
    end
    length(ss) > 10 && throw(ArgumentError("CCNs cannot be more than 10 characters in length"))
    pad = length(ss) > 6 ? 10 : 6
    return lpad(ss, pad, '0')
end

function clean_ccn(i::Integer)
    i < 0 && throw(ArgumentError("CCNs cannot be negative"))
    ndigits(i) > 6 && throw(ArgumentError("Integer CCNs cannot be more than 6 digits in base 10"))
    return lpad(string(i; base=10), 6, '0')
end

"""
    infer_ccn_type(s) -> `Type{T} where T <: CCN`

Infer the type of the CCN from the input.

# Arguments
    - `s::Union{AbstractString,Integer}` - The value to parse.

# Return value
The inferred type. Throws if the type cannot be inferred from the input.
"""
function infer_ccn_type(s::AbstractString)
    length(s) ∉ (6, 10) && throw(ArgumentError("CCN must be a 6- or 10-character string"))
    length(s) == 10 && return SupplierCCN
    tc = s[3]
    tc ∈ MEDICAID_TYPE_CODES && return MedicaidOnlyProviderCCN
    tc ∈ IPPS_EXCLUDED_TYPE_CODES && return IPPSExcludedProviderCCN
    s[6] ∈ keys(EMERGENCY_CODES) && return EmergencyHospitalCCN
    (tc == 'P' || isdigit(tc)) && return MedicareProviderCCN
    throw(ArgumentError("CCN type cannot be inferred from '$s'"))
end

function ccn(i::Integer)
    # can only be a MedicareProviderCCN
    return ccn(MedicareProviderCCN, i)
end

Base.convert(::Type{T}, s::AbstractString) where {T <: CCN} = ccn(T, s)
Base.convert(::Type{T}, i::Integer) where {T <: CCN} = ccn(T, i)
Base.convert(::Type{T}, n::Number) where {T <: CCN} = ccn(T, Integer(n))

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
    n[1:2] ∈ keys(STATE_CODES) || return false
    mapreduce(isdigit, &, n[4:6]) || return false
    return n[3] == 'P' || isdigit(n[3])
end

function Base.isvalid(c::MedicareProviderCCN, i::Int64)
    n = c.number
    if i == 1 || i == 2
        return n[1:2] ∈ keys(STATE_CODES)
    elseif i == 3
        return n[3] == 'P' || isdigit(n[3])
    else
        return isdigit(n[i])
    end
end

function Base.isvalid(c::MedicaidOnlyProviderCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(STATE_CODES) || return false
    n[3] ∈ MEDICAID_TYPE_CODES || return false
    return mapreduce(isdigit, &, n[4:6])
end

function Base.isvalid(c::MedicaidOnlyProviderCCN, i::Int64)
    n = c.number
    if i == 1 || i == 2
        return n[1:2] ∈ keys(STATE_CODES)
    elseif i == 3
        return n[3] ∈ MEDICAID_TYPE_CODES
    else
        return isdigit(n[i])
    end
end

function Base.isvalid(c::IPPSExcludedProviderCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(STATE_CODES) || return false
    n[3] ∈ IPPS_EXCLUDED_TYPE_CODES || return false
    isdigit(n[4]) || n[4] ∈ keys(IPPS_PARENT_HOSPITAL_TYPES) || return false
    return mapreduce(isdigit, &, n[5:6])
end

function Base.isvalid(c::IPPSExcludedProviderCCN, i::Int64)
    n = c.number
    if i == 1 || i == 2
        return n[1:2] ∈ keys(STATE_CODES)
    elseif i == 3
        return n[3] ∈ IPPS_EXCLUDED_TYPE_CODES
    elseif i == 4
        return isdigit(n[4]) || n[4] ∈ keys(IPPS_PARENT_HOSPITAL_TYPES)
    else
        return isdigit(n[i])
    end
end

function Base.isvalid(c::EmergencyHospitalCCN)
    n = c.number
    length(n) == 6 || return false
    n[1:2] ∈ keys(STATE_CODES) || return false
    n[6] ∈ keys(EMERGENCY_CODES) || return false
    return mapreduce(isdigit, &, n[3:5])
end

function Base.isvalid(c::EmergencyHospitalCCN, i::Int64)
    n = c.number
    if i == 1 || i == 2
        return n[1:2] ∈ keys(STATE_CODES)
    elseif i == 6
        return n[6] ∈ keys(EMERGENCY_CODES)
    else
        return isdigit(n[i])
    end
end

function Base.isvalid(c::SupplierCCN)
    n = c.number
    length(n) == 10 || return false
    n[1:2] ∈ keys(STATE_CODES) || return false
    n[3] ∈ keys(SUPPLIER_CODES) || return false
    return mapreduce(isdigit, &, n[4:10])
end

function Base.isvalid(c::SupplierCCN, i::Int64)
    n = c.number
    if i == 1 || i == 2
        return n[1:2] ∈ keys(STATE_CODES)
    elseif i == 3
        return n[3] ∈ keys(SUPPLIER_CODES)
    else
        return isdigit(n[i])
    end
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

A `String` that represents an invalid state code.
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
state(ccn::CCN) = get(STATE_CODES, ccn.number[1:2], INVALID_STATE)

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
        idx = findfirst(x -> sequence ∈ first(x), FACILITY_RANGES)
        if isnothing(idx)
            return ccn.number[3:6]
        else
            val = FACILITY_RANGES[idx]
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
            idx = findfirst(x -> sequence ∈ first(x), FACILITY_RANGES)
            if isnothing(idx)
                return INVALID_FACILITY_TYPE
            else
                val = FACILITY_RANGES[idx]
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
            idx = findfirst(x -> sequence ∈ first(x), MEDICAID_HOSPITAL_RANGES)
            if isnothing(idx)
                return INVALID_FACILITY_TYPE
            else
                val = MEDICAID_HOSPITAL_RANGES[idx]
                return last(val)
            end
        catch
            return INVALID_FACILITY_TYPE
        end
    else
        return get(MEDICAID_FACILITY_CODES, type_code, INVALID_FACILITY_TYPE)
    end
end

facility_type(ccn::IPPSExcludedProviderCCN) = get(MEDICAID_FACILITY_CODES, ccn.number[3], INVALID_FACILITY_TYPE)

facility_type(ccn::EmergencyHospitalCCN) = get(EMERGENCY_CODES, ccn.number[6], INVALID_FACILITY_TYPE)

facility_type(ccn::SupplierCCN) = get(SUPPLIER_CODES, ccn.number[3], INVALID_FACILITY_TYPE)

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
        idx = findfirst(x -> sequence ∈ first(x), FACILITY_RANGES)
        if isnothing(idx)
            return sequence
        else
            val = FACILITY_RANGES[idx]
            range = first(val)
            return sequence - first(range)
        end
    end
end

function sequence_number(ccn::MedicaidOnlyProviderCCN)
    sequence = parse(Int64, ccn.number[4:6])
    type_code = ccn.number[3]
    if type_code == 'J'
        idx = findfirst(x -> sequence ∈ first(x), MEDICAID_HOSPITAL_RANGES)
        if isnothing(idx)
            return sequence
        else
            val = MEDICAID_HOSPITAL_RANGES[idx]
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
        parent_type = get(IPPS_PARENT_HOSPITAL_TYPES, parent_code, ("invalid parent type" => ""))
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

Decode `ccn` and either return the information as a `String` or write to `IO`.
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
        parent_type = get(IPPS_PARENT_HOSPITAL_TYPES, parent_code, ("invalid parent type" => ""))
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