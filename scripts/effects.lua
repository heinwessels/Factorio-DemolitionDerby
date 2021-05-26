local util = require("scripts.curvefever-util")
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

-- Manages beacons. Is there enough? Can I spawn another one?
function Effects.update_effect_beacons(arena)
    if #arena.effect_beacons < arena.ideal_number_of_effect_beacons then
        -- TODO Populate this automatically with weights
        local effects_to_spawn = {
            -- "speed_up-player",
            -- "speed_up-enemy",
            -- "tank-player",
            -- "tank-enemy",
            -- "slow_down-player",
            -- "slow_down-enemy",
            -- "no_trail-player",
            -- "no_trail-enemy",
            -- "full_trail-player",
            -- "full_trail-enemy",
            -- "worm-player",
            "worm-enemy",
            -- "biters-player",
            -- "biters-enemy",
        }
        Effects.attempt_spawn_effect_beacon(
            arena,
            effects_to_spawn[math.random(#effects_to_spawn)]
        )
    else
        -- The array is full. Make sure everything is still valid
        local did_something = false
        for index, effect in pairs(arena.effect_beacons) do
            if not effect.valid then
                did_someting = true
                arena.effect_beacons[index]=nil
            end
        end
        if did_something == true then
            arena.effect_beacons = util.compact_array(arena.effect_beacons)
        end
    end
end

-- Will attempt to spawn an effect beacon at a location
-- Should always work though.
-- Returns a reference to the beacon entity or nill
function Effects.attempt_spawn_effect_beacon(arena, beacon_name)
    local surface = arena.surface
    local spacing = 5
    for try = 1,10 do
        local beacon = surface.create_entity{
            name = "curvefever-effect-"..beacon_name,
            position = {
                x=math.random(arena.area.left_top.x+spacing, arena.area.right_bottom.x-spacing),
                y=math.random(arena.area.left_top.y+spacing, arena.area.right_bottom.y-spacing)
            },            
            force = "enemy" -- We need it to explode when player touches it
        }
        if beacon then
            table.insert(arena.effect_beacons, beacon)
            -- Effects.log(arena, "In arena <"..arena.name.."> created effect beacon <"..beacon_name..">. (Total of "..#arena.effect_beacons..")")
            return beacon
        end
    end
    return nil
end

-- To simplify some designs the arena will take care
-- of some spawned entities. For example, after a biter was spawned
-- this function will ensure it dies on time
-- This function is likely NOT called every tick
function Effects.update_effect_entities(arena, tick)
    local entries = arena.effect_entity_entries
    local number_of_entries = arena.number_of_effect_entities
    for index, entry in pairs(entries) do
        local tick_to_die = entry.tick_to_die
        if tick_to_die and tick > tick_to_die then
            -- This entity should be destroyed or killed
            local entity = entry.entity
            if entry.tick_to_die then
                entity.die()
            else
                entity.destroy()
            end

            -- Remove from this list
            util.array_remove_index_unordered(entries, index, number_of_entries)
            arena.number_of_effect_entities = number_of_entries - 1
        end
    end
end

-- This will make sure that all entities that the arena
-- is taking cared off is killed or destroyed
function Effects.flush_effect_entities(arena)
    local entries = arena.effect_entity_entries
    for index, entry in pairs(entries) do
        local entity = entry.entity
        if entity.valid then
            if entry.should_die then
                entity.die()
            else
                entity.destroy()
            end
        end
    end
    arena.number_of_effect_entities = 0
    entries = { }
end

-- If an entity is added to the effects using this function then
-- the arena will keep track of it and kill (or destroy) it at the
-- correct tick.
function Effects.add_effect_entity(arena, entity, tick_to_die, should_die)
    local number_of_effect_entities = arena.number_of_effect_entities
    arena.number_of_effect_entities = number_of_effect_entities + 1
    arena.effect_entity_entries[arena.number_of_effect_entities] = {
        entity = entity,
        tick_to_die = tick_to_die,  -- nil if never
        should_die = should_die
    }
end

-- Iterate through all effects currently on player and add them to the player
function Effects.apply_effects(arena, player)

    local tick = game.tick
    local surface = player.surface
    local character = player.character    

    -- For every effect on this player
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(player_state.effects) do
        local effect_constants = constants.effects[effect_type]

        -- Need to get the vehicle every iteration in case it's swopped
        local vehicle = player_state.vehicle

        -- Did this effect time out?
        local timed_out = false
        if effect.ticks_to_live and tick > effect.tick_started + effect.ticks_to_live then
            -- Keep track of it effects can stop correctly. Only removed
            -- afterwards
            timed_out = true
        end

        -- Apply the effects
        ------------------------------------------------------------------------
        if effect_type == "trail" then
            -- Default drawing of trail behind player
            if tick % effect_constants.period >= effect_constants.gap then
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
            if tick % constants.effects.speed.fire_freq == 0 then
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
        elseif effect_type == "full_trail" then
            -- Draws a trail behind the player without any gaps
            if not timed_out then                

                -- Make sure the trial effect is removed
                if player_state.effects["trail"] then
                    Effects.remove_effect(arena, player, "trail")                    
                end

                -- Now draw full trail
                local orientation = vehicle.orientation * 2 * math.pi
                local trail_constants = constants.effects.trail
                local position = {
                    x = vehicle.position.x - trail_constants.offset*math.sin(orientation),
                    y = vehicle.position.y + trail_constants.offset*math.cos(orientation),
                }
                if not surface.find_entity("curvefever-trail", position) then 
                    surface.create_entity{
                        name = "curvefever-trail",
                        type = "wall",
                        position = position,
                        create_build_effect_smoke = true,
                    }
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
                if effect.extended == true or effect.fresh == true then
                    -- Should always add a worm if this is triggered.
                    -- Line it up here. We will spawn it in the next gap
                    table.insert(effect.worms_positions_to_spawn, effect.position)
                end

                -- Should we try and spawn a worm?
                local did_something = false -- If we spawned a worm
                for index, position in pairs(effect.worms_positions_to_spawn) do
                    -- First make sure player is far enough away
                    local spacing = effect_constants.spacing
                    if util.position_in_area(
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
                            error("Could not spawn worm on arena <"..arena.name.."> for player <"..player.name.."> at location <"..util.to_string(player.position)..">")
                        else
                            -- Remember when we spawned this worm so that we can kill it at the correct time
                            Effects.add_effect_entity(arena, worm, tick + effect_constants.ticks_to_live, true)

                            -- Now make sure we don't spawn a hord of worms!
                            effect.worms_positions_to_spawn[index]=nil
                            did_something = true
                        end
                    end
                end
                if did_something == true then
                    effect.worms_positions_to_spawn = 
                            util.compact_array(effect.worms_positions_to_spawn)
                end
            end        
            ------------------------------------------------------------------------
        elseif effect_type == "biters" then
            -- Stops player from drawing trail behind him
            if not timed_out then
                if not effect.last_spawn_time then effect.last_spawn_time = tick end
                if effect.last_spawn_time + effect_constants.period < tick then
                    -- Enough time has passed
                    effect.last_spawn_time = tick

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
                        name = "weasel-biter",
                        position = position,
                    }
                    if biter == nil then                            
                        error("Could not spawn biter on arena <"..arena.name.."> for player <"..player.name.."> at location <"..util.to_string(effect.position)..">")
                    else
                        -- Valid biter spawn!
                        
                        -- Point him in the direction of the vechile
                        biter.orientation = vehicle.orientation 

                        -- Find an player to attack
                        local enemy = Effects.find_random_enemy(arena, player)
                        if not enemy then enemy = player end -- If you're the only player they will attack you! Haha!
                        local command = {
                            target= enemy.character.vehicle, 
                            type = defines.command.attack, 
                            distraction = defines.distraction.none
                        }
                        biter.set_command(command)
                        biter.speed = constants.vehicle_speed * effect_constants.speed_modifier
                        
                        Effects.add_effect_entity(arena, biter, tick + effect_constants.biter_life_ticks, true)
                    end
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

-- This handler should be called if any effect beacon
-- is hit. This function will decide if it's part of this
-- arena, and apply it
function Effects.hit_effect_event(arena, beacon)
    local surface = beacon.surface
    
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
            Effects.log(arena, "Could not find vehicle that triggered effect beacon.")
            return
        end
        player = vehicle.get_driver().player
        local last_dash = util.string_find_last(beacon.name, "-")
        local effect_type = string.sub(beacon.name, 19, last_dash-1)
        local target_str = string.sub(beacon.name, last_dash+1, -1)
        if target_str == "enemy" then
            target = Effects.find_random_enemy(arena, player) or player
        else
            target = player
        end
        
        -- Add the applicable effect
        if effect_type == "speed_up" then
            Effects.add_effect(arena, target, {
                speed_up = {
                    speed_modifier = 1.8,
                    ticks_to_live = 4*60,
                },
            })
        elseif effect_type == "tank" then
            Effects.add_effect(arena, target, {
                tank = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "slow_down" then
            Effects.add_effect(arena, target, {
                slow_down = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "no_trail" then
            Effects.add_effect(arena, target, {
                no_trail = {
                    ticks_to_live = 5*60,
                },                
            })
        elseif effect_type == "full_trail" then
            Effects.add_effect(arena, target, {
                full_trail = {
                    ticks_to_live = 5*60,
                },                
            })
        elseif effect_type == "worm" then
            local effect_constants = constants.effects[effect_type]
            Effects.add_effect(arena, target, {
                worm = {
                    ticks_to_live = effect_constants.ticks_to_live,
                },                
            })
        elseif effect_type == "biters" then
            local effect_constants = constants.effects[effect_type]
            Effects.add_effect(arena, target, {
                biters = {
                    ticks_to_live = effect_constants.ticks_to_live,
                },
                no_trail = {
                    ticks_to_live = effect_constants.ticks_to_live
                },
            })
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
            -- Effects.log(arena, "Adding <"..effect_type.."> effect on <"..player.name.."> to arena <"..arena.name)
        end
    end    
end

-- Removes a specific effect from a player if it's applied to him
function Effects.remove_effect(arena, player, effect_type)
    local player_state = arena.player_states[player.index]
    if not player_state.effects[effect_type] then return end
    -- Effects.log(arena, "Removing <"..effect_type.."> effect from "..player.name.." in arena <"..arena.name.."> (total "..#player_state.effects..")")
    player_state.effects[effect_type] = nil    -- Delete
end

-- Removes all effects from a player
function Effects.reset_effects(arena, player)
    local player_state = arena.player_states[player.index]
    player_state.effects = { }
end

-- Finds a random enemy in the arena that is not the player
-- If there's no other players the it will return nil
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

function Effects.log(arena, msg)
    log("Arena Effects <"..arena.name..">: "..msg)
end

return Effects