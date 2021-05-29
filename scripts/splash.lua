local wdd_util = require("scripts.wdd-util")
local constants = require("scripts.constants")

local Splash = { }



-- Show some player the splash screen
function Splash.show(world, player) 
    if not constants.splash.enabled then return end
    if not world.splash then return end
    
    -- There is a splash screen! Show it boooi!
    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints =
        {
            {
                position = {
                    world.splash.position.x,
                    world.splash.position.y
                },
                transition_time = constants.splash.duration,
                time_to_wait = 0,
                zoom = world.splash.zoom,
            },
            {
                target = player.character,
                transition_time = constants.splash.transition,
                zoom = 0.5,
                time_to_wait = 0
            },
            {
                target = player.character,
                transition_time = 0.5*60,
                zoom = 1,
                time_to_wait = 0
            }
        },
        start_position = world.splash.position,
        start_zoom = world.splash.zoom*0.9
    }
end

return Splash