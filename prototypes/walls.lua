data:extend({
    
    -- TRAIL    
    util.merge{
        data.raw["wall"]["stone-wall"],
        {
            name = "wdd-trail",
            resistances = {
                {
                    type = "physical",
                    decrease = 3,
                    percent = 20
                },
                {
                    type = "impact",
                    decrease = 45,
                },
                {
                    type = "fire",
                    percent = 100
                },
                {
                    type = "explosion",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "laser",
                    decrease = -5000,   -- Die instantly
                },
                {
                    type = "acid",
                    percent = 100,      -- immune
                },
            },
        }
    },

    -- BORDER
    util.merge{
        data.raw["item"]["stone-wall"],
        {
            name = "wdd-border",
            place_result = "wdd-border",
        }
    },
    util.merge{
        data.raw["wall"]["stone-wall"],
        {
            name = "wdd-border",
            minable = {result = "wdd-border"},
            max_health = 1000000000,
            resistances = {
                {
                    type = "fire",
                    percent = 100
                },
                {
                    type = "impact",
                    -- Immunity cannot be 100%
                    -- otherwise attack_reaction won't 
                    -- trigger
                    percent = 99,
                },
                {
                    type = "explosion",
                    percent = 100,
                },
                {
                    type = "laser",
                    percent = 100,
                },
                {
                    type = "acid",
                    percent = 100,
                },
                {
                    type = "physical",
                    percent = 100,
                },
            },
            attack_reaction =
            {
                {
                    -- Damage players that hit the wall immensly
                    -- Using electricity because it sounds cool
                    -- This means that tanks can be resistant to
                    -- impacts, but still die at the border wall.
                    range = 2,
                    action = {
                        type = "direct",
                        action_delivery = {
                            type = "instant",
                            target_effects = {
                                type = "damage",
                                damage = {
                                    amount = 5000,
                                    type = "electric"
                                }
                            },                            
                        }
                    },                    
                }
            },
        }
    },
  })