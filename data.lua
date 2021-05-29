require("prototypes.effects")
require("prototypes.vehicles")
require("prototypes.walls")
require("prototypes.biters")
require("prototypes.gui")
require("prototypes.sound")

require("prototypes.coloured-tiles")  -- Only used when blueprinting splash

-- Just make artillery a little stronger
data.raw["artillery-projectile"]["artillery-projectile"].action.action_delivery.target_effects[1].action.radius = 5

-- Remove all tips and tricks
data.raw["tips-and-tricks-item"] = nil
data.raw["tips-and-tricks-item-category"] = nil