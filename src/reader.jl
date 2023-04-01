
include("gdsiistream.jl")
# stream.read(4) == read 4 bytes
import Base: read, UInt64, show, IOStream
# TODO: Extend the show function
# Base.show(io:: IO, x::GDSFloat64)

"""
http://bitsavers.informatik.uni-stuttgart.de/pdf/calma/GDS_II_Stream_Format_Manual_6.0_Feb87.pdf
https://boolean.klaasholwerda.nl/interface/bnf/gdsformat.html#GDSBNF

also see github repo for gdspy
"""

UINT_TO_TYPE = Dict(
    0x00 => nothing,
    # Bit Array, 16 bit word?
    0x01 => UInt16,
    0x02 => Int16,
    0x03 => Int32,
    # Acc. to the veryy old manual, Float32 is not used...
    # 0x04 => Float32,
    0x05 => Float64,
    # ASCII String
    0x06 => String,
)


"""
Read the IOStream assuming next few bits are the Record Header. 
"""
function read(io::IOStream, ::Type{GDSRecordHeader})
    nb = ntoh(read(io, UInt16))
    rt = UINT_TO_RECORD_TYPE[ntoh(read(io, UInt16))]
    return rt,(nb - UInt16(4))
end

read(stream::IOStream, t::Type{<:GDSEmptyRecord}) = t
read(stream::IOStream, t::Type{<:GDS16Bit}) = t(ntoh(read(stream, UInt16)))
read(stream::IOStream, t::Type{<:GDS32Bit}) = t(ntoh(read(stream, UInt32)))
read(stream::IOStream, t::Type{<:GDS64Bit}) = t(ntoh(read(stream, UInt64)))


read(stream::IOStream, t::Type{<:GDSAsciiString}, nbytes) = Char.([ntoh(read(stream, UInt8)) for _ in 1:nbytes]) |> join |> t
read(stream::IOStream, t::Type{GDSXY}, nbytes::UInt16) = t([ntoh(read(stream, Int32)) for _ in 1:(nbytes/4)])
read(stream::IOStream, t::Type{GDSUnits}) = t(read(stream, FloatE64), read(stream, FloatE64))

read(stream::IOStream, t::Type{GDSBeginLibrary}) = t(tuple((ntoh(read(stream, Int16)) for _ in 1:12)...))
read(stream::IOStream, t::Type{GDSBeginStructure}) = t(tuple((ntoh(read(stream, Int16)) for _ in 1:12)...))

GDSBeginElement = Union{GDSBeginBoundary,GDSBeginPath,GDSBeginStructureRef,GDSBeginArrayRef, GDSBeginNode, GDSBeginBox}

TYPE_FROM_BEGIN_TYPE = Dict(
    GDSBeginPath => GDSPath,
    GDSBeginStructureRef => GDSStructureRef,
    GDSBeginArrayRef => GDSArrayRef,
    GDSBeginNode => GDSNode,
    GDSBeginBox => GDSBox,
    GDSBeginText => GDSText,
    GDSEndElement => GDSEndElement,
)

"""
Read a GDSRecord
"""
function read(io::IOStream, ::Type{GDSRecord})
    t, nb = read(io, GDSRecordHeader)
    if t <: GDSBeginElement
        eltype = eval(join(split(string(t), "Begin")))
        data = read(io, eltype)
    else
        data = (t <: GDSAsciiString) | (t == GDSXY) ? read(io, t, nb) : read(io, t)
    end
    return data
end

# function read(io::IOStream, T::Type{<:GDSElement})
#     k = string(typeof(T))[4:end]
#     kwargs = Pair[]
#     v = read(io, GDSRecord)
#     while !(v isa GDSEndElement)
#         v = read(io, GDSRecord)
#         k = string(typeof(v))[4:end]
#         push!(kwargs, k=>v)
#     end
#     # TODO Add GDSProperty? 
#     T(kwargs...)
# end

# function read(io::IOStream, ::Type{GDSStructure})
#     # read GDSBeginStructure
#     bgnstr = read(io, GDSBeginLibrary)

#     name = read(io, GDSRecord)
#     if bgnstr isa GDSEndLibrary
#         return nothing
#     end
#     # read the structure name
#     sname = read(io, GDSRecord)
# end


"""
Read a GDS file into raw records. 
Emulates gdspy behavior.
"""
function read_raw_record(io::IOStream, ::Type{GDSStream})
    # read record header
    rt, nb  = read(io, GDSRecordHeader)
    # data_type = UINT_TO_TYPE[UInt16(RECORD_TYPE_TO_UINT[record_type] & 0x00FF)]
    nb > 0 ? (rt, [read(io, UInt8) for _ in 1:nb]) : (rt, nothing)
end


read_raw(io::IOStream, ::Type{GDSRecord}) = read(io, GDSRecord) |> x -> (type(x), x)

"""
Read the entire file and create a GDSStream 


    <stream format>:: = 
        HEADER BGNLIB [LIBDIRSIZE] [SRFNAME]
        [LIBSECUR] LIBNAME [REFLIBS] [FONTS]
        [ATTRTABLE] [GENERATIONS] [<FormatType>]
        UNITS {<structure>}* ENDLIB
"""
function read(io::IOStream, ::Type{GDSStream})
    # data before you get to strcutres
    prestruct = Dict{Symbol, GDSRecord}()
    rec = read(io, GDSRecord)
    while !(rec isa GDSUnits)
        prestruct[Symbol(typeof(rec))] = rec
        rec = read(io, GDSRecord)
    end
    prestruct[:GDSUnits] = rec

    remaining = Any[]
    while bytesavailable(io) > 0
        push!(remaining, read(io, GDSRecord))
    end
    return prestruct, remaining
    # read a gds structure 
end



