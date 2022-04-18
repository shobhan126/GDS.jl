using Dates
import Base: read, UInt16, UInt64, show

primitive type  GDSFloat64 <: AbstractFloat 64 end 

GDSFloat64(x::UInt64) = reinterpret(GDSFloat64, x)
UInt64(x::GDSFloat64) = reinterpret(UInt64, x)


abstract type GDSRecord end
abstract type GDSEmptyRecord <:GDSRecord end
abstract type GDS16Bit <:GDSRecord end
abstract type GDS32Bit <:GDSRecord end
abstract type GDS64Bit <:GDSRecord end
abstract type GDSAsciiString <:GDSRecord end

"""
Record Header describing the data bytes.
"""
struct GDSRecordHeader{T} <: GDSRecord where T<: GDSRecord
    num_bytes:: UInt16
end


macro emptyrecordtype(args)
    for arg in args.args
        @eval abstract type $(arg) <: GDSEmptyRecord end
    end
end


macro sixteenbittype(args)
    for arg in args.args
        @eval primitive type $(arg) <: GDS16Bit 16 end
        @eval $(arg)(x::UInt16) = reinterpret($(arg), x)
        @eval $(arg)(x::Integer) = reinterpret($(arg), UInt16(x))
    end
end

macro thirtytwobittype(args)
    for arg in args.args
        @eval primitive type $(arg) <: GDS32Bit 32 end
        @eval $(arg)(x::UInt32) = reinterpret($(arg), x)
        @eval $(arg)(x::Integer) = reinterpret($(arg), UInt32(x))
    end
end

macro eightbyterealtype(args)
    for arg in args.args
        @eval primitive type $(arg) <: GDS64Bit 64 end
        @eval $(arg)(x::UInt64) = reinterpret($(arg), x)
        @eval $(arg)(x::Integer) = reinterpret($(arg), UInt64(x))
        @eval $(arg)(x::GDSFloat64) = reinterpret($(arg), x)
        @eval $(arg)(x::GDSFloat64) = reinterpret($(arg), GDSFloat64(x))
    end
end


macro stringtype(args)
    for arg in args.args
        @eval struct $(arg) <: GDSAsciiString value::String end
    end
end


@emptyrecordtype (
    GDSEndLibrary, 
    GDSEndStructure, 
    GDSBeginBoundary,
    GDSBeginPath,
    GDSBeginStructureRef,
    GDSBeginArrayRef, 
    GDSBeginText,
    GDSEndElement,
    # GDSTextNode, # Not being used?
    GDSBeginNode,
    GDSBeginBox,
    GDSEndMasks,
)

@sixteenbittype (
    GDSHeader,
    GDSLayer,
    GDSDataType,
    GDSTextType,
    GDSPresentation,
    GDSStructureTransform,
    GDSPathType,
    GDSGenerations,
    GDSStructureType,
    GDSElementFlags,
    GDSLinkType,
    GDSNodeType,
    GDSPropertyAtrribute,
    GDSBoxType,
    GDSTapeNumber,
    GDSTapeCode,
    GDSStructureClass,
    GDSFormat,
    GDSLibraryDirSize,
    GDSLibSecure,
)


@eightbyterealtype (
    GDSMag,
    GDSAngle
)

# constructor with DateTime objects
# function that casts it into datetime
# show(io: IO)
    # last_modified::DateTime
    # last_accessed::DateTime

@stringtype (
    GDSLibraryName, 
    GDSStructureName,
    GDSRefStructureName,
    GDSString,
    GDSAttributeTable, 
    GDSStypTable, 
    GDSPropertyValue, 
    GDSMask, 
    GDSSRFName
)

# add assertions for ascii string?
struct GDSBeginLibrary <:GDSRecord
    value::NTuple{12, Int16}
end

struct GDSBeginStructure <:GDSRecord
    value::NTuple{12, Int16}
end

# composite type with gds floats?
struct GDSUnits <:GDSRecord
    scale_to_user_units::GDSFloat64
    database_units_in_meters::GDSFloat64
end

primitive type GDSWidth <: GDSRecord 32 end

struct GDSXY <:GDSRecord
    value::Vector{Int32}
end


struct GDSColRow <: GDSRecord
    value::Tuple{UInt16, UInt16}
end

struct GDSReferenceLibraries <: GDSRecord
    value::Vector{String}
end

struct GDSFontNames <: GDSRecord
    value::Vector{String}
end


primitive type GDSPlex <: GDSRecord 32 end
primitive type GDSBeginExtn <: GDSRecord 32 end
primitive type GDSEndExtn <: GDSRecord 32 end


UINT_TO_RECORD_TYPE = Dict(
    0x0002 => GDSHeader,
    0x0102 => GDSBeginLibrary,
    0x0206 => GDSLibraryName,
    0x0305 => GDSUnits,
    0x0400 => GDSEndLibrary,
    0x0502 => GDSBeginStructure,
    0x0606 => GDSStructureName,
    0x0700 => GDSEndStructure,
    0x0800 => GDSBeginBoundary,
    0x0900 => GDSBeginPath, 
    0x0A00 => GDSBeginStructureRef,
    0x0B00 => GDSBeginArrayRef,
    0x0C00 => GDSBeginText,
    0x0D02 => GDSLayer,
    0x0E02 => GDSDataType,
    0x0F03 => GDSWidth,
    0x1003 => GDSXY,
    0x1100 => GDSEndElement,
    0x1206 => GDSRefStructureName,
    0x1302 => GDSColRow,
    # 0x1400 => GDSTextNode,
    0x1602 => GDSTextType,
    0x1701 => GDSPresentation, 
    0x1906 => GDSString,
    0x1A01 => GDSStructureTransform,
    0x1B05 => GDSMag,
    0x1C05 => GDSAngle,
    0x1F06 => GDSReferenceLibraries,
    0x2006 => GDSFontNames,
    0x2102 => GDSPathType,
    0x2202 => GDSGenerations,
    0x2306 => GDSAttributeTable,
    # 0x2406 => STypeTable (unreleased in 6.0, is it there in 7.0??)
    # 0x2502 => StringType (unreleased feature)
    0x2601 => GDSElementFlags,
    # 0x2703 => ElKey (unreleased in 6.0)
    # 0x0028 Link Type (unreleased in 6.0)
    # 0x0029 LinkKeys (unreleased in 6.0)
    0x2B02 => GDSPropertyAtrribute,
    0x2C06 => GDSPropertyValue,
    0x2D00 => GDSBeginBox,
    0x2E02 => GDSBoxType,
    0x2F03 => GDSPlex,
    0x3003 => GDSBeginExtn, # only in CustomPlus?
    0x3103 => GDSEndExtn, # only in CustomPlus?
    0x3202 => GDSTapeNumber,
    0x3302 => GDSTapeCode,
    # 0x3401 => GDSStringClass, internal use only?
    0x3602 => GDSFormat,
    0x3706 => GDSMask,
    0x3800 => GDSEndMasks,
    0x3902 => GDSLibraryDirSize,
    0x3A06 => GDSSRFName,
    0x3B02 => GDSLibSecure,
)

# clean up? how to arrange types better?
# writing the 

RECORD_TYPE_TO_UINT = Dict((v=>k) for (k,v) in UINT_TO_RECORD_TYPE)