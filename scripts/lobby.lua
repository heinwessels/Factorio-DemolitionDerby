local util = require("scripts.curvefever-util")
local constants = require("scripts.constants")
local Arena = require("scripts.arena")
local Portal = require("scripts.portal")
local Cutscene = require("scripts.cutscene")
local LobbyGui = require("scripts.lobby-gui")

local Lobby = { }

function Lobby.create(lobby)
    if type(lobby.surface) == "string" then
        lobby.surface = game.surfaces[lobby.surface]
    end
    local vehicles = lobby.surface.find_entities_filtered{
        name = "curvefever-car-static",
        area = lobby.area
    }
    local vehicle_positions = { }
    for _, vehicle in pairs(vehicles) do
        table.insert(vehicle_positions, vehicle.position)
    end
    lobby = util.merge{
        {
            name = "",
            world = nil, -- A reference to the world
            
            status = "ready",
            -- Other statusses
            --  "countdown"
            --  "wait"  -- for world to put players in a game
            --  "busy"  -- The arena for this game is currently busy
            countdown_start = nil,
            
            arena = nil,
            arena_names = { },   -- Array of arena names this lobby can go to
            target_arena_name = nil,    -- Where the game will be played when in wait

            vehicles = vehicles,     -- Array of vehicles in this lobby
            vehicle_positions = vehicle_positions,     -- Position of each of the vehicles
            
            players = { },
            player_states = { },                -- Specific to lobby!
            max_players = { },
            
            spawn_location = util.middle_of_area(lobby.area),
            area = {left_top={}, right_top={}},
            portals = { }
        },
        lobby
    }
    for _, portal in pairs(lobby.portals) do 
        portal.surface = lobby.surface
        portal.cache = { }
    end
    return lobby
end

-- Delete everything
function Lobby.reset(lobby)
    lobby = nil
end

function Lobby.clean(lobby)
    -- Should I reset car colours here? No. It's kinda nice.
    
    lobby.players = { }
    lobby.player_states = { }    
    for _, portal in pairs(lobby.portals) do
        Portal.flush_cache(portal)
    end
end

-- This should be called every tick.
function Lobby.update(lobby)

    -- Check the gate for players coming in and out
    if game.tick % constants.lobby.frequency.portals == 0 then
        Lobby.check_portals(lobby)
    end

    if game.tick % constants.lobby.frequency.gui_refresh == 0 then
        for _, player in pairs(lobby.players) do
            LobbyGui.refresh(lobby, player)
        end
    end

    -- Update the main lobby state machine
    Lobby.state_machine(lobby)
end

