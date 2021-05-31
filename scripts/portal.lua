local math2d = require("math2d")
local util = require("scripts.wdd-util")
local constants = require("scripts.constants")
local Cutscene = require("scripts.cutscene")

local Portal = { }

function Portal.players_in_range(portal)
    local players = { }
    for _, character in pairs(portal.surface.find_entities_filtered{
        area = portal.area,
        type = "character",
    }) do
        if character.player then
            table.insert(players, character.player)
        end
    end
    return players
end

function Portal.teleport_to(portal, player, duration)
    local surface = player.surface
    local position = player.position -- Remember position for cutscene
    util.teleport_safe(player, util.middle_of_area(portal.area))    
    if constants.lobby.timing.portal_cutscene then
        Cutscene.transition_to{
            player=player,
            start_position=position,
            duration=constants.lobby.timing.portal_cutscene,
        }
    end

    player.play_sound{ path = "wdd-portal-swoosh"}
    
    -- Create some smoke
    surface.create_trivial_smoke{name="smoke-fast", position=position}
    if player.cutscene_character then        
        surface.create_trivial_smoke{name="smoke-fast", position=player.cutscene_character.position}
    else
        surface.create_trivial_smoke{name="smoke-fast", position=player.position}
    end
end

function Portal.flush_cache(portal)
    portal.cache = { }
end

function Portal.refresh_cache(portal, players)
    if not players then    
        Portal.flush_cache(portal)
        return
    end
    for index, entry in pairs(portal.cache) do        
        local player = entry.player
        local found = false
        for _, player_in_range in pairs(players) do
            if index == player_in_range.index then
                -- Player in cache is still in range
                found = true            
            end
        end
        if not found then
            -- There is a grace period. The player can only be removed from cache
            -- after some time. This is mainly because during the cutscene there is
            -- no way to link the character back to the player
            if game.tick > entry.start + constants.lobby.timing.portal_cutscene then
                -- Player in cache was not found in range
                -- Evict!
                Portal.remove_player_from_cache(portal, player)
            end
        end
    end
end

function Portal.player_in_cache(portal, player)        
    return portal.cache[player.index]
end

function Portal.add_player_to_cache(portal, player)
    portal.cache[player.index] = {
        player = player,
        start = game.tick,
    }
end

function Portal.remove_player_from_cache(portal, player)
    if portal.cache[player.index] then
        portal.cache[player.index] = nil
    end
end

return Portal