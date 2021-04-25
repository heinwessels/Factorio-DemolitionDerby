local util = require("util")

local effects = { }
-- This file contains no state. Only handles some effects
-- This is an example of how effects look like minimally
-- {
--      "speed" = {
--          speed_modifier = 1,         -- This effect specific
--
--          ticks_to_live = 3*60,       -- Mandatory
--          tick_started = game.tick    -- Mandatory
--      },
-- }

-- Iterate through all effects currently on player and add them to the player
function effects.apply_effects(arena, player)
    local surface = player.surface
    local vehicle = player.character.vehicle
    local player_state = arena.player_states[player.index]

    -- For every effect on this player
    for effect_type, effect in pairs(player_state.effects) do

        if effect_type == "speed" then
            vehicle.speed = vehicle.speed * (1 + effect.speed_modifier)            
            
            surface.create_entity{
                name = "fire-flame",
                type = "fire",
                position = player.position,
            }

            if game.tick > effect.tick_started + effect.ticks_to_live then
                player_state.effects["speed"] = nil
            end
        end

        -- Did this effect time out?
        if game.tick > effect.tick_started + effect.ticks_to_live then
            log("Removing "..effect_type.." from "..player.name)
            player_state.effects[effect_type] = nil    -- delete this entry in the effects table
        end

    end
end

-- Adds a table of effects to a player
-- If that effect is already given to the player, simply
-- extend the ticks_to_live
function effects.add_effect(arena, player, effects)
    local player_state = arena.player_states[player.index]
    for effect_type, effect in pairs(effects) do
        log("Adding "..effect_type.." to "..player.name)
        if player_state.effects[effect_type] then
            -- Player already has this effect applied. Extend the ticks_to_live
            effect.ticks_to_live = effect.ticks_to_live + player_state.effects[effect_type].ticks_to_live
        end
    
        -- Either way, overwrite the effect
        player_state.effects[effect_type] = util.copy(effect)
    end    
end

-- Removes all effects from a player
function effects.reset_effects(arena, player)
    local player_state = arena.player_states[player.index]
    player_state.effects = { }
end

return effects