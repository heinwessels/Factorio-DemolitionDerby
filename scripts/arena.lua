local util = require("util")
local effects = require("scripts.effects")
local constants = require("scripts.constants")
local builder = require("scripts.arena-builder")

local arena = {
    name = "",
    
    area = { },
    surface = nil,
    builder = builder.create(),

    players = { },
    player_states = { },    
    effects = { },  -- Current effects scattered in arena

    -- Possible statusses
    -- empty        -> Only defined, not built or ready
    -- ready        -> Ready for a game to start (except importing players)
    -- playing      -> currently has a game running
    -- building     -> (Re)building map (done at creation or cleaning)
    status = "empty"
}

-- Set up a arena to be played at some point
-- area     of the arena
function arena.create(name, area, surface)
    arena.name = name
    arena.area = area
    arena.surface = surface
    arena.players = { }

    log("Created arena "..arena.name)
    
    -- Now build the arena
    arena.set_state(arena, "building")
    builder.start(arena)
end

function arena.clean(arena)
    arena.set_state(arena, "building")
    builder.start(arena)
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
        effects.add_effect(arena, player, {
            trail = {              
                ticks_to_live = nil, -- Forever
            },
        })
    end
    log("Started arena "..arena.name.." with "..#arena.players.." players")
    arena.set_state(arena, "playing")
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
function arena.update(arena)

    -- TODO check game. Is all the players still there?
    -- Stuff like that.
    if arena.state == "building" then
        builder.iterate(arena)
        if arena.builder.state == "idle" then
            arena.set_state(arena, "ready")
        end
    end

    if arena.state == "playing" then
        for _, player in pairs(arena.players) do
            if player.character then
                -- Update for a specific player
                
                local vehicle = player.character.vehicle  
                local player_state = arena.player_states[player.index]

                if player_state.status == "playing" and vehicle then

                    -- Ensure player is still driving
                    vehicle.speed = constants.vehicle_speed
                    -- TODO Ensure he is still in his car

                    -- Apply any effects
                    effects.apply_effects(arena, player)

                    -- TODO Update score.
                end
            end
        end
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
        if not vehicle then
            log("Could not find vehicle that triggered effect beacon.")
            return
        end
        player = vehicle.get_driver().player
        local effect_type = string.sub(beacon.name, 19, -1)
        
        -- Add the applicable effect
        if effect_type == "speed_up" then
            effects.add_effect(arena, player, {
                speed_up = {
                    speed_modifier = 1.8,
                    ticks_to_live = 3*60,
                },
            })
        elseif effect_type == "tank" then
            effects.add_effect(arena, player, {
                tank = {
                    speed_modifier = 0.55,
                    ticks_to_live = 3*60,
                },
            })
        elseif effect_type == "slow_down" then
            effects.add_effect(arena, player, {
                slow_down = {
                    speed_modifier = 0.55,
                    ticks_to_live = 3*60,
                },
            })
        elseif effect_type == "no_trail" then
            effects.add_effect(arena, player, {
                no_trail = {
                    ticks_to_live = 3*60,
                },                
            })
        end
    end
end

function arena.set_state(arena, state)
    log("Setting arena <"..arena.name.."> state to <"..state..">")
    arena.state = state
end

return arena
