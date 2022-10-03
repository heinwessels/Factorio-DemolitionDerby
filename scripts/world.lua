util = require("util")

local Arena = require("scripts.arena")
local Lobby = require("scripts.lobby")
local constants = require("scripts.constants")
local util = require("scripts.wdd-util")
local Splash = require("scripts.splash")
local Permissions = require("scripts.permissions")

local World = { }

function World.create(world, map_data)
    world = { }
    world.arenas = { }
    world.lobbies = { }
    world.enabled = false
    world.permissions = nil

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
    for arena_name, arena in pairs(world.arenas) do
        Arena.reset(arena)        
        world.arenas[arena_name] = nil
    end

    -- Clean all lobbies
    for lobby_name, lobby in pairs(world.lobbies) do        
        Lobby.reset(lobby)
        world.lobbies[lobby_name] = nil
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
    World.log("There are now "..#game.connected_players.." players online")

    -- Some random settings
    player.force = "player"
    player.surface.always_day=true  -- TODO Make better?

    -- Make sure the player is at spawn and has a body
    if not player.character then
        util.player_from_spectator(player)
    end
    player.character.driving = false    -- Ensure that he's not in a vehicle
    util.teleport_safe(player, world.spawn_location)

    -- Modify his permissions so that he cannot
    -- mess with things they shouldn't
    Permissions.add_player(player)

    -- Hide some GUI elements
    -- This must be done before the splash, otherwise the gui
    -- settings is only applied to the cutscene controller
    player.game_view_settings.show_controller_gui = false
    player.game_view_settings.show_research_info = false
    player.game_view_settings.show_side_menu = true -- Make sure this is enabled for tips
    player.game_view_settings.show_minimap = false
    
    -- Here is the splashy boi.
    -- After it ends player will automatically be
    -- at his character at spawn
    if constants.splash.enabled and world.splash then
        Splash.show(world, player)
    end
end

function World.on_player_left(world, event)
    if not world then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    World.log("Player <"..player.name.."> left. Last position <"..util.to_string(player.position)..">.")
    World.log("There are now "..#game.connected_players.." players online")

    -- Pull player from any cutscene to make sure 
    -- there's no leftover character
    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
        -- It's okay if it was splash and the gui label remains
        -- It will be destroyed next time the player joins.
    end

    -- Remove player from permissions group
    -- I don't know if it's required.
    -- Just being safe I guess
    Permissions.remove_player(player)

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
    if not world or not world.enabled then return end

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
        --      Player tried to climb out of his car
        --      Driving state changed on vehicle swop
        --      Player crashed and lost
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

-- This event will fire on two occations.
--    * When an effect beacon is hit, and will trigger after the 
--      entity is destoyed (for any reason)
--      This is used to clean up the cache of effect beacons
--    * When a vehicle a player is driving is destroyed, which will be used to
--      determine when a player lost the round.
-- This is all handled by the arena iteself
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
    local player = game.get_player(event.player_index)        
    Splash.cancel_if_watching(player)
end

function World.on_configuration_changed(event)
    -- Recreate permissions any time the mod
    -- changes. Might be that we changed something
    Permissions.setup_permissions()
end

-- Ensure that the current world has valid
-- arenas and is not some players base.
-- We will hard error if that happens.
function World.verify()
    if game.surfaces.nauvis.count_entities_filtered{
        name = "wdd-border",
        limit = 1,
    } == 0 then
        error("This world is not certified for Weasel's Demolition Derby! Please load a valid world instead, or disable Weasel's Demolition Derby until you're ready for another rumble in the jungle!")
    end
end

function World.log(msg)
    log("World: "..msg)
end

return World