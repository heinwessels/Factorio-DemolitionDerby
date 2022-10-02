local World = require("scripts.world")
local Arena = require("scripts.arena")
local map_data = require("scripts.map_data")

-- Setup Handlers
script.on_event(defines.events.on_tick, function (event) 
    -- Update this world!
    World.on_tick(global.world, event) 
end)

script.on_init(function (event) 
    World.verify()

    global.world = { }  -- Placeholder
    World.create(global.world, map_data)
end)

script.on_configuration_changed(
    function (event) World.verify() World.on_configuration_changed(event) end
)
script.on_event(defines.events.on_player_joined_game, 
    function (event) World.on_player_entered(global.world, event) end
)
script.on_event(defines.events.on_player_left_game,
    function (event) World.on_player_left(global.world, event) end
)
script.on_event(defines.events.on_player_driving_changed_state,
    function (event) World.on_player_driving_changed_state(global.world, event) end
)
script.on_event(defines.events.on_script_trigger_effect, 
    function (event) World.on_script_trigger_effect(global.world, event) end
)
script.on_event(defines.events.on_entity_destroyed,
    function (event) World.on_entity_destroyed(global.world, event) end
)
script.on_event(defines.events.on_cutscene_waypoint_reached,
    function (event) World.on_cutscene_waypoint_reached(global.world, event) end
)
script.on_event("crash-site-skip-cutscene",
    function (event) World.on_skip_cutscene(global.world, event) end
)

-- It is possible to define the name and table inside the call
remote.add_interface("wdd", {
    -- the values can be only primitive type or (nested) tables
    
    enable = function (enable)
        World.enable(global.world, enable)
    end,

    clean = function()
        World.clean(global.world)
    end,

    editor = function(enable)
        if enable == nil then enable = true end
        for _, player in pairs(game.players) do
            player.game_view_settings.show_controller_gui = enable
            player.game_view_settings.show_research_info = enable
            player.game_view_settings.show_minimap = enable
        end
    end,

    -- TODO Add way to change constants. And change constants to config.
    -- Config stored in global. Can be reset to defaults

    load = function(map_data_in)
        if map_data_in == nil then map_data_in = map_data end
        global.world = World.create(global.world, map_data_in)
    end,

    reset = function()
        global.world = World.reset(global.world)        
        global.world = nil
    end
})

-- Some nice commands
-- /editor remote.call("wdd", "editor")
-- /c remote.call("wdd", "clean")