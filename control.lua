
local game_state = {
    players = { 
        -- Tables with key of player_index
        -- {
        --     effects = { }
        -- }
    }
}

function ontick_event (event)

    local player = game.players[1]  -- This is not right. Do the loopy
    
    if not game_state.players[player.index] then
        game_state.players[player.index] = { }
    end
    local player_state = game_state.players[player.index]
    
    local surface = player.surface
    local trail_delay = 3    
    
    if not player.character then return end       
    
    if game.tick % 120 then
        if player.driving then
            
            local vehicle = player.character.vehicle


            vehicle.speed = 0.3
            if player_state.effects then

                if player_state.effects["speed"] then
                    local speed_effect = player_state.effects["speed"]
    
                    vehicle.speed = vehicle.speed * (1 + speed_effect.speed_modifier)

                    if game.tick > speed_effect.tick_started + speed_effect.ticks_to_live then
                        player_state.effects["speed"] = nil
                        game.print("Effect done")
                    end
                end
    
            end
            

            local orientation = vehicle.orientation * 2 * math.pi
            local position = {
                x = vehicle.position.x - trail_delay*math.sin(orientation),
                y = vehicle.position.y + trail_delay*math.cos(orientation),
            }
            local e = surface.find_entity(
                "curve-trail",
                position
            )
            if not e then 
                surface.create_entity{
                    name = "curve-trail",
                    type = "wall",
                    position = position,
                    create_build_effect_smoke = true,
                }
            end
        end
    end
end
script.on_event(defines.events.on_tick, ontick_event)

script.on_event(defines.events.on_player_created, function (event)
    -- TODO Set up player state here
end)

script.on_event(defines.events.on_script_trigger_effect, function (event)
    local surface = game.get_surface(event.surface_index)
    local entity = event.source_entity
    local vehicle_in_range = surface.find_entities_filtered{
        position = entity.position,
        radius = 6,
        name = "car",
        type = "car",
        limit = 1, -- TODO HANDLE MORE!
    }
    local player = nil
    if vehicle_in_range then 
        player = vehicle_in_range[1].last_user  -- TODO is this good enough?
        
        if not game_state.players[player.index] then 
            game_state.players[player.index] = { }
        end
        local player_state = game_state.players[player.index]

        player_state["effects"] = { }
        player_state["effects"]["speed"] = {
            speed_modifier = 0.5,
            ticks_to_live = 3*60,
            tick_started = game.tick
        }
        game.print("Got speed!")

    end

end)



-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)