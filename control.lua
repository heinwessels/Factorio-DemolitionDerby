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
        -- Start a game when someone enters a vechicle
        -- TODO Just not good enough yo
        arena.create(nil)  -- TODO Contain area
        arena.init(game.players)
        arena.start()
    end
)

-- TO USE DEBUGGER LOG
-- require('__debugadapter__/debugadapter.lua')
-- __DebugAdapter.print(expr,alsoLookIn)