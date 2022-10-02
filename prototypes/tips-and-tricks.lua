-- Remove all tips vanilla trips and tricks
data.raw["tips-and-tricks-item"] = nil
data.raw["tips-and-tricks-item-category"] = nil


data:extend(
{
    {
        type = "tips-and-tricks-item",
        name = "what-is-demolition-derby",
        order = "a-[basic]-a[0]",
        starting_status = "unlocked",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 10,
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "effect-categories",
        order = "a-[basic]-a[1]",
        starting_status = "unlocked",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 10,
        },
        simulation = {
            init = [[
                game.camera_zoom = 1.1
                local surface = game.surfaces.nauvis
                
                local x = -8
                surface.create_entity{ name = "wdd-effect-tank-player", position = {x, -4} }
                surface.create_entity{ name = "wdd-effect-invert-player", position = {x, 0} }
                surface.create_entity{ name = "wdd-effect-artillery-all", position = {x, 4} }

                local label = function(text, position)
                    rendering.draw_text{
                        text=text,
                        surface=surface, 
                        target= position,
                        scale = 4,
                        color = {1, 1, 1, 1}
                    }
                end
                
                local dx = 3
                label({"tips-and-tricks-util.affects-good"}, {x+dx, -5})
                label({"tips-and-tricks-util.affects-bad"}, {x+dx, -1})
                label({"tips-and-tricks-util.affects-neutral"}, {x+dx, 3})
            ]]
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "effect-types",
        order = "a-[basic]-a[2]",
        starting_status = "unlocked",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 10,
        },
        simulation = {
            init = [[
                game.camera_zoom = 0.8
                local surface = game.surfaces.nauvis

                local create_entry = function(ctx)
                    local surface = game.surfaces.nauvis
                    local dx = 3
                    local dy = -1
                    
                    surface.create_entity{ 
                        name = ctx.entity,
                        position = ctx.position
                    }

                    rendering.draw_text{
                        text=ctx.text,
                        surface=surface, 
                        target= {ctx.position[1]+dx, ctx.position[2]+dy},
                        scale = 3,
                        color = {1, 1, 1, 1}
                    }
                end
                
                local good_x = -15
                create_entry{entity="wdd-effect-speed_up-player", position = {good_x, -8}, text={"tips-and-tricks-util.speed_up"} }
                create_entry{entity="wdd-effect-tank-player", position = {good_x, -4}, text={"tips-and-tricks-util.tank"} }
                create_entry{entity="wdd-effect-worm-player", position = {good_x, 0}, text={"tips-and-tricks-util.worm"} }
                create_entry{entity="wdd-effect-biters-player", position = {good_x, 4}, text={"tips-and-tricks-util.biters"} }
                create_entry{entity="wdd-effect-full_trail-player", position = {good_x, 8}, text={"tips-and-tricks-util.full_trail"} }
                
                local other_x = good_x + 17
                create_entry{entity="wdd-effect-slow_down-player", position = {other_x, -4}, text={"tips-and-tricks-util.slow_down"} }
                create_entry{entity="wdd-effect-invert-player", position = {other_x, 0}, text={"tips-and-tricks-util.invert"} }
                create_entry{entity="wdd-effect-no_trail-player", position = {other_x, -8}, text={"tips-and-tricks-util.no_trail"} }
                create_entry{entity="wdd-effect-artillery-all", position = {other_x, 4}, text={"tips-and-tricks-util.artillery"} }
                create_entry{entity="wdd-effect-nuke-all", position = {other_x, 8}, text={"tips-and-tricks-util.nuke"} }
            ]]
        },
    },
    {
        type = "tips-and-tricks-item",
        name = "vehicle-types",
        order = "a-[basic]-a[3 ]",
        starting_status = "unlocked",
        trigger =
        {
            type = "time-elapsed",
            ticks = 60 * 10,
        },
        simulation = {
            init = [[
                game.camera_zoom = 0.6
                local surface = game.surfaces.nauvis
                
                local width = 18
                local height = 14

                for x = -width,width do
                    if math.abs(x) == width then
                        for y = -height,height do
                            surface.create_entity{name="wdd-border", position={x,y}}
                        end
                    end
                    surface.create_entity{name="wdd-border", position={x,-height}}
                    surface.create_entity{name="wdd-border", position={x,height}}
                end
                
                local car_trail = surface.create_entity{
                    name = "wdd-car", 
                    position = {10, 12},
                    direction = defines.direction.north
                }
                car_trail.speed = 0.3

                local car = surface.create_entity{
                    name = "wdd-car", 
                    position = {-10, -6},
                    direction = defines.direction.east
                }
                
                local tank = surface.create_entity{
                    name = "wdd-tank", 
                    position = {-10, 6},
                    direction = defines.direction.east
                }
                
                local label = function(text, position)
                    rendering.draw_text{
                        text=text,
                        surface=surface, 
                        target= position,
                        scale = 4,
                        color = {1, 1, 1, 1}
                    }
                end
                
                
                script.on_event(defines.events.on_tick, function (event) 
                    local offset = 3
                    if car_trail.valid then
                        surface.create_entity{name="wdd-trail", position={
                            car_trail.position.x, car_trail.position.y + offset
                        }}
                    end
                    if game.tick > 120 then
                        if car.valid then
                            car.speed = 0.3
                            surface.create_entity{name="wdd-trail", position={
                                car.position.x - offset, car.position.y
                            }}
                        end
                        if tank.valid then
                            tank.speed = 0.3
                            surface.create_entity{name="wdd-trail", position={
                                tank.position.x - offset, tank.position.y
                            }}
                        end
                    end
                end)
            ]]
        },
    },
})