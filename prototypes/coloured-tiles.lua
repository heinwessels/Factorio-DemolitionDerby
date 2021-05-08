-- There is coloured concrete in vanilla!
-- https://factorio.com/blog/post/fff-335
-- Here I just give them items so I can create a blueprint using them
-- It's for the splashy boi. They will not be in the actual mod.

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

-- Now make some grass and stuff blueprint-able

local function create_item_for_tile(tile)
    data:extend({
        util.merge{
            data.raw["item"]["refined-concrete"],
            {
                name = tile,
                -- icon = "__base__/graphics/icons/"..colour.."-refined-concrete.png",
                place_as_tile = {
                    result = tile,
                    condition_size = 1,
                    condition = { "water-tile" }
                }
            }
        },
    })
end
for _, colour in pairs({
    "grass-1",
    "grass-2",
    "grass-3",
    "grass-4",
    "dry-dirt",
    "dirt-1",
    "dirt-2",
    "dirt-3",
    "dirt-4",
    "dirt-5",
    "dirt-6",
    "dirt-7",
    "sand-1",
    "sand-2",
    "sand-3",
    "red-desert-1",
    "red-desert-2",
    "red-desert-3",
    "tutorial-grid",
    "landfill",
    "nuclear-ground",
    "water-wube",
    "lab-white",
    "water-shallow",
    "water-mud",
}) do
    create_item_for_tile(colour)
end