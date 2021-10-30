local util = require("scripts.wdd-util")

local size_modifier = 1.5

----------------------------------------------------------------------------------
-- Create the base effect beacon on which all actual implementations will be based
----------------------------------------------------------------------------------
data:extend({
    {
        type = "item",
        name = "wdd-effect-base",
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
        },
        resistances =
        {
            {
                type = "fire",
                percent = 100       -- immune
            },
            {
                type = "explosion",
                percent = 0,
                decrease = -5000  -- die instantly
            },
        },
    },
})

----------------------------------------------------------------------------------
-- The function used to create new effects
----------------------------------------------------------------------------------
local function create_effect_beacon(config)
    -- The morality will determine what colour circle will go 
    -- with which target ("player" or "enemy")
    -- config.morality = "good" [default] or "bad" or "neutral"

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

    -- Determine circle colour based on target and morality
    local morality = config.morality or "good"
    local color = "green"
    if morality == "neutral" then
        color = "blue"
    elseif (morality == "bad" and config.target == "player") or 
            (morality == "good" and config.target == "enemy") then
        color = "red"
    end

    -- Create the entity graphics
    local picture = { layers = { } }
    table.insert(picture.layers, 
        {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/effect-beacon-"..color..".png",
            priority = "medium",
            width = 64,
            height = 64,
            scale = size_modifier,
        }
    )
    for _, layer in pairs(config.picture) do
        if layer.width ~= layer.height then error("Graphic not square: <"..layer.filename..">") end
        table.insert(picture.layers, layer)
    end
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

    -- Create icon from picture data
    local icons = { }
    for _, layer in pairs(picture.layers) do
        -- we assueme that the layer graphic is square
        local scale = 32 / layer.width * (layer.icon_scale or 1)
        table.insert(icons, 
            {
                icon = layer.filename,
                icon_size = layer.width, -- we check that width==height
                scale = scale
            }
        )
    end
    data.raw["land-mine"][name].icons = icons
    data.raw["item"][name].icons = icons
    data.raw["item"][name].place_result = name
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
    picture = {
        {
            filename = "__DemolitionDerby__/graphics/entities/effect-beacon/speed-up-fire.png",
            priority = "medium",
            width = 256,
            height = 256,
            scale = size_modifier / 4,  -- Divide for larger tech icon
        },
        {
            filename = "__base__/graphics/technology/automobilism.png",
            priority = "medium",
            width = 256,
            height = 256,
            shift = {0.35, 0.35},
            scale = size_modifier / 4,  -- Divide for larger tech icon
        }
    },
}
create_effect_beacon_for_both{
    name = "tank",
    picture = {{
        filename = "__base__/graphics/technology/tank.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 1.2,
        icon_scale = 1.2
    }}
}
create_effect_beacon_for_both{
    name = "slow_down",
    picture = {{
        filename = "__base__/graphics/icons/slowdown-capsule.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier,
    }},
    morality = "bad",
}
create_effect_beacon_for_both{
    name = "no_trail",
    picture = {{
        filename = "__base__/graphics/icons/wall.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier * 0.8,
        icon_scale = 0.8
    }},
    overlay = {"not"},
    morality = "bad",
}
create_effect_beacon_for_both{
    name = "full_trail",
    picture = {{
        filename = "__base__/graphics/icons/wall.png",
        priority = "medium",
        width = 64,
        height = 64,
        scale = size_modifier * 0.8,
        icon_scale = 0.8
    }},
}
create_effect_beacon_for_both{
    name = "worm",
    picture = {{
        filename = "__DemolitionDerby__/graphics/entities/effect-beacon/worm.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 1.2,  -- Divide for larger tech icon
    }}
}
create_effect_beacon_for_both{
    name = "biters",
    picture = {{
        filename = "__DemolitionDerby__/graphics/entities/effect-beacon/biter.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 1.1,  -- Divide for larger tech icon
    }}
}
create_effect_beacon{
    name = "artillery",
    target = "all",
    picture = {{
        filename = "__base__/graphics/technology/artillery.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 1.1,
    }},
    morality = "neutral",
}
create_effect_beacon{
    name = "nuke",
    target = "all",
    picture = {{
        filename = "__base__/graphics/technology/atomic-bomb.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 1.1,  -- Divide for larger tech icon
    }},
    morality = "neutral",
}
create_effect_beacon_for_both{
    name = "invert",
    picture = {{
        filename = "__DemolitionDerby__/graphics/entities/effect-beacon/steering-wheel.png",
        priority = "medium",
        width = 256,
        height = 256,
        scale = size_modifier / 4 * 0.8,  -- Scale to make it slightly smaller
        icon_scale = 0.8
    },},
    morality = "bad",
}

-- Remove the base effect used to create all the real ones
data.raw["item"]["wdd-effect-base"] = nil
data.raw["land-mine"]["wdd-effect-base"] = nil

----------------------------------------------------------------------------------
-- Tweak a few game things so that it caters more for this minigame
----------------------------------------------------------------------------------

-- Just make artillery a little stronger
data.raw["artillery-projectile"]["artillery-projectile"].action.action_delivery.target_effects[1].action.radius = 5

-- A green flair for the nuke
data:extend({
    util.merge{
        data.raw["artillery-flare"]["artillery-flare"],
        {
            name = "nuke-flare",
            pictures = {
                filename = "__core__/graphics/shoot-cursor-green.png",
                priority = "low",
                width = 258,
                height = 183,
                frame_count = 1,
                scale = 1,
                flags = {"icon"}
            }
        }
    },
})