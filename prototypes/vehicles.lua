util = require("util")

data:extend({
    ----------------------------------------------------------------------------------
    -- CAR
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["car"],
        {
            name = "curvefever-car",
            place_result = "curvefever-car",
        }
    },
    util.merge{
        data.raw["car"]["car"],
        {
            name = "curvefever-car",
            energy_source = {type = "void"},
            burner = nil,
            sound_no_fuel = nil,    -- We will never have fuel
            minable = {result = "curvefever-car"},
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
                    decrease = -5000  -- die instantly
                },
            },
        }
    },
})
data:extend({
    ----------------------------------------------------------------------------------
    -- CAR THAT CANNOT DRIVE
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["curvefever-car"],
        {
            name = "curvefever-car-static",
            place_result = "curvefever-car-static",
        }
    },
    util.merge{
        data.raw["car"]["curvefever-car"],
        {
            name = "curvefever-car-static",
            minable = {result = "curvefever-car"},
            
            -- Energy source with no fuel and no power icon
            energy_source = {
                type = "burner",
                render_no_power_icon = false,
                effectivity = 1,        -- DUMMY
                fuel_inventory_size = 1,-- DUMMY
            },

            collision_box = {{-0.45, -0.45}, {0.45, 0.45}},
        }
    },
    ----------------------------------------------------------------------------------
    -- TANK
    ----------------------------------------------------------------------------------
    util.merge{
        data.raw["item-with-entity-data"]["tank"],
        {
            name = "curvefever-tank",
            place_result = "curvefever-tank",
        }
    },
    util.merge{
        data.raw["car"]["tank"],
        {
            name = "curvefever-tank",
            energy_source = {type = "void"},
            burner = nil,
            minable = {result = "curvefever-tank"},
            max_health = 2000,
            resistances = {
                {
                    type = "electric",
                    percent = 0,
                    decrease = -5000  -- die instantly on border wall
                },
                {
                    type = "impact",
                    -- percent = 100,   -- Imune
                    percent = 50,       -- TODO Must still die when hit border until reaction is fixed
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
                    type = "physical",
                    percent = 100,  -- immune
                },
            },
        }
    },
})