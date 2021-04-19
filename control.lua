
function creation_event (event)        
    
end

script.on_event(defines.events.on_built_entity, creation_event)
script.on_event(defines.events.on_robot_built_entity, creation_event)
script.on_event(defines.events.script_raised_built, creation_event)
script.on_event(defines.events.script_raised_revive, creation_event)
script.on_event(defines.events.on_robot_built_entity, creation_event)

function removal_event (event)
   
end

script.on_event(defines.events.on_player_mined_entity, removal_event)
script.on_event(defines.events.on_robot_mined_entity, removal_event)
script.on_event(defines.events.on_entity_died, removal_event)
script.on_event(defines.events.script_raised_destroy, removal_event)

function ontick_event (event)

    local player = game.players[1]
    local surface = player.surface
    local trail_delay = 3    
    
    if not player.character then return end       
    
    if game.tick % 120 then
        if player.driving then
            
            local vehicle = player.character.vehicle
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
                }
            end
        end
    end
end
script.on_event(defines.events.on_tick, ontick_event)

-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)