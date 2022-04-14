"""
http://bitsavers.informatik.uni-stuttgart.de/pdf/calma/GDS_II_Stream_Format_Manual_6.0_Feb87.pdf

https://boolean.klaasholwerda.nl/interface/bnf/gdsformat.html#GDSBNF
"""

using SHA
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
    0 => Nothing,
    # Bit Array, 16 bit word?
    1 => UInt16,
    2 => Int16,
    3 => Int64,
    # Acc. to the veryy old manual, Float32 is not used...
    4 => Float32,
    5 => Float64,
    # ASCII String
    6 => String,
)

# stream.read(4) == read 4 bytes
"""
Generator for complete records from a GDSII stream file.

"""
function read_record(stream::IO)
    if bytesavailable(stream) > 3
        num_bytes = ntoh(read(stream, UInt16))-4
        record_type = ntoh(read(stream, UInt16))  ÷ 256
        data_type = record_type & 0x00FF

        if data_type in keys(UINT_TO_TYPE)
            data_type   = UINT_TO_TYPE(data_type)
        else
            data_type = Char
        end

        record_type = Int64(record_type ÷ 256)
        
        if num_bytes > 0
            num_items = (num_bytes - 4) / sizeof(data_type)
            data = [ntoh(read(stream, data_type)) for _ in 1:num_items]
            
        else
            data = None
        end
    else
        return None
    end

end


"""
read a GDS file into raw records. 
"""
function read_raw_record(stream::IOBuffer)
    num_bytes = ntoh(read(stream, UInt16))-4
    record_type = ntoh(read(stream, UInt16))  ÷ 256
    if num_bytes > 0
        return (record_type, [read(stream, UInt8) for _ in 1:num_bytes])
    else
        return (record_type, Nothing)
    end
end


"""

"""
# function gdsii_hash(filename, engine=None)
# end