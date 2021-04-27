local util = require("util")
local constants = require("scripts.constants")

local effects = { }
-- This file contains no state. Only handles some effects
-- This is an example of how effects look like minimally
-- {
--      "speed" = {
--          speed_modifier = 1,         -- This effect specific
--
--          ticks_to_live = 3*60,       -- Mandatory
--          tick_started = game.tick    -- Mandatory
--      },
-- }

-- Iterate through all effects currently on player and add them to the player
function effects.apply_effects(arena, player)    
    -- For every effect on this player
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(player_state.effects) do

        local character = player.character
        local surface = player.surface
        local vehicle = player.character.vehicle        

        -- Did this effect time out?
        local timed_out = false
        if game.tick > effect.tick_started + effect.ticks_to_live then
            -- Keep track of it effects can stop correctly. Only removed
            -- afterwards
            timed_out = true
        end

        if effect_type == "speed" then
            -- Increase the vehicle speed and spawn some flames
            vehicle.speed = vehicle.speed * (1 + effect.speed_modifier)
            if game.tick % constants.effects.speed.fire_freq == 0 then
                surface.create_entity{
                    name = "fire-flame",
                    type = "fire",
                    position = player.position,
                }
            end
            
        elseif effect_type == "tank" then
            -- Change to driving a tank instead of car
            
            if vehicle.name ~= "curvefever-tank" then
                -- Haven't swapped vehicles yet. Do it now.
                effects.swap_vehicle(player, "curvefever-tank")
            elseif timed_out then
                -- Timed out, swap back to normal vehicle
                effects.swap_vehicle(player, "curvefever-car")
            end
        end

        -- Did this effect time out?
        if timed_out then
            log("Removing "..effect_type.." from "..player.name.." in arena: "..arena.name)
            player_state.effects[effect_type] = nil    -- delete this entry in the effects table
        end

    end
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function effects.add_effect(arena, player, effects)
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(effects) do
        log("Adding "..effect_type.." to "..player.name.." in arena: "..arena.name)
        if player_state.effects[effect_type] then
            -- Player already has this effect applied. Extend the ticks_to_live
            effect.ticks_to_live = effect.ticks_to_live + player_state.effects[effect_type].ticks_to_live
        end
    
        -- Either way, overwrite the effect
        player_state.effects[effect_type] = util.copy(effect)
    end    
end

-- Removes all effects from a player
function effects.reset_effects(arena, player)
    local player_state = arena.player_states[player.index]
    player_state.effects = { }
end

-- Will remove the vehicle the player is currently driving,
-- spawn the new vehicle and continue driving seemlessly.
function effects.swap_vehicle(player, vehicle_name)
    local character = player.character
    local vehicle = character.vehicle
    if not vehicle then
        error("Player "..player.name.." isn't driving a vehicle to swap")
    end

    -- Saying we did it a little preemptively
    log("Player "..player.name.." vechicle swopped from "..vehicle.name.." to "..vehicle_name)

    -- Remember what the vehicle is doing now
    local speed = vehicle.speed
    local position = vehicle.position
    local orientation = vehicle.orientation
    local turning_direction = vehicle.riding_state.direction

    -- Get out of vehicle and destroy it
    character.driving = false
    vehicle.destroy{raise_destroy=false}

    -- Create new vehicle, bring it to speed and such
    -- and add character into it
    local surface = player.surface
    vehicle = surface.create_entity{
        name = vehicle_name,
        position = position,
        force = player.force,
        raise_built = false
    }
    if not vehicle then
        error("Creating new vehicle ("..vehicle_name..") during swop for player "..player.name)
    end
    vehicle.speed = speed
    vehicle.orientation = orientation
    vehicle.riding_state = {
        acceleration = 1,
        direction = turning_direction,
    }
    character.driving = true    -- TODO Does this mean he can get into someone elses car?
end

return effects