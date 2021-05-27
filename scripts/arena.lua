local Effects = require("scripts.effects")
local constants = require("scripts.constants")
local Builder = require("scripts.builder")
local util = require("scripts.curvefever-util")
local Cutscene = require("scripts.cutscene")

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
            ideal_number_of_effect_beacons = util.size_of_area(arena.area) * constants.arena.effect_density,
            effect_beacons = { },   -- Array of all effect beacons part of this arena (array of references)
            builder = Builder.create(),
            
            lobby = nil,    -- (Optional) keep reference of lobby that added players. Not required

            max_players = 6,    -- Default
            players = { },
            player_states = { },
            effects = { },  -- Current effects scattered in arena

            effect_entity_entries = { }, -- Entities the arena keeps track of and destroys on time
            number_of_effect_entities = 0,   -- Cache the size

            vehicles = { }, -- Vehicles in starting locations. As soon as a
                            -- game starts this goes to { } and each player's
                            -- vehicle is stored in his player_state
        
            -- Possible statusses
            -- empty        -> Only defined, not built or ready
            -- ready        -> Ready for players to be added to game
            -- waiting-for-players -> Lobby has booked this arena, and is waiting for players
            -- transition-pre  -> Players are moved. Waiting for cutscene to finish
            -- countdown     -> 3, 2, 1, START!
            -- playing      -> Currently playing a round
            -- post-wait    -> After the round there will be a while of nothing.
            -- done         -> Done playing. Waiting for something to happen before clean
            -- building     -> (Re)building map (done at creation or cleaning)
            status = "empty",
            status_start_tick = 0,   -- The tick the status started

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
    Arena.log(arena, "Created arena <"..arena.name.."> with area <"..util.to_string(arena.area)..">")
    return arena
end

