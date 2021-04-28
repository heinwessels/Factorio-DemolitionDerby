----------------------------------------------------------------------------------
-- Create the base effect beacon on which all actual implementations will be based
----------------------------------------------------------------------------------
data:extend({
    {
        type = "item",
        name = "curvefever-effect-base",
        icon = "__base__/graphics/icons/coin.png",
        icon_size = 64, icon_mipmaps = 4,
        subgroup = "gun",
        order = "f[land-mine]",
        place_result = "curvefever-effect-base",
        stack_size = 100
    },
    {
        type = "land-mine",
        name = "curvefever-effect-base",
        icon = "__base__/graphics/icons/coin.png",
        icon_size = 64, icon_mipmaps = 4,
        flags =
        {
            "placeable-enemy",
            "placeable-off-grid"
        },
        minable = {mining_time = 0.5, result = "curvefever-effect-base"},
        mined_sound = { filename = "__core__/sound/deconstruct-small.ogg" },
        max_health = 15,
        corpse = "land-mine-remnants",
        -- dying_explosion = "land-mine-explosion",
        collision_box = {{-0.8,-0.8}, {0.8, 0.8}},
        selection_box = {{-1, -1}, {1, 1}},        
        picture_safe =
        {
            layers = {
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-bad-not.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },
            }
        },
        picture_set =
        {
            layers = {
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-bad-not.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },
            }            
        },
        picture_set_enemy =
        {
            layers = {
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-bad-not.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },
            }  
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
                        effect_id = "curvefever-effect-beacon"
                    }
                }
            }
        }
    },
})

----------------------------------------------------------------------------------
-- The function used to create new effects
----------------------------------------------------------------------------------
function create_effect_beacon(name, icon, picture, type)
    -- type = "good" or "bad" or "bad-not-stripe" (will have a stripe overlay saying NOT)
    if string.match(name, "curvefever-") then error("`curvefever-` preposition added automatically.") end
    name = "curvefever-effect-"..name
    data:extend({
        util.merge{
            data.raw["item"]["curvefever-effect-base"],
            {
                name = name,
                place_result = name,
                icon = icon,
            }
        },
        util.merge{
            data.raw["land-mine"]["curvefever-effect-base"],
            {
                name = name,
                minable = {result = name},                
            }
        },
    })

    if type == "good" then
        picture = {
            layers = {
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-good.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },
                picture,
            }
        }
    elseif type == "bad" then
        picture = {
            layers = {
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-bad.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },
                picture,
            }
        }
    elseif type == "bad-not" then
        picture = {
            layers = {
                picture,
                {
                    filename = "__CurveFever__/graphics/entities/effect-beacon/effect-beacon-bad-not.png",
                    priority = "medium",
                    width = 64,
                    height = 64,
                },                
            }
        }
    end

    data.raw["land-mine"][name].picture_safe = picture
    data.raw["land-mine"][name].picture_set = picture
    data.raw["land-mine"][name].picture_set_enemy = picture
end

----------------------------------------------------------------------------------
-- Now create the effect beacons we want
----------------------------------------------------------------------------------
create_effect_beacon(
    "speed",
    "__base__/graphics/icons/coin.png",
    {
        filename = "__base__/graphics/icons/car.png",
        priority = "medium",
        width = 64,
        height = 64,
    },
    "good"
)
create_effect_beacon(
    "tank",
    "__base__/graphics/icons/coin.png",
    {
        filename = "__base__/graphics/icons/tank.png",
        priority = "medium",
        width = 64,
        height = 64,
    },
    "good"
)
create_effect_beacon(
    "slowdown",
    "__base__/graphics/icons/coin.png",
    {
        filename = "__base__/graphics/icons/slowdown-capsule.png",
        priority = "medium",
        width = 64,
        height = 64,
    },
    "bad"
)
create_effect_beacon(
    "no-trail",
    "__base__/graphics/icons/coin.png",
    {
        filename = "__base__/graphics/icons/wall.png",
        priority = "medium",
        width = 64,
        height = 64,
    },
    "bad-not"
)