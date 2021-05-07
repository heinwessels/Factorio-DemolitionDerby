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
    return (area.right_bottom.x-area.left_top.x)*(area.right_bottom.y-area.left_top.y)
end

-- Is the position within the area?
function Util.position_in_area(position, area)
    return 
        (position.x > area.left_top.x and position.x < area.right_bottom.x ) and
        (position.y > area.left_top.y and position.y < area.right_bottom.y )
end

-- Is the position within the area?
function Util.middle_of_area(area)
    return {
        x=(area.left_top.x + (area.right_bottom.x - area.left_top.x)/2),
        y=(area.left_top.y + (area.right_bottom.y - area.left_top.y)/2)
    }
end

-- When two players are teleported to exactly the same
-- spot they will get stuck on top of another. This
-- Will check if there's an player at position, and if not
-- chose another spot around <position> of <size>.
-- if <size> {x=?, y=?} is nil, then it defaults to <5, 5>
-- TODO Make this smarter so that you spawn more naturally
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

return Util