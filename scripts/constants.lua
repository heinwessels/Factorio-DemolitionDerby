return {
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
        biters = {
            spacing = 4,
            amount = 5,
        }
    },
    arena = {           -- Constants used in an arena
        starting_location_spacing = 20,
        effect_density = 1/(50*50),     -- effects per area in tiles
    },
}