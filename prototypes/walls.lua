data:extend({
    
    -- TRAIL    
    util.merge{
        data.raw["wall"]["stone-wall"],
        {
            name = "curvefever-trail",
        }
    },

    -- BORDER
    util.merge{
        data.raw["item"]["stone-wall"],
        {
            name = "curvefever-border",
            place_result = "curvefever-border",
        }
    },
    util.merge{
        data.raw["wall"]["stone-wall"],
        {
            name = "curvefever-border",
            minable = {result = "curvefever-border"},
            max_health = 100000000,
            resistances = {
                {
                    type = "fire",
                    percent = 100
                },
                {
                    type = "impact",
                    percent = 100,
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

                    -- TODO Get this to actually work!
                    -- TODO Add some cool effects?
                    range = 2,
                    -- damage_type = "impact",       -- Damage that triggers the reaction
                    reaction_modifier = 100000000,
                    action =
                    {
                        type = "direct",
                        action_delivery =
                        {
                            type = "instant",
                            target_effects =
                            {                                
                                type = "damage",
                                damage = {amount = 1000000, type = "electric"}
                            }
                        }
                    },
                }
            },
        }
    },
  })