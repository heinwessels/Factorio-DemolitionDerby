curvefever_util = { }

-- Remove all nils from an array
function curvefever_util.compact_array(t)
    local ans = {}
    for _,v in pairs(t) do
        ans[ #ans+1 ] = v
    end
    return ans
end

return curvefever_util