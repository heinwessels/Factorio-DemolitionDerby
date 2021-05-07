-- There is coloured concrete in vanilla!
-- https://factorio.com/blog/post/fff-335
-- Here I just give them items so I can create a blueprint using them
-- It's for the splashy boi

local function create_coloured_concrete(colour)
    data:extend({
        util.merge{
            data.raw["item"]["refined-concrete"],
            {
                name = colour.."-refined-concrete",
                -- icon = "__base__/graphics/icons/"..colour.."-refined-concrete.png",
                place_as_tile = {
                    result = colour.."-refined-concrete",
                    condition_size = 1,
                    condition = { "water-tile" }
                }
            }
        },
    })
end

for _, colour in pairs({
    "red",
    "acid",
    "black",
    "blue",
    "brown",
    "cyan",
    "green",
    "orange",
    "pink",
    "purple",
    "red",
    "yellow"
}) do
    create_coloured_concrete(colour)
end

