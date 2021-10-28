local util = require("scripts.wdd-util")
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

-- To simplify some designs the arena will take care
-- of some spawned entities. For example, after a biter was spawned
-- this function will ensure it dies on time
-- This function is likely NOT called every tick
function Effects.update_effect_entities(arena, tick)
    local entries = arena.effect_entity_entries
    local index = 1
    --for index, entry in pairs(entries) do
    while index <= arena.number_of_effect_entities do
        local entry = entries[index]
        local tick_to_die = entry.tick_to_die
        if tick_to_die and tick > tick_to_die then
            -- This entity should be destroyed or killed
            local entity = entry.entity
            if entity.valid then
                if entry.should_die then
                    entity.die()
                else
                    entity.destroy()
                end
            end

            -- Remove from this list
            util.array_remove_index_unordered(entries, index, arena.number_of_effect_entities)
            arena.number_of_effect_entities = arena.number_of_effect_entities - 1            

            -- Do not increment index, because now we need to process the entity we just moved
        else
            index = index + 1
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
    arena.effect_entity_entries = { }
end

-- If an entity is added to the effects using this function then
-- the arena will keep track of it and kill (or destroy) it at the
-- correct tick.
function Effects.add_effect_entity(arena, entity, tick_to_die, should_die)    
    arena.number_of_effect_entities = arena.number_of_effect_entities + 1
    arena.effect_entity_entries[arena.number_of_effect_entities] = {
        entity = entity,
        tick_to_die = tick_to_die,  -- nil if never
        should_die = should_die
    }
    if arena.number_of_effect_entities ~= #arena.effect_entity_entries then error("ALERT") end
end

