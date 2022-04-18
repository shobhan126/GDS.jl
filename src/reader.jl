include("recordtypes.jl")
# stream.read(4) == read 4 bytes
import Base: read, UInt64, show, IOStream
# TODO: Extend the show function
# Base.show(io:: IO, x::GDSFloat64)

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
    0x00 => nothing,
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


"""
Read the IOStream assuming next few bits are the Record Header. 
"""
function read(stream::IOStream, ::Type{GDSRecordHeader})
    num_bytes = ntoh(read(stream, UInt16))
    record_type = UINT_TO_RECORD_TYPE[ntoh(read(stream, UInt16))]
    GDSRecordHeader{record_type}(num_bytes-UInt16(4))
end

# write gdsheader?

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


"""
Read a GDSRecord.
"""
function read(stream::IOStream, ::Type{GDSRecord})
    header = read(stream, GDSRecordHeader)
    record_type = typeof(header).parameters[1]
    if supertype(record_type) == GDSAsciiString
        data = read(stream, record_type, header.num_bytes)
    elseif record_type == GDSXY
        data = read(stream, record_type, header.num_bytes)
    else
        data = read(stream, record_type)
    end
    return header, data
end

read(stream::IOStream, t::Type{<:GDSEmptyRecord}) = nothing
read(stream::IOStream, t::Type{<:GDS16Bit}) = t(ntoh(read(stream, UInt16)))
read(stream::IOStream, t::Type{<:GDS32Bit}) = t(ntoh(read(stream, UInt32)))
read(stream::IOStream, t::Type{<:GDS64Bit}) = t(ntoh(read(stream, UInt64)))

"""Read a GDSString subtype."""
function read(stream::IOStream, t::Type{<:GDSAsciiString}, nbytes) 
    chars = Char.([ntoh(read(stream, UInt8)) for _ in 1:nbytes])
    t(join(chars))
end


function read(stream::IOStream, t::Type{GDSBeginLibrary})
    t(tuple((ntoh(read(stream, Int16)) for _ in 1:12)...))
end

function read(stream::IOStream, t::Type{GDSBeginStructure})
    t(tuple((ntoh(read(stream, Int16)) for _ in 1:12)...))
end

function read(stream::IOStream, t::Type{GDSXY}, nbytes::UInt16)
    GDSXY([ntoh(read(stream, Int32)) for _ in 1:(nbytes/4)])
end

read(stream::IOStream, t::Type{GDSUnits}) = t(read(stream, GDSFloat64), read(stream, GDSFloat64))



"""
Read a Single Record from the stream.
"""
function read_record(stream::IOStream)
    header = read(stream, GDSRecordHeader)
    num_bytes = header.num_bytes
    record_type = typeof(header).parameters[1]
    data_type = UINT_TO_TYPE[UInt16(RECORD_TYPE_TO_UINT[record_type] & 0x00FF)]
    if num_bytes > 0
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
        data = nothing
    end
    return record_type, data
end


"""
Read a GDS file into raw records. 
Emulates gdspy behavior.
"""
function read_raw_record(stream::IOStream)
    # read rec  ord header
    header = read(stream, GDSRecordHeader)
    num_bytes = header.num_bytes
    println(num_bytes)
    record_type = typeof(header).parameters[1]
    # data_type = UINT_TO_TYPE[UInt16(RECORD_TYPE_TO_UINT[record_type] & 0x00FF)]
    if num_bytes > 0
        return (record_type, [read(stream, UInt8) for _ in 1:num_bytes])
    else
        return (record_type, nothing)
    end
end
# function gdsii_hash(filename, engine=None)
# end


# stream = open("test_gds.GDS", "r+");
# test = Any[read_raw_record(stream)[1]]
# while bytesavailable(stream) > 0
#     append!(test, [read_raw_record(stream)[1]])
# end;
# length(test)

# stream = open("test_gds.GDS", "r+");
# test2 = Any[read(stream, GDSRecord)]
# while bytesavailable(stream) > 0
#     append!(test2, tuple(read(stream, GDSRecord)))
# end;
# length(test)