require("prototypes.effects")
require("prototypes.vehicles")
require("prototypes.walls")
require("prototypes.biters")
require("prototypes.gui-styles")
require("prototypes.sound")
require("prototypes.fonts")
require("prototypes.tips-and-tricks")

-- require("prototypes.coloured-tiles")  -- Only used when blueprinting splash


-- Character needs to be immune to everything, because we don't
-- want it to die by accident when flung out of it's vehicle.
data.raw.character.character.resistances = {
    {
        type = "fire",
        percent = 100       -- immune
    },
    {
        type = "poison",
        percent = 100       -- immune
    },
    {
        type = "acid",
        percent = 100       -- immune
    },
    {
        type = "impact",
        percent = 100       -- immune
    },
    {
        type = "physical",
        percent = 100       -- immune
    },
    {
        type = "electric",
        percent = 100       -- immune
    },
    {
        type = "explosion",
        percent = 100       -- immune
    },
}


-- Allow single radar to reveal all arenas
data.raw.radar.radar.max_distance_of_nearby_sector_revealed = 15

-- The RedMew sprite for when it's run on their servers.
-- I can add graphics cause it's a mod with data stage :D
data:extend{{
    type = "sprite",
    name = "redmew-cat",
    filename = "__DemolitionDerby__/graphics/redmew-cat.png",
    priority = "extra-high-no-scale",
    width = 256,
    height = 256,
    flags = {"gui-icon"},
    mipmap_count = 1,
    scale = 0.5
}}