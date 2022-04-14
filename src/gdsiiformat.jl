"""
http://bitsavers.informatik.uni-stuttgart.de/pdf/calma/GDS_II_Stream_Format_Manual_6.0_Feb87.pdf

https://boolean.klaasholwerda.nl/interface/bnf/gdsformat.html#GDSBNF

also see github repo for gdspy
"""

"""
The Stream format output file is composed of variable length records. The
minimum record length is four bytes. Records can be infinitely long. The
first four bytes of a record are the header. The first two bytes of the header
contain a count (in eight-bit bytes) of the total record length. The count
tells you where one record ends and another begins. The next record begins
immediately after the last byte included in the count.

The third byte of the header is the record type. The fourth byte of the header
describes the type of data contained within the record. The fifth through last
bytes of a record are data. Figure 2-1 shows a typical record header. 
"""

UINT_TO_TYPE = Dict(
    0x00 => Nothing,
    # Bit Array, 16 bit word?
    0x01 => UInt16,
    0x02 => Int16,
    0x03 => Int32,
    # Acc. to the veryy old manual, Float32 is not used...
    0x04 => Float32,
    0x05 => Float64,
    # ASCII String
    0x06 => String,
)

# stream.read(4) == read 4 bytes
"""
Generator for complete records from a GDSII stream file.
"""

function read_header(stream::IOStream)
    num_bytes = ntoh(read(stream, UInt16))
    record_type = ntoh(read(stream, UInt8))
    data_type = UINT_TO_TYPE[read(stream, UInt8)]
    return num_bytes, record_type, data_type
end


function read_record(stream::IOStream)
    num_bytes, record_type, data_type = read_header(stream)
    if num_bytes > 4
        if data_type != String
            num_items = (num_bytes - 4) / sizeof(data_type)
            data = [ntoh(read(stream, data_type)) for _ in 1:num_items]
        else
            num_items = (num_bytes - 4) / sizeof(UInt8)
            chars = Char.([ntoh(read(stream, UInt8)) for _ in 1:num_items])
            # TODO: 
            #   fix float64 representation.
            if chars[end] == '\0' 
                pop!(chars);
            end
            data = join(chars)
        end
    else
        data = Nothing
    end
    return record_type, data
end



"""
Read a GDS file into raw records. 
Emulates gdspy behavior.
"""
function read_raw_record(stream::IOBuffer)
    # read record header

    if num_bytes > 4
        return (record_type, [read(stream, UInt8) for _ in 1:num_bytes])
    else
        return (record_type, Nothing)
    end
end
# function gdsii_hash(filename, engine=None)
# end

"""
Four-Byte Real (4) and Eight-Byte Real (5):
4-byte real = 2 word floating point representation 
8-byte real = 4 word floating point representation For all non-zero values:
A floating point number is made up of three parts: the sign, the exponent, and the mantissa.

The value of a floating point number is defined to be:

    (Mantissa) x (16 raised to the true value of the exponent field).

The exponent field (bits 1-7) is in Excess-64 representation. 
The 7-bit field shows a number that is 64 greater than the actual exponent.
The mantissa is always a positive fraction >=1/16 and <1. 
For a 4-byte real, the mantissa is bits 8-31. For an 8-byte real, the mantissa is bits 8-63.
The binary point is just to the left of bit 8. Bit 8 represents the value 1/2, bit 9 represents 1/4, etc.
In order to keep the mantissa in the range of 1/16 to 1, the results of floating point arithmetic are normalized. 
Normalization is a process whereby the mantissa is shifted left one hex digit at a time until its left FOUR bits represent a non-zero quantity. 
For every hex digit shifted, the exponent is decreased by one. Since the mantissa is shifted four bits at a time,
 it is possible for the left three bits of a normalized mantissa to be zero.
A zero value, also called true zero, is represented by a number with all bits zero
"""

