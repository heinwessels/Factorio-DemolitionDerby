local arena = require("scripts.arena")

function ontick_event (event)

    arena.update()
end
script.on_event(defines.events.on_tick, ontick_event)

script.on_event(defines.events.on_player_created, function (event)
    -- TODO Set up player state here
end)

script.on_event(defines.events.on_script_trigger_effect, function (event)
    arena.hit_effect_event(event)
end)

script.on_event(defines.events.on_player_driving_changed_state,
    function(event)

        -- TODO This should check first if it was in the lobby
        -- Remember, this event is fired for some effects too
        local player = game.get_player(event.player_index)
        arena.add_player(player)

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
        arena.create("test_arena", nil)  -- TODO Contain area
    end,

    start = function()
        arena.start()
    end,
})

-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)