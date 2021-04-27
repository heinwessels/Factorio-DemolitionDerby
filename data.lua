require("prototypes.effect")
require("prototypes.vehicles")


data:extend({
  util.merge{
      data.raw["item"]["stone-wall"],
      {
          name = "curve-trail",
          place_result = "curve-trail",
      }
  },
  util.merge{
      data.raw["wall"]["stone-wall"],
      {
          name = "curve-trail",
          minable = {result = "curve-trail"},
      }
  },
})