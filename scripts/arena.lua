local util = require("util")
local effects = require("scripts.effects")
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
    local vehicles = arena.surface.find_entities_filtered{
        name = "curvefever-car",
        area = arena.area
    }
    arena = util.merge{
        {
            name = name,        
            surface = surface,
            area = area,
            starting_positions = nil,   -- Each location includes a third entry orientation
            ideal_number_of_effect_beacons = curvefever_util.size_of_area(arena.area) * constants.arena.effect_density,
            effect_beacons = { },   -- Array of all effect beacons part of this arena (array of references)
            builder = Builder.create(),
        
            max_players = 6,    -- Default
            players = { },
            player_states = { },    
            vehicles = { },
            effects = { },  -- Current effects scattered in arena
        
            -- Possible statusses
            -- empty        -> Only defined, not built or ready
            -- ready        -> Ready for players to be added to game
            -- playing      -> currently has a game running
            -- building     -> (Re)building map (done at creation or cleaning)
            status = "empty"
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
    log("Created arena <"..arena.name.."> with area <"..curvefever_util.to_string(area)..">")
    return arena
end

-- Clean up so that we can play another game
function Arena.clean(arena)
    -- Remove all players from the arena
    local spawn = global.world.spawn_location
    for _, player in pairs(arena.players) do
        player.character.driving = false    -- Get out!
        player.teleport(spawn)
    end

    -- Clear the state
    arena.effect_beacons = { } -- Builder will destroy them anyway
    arena.player_states = { }
    arena.players = { }


    -- Rebuild the arena
    Arena.set_status(arena, "building")    
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
function Arena.start(arena)
    if arena.status ~= "ready" then
        log("Cannot start arena <"..arena.name.."> since it's not ready (status = "..arena.status..")")
    end

    if #arena.players == 0 then
        log("Cannot start arena <"..arena.name.."> since it has no players")
    end

    -- Setup and update some variables
    arena.ideal_number_of_effect_beacons = curvefever_util.size_of_area(arena.area) * constants.arena.effect_density

    -- Setup players
    for _, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]
        player_state.status = "playing"
        effects.add_effect(arena, player, {
            trail = {              
                ticks_to_live = nil, -- Forever
            },
        })
    end

    -- Remove unused vehicles
    local surface = arena.surface
    for _, vehicle in pairs(arena.vehicles) do        
        if not vehicle.get_driver() then
            vehicle.destroy()
        end
    end

    -- TODO Add triggers to remaining vehicles being destroyed

    log("Started arena <"..arena.name.."> with "..#arena.players.." players")
    Arena.set_status(arena, "playing")
end

function Arena.create_player_state(arena, player)
    arena.player_states[player.index] = {
        effects = { },      -- What effects are applied to this player?
        score = { },        -- Score of this player"
        status = "idle",    -- nothing has been done to this player
        player = player,    -- Reference to connected player
    }
end

-- Call this function every tick
function Arena.update(arena)

    -- TODO check game. Is all the players still there?
    -- Stuff like that.
    if arena.status == "building" then
        Builder.iterate(arena)
        if arena.builder.state == "idle" then
            -- It's done building
            Arena.set_status(arena, "ready")

            -- There's new vehicles. Get references to it
            arena.vehicles = arena.surface.find_entities_filtered{
                name = "curvefever-car",
                area = arena.area   -- This is quite a large area
            }
        end
    end

    if arena.status == "playing" then

        Arena.update_effect_beacons(arena)

        for _, player in pairs(arena.players) do
            if player.character then
                -- Update for a specific player

                Arena.ensure_players_are_driving(arena, player)
                
                local vehicle = player.character.vehicle  
                local player_state = arena.player_states[player.index]

                if player_state.status == "playing" and vehicle then
                    
                    vehicle.speed = constants.vehicle_speed

                    -- Apply any effects
                    effects.apply_effects(arena, player)
                end
            end
        end
    end
end

-- Ensure the player is still in his vehicle
function Arena.ensure_players_are_driving(arena, player)
    local player_state = arena.player_states[player.index]
    if player_state == "playing" then
        -- Player needs to be in his car
        if not player.character.vehicle then
            player_state.vehicle.set_driver(player)
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
            effects.add_effect(arena, player, {
                speed_up = {
                    speed_modifier = 1.8,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "tank" then
            effects.add_effect(arena, player, {
                tank = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "slow_down" then
            effects.add_effect(arena, player, {
                slow_down = {
                    speed_modifier = 0.55,
                    ticks_to_live = 5*60,
                },
            })
        elseif effect_type == "no_trail" then
            effects.add_effect(arena, player, {
                no_trail = {
                    ticks_to_live = 5*60,
                },                
            })
        elseif effect_type == "worm" then
            effects.add_effect(arena, player, {
                worm = {
                    ticks_to_live = 13*60,
                },                
            })
        elseif effect_type == "biters" then
            effects.add_effect(arena, player, {
                biters = {
                    ticks_to_live = 8*60,
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
