return {
    splash = {
        enabled = true,
        duration = 7*60,        -- Time splash should be shown
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
        effect_spawn_chance = 2*60,     -- A effect will be spawned every n-ticks on average
        effect_density = 1/(50*50),     -- effects per area in tiles        
        start_zoom = 0.5,
        timing = {
            ["transition-pre"] = 1.5*60,   -- Cutscene from lobby to arena
            ["post-wait"] = 3*60,   -- Little period after the round ended            
        },
        frequency = {
            effect_entity = 10,     -- How often effect entities are polled to possibly be spawned
        },
    },
    effects = {
        trail = {
            offset = 3,     -- Distance to draw behind the car
            period = 90,    -- Duty cycle period in ticks of drawing
            gap = 25,       -- Part of the duty cycle that should not be a trail
            ignore = true,  -- ingore in gui and manual spawning
        },
        no_trail = {
            ticks_to_live = 5*60,
        },
        full_trail = {
            ticks_to_live = 5*60,
        },
        speed_up = {
            speed_modifier = 1.8,
            fire_freq = 5,  -- Every how many ticks should fire be spawned
            ticks_to_live = 4*60,
            probability = 2,
        },
        tank = {
            speed_modifier = 0.55,
            ticks_to_live = 10*60,
            probability = 2,
        },
        slow_down = {
            speed_modifier = 0.55,
            ticks_to_live = 5*60,
            probability = 2,
        },
        worm = {
            spacing = 2.5,
            ticks_to_live = 13*60,  -- How long should the worm live?
            probability = 2,
        },
        biters = {
            period = 0.25*60,       -- Every how long should a biter be released
            biters_to_spawn = 5,
            biter_life_ticks = 10*60,-- How long should biters live
            offset = 4,             -- How far behind vehicle should they spawn
            speed_modifier = 1,     -- Relative to player speed
            ticks_to_live = 10*60, 
            probability = 2,
        },
        artillery = {
            warm_up_time = 1*60,    -- How long before the shots start to fire
            shell_travel_time = 3*60,-- How long must the shells travel?
            period = 0.4*60,       -- Period at which to fire shots
            shots_per_sound = 5,    -- How many shots to fire for each sound played
            coverage_density = 1/(30*30), -- effects per area in tiles
            ticks_to_live = 10*60,  -- Just some maximum amount of time to live
            probability = 2,
        },
        nuke = {
            warm_up_time = 3*60,    -- How long before the shot is fired
            shell_travel_time = 3*60,
            player_proximity = 20,   -- How close nuke will drop to player
            ticks_to_live = 6*60            
        },
        invert = {
            ticks_to_live = 5*60,
            probability = 2,
        }
    },
}