-- Every function will be given
--      arena, player, effect, ctx
-- where ctx is a table that contains
--  ctx = {
--      player_state
--      timed_out,
--      tick,
--      effect_constants
--  }
local apply_effects_handler = {
    ["trail"] = function (arena, player, effect, ctx)
        -- Default drawing of trail behind player
        local effect_constants = ctx.effect_constants
        if ctx.tick % effect_constants.period >= effect_constants.gap then
            local vehicle = ctx.player_state.vehicle
            local orientation = vehicle.orientation * 2 * math.pi
            local position = {
                x = vehicle.position.x - effect_constants.offset*math.sin(orientation),
                y = vehicle.position.y + effect_constants.offset*math.cos(orientation),
            }
            local surface = arena.surface
            if not surface.find_entity("wdd-trail", position) then 
                surface.create_entity{
                    name = "wdd-trail",
                    type = "wall",
                    position = position,
                    create_build_effect_smoke = true,
                }
            end
        end
    end,
    ["speed_up"] = function (arena, player, effect, ctx)
        -- Increase vehicle speed and spurt flames
        local vehicle = ctx.player_state.vehicle
        local effect_constants = ctx.effect_constants
        vehicle.speed = vehicle.speed * effect.speed_modifier
        if ctx.tick % effect_constants.fire_freq == 0 then
            arena.surface.create_entity{
                name = "fire-flame",
                type = "fire",
                position = player.position,
            }
        end
    end,
    ["tank"] = function (arena, player, effect, ctx)
        -- Turn into tank and go slower
        if not ctx.timed_out then            
            local vehicle = ctx.player_state.vehicle
            vehicle.speed = vehicle.speed * effect.speed_modifier
            if not string.match(vehicle.name, "tank") then
                -- Haven't swapped vehicles yet. Do it now.
                ctx.player_state.vehicle = Effects.swap_vehicle(player, "wdd-tank")
            end
        else
            -- Timed out, swap back to normal vehicle
            ctx.player_state.vehicle = Effects.swap_vehicle(player, "wdd-car")
        end
    end,
    ["invert"] = function (arena, player, effect, ctx)
        -- Turn into tank and go slower
        local vehicle = ctx.player_state.vehicle
        if not ctx.timed_out then            
            if string.sub(vehicle.name, -8, -1) ~= "inverted" then
                -- Player isn't driving the inverted version
                ctx.player_state.vehicle = 
                        Effects.swap_vehicle(player, vehicle.name.."-inverted")
            end
        else
            -- Timed out, swap back to normal vehicle
            if string.sub(vehicle.name, -8, -1) == "inverted" then
                -- but only if it actually still have the inverted vehicle
                ctx.player_state.vehicle = 
                        Effects.swap_vehicle(player, string.sub(vehicle.name, 1, -10))
            end
        end
    end,
    ["slow_down"] = function (arena, player, effect, ctx)
        -- Throw down a slow-down sticker right on the player and go slow
        local vehicle = ctx.player_state.vehicle
        if not ctx.timed_out then
            vehicle.speed = vehicle.speed * effect.speed_modifier
            if not Effects.vehicle_has_sticker(vehicle, "slowdown-sticker") then
                arena.surface.create_entity{
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
    end,
    ["no_trail"] = function (arena, player, effect, ctx)
        -- Stops player from drawing trail behind him
        if effect.fresh then               
            if ctx.player_state.effects["trail"] then
                Effects.remove_effect(arena, player, "trail")
            end
        elseif ctx.timed_out then
            -- On time-out give the player the trail effect again
            Effects.add_effect(arena, player, {
                trail = {              
                    ticks_to_live = nil, -- Forever
                },
            })
        end
    end,
    ["full_trail"] = function (arena, player, effect, ctx)
        -- Draws a trail behind the player without any gaps
        if not ctx.timed_out then
            -- Make sure the trial effect is removed

            if effect.fresh then
                Effects.remove_effect(arena, player, "trail")                    
            end

            -- Now draw full trail
            local vehicle = ctx.player_state.vehicle
            local orientation = vehicle.orientation * 2 * math.pi
            local effect_constants = constants.effects.trail
            local position = {
                x = vehicle.position.x - effect_constants.offset*math.sin(orientation),
                y = vehicle.position.y + effect_constants.offset*math.cos(orientation),
            }
            local surface = arena.surface
            if not surface.find_entity("wdd-trail", position) then 
                surface.create_entity{
                    name = "wdd-trail",
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
    end,
    ["nuke"] = function (arena, player, effect, ctx)
        local tick = ctx.tick
        local effect_constants = ctx.effect_constants
        if effect.fresh then
            -- Find a target
            effect.target = util.random_position_in_area(
                util.area_grow(arena.area, -20) -- edge of blast should only reach border
            )

            -- Play siren sound
            for _, player in pairs(arena.players) do
                -- Play the sound at the location where the nuke is gonna drop
                player.play_sound{ path = "wdd-nuke", position = effect.target }
            end
        elseif tick > effect.tick_started + effect_constants.warm_up_time then
            -- Handle main functionality here
            
            -- Create flair
            local surface = arena.surface
            local flair = surface.create_entity{
                name = "nuke-flare", 
                position = effect.target, 
                height = 2,             -- Top of the fall
                vertical_speed = 0.01,  -- How fast does it fall
                frame_speed = 1,        -- Don't think this does anything 
                movement = {0, 0}
            }
            if flair then
                Effects.add_effect_entity(arena, flair, 
                    tick + effect_constants.shell_travel_time
                ) -- Should dissapear when shell hits
            end

            -- Create projectile
            local speed = 1
            local offset_target = {
                x = effect.target.x,
                y = effect.target.y - speed*effect_constants.shell_travel_time
            }
            local nuke = surface.create_entity{
                name = "atomic-rocket", 
                position = offset_target, 
                force = "enemy", 
                target = effect.target,
                speed = speed
            }
            if nuke then
                Effects.add_effect_entity(arena, nuke,
                    tick + effect_constants.shell_travel_time*2    -- By this time it should've hit anyway
                )
            end

            -- Remove this effect
            effect.mark_for_deletion = true
        end
    end,
    ["artillery"] = function (arena, player, effect, ctx)
        -- Artillery will rain from the sky!
        local tick = ctx.tick
        local effect_constants = ctx.effect_constants
        if not effect.last_shot_fired then
            -- We haven't fired the first shot yet. Can we?
            if tick > effect.tick_started + effect_constants.warm_up_time then
                -- We can start!
                effect.shots_left = util.size_of_area(arena.area) * effect_constants.coverage_density
                effect.last_shot_fired = 0  -- But we will do it next tick for simplicity
            end
        else
            -- Player drove through artillery again.
            if effect.extended == true then
                effect.shots_left = effect.shots_left
                        + util.size_of_area(arena.area) * effect_constants.coverage_density
            end

            local surface = arena.surface
            if tick > (effect.last_shot_fired + effect_constants.period) and effect.shots_left > 0 then

                -- Do the kaboom for everyone!
                -- We're going to shoot a couple of shots for every sound                    
                surface.play_sound{ path = "wdd-artillery-shoot" }

                local shots_fired_now = 0
                while effect.shots_left > 0 and shots_fired_now < effect_constants.shots_per_sound do
                    -- Fire a random shot!
                    local target = util.random_position_in_area(arena.area)
                    
                    -- First create a flair
                    -- It doesn't do anything. Only shows players where it will hit
                    local flair = surface.create_entity{
                        name = "artillery-flare", 
                        position = target, 
                        height = 2,             -- Top of the fall
                        vertical_speed = 0.01,  -- How fast does it fall
                        frame_speed = 1,        -- Don't think this does anything 
                        movement = {0, 0}
                    }
                    if flair then
                        Effects.add_effect_entity(arena, flair, 
                            tick + effect_constants.shell_travel_time*1.707
                        ) -- Should dissapear when shell hits
                    end

                    -- Create the artillery shell mid air!
                    local speed = 1
                    local offset_target = {
                        x = target.x - speed*effect_constants.shell_travel_time,
                        y = target.y - speed*effect_constants.shell_travel_time
                    }
                    local shell = surface.create_entity{
                        name = "artillery-projectile", 
                        position = offset_target, 
                        force = "enemy", 
                        target = target,
                        speed = speed
                    }
                    if shell then
                        Effects.add_effect_entity(arena, shell,
                            tick + effect_constants.shell_travel_time*2    -- By this time it should've hit anyway
                        )
                    end

                    -- Fire control
                    shots_fired_now = shots_fired_now + 1
                    effect.last_shot_fired = tick
                    effect.shots_left = effect.shots_left - 1
                end
            end
        end
    end,
    ["worm"] = function (arena, player, effect, ctx)
        -- Stops player from drawing trail behind him
        if not ctx.timed_out then
            if not effect.worms_positions_to_spawn then
                effect.worms_positions_to_spawn = { }
            end                
            if effect.extended == true or effect.fresh == true then
                -- Should always add a worm if this is triggered.
                -- Line it up here. We will spawn it in the next gap
                table.insert(effect.worms_positions_to_spawn, effect.position)
            end

            -- Should we try and spawn a worm?
            local effect_constants = ctx.effect_constants
            local surface = arena.surface
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
                        name = "wdd-trail"
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
                        Effects.add_effect_entity(arena, worm, ctx.tick + effect_constants.ticks_to_live, true)

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
    end,
    ["biters"] = function (arena, player, effect, ctx)
        -- Stops player from drawing trail behind him
        if not ctx.timed_out then
            local tick = ctx.tick
            local effect_constants = ctx.effect_constants
            if not effect.last_spawn_time then effect.last_spawn_time = tick end
            if effect.last_spawn_time + effect_constants.period < tick then
                -- Enough time has passed
                effect.last_spawn_time = tick

                -- Determine where to spawn biter
                local vehicle = ctx.player_state.vehicle
                local orientation = vehicle.orientation * 2 * math.pi
                local position = {
                    x = vehicle.position.x - effect_constants.offset*math.sin(orientation),
                    y = vehicle.position.y + effect_constants.offset*math.cos(orientation),
                }
                                    
                -- Is there a wall in the way? Destroy it!
                local surface = arena.surface
                for _, wall in pairs(surface.find_entities_filtered{
                    area = {
                        left_top =      {x=position.x - 3, y=position.y - 3},
                        right_bottom =  {x=position.x + 3, y=position.y + 3}
                    },
                    name = "wdd-trail"
                }) do                        
                    wall.die()
                end

                -- Spawn biter
                biter = surface.create_entity{
                    name = "wdd-biter",
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
                    biter.speed = constants.arena.vehicle_speed * effect_constants.speed_modifier
                    
                    Effects.add_effect_entity(arena, biter, tick + effect_constants.biter_life_ticks, true)
                end
            end
        end
    end,
}

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

        -- Apply the effect to the player using a special switch case handler
        local handler = apply_effects_handler[effect_type]
        if handler then handler(arena, player, effect, {
            player_state = player_state,
            effect_constants = effect_constants,
            tick = tick, 
            timed_out = timed_out
        }) end

        -- Did this effect time out?
        effect.fresh = false
        effect.extended = false
        if timed_out or effect.mark_for_deletion then
            Effects.remove_effect(arena, player, effect_type)
        end        
    end
end

-- A beacon is destroyed. If it was activated by a player it
-- would already have been handled
function Effects.on_entity_destroyed(arena, reg, unit_number)
    local beacon = arena.effect_beacons[reg]
    if beacon then
        -- This beacon was destroyed in our arena!

        -- Ignore it if this arena isn't playing though
        -- We're gonna clean the array before playing again 
        -- anyway
        if not arena.status == "playing" then return true end

        -- Remove the entry from our table
        arena.effect_beacons[reg] = nil
        arena.number_of_effect_beacons = 
                arena.number_of_effect_beacons - 1

        -- Return the fact that it was in our arena
        -- so that the world doesn't send it to
        -- other arenas
        return true
    end
    -- If it wasn't in this arena nil is returned, and the world
    -- will know to try the next arena
end

local effects_to_spawn = {
    "speed_up-player",
    "speed_up-enemy",
    "tank-player",
    "tank-enemy",
    "invert-player",
    "invert-enemy",
    "slow_down-player",
    "slow_down-enemy",
    "no_trail-player",
    "no_trail-enemy",
    "full_trail-player",
    "full_trail-enemy",
    "worm-player",
    "worm-enemy",
    "biters-player",
    "biters-enemy",
    "artillery-all",
    "nuke-all",
}
-- Here the effect beacons are updated. If there are less than the ideal number
-- then we add more. The length it cached, so it's easy to check.
-- It's known when an effect beacon was destroyed using the 
-- <register_on_entity_destroyed> function.
function Effects.update_effect_beacons(arena)
    if arena.number_of_effect_beacons < arena.ideal_number_of_effect_beacons then
        -- There are less beacons than we desire. More should be spawned

        -- Roll the dice and see if a new entity will be spawned
        if math.random(0, 
            math.ceil(constants.arena.effect_spawn_chance / constants.arena.frequency.effect_entity)
        ) == 0 then

            local type_to_spawn = effects_to_spawn[math.random(#effects_to_spawn)]
            local beacon = Effects.attempt_spawn_effect_beacon(
                arena, type_to_spawn
            )
            if beacon then
                -- We successfully created a placed a new entity!

                for _, player in pairs(arena.players) do 
                    player.play_sound{ path = "wdd-effect-created" }
                end

                -- Now register a callback so that we know when this beacon is destroyed
                -- Either by a player driving over it, or by some other means
                -- We receive an registration number. We will use this as key
                local reg = script.register_on_entity_destroyed(beacon)

                -- Add it to the table of effect beacons            
                arena.number_of_effect_beacons = arena.number_of_effect_beacons + 1
                arena.effect_beacons[reg] = beacon
            end
            
        end
    end
end

-- Will attempt to spawn an effect beacon at a location
-- Should always work though.
-- Returns a reference to the beacon entity or nill
function Effects.attempt_spawn_effect_beacon(arena, beacon_name)
    local surface = arena.surface
    local spacing = 5   -- How far from the edges may we spawn things?
    for try = 1,10 do
        local beacon = surface.create_entity{
            name = "wdd-effect-"..beacon_name,
            position = util.random_position_in_area({
                left_top = {x=arena.area.left_top.x+spacing, y=arena.area.left_top.y+spacing},
                right_bottom = {x=arena.area.right_bottom.x-spacing, y=arena.area.right_bottom.y-spacing}
            }),
            force = "enemy" -- We need it to explode when player touches it
        }
        if beacon then return beacon end
    end
    return nil
end

-- This handler should be called if any effect beacon
-- is hit. This function will decide if it's part of this
-- arena, and apply it
-- Note: This does not clean up (or even touch) the cache
-- of effect beacons. That's handled afterwards by the
-- <on_entity_destroyed> event.
function Effects.hit_effect_event(arena, beacon)
    local surface = beacon.surface
    
    local vehicle_in_range = surface.find_entities_filtered{
        position = beacon.position,
        radius = 6,
        type = "car",
        limit = 1, -- TODO HANDLE MORE!
    }
    local player = nil
    if not vehicle_in_range then error("No vehicle found to apply effect to!") end
    local vehicle = vehicle_in_range[1]
    if not vehicle then return end  -- This beacon was likely destroyed by non-player
    local driver = vehicle.get_driver()
    if not driver then return end   -- Just silently ignore if something goes wrong
    player = vehicle.get_driver().player
    
    -- Unpack effect beacon
    local last_dash = util.string_find_last(beacon.name, "-")
    local effect_type = string.sub(beacon.name, 12, last_dash-1)
    local target_str = string.sub(beacon.name, last_dash+1, -1)
    local target = nil
    if target_str == "enemy" then   -- Who should this effect be applied to?
        target = Effects.find_random_enemy(arena, player) or player
    else
        -- This is either "player" or "all"
        -- It it's all it simply means who will do the execution
        target = player
    end
    
    -- Add the applicable effect
    effect = constants.effects[effect_type]
    if not effect then error("Effect of type <"..effect_type.."> not recognised") end
    Effects.add_effect(arena, target, {[effect_type]=effect}, target_str)
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function Effects.add_effect(arena, player, effects, source)

    -- Play a ping for all player that it's applied to    
    player.play_sound{ path = "wdd-effect-activate" }
    
    local player_state = arena.player_states[player.index]
    for effect_type, effect_to_apply in pairs(effects) do

        -- Deepcopy for no weird shenanigans!
        -- Otherwise when extending will change constants :/
        local effect = util.deepcopy(effect_to_apply)

        -- Add this effect to player
        effect.position = player.position
        effect.source = source or "player"  -- if none is supplied assume player
        local player_effect = player_state.effects[effect_type]
        if player_effect and player_effect.ticks_to_live then
            -- Player already has this effect applied. Extend time            
            player_effect.extended = true -- This will show an extension has been made
            player_effect.position = effect.position
            player_effect.ticks_to_live = player_effect.ticks_to_live + effect.ticks_to_live
        else
            -- Player does not currently have this effect applied. Add it
            effect.tick_started = game.tick
            effect.extended = false
            effect.fresh = true
            player_state.effects[effect_type] = effect
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
    if not vehicle then return nil end

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