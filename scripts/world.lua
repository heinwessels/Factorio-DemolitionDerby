util = require("util")

local Arena = require("scripts.arena")
local Lobby = require("scripts.lobby")

local World = { }

function World.create(world, map_data)
    world = { }
    world.arenas = { }
    world.lobbies = { }
    world.spawn_location = map_data.spawn_location

    for _, lobby in pairs(map_data.lobbies) do
        world.lobbies[lobby.name] = Lobby.create(lobby)
    end
    for _, arena in pairs(map_data.arenas) do
        world.arenas[arena.name] = Arena.create(arena)
    end
    return world
end

function World.reset(world)
    world.create(world, map_data)
    
    -- Move all players to spawn
    for _, player in pairs(game.players) do
        player.teleport(world.spawn_location)
    end

    -- Clean all arenas
    for _, arena in pairs(world.arenas) do
        Arena.clean(arena)
    end

    -- Clean all lobbies
    for _, lobby in pairs(world.lobby) do
        Arena.clean(lobby)
    end

    return world
end

function World.player_entered(event)
    -- Just make sure he goes to spawn.
    local player = game.players[event.player_index ]
    player.teleport(world.spawn_location)
end

function World.on_tick(world, event)
    for _, arena in pairs(world.arenas) do
        Arena.update(arena)
    end
end

function World.on_player_driving_changed_state(world, event)
    
    ---------------------------------------
    -- TODO THIS WILL HAVE TO BE VERY SMART
    ---------------------------------------

    local player = game.get_player(event.player_index)        
    Arena.add_player(world.arenas["achtung"], player)

    if not event.entity then
        -- The player might have tried to climb out of his car.
        -- Maybe prevent him!
    end
end

function World.on_script_trigger_effect(world, event)
    for _, arena in pairs(world.arenas) do
        Arena.hit_effect_event(arena, event)
    end
end

return World