data:extend({
    {
        type = "item",
        name = "curve-effect-base",
        icon = "__base__/graphics/icons/land-mine.png",
        icon_size = 64, icon_mipmaps = 4,
        subgroup = "gun",
        order = "f[land-mine]",
        place_result = "curve-effect-base",
        stack_size = 100
    },
    {
        type = "land-mine",
        name = "curve-effect-base",
        icon = "__base__/graphics/icons/land-mine.png",
        icon_size = 64, icon_mipmaps = 4,
        flags =
        {
            "placeable-player",
            "placeable-enemy",
            "player-creation",
            "placeable-off-grid",
            "not-on-map"
        },
        minable = {mining_time = 0.5, result = "land-mine"},
        mined_sound = { filename = "__core__/sound/deconstruct-small.ogg" },
        max_health = 15,
        corpse = "land-mine-remnants",
        dying_explosion = "land-mine-explosion",
        collision_box = {{-0.4,-0.4}, {0.4, 0.4}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        -- damaged_trigger_effect = hit_effects.entity(),
        -- open_sound = sounds.machine_open,
        -- close_sound = sounds.machine_close,
        picture_safe =
        {
            filename = "__CurveFever__/graphics/entities/effect-beacon/hr-land-mine.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = 0.5
        },
        picture_set =
        {
            filename = "__CurveFever__/graphics/entities/effect-beacon/hr-land-mine.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = 0.5
        },
        picture_set_enemy =
        {
            filename = "__CurveFever__/graphics/entities/effect-beacon/hr-land-mine.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = 0.5
        },
        trigger_radius = 2,
        ammo_category = "landmine",
        action =
        {
            type = "direct",
            action_delivery =
            {
                type = "instant",
                source_effects =
                {                    
                    {
                        type = "script",
                        effect_id = "curve-apply-effect"
                    }
                }
            }
        }
    },

})