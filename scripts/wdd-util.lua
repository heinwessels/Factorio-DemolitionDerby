local Factorio_util = require("util")

local Util = { }

function Util.merge(tables) return Factorio_util.merge(tables) end

-- Remove all nils from an array
function Util.compact_array(t)
    local ans = {}
    local l = 1
    for _,v in pairs(t) do
        ans[ l ] = v
        l = l + 1
    end
    return ans
end

-- Removes index of a table by overwriting it 
-- with the last element in the table, and then setting
-- the last element to nil. This is useful when looping 
-- through an array
function Util.array_remove_index_unordered(arr, index, length)
    local last_index = length or #arr
    arr[index] = arr[last_index]
    arr[last_index] = nil
end

function Util.is_player_in_list(players, player)
    for _, other in pairs(players) do
        if other.index == player.index then return true end
    end
    return false
end

-- Returns the area of an area in tiles^2
function Util.size_of_area(area)
    return (area.right_bottom.x-area.left_top.x)*(area.right_bottom.y-area.left_top.y)
end

-- Is the position within the area?
function Util.position_in_area(position, area)
    return 
        (position.x > area.left_top.x and position.x < area.right_bottom.x ) and
        (position.y > area.left_top.y and position.y < area.right_bottom.y )
end

function Util.random_position_in_area(area)
    return {
        x=math.random(area.left_top.x, area.right_bottom.x),
        y=math.random(area.left_top.y, area.right_bottom.y)
    }
end

-- Is the position within the area?
function Util.middle_of_area(area)
    return {
        x=(area.left_top.x + (area.right_bottom.x - area.left_top.x)/2),
        y=(area.left_top.y + (area.right_bottom.y - area.left_top.y)/2)
    }
end

function Util.area_grow(area, growth)
    return {
        left_top = {
            x = area.left_top.x - growth,
            y = area.left_top.y - growth
        },
        right_bottom = { 
            x = area.right_bottom.x + growth,
            y = area.right_bottom.y + growth
        }
    }
end


-- When two players are teleported to exactly the same
-- spot they will get stuck on top of another. This
-- Will first try to spawn at the correct location.
-- If this doesn't work it will try to spawn randomly
-- in the area of <size> around player
function Util.teleport_safe(player, position, size)
    if not size then size = {x=5, y=5} end
    local surface = player.surface

    -- First try to spawn exactly at the desired location
    local obstruction = surface.find_entity("character", position)
    if not obstruction then
        player.teleport(position)
        return
    end

    -- If we're here it didn't work. Now try to spawn randomly 
    -- at some location
    local tries = 10
    while tries > 0 do
        local random_position = {
            x = position.x + (math.random(0, size.x)-size.x/2),   -- Random location with 0.1 tile resolution
            y = position.y + (math.random(0, size.y)-size.y/2),
        }
        obstruction = surface.find_entity("character", random_position)
        if not obstruction then
            player.teleport(random_position)
            return
        end
    end
    error([[
        Could not find a valid safe place to teleport player ]]..player.name..[[.
        Attempted to teleport to ]]..Util.to_string(position)..[[ 
        with size ]]..Util.to_string(size)..[[
    ]])
end

-- Turn the player into a spectator.
-- It will return a reference to the character
-- that's left behind
function Util.player_to_spectator(player)
    local character = player.character
    if not character then return end
    player.disassociate_character(character)
    if not controller then controller = defines.controllers.spectator end
    player.set_controller{type = defines.controllers.spectator}
    character.associated_player = nil
    return character
end

-- This will give a player that's currently
-- a spectator back his body.
function Util.player_from_spectator(player)
    if player.character then return end
    local character = player.surface.create_entity{
        name = "character",
        position = player.position,
        force = "player",
    }
    player.associate_character(character)
    player.set_controller{
        type = defines.controllers.character, 
        character = character,                
    }
end

function Util._table_print (tt, done)
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
                table.insert(sb, Util._table_print (value, indent + 2, done))
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
        return "{"..Util._table_print(tbl).."}"
    elseif type(tbl) == "string" then
        return tbl
    else
        return tostring(tbl)
    end
end

function Util.round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces>0 then
      local mult = 10^numDecimalPlaces
      return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

function Util.string_find_last(haystack, needle)
    -- https://stackoverflow.com/a/20460403
    local i=haystack:match(".*"..needle.."()")
    if i==nil then return nil else return i-1 end
end

return Util