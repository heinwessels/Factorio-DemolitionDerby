local util = require("scripts.curvefever-util")

data:extend({
    
    -- My own biters that the player spawns
    util.merge{
        data.raw["unit"]["behemoth-biter"],
        {
            name = "weasel-biter",
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
                }
            },
        }
    },

})