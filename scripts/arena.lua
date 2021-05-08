local util = require("util")
local Effects = require("scripts.effects")
local constants = require("scripts.constants")
local Builder = require("scripts.builder")
local curvefever_util = require("scripts.curvefever-util")

local Arena = { }

-- Set up a arena to be played at some point
-- area     of the arena
function Arena.create(arena)
    if type(arena.surface) == "string" then
        arena.surface = game.surfaces[arena.surface]
    end
    arena = util.merge{
        {
            name = name,        
            surface = surface,
            area = area,
            starting_positions = nil,   -- Each location includes a third entry orientation
            ideal_number_of_effect_beacons = curvefever_util.size_of_area(arena.area) * constants.arena.effect_density,
            effect_beacons = { },   -- Array of all effect beacons part of this arena (array of references)
            builder = Builder.create(),
            
            lobby = nil,    -- (Optional) keep reference of lobby that added players. Not required

            max_players = 6,    -- Default
            players = { },
            player_states = { },    
            effects = { },  -- Current effects scattered in arena
            
            vehicles = { }, -- Vehicles in starting locations. As soon as a
                            -- game starts this goes to { } and each player's
                            -- vehicle is stored in his player_state
        
            -- Possible statusses
            -- empty        -> Only defined, not built or ready
            -- ready        -> Ready for players to be added to game
            -- playing      -> Currently playing a round
            -- post-wait    -> After the round there will be a second of something.
            -- done         -> Done playing. Waiting for something to happen before clean
            -- building     -> (Re)building map (done at creation or cleaning)
            status = "empty",

            -- Remembers some information about this round
            round = {
                tick_started = 0,       -- The tick when this round started
                tick_ended = 0,       -- The tick when this round started
                players_alive = 0,      -- Keep track of how many players alive while playing                
            }
        },
        arena
    }
    
    -- Create some starting locations if none was given
    if not arena.starting_positions or #arena.starting_positions==0 then
        arena.starting_locations = Arena.create_default_starting_locations(arena)
    end

    -- Now build the arena
    Arena.set_status(arena, "building")
    Builder.start(arena)
    
    -- Created!
    log("Created arena <"..arena.name.."> with area <"..curvefever_util.to_string(arena.area)..">")
    return arena
end

-- Clean up so that we can play another game
function Arena.clean(arena)
    Arena.set_status(arena, "building")  

    -- Remove all players from the arena
    local position = global.world.spawn_location
    if arena.lobby then
        position = arena.lobby.spawn_location
    end
    local surface = arena.surface
    for _, player in pairs(arena.players) do

        if player.character and player.character.vehicle then
            -- If player was in a car get him out
            player.character.driving = false
        end

        if not player.character then
            -- Player was spectating and don't have a character
            -- Give his body back
            curvefever_util.player_from_spectator(player)
        end

        -- Move him back to spawn
        curvefever_util.teleport_safe(player, position)
    end

    -- Clear the state
    arena.effect_beacons = { } -- Builder will destroy them anyway
    arena.player_states = { }
    arena.players = { }

    -- Rebuild the arena      
    Builder.start(arena)
end

-- Delete everything
function Arena.reset(arena)
    arena = nil
end

