-- Remove all tips vanilla trips and tricks
data.raw["tips-and-tricks-item"] = nil
data.raw["tips-and-tricks-item-category"] = nil


data:extend(
{
    {
        type = "tips-and-tricks-item",
        name = "introduction",
        order = "a-[basic]-a[introduction]",
        starting_status = "unlocked",
        trigger =
        {
        type = "time-elapsed",
        ticks = 60 * 10,
        },
        simulation = {
            init = [[
                game.camera_zoom = 1
                local surface = game.surfaces.nauvis
                surface.create_entity{ name = "wdd-effect-tank-player", position = {-2, -4} }
                surface.create_entity{ name = "wdd-effect-invert-enemy", position = {-2, 0} }
                surface.create_entity{ name = "wdd-effect-artillery-all", position = {-2, 4} }

                local label = function(text, position)
                    rendering.draw_text{
                        text=text,
                        surface=surface, 
                        target= position,
                        scale = 4,
                        color = {1, 1, 1, 1}
                    }
                end

                label("Player", {2, -5})
                label("Enemy", {2, -1})
                label("All", {2, 3})
            ]]
        },
    },
})