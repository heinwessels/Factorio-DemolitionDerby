local util = require("util")
local curvefever_util = require("scripts.curvefever-util")
local constants = require("scripts.constants")

local Effects = { }
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
function Effects.apply_effects(arena, player)

    local surface = player.surface
    local character = player.character    

    -- For every effect on this player
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(player_state.effects) do
        local effect_constants = constants.effects[effect_type]

        -- Need to get the vehicle every iteration in case it's swopped
        local vehicle = player_state.vehicle
        if vehicle ~= player.character.vehicle then
            -- There's a mismatch in vehicles. Something went out of sync            
            error([[
                Vehicles out of sync for <]]..player.name..[[> in arena <]]..arena.name..[[>. 
                Expects a <]]..vehicle.name.." but is driving a <"..player.character.vehicle.name..[[>.
            ]])
        end

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
            if game.tick % effect_constants.period >= effect_constants.gap then
                local orientation = vehicle.orientation * 2 * math.pi
                local position = {
                    x = vehicle.position.x - effect_constants.offset*math.sin(orientation),
                    y = vehicle.position.y + effect_constants.offset*math.cos(orientation),
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
                    player_state.vehicle = Effects.swap_vehicle(player, "curvefever-tank")
                end
            else
                -- Timed out, swap back to normal vehicle
                player_state.vehicle = Effects.swap_vehicle(player, "curvefever-car")
            end
        ------------------------------------------------------------------------            
        elseif effect_type == "slow_down" then
            -- Throw down a slow-down sticker right on the player and go slow
            if not timed_out then
                vehicle.speed = vehicle.speed * effect.speed_modifier
                if not Effects.vehicle_has_sticker(vehicle, "slowdown-sticker") then
                    surface.create_entity{
                        name = "slowdown-sticker",
                        target = vehicle,
                        target_type = "position",
                        position = player.position,
                    }
                end
            else
                -- Remove the sticker when timed out
                Effects.vehicle_remove_sticker(vehicle, "slowdown-sticker")
            end
        ------------------------------------------------------------------------
        elseif effect_type == "no_trail" then
            -- Stops player from drawing trail behind him
            if not timed_out then                
                if player_state.effects["trail"] then
                    Effects.remove_effect(arena, player, "trail")
                end
            else
                -- On time-out give the player the trail effect again
                Effects.add_effect(arena, player, {
                    trail = {              
                        ticks_to_live = nil, -- Forever
                    },
                })
            end
        ------------------------------------------------------------------------
        elseif effect_type == "worm" then
            -- Stops player from drawing trail behind him
            if not timed_out then
                if not effect.worms_positions_to_spawn then
                    effect.worms_positions_to_spawn = { }
                end
                if not effect.worms then effect.worms = { } end
                if effect.extended == true or effect.fresh == true then
                    -- Should always add a worm if this is triggered.
                    -- Line it up here. We will spawn it in the next gap
                    table.insert(effect.worms_positions_to_spawn, effect.position)
                end
                
                -- First loop through existing worms and see if some should die
                -- (Only because there can be multiple)
                local did_something = false
                for index, worm_instance in pairs(effect.worms) do
                    if worm_instance.time + effect_constants.ticks_to_live
                            < game.tick then
                        -- We can delete destroy this worm
                        worm_instance.worm.die()
                        effect.worms[index] = nil
                    end
                end
                if did_something == true then
                    effect.worms = curvefever_util.compact_array(effect.worms)
                end

                -- Should we try and spawn a worm?
                did_something = false
                for index, position in pairs(effect.worms_positions_to_spawn) do
                    -- First make sure player is far enough away
                    local spacing = effect_constants.spacing
                    if curvefever_util.position_in_area(
                        player.position,
                        {
                            left_top = {x = position.x - 2*spacing, y= position.y - 2*spacing},
                            right_bottom = {x = position.x + 2*spacing, y= position.y + 2*spacing}
                        }
                    ) == false then
                        -- Player is far enough away
                        
                        -- Destroy all walls in that area
                        for _, wall in pairs(surface.find_entities_filtered{
                            area = {
                                {position.x - spacing, position.y - spacing},
                                {position.x + spacing, position.y + spacing}
                            },
                            name = "curvefever-trail"
                        }) do
                            wall.die()
                        end

                        -- Add worm
                        local worm = surface.create_entity{
                            name = "behemoth-worm-turret",                        
                            position = position,
                        }
                        if worm == nil then
                            error("Could not spawn worm on arena <"..arena.name.."> for player <"..player.name.."> at location <"..curvefever_util.to_string(player.position)..">")
                        else
                            -- Remember when we spawned this worm so that we can kill it at the correct time
                            table.insert(effect.worms,{
                                worm = worm,
                                time = game.tick
                            })

                            -- Now make sure we don't spawn a hord of worms!
                            effect.worms_positions_to_spawn[index]=nil
                            did_something = true
                        end
                    end
                end
                if did_something == true then
                    effect.worms_positions_to_spawn = 
                            curvefever_util.compact_array(effect.worms_positions_to_spawn)
                end
            else
                -- Worms should ideally be destoryed already by this point,
                -- but it might happen that it wasn't. Here we just make dsure 
                -- it's all cleaned up.
                for _, worm in pairs(effect.worms) do
                    if worm.valid then
                        worm.die()
                    end
                end
            end        
            ------------------------------------------------------------------------
        elseif effect_type == "biters" then
            -- Stops player from drawing trail behind him
            if not timed_out then
                if not effect.biters then effect.biters = { } end
                if not effect.max_biters then effect.max_biters = effect_constants.max_biters end
                if effect.extended == true then                    
                    effect.max_biters = effect.max_biters + effect_constants.max_biters
                end
                if not effect.last_spawn_time then effect.last_spawn_time = game.tick end
                if #effect.biters < effect.max_biters
                        and effect.last_spawn_time + effect_constants.period < game.tick then
                    -- Enough time has passed
                    effect.last_spawn_time = game.tick

                    -- Determine where to spawn biter
                    local orientation = vehicle.orientation * 2 * math.pi
                    local position = {
                        x = vehicle.position.x - effect_constants.offset*math.sin(orientation),
                        y = vehicle.position.y + effect_constants.offset*math.cos(orientation),
                    }
                                        
                    -- Is there a wall in the way? Destroy it!
                    for _, wall in pairs(surface.find_entities_filtered{
                        area = {
                            left_top =      {x=position.x - 3, y=position.y - 3},
                            right_bottom =  {x=position.x + 3, y=position.y + 3}
                        },
                        name = "curvefever-trail"
                    }) do                        
                        wall.die()
                    end

                    -- Spawn biter
                    biter = surface.create_entity{
                        name = "behemoth-biter",
                        position = position,
                    }
                    if biter == nil then                            
                        error("Could not spawn biter on arena <"..arena.name.."> for player <"..player.name.."> at location <"..curvefever_util.to_string(effect.position)..">")
                    else
                        -- Valid biter spawn!
                        
                        -- Find an player to attack
                        local enemy = nil
                        if #arena.players > 0 then
                            -- TODO Chooses closest player
                            enemy = Effects.find_random_enemy(arena, player)
                        end                        
                        if not enemy then enemy = player end -- If you're the only player they will attack you! Haha!
                        local command = {
                            target= enemy.character.vehicle, 
                            type = defines.command.attack, 
                            distraction = defines.distraction.none
                        }
                        biter.set_command(command)
                        biter.speed = constants.vehicle_speed * effect_constants.speed_modifier
                        table.insert(effect.biters, biter)
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
        effect.fresh = false
        effect.extended = false
        if timed_out then
            Effects.remove_effect(arena, player, effect_type)
        end        
    end
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function Effects.add_effect(arena, player, effects)
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(effects) do
        effect.position = player.position        
        if player_state.effects[effect_type] then
            -- Player already has this effect applied. Extend time            
            player_state.effects[effect_type].extended = true -- This will show an extension has been made
            player_state.effects[effect_type].position = effect.position
            player_state.effects[effect_type].ticks_to_live = player_state.effects[effect_type].ticks_to_live + effect.ticks_to_live
        else
            -- Player does not currently have this effect applied. Add it
            effect.tick_started = game.tick
            effect.extended = false
            effect.fresh = true
            player_state.effects[effect_type] = effect
            -- log("Adding <"..effect_type.."> effect on <"..player.name.."> to arena <"..arena.name)
        end
    end    
end

-- Removes a specific effect from a player if it's applied to him
function Effects.remove_effect(arena, player, effect_type)
    local player_state = arena.player_states[player.index]
    if not player_state.effects[effect_type] then return end
    -- log("Removing <"..effect_type.."> effect from "..player.name.." in arena <"..arena.name.."> (total "..#player_state.effects..")")
    player_state.effects[effect_type] = nil    -- Delete
end

-- Removes all effects from a player
function Effects.reset_effects(arena, player)
    local player_state = arena.player_states[player.index]
    player_state.effects = { }
end

-- Finds a random enemy in the arena that is not the player
function Effects.find_random_enemy(arena, player)
    local enemies = { }
    for _, enemy in pairs(arena.players) do
        local enemy_state = arena.player_states[enemy.index]
        if enemy_state.status == "playing" then
            if enemy ~= player then                                        
                table.insert(enemies, enemy)
            end
        end
    end
    if #enemies == 0 then return nil end
    if #enemies == 1 then return enemies[1] end
    return enemies[math.random(#enemies)]
end

-- Will remove the vehicle the player is currently driving,
-- spawn the new vehicle and continue driving seemlessly.
function Effects.swap_vehicle(player, vehicle_name)
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
    local acceleration = 0
    if speed > 0 then acceleration = 1 end
    vehicle.riding_state = {
        acceleration = 1,
        direction = turning_direction,
    }
    vehicle.set_driver(player)
    return vehicle
end

function Effects.vehicle_has_sticker(vehicle, sticker_name)
    if not vehicle.stickers then return false end
    for _, sticker in pairs(vehicle.stickers) do
        if sticker.name == sticker_name then
            return true
        end
    end
    return false
end

function Effects.vehicle_remove_sticker(vehicle, sticker_name)
    -- Fails silently
    if not vehicle.stickers then return end
    for index, sticker in pairs(vehicle.stickers) do
        if sticker.name == sticker_name then            
            sticker.destroy()
            return
        end
    end
end

return Effects