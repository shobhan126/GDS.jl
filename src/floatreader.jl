"""
Read the Excess-64 Binary Representation into Float64.
"""
function read_gdsfloat64(stream::IOStream)
    # currently blindly using the logic used in gdspy. 
    # TODO: test, add reasoning, simplify; extend Base.read instead of naming this new function
    byte_1 = read(stream, UInt8)
    exponent_bits =  bitstring(byte_1 & 0x7F)
    mantissa_bits = join(bitstring.(read(stream, 7)))
    parse(Int64, mantissa_bits, base=2)  * 16.0^(parse(Int64, exponent_bits, base=2)-64.0)/ 72057594037927936.0
end