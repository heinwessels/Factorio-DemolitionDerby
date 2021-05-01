local Arena = require("scripts.arena")

local arenas = nil

-- Setup Handlers
script.on_event(defines.events.on_tick, function (event)

    -- TODO This is a temporary hack. Remove it once
    -- mod is stable.
    -----------------------------------------------------------------------
    if global.script_data == nil then        
        if not global.script_data then
            global.script_data = { 
                arenas = { }
            }
        end
        arenas = global.script_data.arenas
    else
        arenas = global.script_data.arenas
    end
    -----------------------------------------------------------------------

    for _, arena in pairs(arenas) do
        Arena.update(arenas["test_arena"])
    end
end)

script.on_event(defines.events.on_player_created, function (event)
    -- TODO Set up player state here
end)

script.on_event(defines.events.on_script_trigger_effect, function (event)
    -- Send event to every arena
    for _, arena in pairs(arenas) do
        Arena.hit_effect_event(arena, event)
    end
end)

script.on_event(defines.events.on_player_driving_changed_state,
    function(event)

        -- TODO This should check first if it was in the lobby
        -- Remember, this event is fired for some effects too
        local player = game.get_player(event.player_index)
        Arena.add_player(arenas["test_arena"], player)

        if not event.entity then
            -- The player might have tried to climb out of his car.
            -- Maybe prevent him!
        end
    end
)

-- It is possible to define the name and table inside the call
remote.add_interface("curvefever-interface", {
    -- the values can be only primitive type or (nested) tables
    create = function()
        name = "test_arena"
        arenas[name] = Arena.create(
            name, 
            {{x=-142.5, y=48.8}, {x=309.5, y=295.5}}, 
            game.surfaces.nauvis
        )
    end,

    start = function()
        Arena.start(arenas["test_arena"])
    end,

    clean = function()
        Arena.clean(arenas["test_arena"])
    end,

    reset_all = function()
        arenas = { }
    end
})

-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)