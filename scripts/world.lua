util = require("util")

local Arena = require("scripts.arena")
local Lobby = require("scripts.lobby")
local constants = require("scripts.constants")
local util = require("scripts.wdd-util")
local Splash = require("scripts.splash")

local World = { }

function World.create(world, map_data)
    world = { }
    world.arenas = { }
    world.lobbies = { }
    world.enabled = false

    if map_data ~= nil then        
        world.spawn_location = map_data.spawn_location
        world.enabled = true
        world.splash = map_data.splash
        world.players_in_splash = {} -- Table with unit number as key, and tick started as value

        for _, lobby in pairs(map_data.lobbies) do
            world.lobbies[lobby.name] = Lobby.create(lobby)
        end
        for _, arena in pairs(map_data.arenas) do
            world.arenas[arena.name] = Arena.create(arena)
        end
    end
    return world
end

function World.enable(world, enable)
    if enable == nil then enable = true end
    world.enabled = enable
end

function World.clean(world)
    for _, lobby in pairs(world.lobbies) do
        Lobby.clean(lobby)
    end
    for _, arena in pairs(world.arenas) do
        Arena.clean(arena)
    end
end

function World.reset(world)
    
    -- Move all players to spawn
    for _, player in pairs(game.players) do
        util.teleport_safe(player, world.spawn_location)
    end

    -- Clean all arenas
    for _, arena in pairs(world.arenas) do
        Arena.reset(arena)
    end

    -- Clean all lobbies
    for _, lobby in pairs(world.lobbies) do
        Arena.reset(lobby)
    end

    -- Now destory the world
    -- It will be created again in the next tick
    return nil
end

function World.on_player_entered(world, event)
    -- Just make sure he goes to spawn.
    if not world then return end
    local player = game.get_player(event.player_index)    

    World.log("Player <"..player.name.."> joined. Initial position <"..util.to_string(player.position)..">.")

    -- Set up some global things
    if not global.players then global.players = {} end
    if not global.players[player.index] then global.players[player.index] = { } end

    -- Some random settings
    player.force = "player"
    player.surface.always_day=true  -- TODO Make better?

    -- Make sure the player is at spawn and has a body
    if not player.character then
        util.player_from_spectator(player)
    end
    player.character.driving = false    -- Ensure that he's not in a vehicle
    util.teleport_safe(player, world.spawn_location)

    -- Here is the splashy boi.
    -- After it ends player will automatically be
    -- at his character at spawn
    if constants.splash.enabled and world.splash then
        Splash.show(world, player)
    end

    -- Hide some GUI elements
    player.game_view_settings.show_controller_gui = false
    player.game_view_settings.show_research_info = false
    player.game_view_settings.show_side_menu = false
    player.game_view_settings.show_minimap = false

end

function World.on_player_left(world, event)
    if not world then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    World.log("Player <"..player.name.."> left. Last position <"..util.to_string(player.position)..">.")

    -- Pull player from any cutscene to make sure 
    -- there's no leftover character
    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
        -- It's okay if it was splash and the gui label remains
        -- It will be destroyed next time the player joins.
    end

    -- Remove player from arenas and lobbies
    for index, lobby in pairs(world.lobbies) do
        Lobby.on_player_left(lobby, player)
    end
    for _, arena in pairs(world.arenas) do
        Arena.on_player_left(arena, player)
    end 
end


function World.on_tick(world, event)

    -- The rest should only work if the world is active
    if not world.enabled then return end

    for index, lobby in pairs(world.lobbies) do
        Lobby.update(lobby, index)
    end

    for _, arena in pairs(world.arenas) do
        Arena.update(arena)
    end
end

-- Players like to climb out of their vehicles of get kicked out
-- when their vehicle is destroyed. We must handle it correctly.
-- Here we pass the event along to the appropriate arena or lobby
-- We are checking the players and possibly the vehicle too 
function World.on_player_driving_changed_state(world, event)    
    if world.enabled == false then return end

    local player = game.get_player(event.player_index)
    local vehicle = event.entity

    -- Check if this player was playing in an arena
    for _, arena in pairs(world.arenas) do
        -- This player is playing in this arena
        -- This could be either:
        --  Player tried to climb out of his car
        --  Player crashed and lost
        if Arena.player_driving_state_changed(arena, player, vehicle) then
            return  -- Event location found. Stop looking for other locations
        end
    end

    -- Now we know the event was not in an arena
    -- Check if this player was playing in an arena
    for _, lobby in pairs(world.lobbies) do
        if Lobby.player_driving_state_changed(lobby, player, vehicle) then
            return -- The event has been handled
        end
    end
end

-- This will handle the effect beacons, as each beacon
-- has a script trigger action. It need to be determined
-- for which arena it is though.
function World.on_script_trigger_effect(world, event)
    for _, arena in pairs(world.arenas) do
        if Arena.on_script_trigger_effect(arena, event) then return end
    end
end

-- This also triggers when an effect beacon is hit, but will
-- only trigger after the entity is destoyed (for any reason)
-- This is only used to clean up the cache of effect beacons
function World.on_entity_destroyed(world, event)
    for _, arena in pairs(world.arenas) do
        if Arena.on_entity_destroyed(arena, event) then return end
    end
end

-- This will be called on every splash, portal and transition
-- to/from arena, but this is only to remove the skip splash
-- label. So send it straight there
function World.on_cutscene_waypoint_reached(world, event)    
    Splash.on_cutscene_waypoint_reached(event)
end

-- The player can skip the splash when he joins
-- the game. We refine this here a little, and
-- simply tell Splash to skip if watching.
function World.on_skip_cutscene(world, event)
    if event.player_index ~= 1 then return end
    local player = game.get_player(event.player_index)        
    Splash.cancel_if_watching(player)
end

function World.log(msg)
    log("World: "..msg)
end

return World