-- Add player to arena to be played
-- This will teleport them into the vehicles
function Arena.add_player(arena, player)
    if arena.status ~= "ready" then
        error("Can only add players to arena when it's ready or accepting. Arena <"..arena.name..">'s status is <"..arena.status..">")
    end
    
    -- Check if this player was already added
    if arena.player_states[player.index] then
        log("Cannot add player "..player.name.." to arena "..arena.name.." again (Total: "..#arena.players..")")
        return
    end
    
    -- Add player to arena
    table.insert(arena.players, player)
    Arena.create_player_state(arena, player)

    -- Teleport player into his vehicle
    player.character.driving = false    -- Get the guy out of his car
    local vehicle = arena.vehicles[#arena.players]
    player.teleport(vehicle.position)
    vehicle.set_driver(player)

    -- TODO Create handles for destroying of vehicles

    log("Added player "..player.name.." to arena "..arena.name.." (Total: "..#arena.players..")")
end

-- Start the game for this arena
-- Players need to be in the arena in the cars already.
-- TODO Let arena start do it rather. More robust.
-- This will do some checks.
-- <lobby> can be nil, but if it's there <arena> will remember
-- and then teleport players back to the lobby instead of spawn
function Arena.start_round(arena, lobby)
    if arena.status ~= "ready" then
        log("Cannot start arena <"..arena.name.."> since it's not ready (status = "..arena.status..")")
    end

    if #arena.players == 0 then
        log("Cannot start arena <"..arena.name.."> since it has no players")
    end

    -- Setup and update some variables
    arena.ideal_number_of_effect_beacons = curvefever_util.size_of_area(arena.area) * constants.arena.effect_density
    arena.lobby = lobby

    -- Setup players
    for index, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]
        player_state.status = "playing"
        Effects.add_effect(arena, player, {
            trail = {              
                ticks_to_live = nil, -- Forever
            },
        })

        -- Make sure player is in the correct force
        player.force = "player"

        -- Give them a real car (and not a static one)
        -- And store it in the state! We will remove
        player_state.vehicle = Effects.swap_vehicle(
            player,
            "curvefever-car"
        )
    end

    -- Remove unused vehicles that's left
    local surface = arena.surface
    for _, vehicle in pairs(arena.vehicles) do
        if vehicle and vehicle.valid and not vehicle.get_driver() then
            vehicle.destroy()
        end
    end

    -- Remove any references to the vehicles in the arena. Now we store them
    -- In the player state
    arena.vehicles = { }

    log("Started arena <"..arena.name.."> with "..#arena.players.." players")
    Arena.set_status(arena, "playing")    
    arena.round.tick_started = game.tick
    arena.round.tick_ended = 0
    arena.round.players_alive = #arena.players
end

function Arena.create_player_state(arena, player)
    arena.player_states[player.index] = {
        effects = { },      -- What effects are applied to this player?
        score = { },        -- Score of this player"
        status = "idle",    -- nothing has been done to this player
        player = player,    -- Reference to connected player
        vehicle = nil,      -- Reference to players vehicle while playing
    }
end

-- Call this function every tick
function Arena.update(arena)

    ---------------------------------------------------
    if arena.status == "building" then
        Builder.iterate(arena)
        if arena.builder.state == "idle" then
            -- It's done building
            Arena.set_status(arena, "ready")

            -- There's new vehicles. Get references to it
            arena.vehicles = arena.surface.find_entities_filtered{
                name = "curvefever-car-static", --It's static until the game begins
                area = arena.area   -- This is quite a large area
            }
        end    

    ---------------------------------------------------
    elseif arena.status == "playing" then

        -- Add more effect beacons if required
        Arena.update_effect_beacons(arena)
        
        -- Update player specific things
        arena.round.players_alive = 0   -- Will count the amount now
        local player_alive = nil
        for _, player in pairs(arena.players) do
            if player.character then
                -- Update for a specific player
                
                local vehicle = player.character.vehicle  
                local player_state = arena.player_states[player.index]

                if player_state.status == "playing" or player_state.status == "lost" and vehicle then
                    
                    if player_state.status == "playing" then
                        -- This player is still playing
                        arena.round.players_alive = arena.round.players_alive + 1
                        player_alive = player -- If round end, this will contain the victor
                        
                        -- Force player to always be moving
                        vehicle.speed = constants.vehicle_speed
                    end

                    -- Apply any effects
                    -- This should happen even if the player has 
                    -- lost, so that his effects can timeout correctly
                    -- (Like the bugs)
                    Effects.apply_effects(arena, player)
                end
            end
        end

        -- Check if the round is over, etc.
        local should_end = false
        if constants.single_player == true and arena.round.players_alive == 0 then
            should_end = true
        elseif constants.single_player == false and arena.round.players_alive <= 1 then
            should_end = true
        end
        if should_end then
            -- The game is over!
            arena.round.tick_ended = game.tick
            if not player_alive then player_alive={name = "<NO PLAYER>"} end    -- TODO Hacky
            log("Round over at <"..arena.name.."> after "..(arena.round.tick_ended-arena.round.tick_started).." ticks. <"..player_alive.name.."> was the victor!")
            game.print("On Arena "..arena.name.." - after "..(arena.round.tick_ended-arena.round.tick_started).." ticks -"..player_alive.name.." emerged victorious!")

            -- TODO Show some victory thing
            -- TODO Show score!
            -- TODO Play nice sound

            Arena.set_status(arena, "post-wait")
        end
    ---------------------------------------------------
    elseif arena.status == "post-wait" then
        -- This just a little cool down after the round ended
        if game.tick > (arena.round.tick_ended + constants.round.post_wait) then            
            Arena.end_round(arena)
        end
    ---------------------------------------------------
    end
end

-- Handle things when a round ends.
-- Players need to see scores
-- And then be teleported back to arena
-- Seperate fucntion so that it can be called remotely
function Arena.end_round(arena)   
        
    -- Initiate clean of the arena
    -- It will also remove all players
    Arena.clean(arena)
end

-- This function must be called when a player
-- lost during a match. We will try to remove
-- his character and make him an observer.
function Arena.player_on_lost(arena, player)
    local player_state = arena.player_states[player.index]

    player_state.status = "lost"
    log("Player <"..player.name.."> died on arena <"..arena.name..">")

    -- Remove his character entity (the little man on the screen)
    local character = curvefever_util.player_to_spectator(player)
    character.die() -- The body will remain there... nice
end

-- Player likely accidentally pressed enter while playing.
-- Double check, and put him back in his car. This is 
-- also triggered when the player swops cars during an
-- effect. 
function Arena.player_driving_state_changed(arena, event)
    local player = game.get_player(event.player_index)
    local player_state = arena.player_states[player.index]
    local entity = event.entity    
        
    if arena.status == "playing" and player_state.status == "playing" then
        -- We only really care if player is playing
        -- AND if the arena is playing
        if player.character.driving == false then
            -- This means he likely got OUT of his vehicle
            -- This could be because of the effect
            if entity and player_state.vehicle == entity then
                -- The player's car still exists. This means he tried
                -- to climb out or swapped vehicles. Just make sure he
                -- back in his vehicle.
                player_state.vehicle.set_driver(player)
            
            elseif not entity then
                -- Player is not driving anymore and his entity doesn't exist.
                -- This means he likely lost the match. This means we need to do
                -- some stuff.
                Arena.player_on_lost(arena, player)
            end
        end
    end
end

-- Manages beacons. Is there enough? Can I spawn another one?
function Arena.update_effect_beacons(arena)
    if #arena.effect_beacons < arena.ideal_number_of_effect_beacons then
        -- TODO Populate this automatically with weights
        local effects_to_spawn = {
            "speed_up",
            "tank",
            "slow_down",
            "no_trail",
            "worm",
            "biters",
        }
        Arena.attempt_spawn_effect_beacon(
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
            arena.effect_beacons = curvefever_util.compact_array(arena.effect_beacons)
        end
    end
end

-- Will attempt to spawn an effect beacon at a location
-- Should always work though.
-- Returns a reference to the beacon entity or nill
function Arena.attempt_spawn_effect_beacon(arena, beacon_name)
    local surface = arena.surface
    local spacing = 5
    for try = 1,10 do
        local beacon = surface.create_entity{
            name = "curvefever-effect-"..beacon_name,
            position = {
                x=math.random(arena.area.left_top.x+spacing, arena.area.right_bottom.x-spacing),
                y=math.random(arena.area.left_top.y+spacing, arena.area.right_bottom.y-spacing)
            },            
            force = "enemy"
        }
        if beacon then
            table.insert(arena.effect_beacons, beacon)
            -- log("In arena <"..arena.name.."> created effect beacon <"..beacon_name..">. (Total of "..#arena.effect_beacons..")")
            return beacon
        end
    end
    return nil
end

-- This handler should be called if any effect beacon
-- is hit. This function will decide if it's part of this
-- arena, and apply it
function Arena.hit_effect_event(arena, event)
    local surface = game.get_surface(event.surface_index)
    local beacon = event.source_entity
    
    -- TODO Ensure this beacon is inside this arena

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
            Effects.add_effect(arena, player, {
                speed_up = {
                    speed_modifier = 1.8,
                    ticks_to_live = 4*60,
                },
            })
        elseif effect_type == "tank" then
            Effects.add_effect(arena, player, {
                tank = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "slow_down" then
            Effects.add_effect(arena, player, {
                slow_down = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "no_trail" then
            Effects.add_effect(arena, player, {
                no_trail = {
                    ticks_to_live = 5*60,
                },                
            })
        elseif effect_type == "worm" then
            local effect_constants = constants.effects[effect_type]
            Effects.add_effect(arena, player, {
                worm = {
                    ticks_to_live = effect_constants.ticks_to_live,
                },                
            })
        elseif effect_type == "biters" then
            local effect_constants = constants.effects[effect_type]
            Effects.add_effect(arena, player, {
                biters = {
                    ticks_to_live = effect_constants.ticks_to_live,
                },
                no_trail = {
                    ticks_to_live = effect_constants.period * (effect_constants.max_biters + 1)
                },
            })
        end
    end
end

function Arena.create_default_starting_locations(arena)
    -- Determines some default starting locations
    -- Currently only places them in a grid.
    -- TODO Rather make a cool circle thing
    arena.starting_locations = { }
    local spacing = constants.arena.starting_location_spacing
    local middle = {
        x=arena.area.left_top.x+(arena.area.right_bottom.x-arena.area.left_top.x)/2,
        y=arena.area.left_top.y+(arena.area.right_bottom.y-arena.area.left_top.y)/2,
    }    
    local x = middle.x-spacing*((math.ceil(arena.max_players/2)-1)/2)
    while #arena.starting_locations < arena.max_players do
        local y = middle.y + spacing/2
        local direction = defines.direction.south
        if #arena.starting_locations % 2 ~= 0 then
            y = middle.y - spacing/2
            direction = defines.direction.north
        else
            -- Ready for next column
            x = x + spacing -- This is our iterator
        end
        table.insert(arena.starting_locations, {x=x, y=y, direction=direction})
    end
    return arena.starting_locations
end

function Arena.set_status(arena, status)
    log("Setting arena <"..arena.name.."> status to <"..status..">")
    arena.status = status
end

return Arena
