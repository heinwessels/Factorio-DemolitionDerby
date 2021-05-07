return {
    single_player = true,  -- Debugging purposes, for I am but one person
    splash = {
        enabled = false,
        duration = 5*60,        -- Time splash should be shown
        transition = 2*60,      -- Transition from splash to spawn
    },
    round = {
        pre_wait = 3*60,    -- After lobby added players, when should game start
        post_wait = 3*60,   -- How long after a match ended should game start
    },
    trail = {
        offset = 3,     -- Distance to draw behind the car
        period = 90,    -- Duty cycle period in ticks of drawing
        gap = 25,       -- Part of the duty cycle that should not be a trail
    },
    vehicle_speed = 0.3,
    effects = {
        speed = {
            fire_freq = 5,  -- Every how many ticks should fire be spawned
        },
        worm = {
            spacing = 2.5,
        },
        biters = {
            spacing = 2,
            amount = 5,
        }
    },
    arena = {           -- Constants used in an arena
        starting_location_spacing = 20,
        effect_density = 1/(50*50),     -- effects per area in tiles
    },
    lobby = {
        countdown = 1*60,      -- How long does it countdown before start
    },
}