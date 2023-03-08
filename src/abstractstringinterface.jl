# Unary AbstractString methods
for op = (
    :ncodeunits,
    :codeunit,
    :iterate,
    :length,
    :sizeof,
    :String,
    :codeunits,
    :uppercase,
    :lowercase,
    :chop,
    :chomp,
    :textwidth,
    :ascii,
    :isascii,
    )
    @eval Base.$op(c::CCN) = $op(c.number)
end

# Binary AbstractString interface

for op = (
    :codeunit,
    :iterate,
    :^,
    :repeat,
    :SubString,
    :getindex,
    :startswith,
    :endswith,
    :contains,
    )
    @eval Base.$op(c::CCN, x) = $op(c.number, x)
end

Base.occursin(r::Regex, c::CCN; kwargs...) = occursin(r, c.number; kwargs...)
Base.replace(c::CCN, p::Pair...; kwargs...) = replace(c.number, p...; kwargs...)
Base.first(c::CCN, i::Integer) = first(c.number, i)
Base.last(c::CCN, i::Integer) = last(c.number, i)

# Symmetric AbstractString interface

for op = (
    :*,
    :cmp,
    :isless,
    :(==),
    )
    @eval Base.$op(l::CCN, r::CCN) = $op(l.number, r.number)
    @eval Base.$op(l::CCN, x) = $op(l.number, x)
    @eval Base.$op(x, r::CCN) = $op(x, r.number)
end

if VERSION >= v"1.8"
    for op = (:eachsplit, :chopprefix, :chopsuffix)
        @eval Base.$op(c::CCN, x) = $op(c.number, x)
    end
end
