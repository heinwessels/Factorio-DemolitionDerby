local util = require("util")
local effects = require("scripts.effects")
local constants = require("scripts.constants")
local Builder = require("scripts.builder")
local curvefever_util = require("scripts.curvefever-util")

local Arena = { }

-- Set up a arena to be played at some point
-- area     of the arena
function Arena.create(name, area, surface)
    arena = {
        name = name,
        
        surface = surface,
        area = area,
        starting_positions = { },   -- Each location includes a third entry orientation
        ideal_number_of_effect_beacons = curvefever_util.size_of_area(area) * constants.arena.effect_density,
        effect_beacons = { },   -- Array of all effect beacons part of this arena (array of references)
        builder = Builder.create(),
    
        max_players = 6,    -- Default
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

    -- TODO Add minimum allowed size


    -- Create some starting locations if none was given
    if not arena.starting_positions or #arena.starting_positions==0 then
        Arena.create_default_starting_locations(arena)
    end

    -- Now build the arena
    Arena.set_state(arena, "building")
    Builder.start(arena)
    
    -- Created!
    log("Created arena <"..arena.name.."> with area <"..curvefever_util.to_string(area)..">")
    return arena
end

function Arena.clean(arena)
    -- Clear the state
    arena.effect_beacons = { } -- Builder will destroy them
    for _, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]
        player_state.effects = { }
    end

    -- Rebuild the arena
    Arena.set_state(arena, "building")    
    Builder.start(arena)
end

-- Add player to arena to be played
function Arena.add_player(arena, player)

    if arena.player_states[player.index] then
        log("Cannot add player "..player.name.." to arena "..arena.name.." again (Total: "..#arena.players..")")
        return
    end

    table.insert(arena.players, player)
    Arena.create_player_state(arena, player)

    log("Added player "..player.name.." to arena "..arena.name.." (Total: "..#arena.players..")")
end

-- Start the game for this arena
function Arena.start(arena)
    if arena.state ~= "ready" then
        log("Cannot start arena <"..arena.name.."> since it's not ready (state = "..arena.state..")")
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
    for _, starting_position in pairs(arena.starting_locations) do
        local vehicle = surface.find_entity(
            "curvefever-car",
            {starting_position.x, starting_position.y}
        )
        if not vehicle then
            error("In arena <"..arena.name.."> there should be a vehicle at starting location <"..curvefever_util.to_string(starting_position)..">")
        elseif not vehicle.get_driver() then
            vehicle.destroy()
        end
    end

    -- TODO Add triggers to remaining vehicles being destroyed

    log("Started arena <"..arena.name.."> with "..#arena.players.." players")
    Arena.set_state(arena, "playing")
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
    if arena.state == "building" then
        Builder.iterate(arena)
        if arena.builder.state == "idle" then
            Arena.set_state(arena, "ready")
        end
    end

    if arena.state == "playing" then

        Arena.update_effect_beacons(arena)

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
    for try = 1,10 do
        local beacon = surface.create_entity{
            name = "curvefever-effect-"..beacon_name,
            position = {
                x=math.random(arena.area[1].x+1, arena.area[2].x-1),
                y=math.random(arena.area[1].y+1, arena.area[2].y-1)
            },            
            force = "enemy"
        }
        if beacon then
            table.insert(arena.effect_beacons, beacon)
            log("In arena <"..arena.name.."> created effect beacon <"..beacon_name..">. (Total of "..#arena.effect_beacons..")")
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
                    ticks_to_live = 13*60,
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
        x=arena.area[1].x+(arena.area[2].x-arena.area[1].x)/2,
        y=arena.area[1].y+(arena.area[2].y-arena.area[1].y)/2,
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
end

function Arena.set_state(arena, state)
    log("Setting arena <"..arena.name.."> state to <"..state..">")
    arena.state = state
end

return Arena
