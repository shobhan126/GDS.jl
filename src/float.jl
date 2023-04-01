import Base
using DocStringExtensions

"""
Excess-64 64-Bit Float Point Format used for GDSII files.

    $(TYPEDEF)
"""
primitive type  FloatE64 <: AbstractFloat 64 end 

FloatE64(x::UInt64) = reinterpret(FloatE64, x)
UInt64(x::FloatE64) = reinterpret(UInt64, x)

"""
Read the Excess-64 Binary Representation.
"""
read(stream::IOStream, ::Type{FloatE64}) = FloatE64(ntoh(read(stream, UInt64)))

# TODO: fix this. this is definitely wrong right now...
"""
Text representation for GDSFloat64 type.
"""
function Base.show(io::IO,::MIME"text/plain", x::FloatE64)
    xbin = bitstring(reinterpret(UInt64, x))
    exponent_bits =  xbin[2:8]
    mantissa_bits = xbin[9:end]
    sign = (-1.0)^parse(Bool, xbin[1])
    println(sign * parse(Int64, mantissa_bits, base=2)  * 16.0^(parse(Int64, exponent_bits, base=2)-64.0)/ 72057594037927936.0)
end

# TODO: define algebra for excess-64 represenation
#   define how to typecast to float64 and back. 
#
# function Base.+(x::GDSFloat64, y::GDSFloat64)
# end
#
# function Base.-(x::GDSFloat64, y::GDSFloat64)
# end
#
# function Base.*(x::GDSFloat64, y::GDSFloat64)
# end
#
# function Base./(x::GDSFloat64, y::GDSFloat64)
# end