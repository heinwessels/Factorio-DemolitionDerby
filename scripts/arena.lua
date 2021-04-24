local util = require("util")
local effects = require("scripts.effects")
local constants = require("scripts.constants")

local arena = { 
    area = { },
    players = { },
    player_states = { },    
    effects = { },  -- Current effects scattered in arena

    state = "empty"
}

-- Set up a arena to be played at some point
-- area     of the arena
function arena.create(area)
    arena.area = area
    arena.state = "created"
end

-- Start a game in a arena with players
-- players to join in this game (array)
function arena.init(players)
    arena.players = players

    -- TODO Teleport players to starting locations
    -- Reset scores

    -- Setup all the player
    for _, player in pairs(arena.players) do
        arena.create_player_state(arena, player)

        -- Teleport to position with correct vehicle
    end

    arena.state = "init"
end

-- Start the game for this arena
function arena.start()
    for _, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]
        player_state.status = "playing"
    end
end

function arena.create_player_state(arena, player)
    arena.player_states[player.index] = {
        effects = { },  -- What effects are applied to this player?
        score = { },    -- Score of this player"
        status = "idle" -- nothing has been done to this player
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

            -- TODO is this player still active?
            if player_state.status == "playing" and vehicle then

                -- Ensure he is still driving            
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
    local surface = player.surface
    local vehicle = player.character.vehicle
    local orientation = vehicle.orientation * 2 * math.pi
    local position = {
        x = vehicle.position.x - constants.trail_delay*math.sin(orientation),
        y = vehicle.position.y + constants.trail_delay*math.cos(orientation),
    }
    if not surface.find_entity("curve-trail", position) then 
        surface.create_entity{
            name = "curve-trail",
            type = "wall",
            position = position,
            create_build_effect_smoke = true,
        }
        return position
    end    
end


-- This handler should be called if any effect beacon
-- is hit. This function will decide if it's part of this
-- arena, and apply it
function arena.hit_effect_event(event)
    local surface = game.get_surface(event.surface_index)
    local entity = event.source_entity
    local vehicle_in_range = surface.find_entities_filtered{
        position = entity.position,
        radius = 6,
        name = "car",
        type = "car",
        limit = 1, -- TODO HANDLE MORE!
    }
    local player = nil
    if vehicle_in_range then 
        player = vehicle_in_range[1].last_user  -- TODO is this good enough?
        
        -- Add the applicable effect
        effects.add_effect(arena, player, {
            speed = {
                speed_modifier = 0.5,
                ticks_to_live = 3*60,
                tick_started = game.tick,
            },
        })

        -- TODO Handle other types

    end
end

return arena
