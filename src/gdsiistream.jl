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
3. Structure => Cell
4. Elements
5. Boundary => Defines the boundary of a closed object
6. Path
7. SRef => CellReference
8. ARef
9. text
10. node
11. box
12. textbody
13. strans 
14. property

TODO: replace the name Structure with Cell.
SREF => CellReference
"""

abstract type GDSElement end
# # GDS Elements Boundary, Path, SRef, ARef, Node, Box
# text will be a separate type?
_sub_elements = [
    :GDSFormatType => (GDSFormat, [GDSMask]),
    :GDSTextBody => (GDSDataType, [GDSPresentation], [GDSPathType], [GDSWidth], [GDSStructureTransform], GDSXY, GDSString),
    :GDSStructureTransformation => (GDSStructureTransform, [GDSMag], [GDSAngle]),
    :GDSProperty => (GDSPropertyAttribute, GDSPropertyValue)
]

_str = x -> rsplit(lowercase(string(x)), "gds")[2]
_tosym = p -> p isa DataType ? Symbol(_str(p)) : Symbol(_str(p[1]))
_totypes = p -> p isa DataType ? p : :(Union{Nothing,$(p[1])})
_toparam = p -> p isa DataType ? _tosym(p) : Expr(:kw, (_tosym(p)), :nothing)

# create structures
for (k, v) in _sub_elements
    pnames = _tosym.(v)
    ptypes = _totypes.(v)
    props = [:($n::$t) for (n, t) in zip(pnames, ptypes)]
    struct_declaration = Expr(
        :struct,
        false, # ismutable or not
        k, Expr(:block, props...))
    @eval $struct_declaration
    # construction defintions
    constructor_declaration = Expr(
        :(=),
        Expr(:call, k, Expr(:parameters, _toparam.(v)...)),
        Expr(:call, k, pnames...)
    )
    @eval $constructor_declaration
end


_gds_elements = Dict([
    :GDSBoundary => ([GDSElementFlags], [GDSPlex], GDSLayer, GDSDataType, GDSXY),
    :GDSPath => ([GDSElementFlags], [GDSPlex], GDSLayer, GDSDataType, [GDSPathType], [GDSWidth], [GDSBeginExtn], [GDSEndExtn], GDSXY),
    :GDSStructureReference => ([GDSElementFlags], [GDSPlex], GDSStructureName, [GDSStructureTransformation], GDSXY),
    :GDSArrayReference => ([GDSElementFlags], [GDSPlex], GDSStructureName, [GDSStructureTransformation], GDSColRow, GDSXY),
    :GDSNode => ([GDSElementFlags], [GDSPlex], GDSLayer, GDSDataType, GDSXY),
    :GDSBox => ([GDSElementFlags], [GDSPlex], GDSLayer, GDSDataType, GDSXY),
    :GDSText => ([GDSElementFlags], [GDSPlex], GDSLayer, GDSTextBody),
])


for (k, v) in _gds_elements
    pnames = _tosym.(v)
    ptypes = _totypes.(v)
    props = [:($n::$t) for (n, t) in zip(pnames, ptypes)]
    struct_declaration = Expr(
        :struct,
        false, # ismutable or not
        Expr(:<:, k, :GDSElement), Expr(:block, props...))
    @eval $struct_declaration

    constructor_declaration = Expr(
        :(=),
        Expr(:call, k, Expr(:parameters, _toparam.(v)...)),
        Expr(:call, k, pnames...)
    )
    @eval $constructor_declaration
end

_stream_elements = [
    :GDSStructure => (GDSStructureName, [GDSElement]),
]


for (k, v) in _stream_elements
    pnames = _tosym.(v)
    ptypes = _totypes.(v)
    props = [:($n::$t) for (n, t) in zip(pnames, ptypes)]
    struct_declaration = Expr(
        :struct,
        false, # ismutable or not
        Expr(:<:, k, :GDSRecord), Expr(:block, props...))
    @eval $struct_declaration

    constructor_declaration = Expr(
        :(=),
        Expr(:call, k, Expr(:parameters, _toparam.(v)...)),
        Expr(:call, k, pnames...)
    )
    @eval $constructor_declaration
end

struct GDSStream
    header::GDSHeader
    beginlib::GDSBeginLibrary
    libdirsize::GDSLibraryDirSize
    srfname::GDSSRFName
    libsecure::GDSLibSecure
    libname::GDSLibraryName
    reflibs
    fonts
    attributetable
    generations
    formattype
    units
    structures
end


# extending Base: read & write.
# function read(stream, GDSStream)
# function write(stream, GDSStream)