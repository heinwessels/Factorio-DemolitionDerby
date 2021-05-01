Util = { }

-- Remove all nils from an array
function Util.compact_array(t)
    local ans = {}
    for _,v in pairs(t) do
        ans[ #ans+1 ] = v
    end
    return ans
end

-- Returns the area of an area in tiles^2
function Util.size_of_area(area)
    return (area[2].x-area[1].x)*(area[2].y-area[1].y)
end

function Util.table_print (tt, done)
    local done = done or {}
    local indent = indent or 0
    if type(tt) == "table" then
        local sb = {}
        for key, value in pairs (tt) do            
            if type (value) == "table" and not done [value] then
                done [value] = true
                if type(key) ~= "number" then
                    table.insert(sb, key .. " = {");
                else
                    table.insert(sb, "{");
                end
                table.insert(sb, Util.table_print (value, indent + 2, done))
                table.insert(sb, "}, ");
            elseif type(key) == "number"  then
                table.insert(sb, string.format("\"%s\"", tostring(value)))
            else
                table.insert(sb, string.format(
                    "%s = \"%s\", ", tostring (key), tostring(value))
                )
            end
        end
        return table.concat(sb)
    else
        return tt
    end
end
  
function Util.to_string( tbl )
    if type(tbl) == "nil" then
        return tostring(nil)
    elseif type(tbl) == "table" then
        return "{"..Util.table_print(tbl).."}"
    elseif type(tbl) == "string" then
        return tbl
    else
        return tostring(tbl)
    end
end

return Util