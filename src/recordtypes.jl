using Dates

abstract type GDSRecord end


struct GDSRecordHeader <:GDSRecord
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

struct GDSUnits <:GDSEndLib

end

struct GDS