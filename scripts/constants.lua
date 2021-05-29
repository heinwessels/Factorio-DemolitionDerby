return {
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
        allow_single_player = true, -- TODO unused
        vehicle_speed = 0.3,
        starting_location_spacing = { 
            x = 40,
            y = 10
        },
        effect_density = 1/(50*50),     -- effects per area in tiles
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
    effects = {
        trail = {
            offset = 3,     -- Distance to draw behind the car
            period = 90,    -- Duty cycle period in ticks of drawing
            gap = 25,       -- Part of the duty cycle that should not be a trail
        },
        speed_up = {
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
        },
        artillery = {
            warm_up_time = 1*60,    -- How long before the shots start to fire
            shell_travel_time = 3*60,-- How long must the shells travel?
            period = 0.4*60,       -- Period at which to fire shots
            shots_per_sound = 5,    -- How many shots to fire for each sound played
            coverage_density = 1/(30*30), -- effects per area in tiles
        },
        invert = {
            ticks_to_live = 5*60,
        }
    },
}