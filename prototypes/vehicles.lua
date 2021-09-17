util = require("util")

data:extend({
    ----------------------------------------------------------------------------------
    -- CAR
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["car"],
        {
            name = "wdd-car",
            place_result = "wdd-car",
        }
    },
    util.merge{
        data.raw["car"]["car"],
        {
            name = "wdd-car",
            energy_source = {type = "void"},
            minable = {result = "wdd-car"},
            alert_when_damaged = false,
            max_health = 100,
            resistances = {
                {
                    type = "fire",
                    percent = 100       -- immune
                },
                {
                    type = "acid",
                    percent = 0,
                    decrease = -5000  -- die instantly
                },
                {
                    type = "impact",
                    percent = 0,
                    decrease = -5000  -- die instantly
                },
                {
                    type = "physical",
                    percent = 0,
                    decrease = -5000  -- die instantly
                },
                {
                    type = "electric",
                    percent = 0,
                    decrease = -5000  -- die instantly on border wall
                },
                {
                    type = "explosion",
                    percent = 0,
                    decrease = -5000  -- die instantly
                },
            },
        }
    },
})
data.raw.car["wdd-car"].sound_no_fuel = nil    -- We will never have fuel. disable the sound
data:extend({
    ----------------------------------------------------------------------------------
    -- CAR THAT CANNOT DRIVE
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["wdd-car"],
        {
            name = "wdd-car-static",
            place_result = "wdd-car-static",
        }
    },
    util.merge{
        data.raw["car"]["wdd-car"],
        {
            name = "wdd-car-static",
            minable = {result = "wdd-car"},
            
            -- Energy source with no fuel and no power icon
            energy_source = {
                type = "burner",
                render_no_power_icon = false,
                effectivity = 1,        -- DUMMY
                fuel_inventory_size = 1,-- DUMMY
            },
        }
    },
    ----------------------------------------------------------------------------------
    -- TANK
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["tank"],
        {
            name = "wdd-tank",
            place_result = "wdd-tank",
        }
    },
    util.merge{
        data.raw["car"]["tank"],
        {
            name = "wdd-tank",
            energy_source = {type = "void"},
            burner = nil,
            minable = {result = "wdd-tank"},
            alert_when_damaged = false,
            max_health = 2000,
            resistances = {
                {
                    type = "electric",
                    percent = 0,
                    decrease = -5000  -- die instantly on border wall
                },
                {
                    type = "impact",
                    percent = 100,   -- Imune
                },
                {
                    type = "fire",
                    percent = 100     -- immune
                },
                {
                    type = "acid",
                    percent = 100,  -- immune
                },
                {
                    type = "poison",
                    percent = 100,  -- immune
                },
                {
                    type = "explosion",
                    percent = 100,  -- immune
                },
                {
                    type = "physical",
                    percent = 100,  -- immune
                },
            },
        }
    },    
})

----------------------------------------------------------------------------------
-- Create versions for both car and tank with inverted driving
----------------------------------------------------------------------------------
data:extend({
    util.merge{
        data.raw["car"]["wdd-car"],
        {
            name = "wdd-car-inverted",
            rotation_speed = -data.raw.car["wdd-car"].rotation_speed
        }
    },
    util.merge{
        data.raw["car"]["wdd-tank"],
        {
            name = "wdd-tank-inverted",
            rotation_speed = -data.raw.car["wdd-tank"].rotation_speed
        }
    },
})