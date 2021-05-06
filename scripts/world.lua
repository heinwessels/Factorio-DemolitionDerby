util = require("util")

local Arena = require("scripts.arena")
local Lobby = require("scripts.lobby")
local constants = require("scripts.constants")
local curvefever_util = require("scripts.curvefever-util")
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
        player.teleport(world.spawn_location)
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

function World.player_entered(world, event)
    -- Just make sure he goes to spawn.
    if not world then return end
    local player = game.get_player(event.player_index)    
    player.force = "player"

    -- TODO What to do with day time?
    player.surface.always_day=true

    -- Make sure the player is at spawn and has a body
    if not player.character then
        curvefever_util.player_from_spectator(player)
        player.character.driving = false    -- Ensure that he's not in a vehicle
    end
    curvefever_util.teleport_safe(player, world.spawn_location)

    -- Here is the splashy boi.
    -- After it ends player will automatically be
    -- at his character at spawn
    if constants.splash.enabled and world.splash then
        Splash.show(world, player)
    end

    -- Hide some GUI elements
    if constants.single_player == false then
        player.game_view_settings.show_controller_gui = false
        player.game_view_settings.show_research_info = false
        player.game_view_settings.show_side_menu = false
        player.game_view_settings.show_minimap = false         
    end

end

function World.on_tick(world, event)

    -- The rest should only work if the world is active
    if world.enabled == false then return end

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

    -- Check if this player was playing in an arena
    for _, arena in pairs(world.arenas) do
        if arena.player_states[player.index] then
            -- The player who got out of his car is in this arena
            -- It's not possible for him to try climb in in an arena
            -- hopefully.
            Arena.player_driving_state_changed(arena, event)
            return
        end
    end

    if not event.entity then
        -- The player might have tried to climb out of his car.
        -- Prevent him!
    end
end

function World.on_script_trigger_effect(world, event)
    for _, arena in pairs(world.arenas) do
        Arena.hit_effect_event(arena, event)
    end
end

return World