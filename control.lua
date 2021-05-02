local World = require("scripts.world")
local Arena = require("scripts.arena")
local map_data = require("scripts.map_data")

-- Setup Handlers
script.on_event(defines.events.on_tick, function (event) 

    -- Have we set up what we want?
    if global.world == nil then
        global.world = { }
        global.world = World.create(global.world, map_data)
    end

    -- Update this world!
    World.on_tick(global.world, event) 
end)
script.on_event(defines.events.on_player_created, 
    function (event) World.player_entered(global.world, event) end
)
script.on_event(defines.events.on_script_trigger_effect, 
    function (event) World.on_script_trigger_effect(global.world, event) end
)
script.on_event(defines.events.on_player_driving_changed_state,
    function (event) World.on_player_driving_changed_state(global.world, event) end
)

-- -- It is possible to define the name and table inside the call
remote.add_interface("curvefever-interface", {
    -- the values can be only primitive type or (nested) tables
    
    start = function()
        Arena.start(global.world.arenas["achtung"])
    end,

    clean = function()
        Arena.clean(global.world.arenas["achtung"])
    end,

    reset = function()
        global.world = World.create(global.world)
    end
})

-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)