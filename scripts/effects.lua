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
    for effect_type, effect in pairs(player_state.effects) do
        local effect_constants = constants.effects[effect_type]

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
        elseif effect_type == "speed_up" then
            -- Increase vehicle speed and spurt flames
            vehicle.speed = vehicle.speed * effect.speed_modifier
            if game.tick % constants.effects.speed.fire_freq == 0 then
                surface.create_entity{
                    name = "fire-flame",
                    type = "fire",
                    position = player.position,
                }
            end
        ------------------------------------------------------------------------
        elseif effect_type == "tank" then
            -- Turn into tank and go slower
            if not timed_out then
                vehicle.speed = vehicle.speed * effect.speed_modifier
                if vehicle.name ~= "curvefever-tank" then
                    -- Haven't swapped vehicles yet. Do it now.
                    effects.swap_vehicle(player, "curvefever-tank")
                end
            else
                -- Timed out, swap back to normal vehicle
                effects.swap_vehicle(player, "curvefever-car")
            end
        ------------------------------------------------------------------------            
        elseif effect_type == "slow_down" then
            -- Throw down a slow-down sticker right on the player and go slow
            if not timed_out then
                vehicle.speed = vehicle.speed * effect.speed_modifier
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
        elseif effect_type == "no_trail" then
            -- Stops player from drawing trail behind him
            if not timed_out then                
                if player_state.effects["trail"] then
                    effects.remove_effect(arena, player, "trail")
                end
            else
                -- On time-out give the player the trail effect again
                effects.add_effect(arena, player, {
                    trail = {              
                        ticks_to_live = nil, -- Forever
                    },
                })
            end
        ------------------------------------------------------------------------
        elseif effect_type == "worm" then
            -- Stops player from drawing trail behind him
            if not timed_out then
                if effect.worm == nil then
                    -- Worm not spawned yet

                    -- First make sure player is far enough away
                    local buffer = 1
                    if (player.position.x > effect.position.x + buffer
                            or player.position.x < effect.position.x - buffer) and
                            (player.position.y > effect.position.y + buffer
                            or player.position.y < effect.position.y - buffer)
                    then
                        -- Player is far enough away
                        
                        -- Destroy all walls in that area
                        for _, wall in pairs(surface.find_entities_filtered{
                            area = {
                                {effect.position.x - buffer, effect.position.y - buffer},
                                {effect.position.x + buffer, effect.position.y + buffer}
                            },
                            name = "curvefever-trail"
                        }) do
                            wall.die()
                        end

                        -- Add worm
                        effect.worm = surface.create_entity{
                            name = "behemoth-worm-turret",                        
                            position = effect.position,
                        }
                        if effect.worm == nil then
                            error("Could not spawn worm on arena <"..arena.name.."> for player <"..player.name.."> at location <"..curvefever_util.to_string(player.position)..">")
                        end
                    end
                end
            else
                -- Timed out. Remove the worm
                if effect.worm and effect.worm.valid then
                    effect.worm.die()
                end
            end        
            ------------------------------------------------------------------------
        elseif effect_type == "biters" then
            -- Stops player from drawing trail behind him
            if not timed_out then
                if not effect.biters then effect.biters = { } end
                if #effect.biters < effect_constants.amount then
                    if curvefever_util.position_in_area(
                        player.position,
                        {
                            {
                                x=effect.position.x-effect_constants.spacing, 
                                y=effect.position.y-effect_constants.spacing
                            },
                            {
                                x=effect.position.x+effect_constants.spacing, 
                                y=effect.position.y+effect_constants.spacing
                            }
                        }
                    ) == false then
                        -- Far enough away. 
                        
                        -- Is there a wall in the way?
                        for _, wall in pairs(surface.find_entities_filtered{
                            area = {
                                {effect.position.x - 2, effect.position.y - 2},
                                {effect.position.x + 2, effect.position.y + 2}
                            },
                            name = "curvefever-trail"
                        }) do
                            wall.die()
                        end

                        -- Spawn biter
                        biter = surface.create_entity{
                            name = "behemoth-biter",                        
                            position = effect.position,
                        }
                        if biter == nil then                            
                            error("Could not spawn biter on arena <"..arena.name.."> for player <"..player.name.."> at location <"..curvefever_util.to_string(effect.position)..">")
                        else
                            -- Valid biter spawn!
                            
                            -- Find an player to attack
                            if #arena.players > 1 then
                                -- If you're the only player they will attack you! Haha!

                                -- TODO choose closest player!
                                local enemies = { }
                                for _, enemy in pairs(arena.players) do
                                    if enemy.index ~= player.index then
                                        table.insert(enemies, enemy)
                                    end
                                end
                                local enemy = enemies[math.random(#enemies)]
                                local command = {
                                    target= enemy, 
                                    type = defines.command.attack, 
                                    distraction = defines.distraction.none
                                }
                                biter.set_command(command)
                            end

                            biter.speed = constants.vehicle_speed   -- As fast as a normal vehicle
                            table.insert(effect.biters, biter)
                            effect.position = player.position
                        end
                    end
                end
            else
                for _, biter in pairs(effect.biters) do
                    biter.die()
                end
            end
        end
        ------------------------------------------------------------------------

        -- Did this effect time out?
        if timed_out then
            effects.remove_effect(arena, player, effect_type)
        end        
    end
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function effects.add_effect(arena, player, effects)
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(effects) do
        effect.position = player.position
        if player_state.effects[effect_type] then
            -- Player already has this effect applied. Extend time
            player_state.effects[effect_type].ticks_to_live = effect.ticks_to_live
            -- log("Extending <"..effect_type.."> effect on <"..player.name.."> in arena <"..arena.name)
        else
            -- Player does not currently have this effect applied. Add it
            effect.tick_started = game.tick
            player_state.effects[effect_type] = effect
            -- log("Adding <"..effect_type.."> effect on <"..player.name.."> to arena <"..arena.name)
        end
    end    
end

-- Removes a specific effect from a player if it's applied to him
function effects.remove_effect(arena, player, effect_type)
    local player_state = arena.player_states[player.index]
    if not player_state.effects[effect_type] then return end
    -- log("Removing <"..effect_type.."> effect from "..player.name.." in arena <"..arena.name.."> (total "..#player_state.effects..")")
    player_state.effects[effect_type] = nil    -- Delete
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
    -- log("Player "..player.name.." vechicle swopped from "..vehicle.name.." to "..vehicle_name)

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