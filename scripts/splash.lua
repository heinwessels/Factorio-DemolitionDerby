local wdd_util = require("scripts.wdd-util")
local constants = require("scripts.constants")

local Splash = {
    -- I store this here because the `on_cutscene_waypoint_reached`
    -- can be called when a player is joining, and the Splash waypoits
    -- is not setup yet. Whhhhhyyyy though, I need to go sleep
    number_of_waypoints = 4
}

function Splash.create(world)
    -- To keep track of players watching
    global.splash = global.splash or { players = {} }
end

-- Returns true if player if we think
-- the player is watching the splash
function Splash.is_watching(player)
    return global.splash.players[player.index]
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

        -- Remember player is no longer watching
        global.splash.players[player.index] = nil

        -- Remove the label too
        Splash.destroy_label(player)

        -- Welcome the player
        player.print({"wdd.welcome-msg"})

        -- Custom RedMew support to show that they are hosting.
        if remote.interfaces["redmew"] and remote.interfaces["redmew"]["active"] then
            player.print({"wdd.welcome-msg-redmew"})
        end
    end
end

-- This will be called on every splash, portal and transition
-- to/from arena, but this is only to remove the skip splash
-- label. First determine if the player is actually watching
-- the splash, and then if it's the last waypoint that's reached.
function Splash.on_cutscene_waypoint_reached(event)        
    local player = game.get_player(event.player_index)
    if not Splash.is_watching(player) then return end
    local splash_data = global.splash.players[player.index]
    if not splash_data then return end
    
    -- Player is watching splash. If he reached the 
    -- last waypoint then remove the label    
    -- NOTE: For some reason returned index starts at 0. Hence -1
    -- Bug report [Won't fix]: https://forums.factorio.com/viewtopic.php?f=58&t=99926&p=552385#p552385
    if event.waypoint_index == #splash_data.waypoints-1 then
        Splash.cancel_if_watching(player)
    end
end

-- Show some player the splash screen
function Splash.show(world, player) 
    if not constants.splash.enabled then return end
    if not world.splash then return end

    -- Tell the player he can skip it if he wants
    Splash.create_skip_label(player)

    -- Aim the waypoints at this particular player
    -- Create the waypoints
    local splash = world.splash
    local waypoints = {
        {
            position = {
                splash.position.x + splash.travel.x/2,
                splash.position.y + splash.travel.y/2
            },
            time_to_wait = constants.splash.duration / 2,
            transition_time = constants.splash.duration / 2,
            time_to_wait = 0,
            zoom = splash.zoom,
        },
        {
            position = {
                splash.position.x - splash.travel.x/2,
                splash.position.y - splash.travel.y/2
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

    -- There is a splash screen! Show it boooi!
    player.set_controller {
        type = defines.controllers.cutscene,
        waypoints = waypoints,
        start_position = world.splash.position,
        start_zoom = world.splash.zoom * 0.9
    }

    -- Remember player is watching. Only do this after
    -- everything is setup so that the event isn't
    -- called with a broken Splash
    global.splash.players[player.index] = { waypoints = waypoints }
end

return Splash