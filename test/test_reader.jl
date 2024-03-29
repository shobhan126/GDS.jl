using Test

include("../src/reader.jl")

stream = open("test_gds.GDS", "r+");
test = Any[read_raw_record(stream, GDSStream)]
while bytesavailable(stream) > 0
    append!(test, [read_raw_record(stream, GDSStream)[1]])
end;

# GDSBoundary(; elementflags=nothing, plex=nothing, layer, datatype, xy) = GDSBoundary(elementflags, plex, layer, datatype, xy)
stream = open("test_gds.GDS", "r+");
test2 = Any[read(stream, GDSRecord)]
while bytesavailable(stream) > 0
    push!(test2, read(stream, GDSRecord))
end;


a = [(t isa DataType ? t : typeof(t)) for t in test2]
length(test)

stream = open("test_gds.GDS", "r+");
a, b = read(stream, GDSStream)

b[1]