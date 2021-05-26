return {
    single_player = true,  -- Debugging purposes, for I am but one person
    editor = false,         -- Basically returns the toolbars if set to true
    splash = {
        enabled = false,
        duration = 5*60,        -- Time splash should be shown
        transition = 2*60,      -- Transition from splash to spawn
    },
    lobby = {
        timing = {
            countdown = 0.5*60,      -- Time buffer from when arena is booked, and new players can jump in
            portal_cutscene = 0.5*60,        -- Duration of cutscene. Nill to disable
        },
        frequency = {   -- every <n> ticks
            portals = 15,           -- Refresh
            players_ready = 30,     -- Check players ready
            gui_refresh = 60,       -- GUI refresh rate
        },
    },
    round = {        
    },
    arena = {           -- Constants used in an arena
        starting_location_spacing = 20,
        effect_density = 1/(45*45),     -- effects per area in tiles
        start_zoom = 0.4,
        
        timing = {
            ["transition-pre"] = 1.5*60,   -- Cutscene from lobby to arena
            ["countdown"] = 3*60,
            ["post-wait"] = 2*60,   -- Little period after the round ended            
        },
        frequency = {
            effect_entity = 10,     -- How often effect entities are polled
        },
    },    
    vehicle_speed = 0.3,
    effects = {
        trail = {
            offset = 3,     -- Distance to draw behind the car
            period = 90,    -- Duty cycle period in ticks of drawing
            gap = 25,       -- Part of the duty cycle that should not be a trail
        },
        speed = {
            fire_freq = 5,  -- Every how many ticks should fire be spawned
        },
        worm = {
            spacing = 2.5,
            ticks_to_live = 13*60,  -- How long should the worm live?
        },
        biters = {
            period = 0.25*60,       -- Every how long should a biter be released
            ticks_to_live = 1.5*60, -- This will determine how many biters will spawn
            biter_life_ticks = 8*60,-- How long should biters live
            offset = 4,             -- How far behind vehicle should they spawn
            speed_modifier = 0.9,   -- Relative to player speed
        }
    },
}