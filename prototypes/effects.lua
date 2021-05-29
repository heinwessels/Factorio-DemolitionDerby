local util = require("scripts.wdd-util")

local size_modifier = 1.5

----------------------------------------------------------------------------------
-- Create the base effect beacon on which all actual implementations will be based
----------------------------------------------------------------------------------
data:extend({
    {
        type = "item",
        name = "wdd-effect-base",
        icon = "__base__/graphics/icons/coin.png",
        icon_size = 64, icon_mipmaps = 4,
        subgroup = "gun",
        order = "f[land-mine]",
        place_result = "wdd-effect-base",
        stack_size = 100
    },
    {
        type = "land-mine",
        name = "wdd-effect-base",
        icon = "__base__/graphics/icons/coin.png",
        icon_size = 64, icon_mipmaps = 4,
        flags =
        {
            "placeable-enemy",
            "placeable-off-grid"
        },
        minable = {mining_time = 0.5, result = "wdd-effect-base"},
        mined_sound = { filename = "__core__/sound/deconstruct-small.ogg" },
        max_health = 15,
        trigger_radius = 2.5,
        timeout = 0,    -- Immediatelly active
        corpse = nil,   -- Nothing is left when beacon activated
        collision_box = {{-size_modifier,-size_modifier}, {size_modifier, size_modifier}},
        selection_box = {{-size_modifier, -size_modifier}, {size_modifier, size_modifier}},
        picture_safe = {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-player.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = size_modifier,
        },
        picture_set = {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-player.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = size_modifier,
        },
        picture_set_enemy = {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-player.png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = size_modifier,
        },
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
                        effect_id = "wdd-effect-beacon"
                    }
                }
            }
        }
    },
})

----------------------------------------------------------------------------------
-- The function used to create new effects
----------------------------------------------------------------------------------
local function create_effect_beacon(config)
    -- type = "good" or "bad" or "bad-not-stripe" (will have a stripe overlay saying NOT)
    if string.match(config.name, "wdd-") then error("`wdd-` preposition added automatically.") end
    local name = "wdd-effect-"..config.name.."-"..config.target
    data:extend({
        util.merge{
            data.raw["item"]["wdd-effect-base"],
            {
                name = name,
                place_result = name,
                icon = config.icon,
            }
        },
        util.merge{
            data.raw["land-mine"]["wdd-effect-base"],
            {
                name = name,
                minable = {result = name},                
            }
        },
    })

    local picture = { layers = { } }

    table.insert(picture.layers, 
        {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-"..config.target..".png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = size_modifier,
        }
    )

    table.insert(picture.layers, config.picture)

    if not config.overlay then config.overlay = { } end
    for _, overlay in pairs(config.overlay) do
        table.insert(picture.layers, 
            {
                filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-overlay-"..overlay..".png",
                priority = "medium",
                width = 64,
                height = 64,
                scale = size_modifier,
            }
        )
    end

    data.raw["land-mine"][name].picture_safe = picture
    data.raw["land-mine"][name].picture_set = picture
    data.raw["land-mine"][name].picture_set_enemy = picture
end

-- Create this effect beacon for player and enemy
local function create_effect_beacon_for_both(config)
    config.target = "player"
    create_effect_beacon(config)
    config.target = "enemy"
    create_effect_beacon(config)
end

----------------------------------------------------------------------------------
-- Now create the effect beacons we want
----------------------------------------------------------------------------------


create_effect_beacon_for_both{
    name = "speed_up",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/car.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    },    
    type = "good",
}
create_effect_beacon_for_both{
    name = "tank",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/tank.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }
}
create_effect_beacon_for_both{
    name = "slow_down",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/slowdown-capsule.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    },
}
create_effect_beacon_for_both{
    name = "no_trail",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/wall.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier * 0.9,
    },
    overlay = {"not"},
}
create_effect_beacon_for_both{
    name = "full_trail",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/wall.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier * 0.9,
    },
}
create_effect_beacon_for_both{
    name = "worm",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/behemoth-worm.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }
}
create_effect_beacon_for_both{
    name = "biters",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/behemoth-biter.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }
}
create_effect_beacon{
    name = "artillery",
    target = "all",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/artillery-turret.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }
}
create_effect_beacon_for_both{
    name = "invert",
    icon = "__base__/graphics/icons/coin.png",
    picture = {
        filename = "__base__/graphics/icons/signal/signal_R.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }
}