-- Add player to lobby. The player will stay in this lobby,
-- even while playing a arena. The scoring system will
-- be stored per lobby
function Lobby.add_player(lobby, player)
    if #lobby.players < lobby.max_players then
        if not lobby.player_states[player.index] then

            -- The player can be added! Now do it.

            -- Add some lobby things
            table.insert(lobby.players, player)
            lobby.player_states[player.index] = {
                gui = { },
                score = 0,  -- This score will be persistent while in this lobby
                ready = false,
            }

            -- Make sure player has a GUI
            LobbyGui.build_interface(lobby, player)
            
            Lobby.log(lobby, "Adding player <"..player.name..">. (Number of players: "..#lobby.players..")")
        else
            Lobby.log(lobby, "Cannot add player <"..player.name.."> again. (Number of players: "..#lobby.players..")")
        end
    else
        Lobby.log(lobby, "Cannot add player <"..player.name..">. Lobby is full.")
    end
end

function Lobby.remove_player(lobby, player, silent_fail)
    for index, player_in_lobby in pairs(lobby.players) do
        if player.index == player_in_lobby.index then
            
            -- Removing player
            LobbyGui.destroy(lobby, player) -- before killing state
            lobby.player_states[player.index] = nil
            table.remove(lobby.players, index)
            
            Lobby.log(lobby, "Removing player <"..player.name..">.")
            return

        end
    end
    if not silent_fail then
        Lobby.log(lobby, "Could not remove player <"..player.name..">. Not found")
    end
end

function Lobby.on_player_left(lobby, player)
    Lobby.remove_player(lobby, player, true)
end

function Lobby.state_machine(lobby)
    if not lobby.vehicles then return end   -- Shouldn't do anything if there's no vehicles
    
    ---------------------------------------------------    
    if lobby.status == "ready" then

        -- See if all players in the lobby are in their cars
        if game.tick % constants.lobby.frequency.players_ready == 0 then
            local player_count = #lobby.players
            if player_count > 0 then
                local count_ready_players = Lobby.count_ready_players(lobby)
                if count_ready_players > 0 and count_ready_players == player_count then
                    -- Can start the count down!
                    Lobby.set_status(lobby, "countdown")
                    lobby.countdown_start = game.tick                
                    -- After the countdown we wil finalize the game
                end
            end
        end        
    ---------------------------------------------------
    elseif lobby.status == "countdown" then

        -- First check all the players are still in their cars
        -- TODO Do this with events rather
        if Lobby.count_ready_players(lobby) == #lobby.players then

            local diff = game.tick - lobby.countdown_start                    
            if diff > constants.lobby.timing.countdown then

                -- Choose a target arena randomly
                lobby.target_arena_name = lobby.arena_names[math.random(#lobby.arena_names)]                
                lobby.arena = global.world.arenas[lobby.target_arena_name]
                Lobby.log(lobby, "Set target arena to <"..lobby.target_arena_name..">")
                
                -- Now we will wait for the arena to be ready
                Lobby.set_status(lobby, "waiting")
            end    
        else
            -- Some player climbed out of their car. Stop countdown
            game.print("Countdown stopped for "..lobby.name.."! All players not ready")
            Lobby.set_status(lobby, "ready")
        end
    ---------------------------------------------------
    elseif lobby.status == "waiting" then

        if Lobby.count_ready_players(lobby) == #lobby.players then

            -- Waiting for a arena to be ready to send the players too   
            local arena = lobby.arena
            if arena.status == "ready" then
                -- Arena is ready! Add and teleport players to the arena.

                -- This will teleport them into the cars in the arena
                for _, player in pairs(lobby.players) do                
                    local position = player.position    -- Remember where player was
                    
                    -- Get vehicle index
                    local car_index = nil
                    for index, vehicle in pairs(lobby.vehicles) do
                        if vehicle.get_driver() == player.character then
                            car_index = index
                        end
                    end
                    Arena.add_player(arena, player, car_index)     -- This will teleport them

                    -- Add a cutscene from the player position in the lobby
                    -- to where they are in the arena now
                    Cutscene.transition_to{
                        player=player,
                        start_position=position,
                        duration=constants.arena.timing["transition-pre"],
                        end_zoom=constants.arena.start_zoom,
                    }
                end

                -- Start the game!
                Arena.start_round(arena, lobby)
                if arena.status ~= "transition-pre" then
                    Lobby.log(lobby, "Something went wrong starting arena <"..arena.name..">.")
                end
                Lobby.set_status(lobby, "busy")
            end
        else
            -- Some player climbed out of their car. Stop countdown
            game.print("Countdown stopped for "..lobby.name.."! All players not ready")
            Lobby.set_status(lobby, "ready")
        end
    ---------------------------------------------------
    elseif lobby.status == "busy" then
        local arena = lobby.arena
        if arena.status == "done" then
            -- The arena round is done
            -- And the arena transfered the players back to the lobby
            Lobby.set_status(lobby, "ready")

            -- Now reset the arena reference
            lobby.arena = nil
        end    
    ---------------------------------------------------
    end
end

-- Check for players coming in and out of the gate.
-- This is too make sure there's never more than the
-- max amount of players in the lobby.
-- There is a gate, but it won't be used.
function Lobby.check_portals(lobby)    
    
    local inside_portal = lobby.portals.inside
    local outside_portal = lobby.portals.outside
    if not inside_portal or not outside_portal then return end

    -- Handle outside portal
    
    local players = Portal.players_in_range(outside_portal)
    Portal.refresh_cache(outside_portal, players)
    for _, player in pairs(players) do
        if not Portal.player_in_cache(outside_portal, player) then
            -- This is the first time the player is in the area

            -- This player is trying to get in
            if #lobby.players < lobby.max_players then
                -- There is still space in this lobby for player
                -- Teleport him!
                Portal.teleport_to(inside_portal, player)            

                -- Make sure he isn't instantly teleported back
                Portal.add_player_to_cache(inside_portal, player)

                -- Add him to lobby
                Lobby.add_player(lobby, player)
            else
                -- There is no more space in lobby
                if game.tick % 120 == 0 then
                    player.create_local_flying_text{
                        text = {"lobby.full-flying-text"},
                        position = {
                            player.position.x,
                            player.position.y - 2,
                        },
                        color = {r=1,g=0,b=0,a=1},
                    }
                end
            end
        end
    end

    -- Handle inside portal
    if #lobby.players > 0 then
        -- Only handle this is we know there are players inside

        players = Portal.players_in_range(inside_portal)
        Portal.refresh_cache(inside_portal, players)
        for _, player in pairs(players) do
            if not Portal.player_in_cache(inside_portal, player) then            
                -- This is the first time the player is in the area

                -- This player wants to leave the lobby!

                -- Teleport him!
                Portal.teleport_to(outside_portal, player)            

                -- Make sure he isn't instantly teleported back
                Portal.add_player_to_cache(outside_portal, player)

                -- Remove him from the lobby
                Lobby.remove_player(lobby, player)
            end
        end
    end

end

-- Count the ready players (players in cars)
function Lobby.count_ready_players(lobby)
    local count_ready_players = 0
    for _, player in pairs(lobby.players) do
        local player_state = lobby.player_states[player.index]
        if player_state.ready then
            count_ready_players = count_ready_players + 1
        end
    end
    return count_ready_players
end

-- This happens when players climb in cars in the lobby
-- to show that they are ready to play. We will use this
-- event to keep track of that
function Lobby.player_driving_state_changed(lobby, player, vehicle)
    
    local event_handled = falses

    -- First verify this event happened in this lobby
    if not util.position_in_area(player.position, lobby.area) then return end

    -- Log that this happened, because this is error prone
    Lobby.log(lobby, "Driving state change. Player: "..player.name..". Vehicle: "..((vehicle and vehicle.name) or "nil"))

    -- Is he one of the players in the lobby?
    -- (this should not be possible, but it should be robust)
    if not util.is_player_in_list(lobby.players, player) then
        -- Player should not be here. Teleport him to spawn
        if player.character.driving then
            -- However, we only do this when he get's into a car
            -- This is to distinguish the kick event from when we take
            -- him out of the car, to not teleport him twice

            player.character.driving = false -- Make sure he is out of car
            util.teleport_safe(player, global.world.spawn_location)
            player.create_local_flying_text{
                text = {"lobby.not-recognised"},
                position = {
                    player.position.x,
                    player.position.y - 2,
                },
                color = {r=1,g=0,b=0,a=1},
            }        
            return true -- Let world know we handled it
        else
            return -- Just ignore
        end
    end

    -- If we reach this point then the event happened in this lobby
    -- and it's a legal player in this lobby. So set his ready status
    -- according to if he is in a car or not
    local player_state = lobby.player_states[player.index]
    player_state.ready = player.character.driving

end

function Lobby.set_status(lobby, status)
    Lobby.log(lobby, "Setting state to <"..status..">")
    lobby.status_start_tick = game.tick
    lobby.status = status
end

function Lobby.log(lobby, msg)
    log("Lobby <"..lobby.name..">: "..msg)
end

return Lobby