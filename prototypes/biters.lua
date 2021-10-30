local util = require("scripts.wdd-util")

data:extend({
    
    -- My own biters that the player spawns
    util.merge{
        data.raw["unit"]["behemoth-biter"],
        {
            name = "wdd-biter",
            resistances = {
                {
                    type = "physical",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "fire",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "explosion",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "poison",
                    decrease = -5000,   -- Die instantly in vehicle explosions
                }
            },
        }
    },

    -- Make my own worm
    util.merge{
        data.raw["turret"]["behemoth-worm-turret"],
        {
            name = "wdd-worm",
            resistances = {                
                {
                    type = "fire",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "explosion",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "poison",
                    decrease = -5000,   -- Die instantly in vehicle explosions
                },
                {
                    type = "poison",
                    decrease = -5000,   -- Die instantly in vehicle explosions
                }
            },
        }
    },

})