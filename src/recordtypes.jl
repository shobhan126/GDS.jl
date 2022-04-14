using Dates

abstract type GDSRecord end

struct GDSHeader
    length::UInt16
    record_type<:GDSRecord
    data_type::Union{UInt16, Int16, Int32, Float64, String}
end

struct GDSBeginLib <:GDSRecord
    last_modified::DateTime
    last_accessed::DateTime
end

struct GDSLibName <:GDSRecord
    name::String
end

struct GDSUnits <:GDSRecord
    scale_to_user_units::Float64
    database_units_in_meters::Float64
end


struct GDSEndLib <: GDSRecord
end

struct GDSBeginString <:GDSRecord
end

struct GDSBoundary
end

struct 