import Base: read, UInt64, show

include("recordtypes.jl")
# TODO: Extend the show function
# Base.show(io:: IO, x::GDSFloat64)

"""
Read the Excess-64 Binary Representation into Float64.
"""
function read(stream::IOStream, ::Type{GDSFloat64})
    # currently blindly using the logic used in gdspy. 
    # TODO: test, add reasoning, simplify; extend Base.read instead of naming this new function
    byte_1 = read(stream, UInt8)
    exponent_bits =  bitstring(byte_1 & 0x7F)
    mantissa_bits = join(bitstring.(read(stream, 7)))
    sign = (-1.0)^(byte_1 & 0x80) 
    value = sign * parse(Int64, mantissa_bits, base=2)  * 16.0^(parse(Int64, exponent_bits, base=2)-64.0)/ 72057594037927936.0
    GDSFloat64(reinterpret(UInt64, value))
end


function read(stream::IOStream, ::Type{GDSRecordHeader})
"""
Read the IOStream assuming next few bits are the Record Header. 
"""
    num_bytes = ntoh(read(stream, UInt16))
    record_type = ntoh(read(stream, UInt8))
    data_type = UINT_TO_TYPE[read(stream, UInt8)]
    return num_bytes, record_type, data_type
end