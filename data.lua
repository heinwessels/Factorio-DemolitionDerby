require ("prototypes.effect")

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

data.raw["car"]["car"].resistances = {
    {
      type = "fire",
      percent = 100
    },
    {
      type = "impact",
      percent = 0,
      decrease = -5000
    },
    {
      type = "acid",
      percent = 20
    }
}