-- Clean up so that we can play another game
function Arena.clean(arena)
    Arena.set_status(arena, "building")  

    -- Clear all effect entities
    Effects.flush_effect_entities(arena)

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
-- Vehicle_index is optional and specifies which car to get into
function Arena.add_player(arena, player, vehicle_index)
    if arena.status ~= "ready" then
        error("Can only add players to arena when it's ready or accepting. Arena <"..arena.name..">'s status is <"..arena.status..">")
    end
    
    -- Check if this player was already added
    if arena.player_states[player.index] then
        Arena.log(arena, "Cannot add player "..player.name.." again (Total: "..#arena.players..")")
        return
    end
    
    -- Add player to arena
    table.insert(arena.players, player)
    local player_state = Arena.create_player_state(arena, player)   -- This will reset his score to zero

    -- Teleport player into his vehicle
    player.character.driving = false    -- Get the guy out of his car in the lobby
    if not vehicle_index then vehicle_index = #arena.players end
    local vehicle = arena.vehicles[vehicle_index]  -- This is still the static vehicle
    player_state.vehicle = vehicle
    player.teleport(vehicle.position)
    vehicle.set_driver(player)

    -- TODO Create handles for destroying of vehicles

    Arena.log(arena, "Added player "..player.name)
end

-- When a player left
function Arena.on_player_left(arena, player)
    for index, player_in_arena in pairs(arena.players) do
        if player.index == player_in_arena.index then
            
            -- Removing player
            Arena.log(arena, "Removing player <"..player.name..">.")
            
            local player_state = arena.player_states[player.index]
            if player_state.status == "playing" then
                -- Player is still playing. 
                -- He already left the game though.
                -- So just destroy his vehicle
                local vehicle = player_state.vehicle                
                vehicle.die()

                -- TODO Carefully stop his effects
            end
            
            arena.player_states[player.index] = nil
            table.remove(arena.players, index)
            return
        end
    end
end

-- Start the game for this arena (as it looks from the outside)
-- In arena it will still go through 2 waiting periods before actually starting
-- Players need to be in the arena in the cars already.
-- TODO Let arena start do it rather. More robust.
-- This will do some checks.
-- <lobby> can be nil, but if it's there <arena> will remember
-- and then teleport players back to the lobby instead of spawn
function Arena.start_round(arena, lobby)
    if arena.status ~= "ready" then
        Arena.log(arena, "Cannot start since it's not ready (status = "..arena.status..")")
    end

    if #arena.players == 0 then
        Arena.log(arena, "Cannot start since it has no players")
    end

    -- Setup and update some variables
    arena.ideal_number_of_effect_beacons = util.size_of_area(arena.area) * constants.arena.effect_density
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
        
    end

    -- Remove unused vehicles
    local surface = arena.surface
    for _, vehicle in pairs(arena.vehicles) do
        if vehicle and vehicle.valid and not vehicle.get_driver() then
            vehicle.destroy()
        end
    end
    
    Arena.set_status(arena, "transition-pre")
end

function Arena.create_player_state(arena, player)
    arena.player_states[player.index] = {
        effects = { },      -- What effects are applied to this player?
        score = { },        -- Score of this player"
        status = "idle",    -- nothing has been done to this player
        player = player,    -- Reference to connected player
        vehicle = nil,      -- Reference to players vehicle while playing
        score = 0,          -- Score for a specific round
    }
    return arena.player_states[player.index]
end

-- Call this function every tick
function Arena.update(arena)
    local tick = game.tick

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
    elseif arena.status == "ready" then
        -- Just idling. Waiting for lobby to book us.
    
    ---------------------------------------------------
    elseif arena.status == "waiting-for-players" then
        -- We are booked. Waiting for lobby to transfer
        -- the players.
    
    ---------------------------------------------------
    elseif arena.status == "transition-pre" then
        -- Players were teleported to arena.
        -- Now wait for cutscene to finish
        if arena.status_start_tick + constants.arena.timing["transition-pre"] < tick then
            -- The transition should be done.
            Arena.set_status(arena, "countdown")
        end
    ---------------------------------------------------
    elseif arena.status == "countdown" then
        -- Now we need to display a count down for the player
        if arena.status_start_tick + constants.arena.timing["countdown"] < tick then
            -- COUNTDOWN FINISHED! ACTUAL START!

            for _, player in pairs(arena.players) do
                local player_state = arena.player_states[player.index]

                -- Players are still in the fake cars
                -- Give them a real car (and not a static one)
                -- And store it in the state! We will remove
                player_state.vehicle = Effects.swap_vehicle(
                    player,
                    "curvefever-car"
                )
            end
            
            -- Remove any references to the vehicles in the arena. Now we store them
            -- In the player state. (Easier when swopping vechiles as effects)
            arena.vehicles = { }

            arena.round.tick_started = tick
            arena.round.tick_ended = 0
            arena.round.players_alive = #arena.players

            Arena.set_status(arena, "playing")            
            Arena.log(arena, "Started with "..#arena.players.." players")
            game.print("Round in Arena: "..arena.name.." started!")
        end
    ---------------------------------------------------
    elseif arena.status == "playing" then

        -- Add more effect beacons if required
        Effects.update_effect_beacons(arena)

        -- Update effect entities
        if tick % constants.arena.frequency.effect_entity == 0 then
            Effects.update_effect_entities(arena, tick)
        end
        
        -- Update player specific things
        arena.round.players_alive = 0   -- Will count the amount now
        local player_alive = nil
        for _, player in pairs(arena.players) do
            if player.character then
                -- Update for a specific player
                
                local vehicle = player.character.vehicle  
                local player_state = arena.player_states[player.index]

                if constants.single_player then
                    -- Just some way to check score while I'm on my own
                    if tick % 60 == 0 then player_state.score = player_state.score + 1 end
                end

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
            arena.round.tick_ended = tick
            if not player_alive then 
                game.print("On Arena "..arena.name.." after "..util.round((arena.round.tick_ended-arena.round.tick_started)/60, 1).." seconds there was no clear winner!")
                Arena.log(arena, "Round over after "..(arena.round.tick_ended-arena.round.tick_started).." ticks. There was no winner.")
            else
                game.print("On Arena "..arena.name.." the player "..player_alive.name.." emerged victorious after "..util.round((arena.round.tick_ended-arena.round.tick_started)/60, 1).." seconds!")
                Arena.log(arena, "Round over after "..(arena.round.tick_ended-arena.round.tick_started).." ticks. <"..player_alive.name.."> was the victor!")
            end

            -- TODO Show some victory thing
            -- TODO Show score!
            -- TODO Play nice sound

            Arena.set_status(arena, "post-wait")
        end
    ---------------------------------------------------
    elseif arena.status == "post-wait" then
        -- This just a little cool down after the round ended
        if tick > (arena.round.tick_ended + constants.arena.timing["post-wait"]) then
            Arena.end_round(arena)  -- This will move players back to the lobby
            Arena.set_status(arena, "done")
        end
    ---------------------------------------------------
    elseif arena.status == "done" then
        -- Initiate clean of the arena
        -- The lobby also waits for this state to reset his state machine
        if game.tick > arena.status_start_tick + 5 then -- Just give a few ticks
            Arena.clean(arena)  --- This will set the status to "building"
        end
    end
end

-- A player touched a effect beacon.
-- If in this arena, then transfer it to our effects department
function Arena.hit_effect_event(arena, event)
    local beacon = event.source_entity
    if beacon.type ~= "land-mine" then return end    
    if util.position_in_area(beacon.position, arena.area) then
        Effects.hit_effect_event(arena, beacon)
        return true
    end
end

-- Handle things when a round ends.
-- Players need to see scores
-- And then be teleported back to arena
-- Seperate fucntion so that it can be called remotely
function Arena.end_round(arena)   
    
    -- Remove all players from the arena
    local surface = arena.surface
    local lobby = arena.lobby
    for _, player in pairs(arena.players) do
        local player_state = arena.player_states[player.index]

        if player.character and player.character.vehicle then
            -- If player was in a car get him out
            player.character.driving = false
        end

        if not player.character then
            -- Player was spectating and don't have a character
            -- Give his body back.
            util.player_from_spectator(player)
        end

        -- Make sure he has full health
        player.character.health = player.character.prototype.max_health

        -- Remove his GUI arrows
        player.clear_gui_arrow()    -- TODO actually implement

        -- Move him back to spawn or the the lobby
        local old_position = player.position        
        if lobby then
            util.teleport_safe(player, lobby.spawn_location)

            -- Update his lobby score
            local lobby_state = lobby.player_states[player.index]
            lobby_state.score = lobby_state.score + player_state.score

        else
            util.teleport_safe(player, global.world.spawn_location)
        end

        -- Create a cutscene to transition the player
        Cutscene.transition_to{
            player=player,
            start_position=old_position,
            duration=constants.arena.timing["transition-pre"],
            end_zoom=1,
        }
    end
end

-- This function must be called when a player
-- lost during a match. We will try to remove
-- his character and make him an observer.
function Arena.player_on_lost(arena, player)
    local player_state = arena.player_states[player.index]

    player_state.status = "lost"
    game.print(player.name.." died in Arena "..arena.name.."!")
    Arena.log(arena, "Player <"..player.name.."> died.")

    -- Remove his character entity (the little man on the screen)
    local character = util.player_to_spectator(player)
    character.die() -- The body will remain there... nice

    -- Now give all the other alive players one point
    for _, enemy in pairs(arena.players) do
        if enemy.index ~= player.index then
            local enemy_state = arena.player_states[enemy.index]
            if enemy_state.status == "playing" then
                enemy_state.score = enemy_state.score + 10
            end
        end        
    end
end

-- Player likely accidentally pressed enter while playing.
-- Double check, and put him back in his car. This is 
-- also triggered when the player swops cars during an
-- effect. 
function Arena.player_driving_state_changed(arena, player, vehicle)
    
    -- First verify this event happened in this arena
    if not util.position_in_area(player.position, arena.area) then return end
    
    -- Did it happen to one of the known players?
    local player_state = arena.player_states[player.index]
    if not player_state then return true end -- Just ignore it, and notify world it's handled
    
    -- This is something we should handel
    if (arena.status == "playing" or arena.status == "countdown") and 
            (player_state.status == "playing" or player_state.status == "idle") then
        -- We only really care if player is playing
        -- AND if the arena is playing
        if player.character.driving == false then
            -- This means he likely got OUT of his vehicle
            -- This could be because of the effect
            if vehicle and player_state.vehicle == vehicle then
                -- The player's car still exists. This means he tried
                -- to climb out or swapped vehicles. Just make sure he
                -- back in his vehicle.
                player_state.vehicle.set_driver(player)
            
            elseif not vehicle then
                -- Player is not driving anymore and his vehicle doesn't exist.
                -- This means he lost the match. This means we need to do
                -- some stuff.
                Arena.player_on_lost(arena, player)
            end
        end
    end
end

function Arena.create_default_starting_locations(arena)
    -- Determines some default starting locations
    -- Currently only places them in a grid.
    -- Assumes the arena is horizontal, as it should be
    -- TODO Rather make a cool circle thing
    arena.starting_locations = { }
    local spacing = constants.arena.starting_location_spacing
    local middle = util.middle_of_area(arena.area)
    local x = middle.x-spacing.x*((math.ceil(arena.max_players/2)-1)/2)
    while #arena.starting_locations < arena.max_players do
        local y = middle.y + spacing.y/2
        local direction = defines.direction.south
        if #arena.starting_locations % 2 ~= 0 then
            y = middle.y - spacing.y/2
            direction = defines.direction.north
        end
        table.insert(arena.starting_locations, {x=x, y=y, direction=direction})

        if #arena.starting_locations % 2 == 0 then
            -- Ready for next column
            x = x + spacing.x -- This is our iterator
        end
    end
    return arena.starting_locations
end

function Arena.set_status(arena, status)
    Arena.log(arena, "Setting arena <"..arena.name.."> status to <"..status..">")
    arena.status_start_tick = game.tick
    arena.status = status
end

function Arena.log(arena, msg)
    log("Arena <"..arena.name..">: "..msg)
end

return Arena
