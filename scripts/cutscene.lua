local constants = require("scripts.constants")

local Cutscene = { }

-- This function will smootly transition the player camera from
-- where he is currently to the new position. Fields in config are:
-- player
-- start_position:  Can be nil, then player.position will be used
-- end_position:    Can be nil, then player.position will be used
-- start_zoom:      Can be nil, then player.zoom will be used
-- end_zoom:        CANNOT BE NIL
-- duration:        in ticks. Cannot be nil
function Cutscene.transition_to(tbl)
    if not tbl.duration then error("Cutscene need duration") end
    local position = tbl.end_position
    if not position then position = tbl.player.position end

    tbl.player.set_controller {
        type = defines.controllers.cutscene,
        waypoints =
        {            
            {
                position = position,
                transition_time = tbl.duration*0.9,
                zoom = tbl.end_zoom,
                time_to_wait = 0
            },
        },
        start_position = tbl.start_position,
        start_zoom = tbl.start_zoom
    }
end

return Cutscene