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
                -- {
                --     type = "impact",
                --     percent = 100,
                -- },
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
                    -- how far the mirroring works
                    range = 2,
                    -- what kind of damage triggers the mirroring
                    -- if not present then anything triggers the mirroring
                    damage_type = "physical",
                    -- caused damage will be multiplied by this and added to the subsequent damages
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
                                -- always use at least 0.1 damage
                                damage = {amount = 0.1, type = "physical"}
                            }
                        }
                    },
                }
            },
        }
    },
  })