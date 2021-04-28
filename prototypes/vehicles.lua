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
            minable = {result = "curvefever-car"},
            resistances = {
                {
                  type = "fire",
                  percent = 100
                },
                {
                  type = "impact",
                  percent = 0,
                  decrease = -5000  -- die instantly
                },
            },
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
                  type = "fire",
                  percent = 100
                },
                {
                  type = "impact",
                  percent = 99,
                },
            },
        }
    },
})