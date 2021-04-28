local util = require("util")
local curvefever_util = require("scripts.curvefever-util")
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

    local surface = player.surface
    local character = player.character    

    -- For every effect on this player
    local player_state = arena.player_states[player.index]
    for effect_index, effect in pairs(player_state.effects) do
        if effect then
            local effect_type = effect.type

            -- Need to get the vehicle every iteration in case it's swopped
            local vehicle = player.character.vehicle

            -- Did this effect time out?
            local timed_out = false
            if effect.ticks_to_live and game.tick > effect.tick_started + effect.ticks_to_live then
                -- Keep track of it effects can stop correctly. Only removed
                -- afterwards
                timed_out = true
            end

            -- Apply the effects
            ------------------------------------------------------------------------
            if effect_type == "trail" then
                -- Default drawing of trail behind player
                if game.tick % constants.trail.period >= constants.trail.gap then
                    local orientation = vehicle.orientation * 2 * math.pi
                    local position = {
                        x = vehicle.position.x - constants.trail.offset*math.sin(orientation),
                        y = vehicle.position.y + constants.trail.offset*math.cos(orientation),
                    }
                    if not surface.find_entity("curvefever-trail", position) then 
                        surface.create_entity{
                            name = "curvefever-trail",
                            type = "wall",
                            position = position,
                            create_build_effect_smoke = true,
                        }
                    end
                end
            ------------------------------------------------------------------------
            elseif effect_type == "speed" then
                -- Modifies the vehicle speed 
                vehicle.speed = vehicle.speed * effect.speed_modifier
            ------------------------------------------------------------------------
            elseif effect_type == "tank" then
                -- Change to driving a tank instead of car            
                if vehicle.name ~= "curvefever-tank" then
                    -- Haven't swapped vehicles yet. Do it now.
                    effects.swap_vehicle(player, "curvefever-tank")
                elseif timed_out then
                    -- Timed out, swap back to normal vehicle
                    effects.swap_vehicle(player, "curvefever-car")
                end
            ------------------------------------------------------------------------
            elseif effect_type == "fire" then
                -- Throw down a slow-down sticker right on the player
                if game.tick % constants.effects.speed.fire_freq == 0 then
                    surface.create_entity{
                        name = "fire-flame",
                        type = "fire",
                        position = player.position,
                    }
                end
            ------------------------------------------------------------------------
            elseif effect_type == "slowdown" then
                -- Throw down a slow-down sticker right on the player
                if not timed_out then
                    if not effects.vehicle_has_sticker(vehicle, "slowdown-sticker") then
                        surface.create_entity{
                            name = "slowdown-sticker",
                            target = vehicle,
                            target_type = "position",
                            position = player.position,
                        }
                    end
                else
                    -- Remove the sticker when timed out
                    effects.vehicle_remove_sticker(vehicle, "slowdown-sticker")
                end
            ------------------------------------------------------------------------
            elseif effect_type == "no-trail" then
                -- Stops player from drawing trail behind him
                if not timed_out then
                    local trail_effect_index = effects.has_effect(arena, player, "trail")
                    if trail_effect_index then
                        log("Removing trail effect from "..player.name.." in arena "..arena.name.." (total "..#player_state.effects..")")
                        player_state.effects[trail_effect_index] = nil    -- Delete (remember to compact array afterwards)
                    end
                else
                    -- On time-out give the player the trail effect again
                    effects.add_effect(arena, player, {
                        {
                            type = "trail",                
                            ticks_to_live = nil, -- Forever
                        },
                    })
                end
            end
            ------------------------------------------------------------------------

            -- Did this effect time out?
            if timed_out then
                log("Removing "..effect_type.." effect from "..player.name.." in arena "..arena.name.." (total "..#player_state.effects..")")
                player_state.effects[effect_index] = nil    -- Delete (remember to compact array afterwards)
            end
        end        
    end

    -- Remove possible nils from effects array
    curvefever_util.compact_array(player_state.effects)
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function effects.add_effect(arena, player, effects)
    local player_state = arena.player_states[player.index]
    for _, effect in pairs(effects) do
        local effect_type = effect.type
        effect.tick_started = game.tick        
        table.insert(player_state.effects, util.copy(effect))
        log("Adding "..effect_type.." effect to "..player.name.." in arena "..arena.name.." (total "..#player_state.effects..")")
    end    
end

-- Checks if a player has some instance of a effect type
-- and returns the index of that effect
function effects.has_effect(arena, player, effect_type)
    local player_state = arena.player_states[player.index]
    for index, effect in pairs(player_state.effects) do
        if effect.type == effect_type then
            return index
        end
    end
    return nil
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
        raise_built = false,
        create_build_effect_smoke = true,
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

function effects.vehicle_has_sticker(vehicle, sticker_name)
    if not vehicle.stickers then return false end
    for _, sticker in pairs(vehicle.stickers) do
        if sticker.name == sticker_name then
            return true
        end
    end
    return false
end

function effects.vehicle_remove_sticker(vehicle, sticker_name)
    -- Fails silently
    if not vehicle.stickers then return end
    for index, sticker in pairs(vehicle.stickers) do
        if sticker.name == sticker_name then            
            sticker.destroy()
            return
        end
    end
end

return effects