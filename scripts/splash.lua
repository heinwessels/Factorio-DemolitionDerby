local wdd_util = require("scripts.wdd-util")
local constants = require("scripts.constants")

local Splash = { }

-- Returns true if player if we think
-- the player is watching the splash
function Splash.is_watching(player)
    return (player.gui.screen.skip_cutscene_label and true) or false
end

-- Add's a little label at the bottom of the screen
-- saying you can skip the intro cutscene with tab
-- NOTE: We use this label to know the player is
-- watching the splash
function Splash.create_skip_label(player)

    -- First make sure there isn't some left over label
    Splash.destroy_label(player)

    -- Create the label
    local label = player.gui.screen.add{
        type = "label", 
        caption = {"skip-cutscene"}, 
        name = "skip_cutscene_label"
    }

    -- Set size
    label.style.horizontal_align = "center"
    local resolution = player.display_resolution
    label.style.width = resolution.width / player.display_scale
    label.location = {0, (resolution.height) - ((20 + 8) * player.display_scale)}
end

-- Remove the skip label. We use this label
-- to know if the player is watching the splash
function Splash.destroy_label(player)
    if player.gui.screen.skip_cutscene_label then
        player.gui.screen.skip_cutscene_label.destroy()
    end
end

-- All ends of splash will end here.
function Splash.cancel_if_watching(player)
    if Splash.is_watching(player) then
        -- This player was busy watching the splash. Cancel it safely
        if player.controller_type == defines.controllers.cutscene then
            player.exit_cutscene()
        end

        -- Remove the label too
        Splash.destroy_label(player)

        -- Welcome the player
        player.print({"general.welcome-msg"})
    end
end

-- This will be called on every splash, portal and transition
-- to/from arena, but this is only to remove the skip splash
-- label. First determine if the player is actually watching
-- the splash, and then if it's the last waypoint that's reached.
function Splash.on_cutscene_waypoint_reached(event)    
    if event.player_index ~= 1 then return end
    local player = game.get_player(event.player_index)
    if not Splash.is_watching(player) then return end
    -- Player is watching splash. If he reached the 
    -- last waypoint then remove the label    
    -- NOTE: For some reason returned index starts at 0? Hence -1
    if event.waypoint_index == Splash.number_of_waypoints-1 then
        Splash.cancel_if_watching(player)
    end
end

-- Show some player the splash screen
function Splash.show(world, player) 
    if not constants.splash.enabled then return end
    if not world.splash then return end
    
    -- Tell the player he can skip it if he wants
    Splash.create_skip_label(player)

    -- Create the waypoints
    local splash = world.splash
    local waypoints = {
        {
            position = {
                splash.position.x - splash.travel.x/2,
                splash.position.y - splash.travel.y/2
            },
            time_to_wait = constants.splash.duration / 2,
            transition_time = constants.splash.duration / 2,
            time_to_wait = 0,
            zoom = splash.zoom,
        },
        {
            position = {
                splash.position.x + splash.travel.x/2,
                splash.position.y + splash.travel.y/2
            },
            transition_time = constants.splash.duration / 2,
            time_to_wait = 0,
            zoom = splash.zoom,
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
    }
    Splash.number_of_waypoints = #waypoints

    -- There is a splash screen! Show it boooi!
    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        start_position = splash.position,
        start_zoom = splash.zoom*0.9
    }
end

return Splash