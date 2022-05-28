require("prototypes.effects")
require("prototypes.vehicles")
require("prototypes.walls")
require("prototypes.biters")
require("prototypes.gui-styles")
require("prototypes.sound")
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