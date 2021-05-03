util = require("util")

local Arena = require("scripts.arena")
local Lobby = require("scripts.lobby")


local World = { }

function World.create(world, map_data)
    world = { }
    world.arenas = { }
    world.lobbies = { }
    world.enabled = true
    
    world.spawn_location = map_data.spawn_location

    for _, lobby in pairs(map_data.lobbies) do
        world.lobbies[lobby.name] = Lobby.create(lobby)
    end
    for _, arena in pairs(map_data.arenas) do
        world.arenas[arena.name] = Arena.create(arena)
    end
    return world
end

function World.enable(world, enable)
    if enable == nil then enable = true end
    world.enabled = enable
end

function World.clean(world)
    for _, lobby in pairs(world.lobbies) do
        world.lobbies[lobby.name] = Lobby.clean(lobby)
    end
    for _, arena in pairs(world.arenas) do
        world.arenas[arena.name] = Arena.clean(arena)
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
    local player = game.get_player(event.player_index)
    player.teleport(world.spawn_location)
end

function World.on_tick(world, event)

    if world.enabled == false then return end

    for index, lobby in pairs(world.lobbies) do
        Lobby.update(lobby, index)
    end

    for _, arena in pairs(world.arenas) do
        Arena.update(arena)
    end
end

function World.on_player_driving_changed_state(world, event)
    
    ---------------------------------------
    -- TODO THIS WILL HAVE TO BE VERY SMART
    ---------------------------------------


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