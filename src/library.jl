
mutable struct Cell
    name:: String
    polygons::Vector{<:Any}
    paths::Vector{<:Any}
    labels::Vector{<:Any}
    references::Vector{<:Any}
    bounding_box::Bool
end
"""
The Cell object requires the following functions

to_gds()

copy

add_element -> extend julia's insert! function
remove, (polygons, paths, labels)
area(self, by_spec) 

getters -> layers, datatypes, texttypes, svg_classes, bounding_box,


"""




struct CellReference
    reference
    origin
    rotation
    magnification
    x_reflection::Bool
    ignore_missing::Bool
end