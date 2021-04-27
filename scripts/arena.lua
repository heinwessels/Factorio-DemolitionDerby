local util = require("util")
local effects = require("scripts.effects")
local constants = require("scripts.constants")

local arena = {
    name = "",

    area = { },
    players = { },
    player_states = { },    
    effects = { },  -- Current effects scattered in arena

    status = "empty"
}

-- Set up a arena to be played at some point
-- area     of the arena
function arena.create(name, area)
    arena.name = name
    arena.area = area
    arena.status = "ready"
    arena.players = { }

    log("Created arena "..arena.name)
end

-- Add player to arena to be played
function arena.add_player(player)

    if arena.player_states[player.index] then
        log("Cannot add player "..player.name.." to arena "..arena.name.." again (Total: "..#arena.players..")")
        return
    end

    table.insert(arena.players, player)
    arena.create_player_state(arena, player)

    log("Added player "..player.name.." to arena "..arena.name.." (Total: "..#arena.players..")")
end

-- Start the game for this arena
function arena.start()
    for _, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]
        player_state.status = "playing"
    end
    arena.status = "playing"
    log("Started arena "..arena.name.." with "..#arena.players.." players")
end

function arena.create_player_state(arena, player)
    arena.player_states[player.index] = {
        effects = { },      -- What effects are applied to this player?
        score = { },        -- Score of this player"
        status = "idle",    -- nothing has been done to this player
        player = player,    -- Reference to connected player
    }
end

-- Call this function every tick
function arena.update()

    -- TODO check game. Is all the players still there?
    -- Stuff like that.

    for _, player in pairs(arena.players) do
        if player.character then
            -- Update for a specific player
            
            local vehicle = player.character.vehicle  
            local player_state = arena.player_states[player.index]

            if player_state.status == "playing" and vehicle then

                -- Ensure player is still driving
                vehicle.speed = constants.vehicle_speed
                -- TODO Ensure he is still in his car

                -- Draw tail
                local tail_position = arena.draw_tail(player)

                -- Apply any effects
                effects.apply_effects(arena, player)

                -- TODO Update score.
            end
        end
    end
end

-- Draws a tail behind the player
function arena.draw_tail(player)
    if game.tick % constants.trail.period < constants.trail.gap then return end
    local surface = player.surface
    local vehicle = player.character.vehicle
    local orientation = vehicle.orientation * 2 * math.pi
    local position = {
        x = vehicle.position.x - constants.trail.offset*math.sin(orientation),
        y = vehicle.position.y + constants.trail.offset*math.cos(orientation),
    }
    if not surface.find_entity("curve-trail", position) then 
        surface.create_entity{
            name = "curve-trail",
            type = "wall",
            position = position,
            create_build_effect_smoke = true,
        }
    end    
end


-- This handler should be called if any effect beacon
-- is hit. This function will decide if it's part of this
-- arena, and apply it
function arena.hit_effect_event(event)
    local surface = game.get_surface(event.surface_index)
    local beacon = event.source_entity
    
    if not string.sub(beacon.name, 1, 17) then return end
    
    local vehicle_in_range = surface.find_entities_filtered{
        position = beacon.position,
        radius = 6,
        name = {"curvefever-car", "curvefever-tank"},
        limit = 1, -- TODO HANDLE MORE!
    }
    local player = nil
    if vehicle_in_range then
        local vehicle = vehicle_in_range[1]
        player = vehicle.get_driver().player
        local effect_type = string.sub(beacon.name, 19, -1)
        
        -- Add the applicable effect
        if effect_type == "speed" then
            effects.add_effect(arena, player, {
                speed = {
                    speed_modifier = 0.5,
                    ticks_to_live = 3*60,
                    tick_started = game.tick,
                },
            })
        elseif effect_type == "tank" then
            effects.add_effect(arena, player, {
                tank = {
                    ticks_to_live = 3*60,
                    tick_started = game.tick,
                },
            })
        end

        -- TODO Handle other types

    end
end

return arena
