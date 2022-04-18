import Base: read, UInt64, show, IOStream

"""
types encapsulating gds stream syntax  
"""
include("recordtypes.jl")
# TODO: Extend the show function
# Base.show(io:: IO, x::GDSFloat64)

"""
1. Stream
2. formattype
3. Structure
4. Elements
5. Boundary
6. Path
7. SRef
8. ARef
9. text
10. node
11. box
12. textbody
13. strans
14. property
"""


abstract type GDSElement end
# GDS Elements Boundary, Path, SRef, ARef, Text, Node, Box


struct GDSStream 
    header
    beginlib
    libdirsize
    srfname
    libsecure
    libname
    reflibs
    fonts
    attributetable
    generations
    formattype
    units
    structures
end

struct GDSFormatType
    format
    masks
end


struct GDSStructure
    name::GDSAsciiString
    elements::Vector{<:GDSElement}
end

struct GDSBoundary <: GDSElement
    flags::Union{Nothing, GDSElementFlags}
    plex::Union{Nothing, GDSPlex}
    layer:: GDSLayer
    datatype::GDSDataType
    xy:: GDSXY
end
GDSBoundary(layer::GDSLayer, datatype::GDSDataType, xy::GDSXY) = GDSBoundary(nothing, nothing, layer, datatype, xy)

struct GDSPath <: GDSElement
    flags
    plex
    layer
    datatype
    pathtype
    width
    beginextn
    endextn
    xy:: GDSXY
end


struct GDSStructureReferenc <: GDSElement
    flags
    plex
    name
    strans
    xy
end


struct GDSArrayReference <: GDSElement
    flags
    plex 
    sname
    strans
    colrow
    xy
end

struct GDSText <: GDSElement
    flags
    plex
    layer
    textbody
end


struct GDSNode <: GDSElement
    flags
    plex
    layer
    nodetype
    xy
end

struct GDSBox <: GDSElement
    flags
    plex
    layer
    boxtype
    xy
end

struct TextBody <: GDSElement
    type
    presentation
    pathtype
    width
    strans
    xy
    gdsstring
end

struct GDStructureTransformation <: GDSElement
    strans
    magnitude
    angle
end


struct GDSProperty <: GDSElement
    attribute
    value
end
