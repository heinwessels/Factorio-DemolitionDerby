local wdd_util = require("scripts.wdd-util")
local Builder = { }

function Builder.create()
    return { 
        state = "idle",
        -- Other valid states:
        --  starting
        --  cleaning
        --  building
        --  idle

        iterator = 0,   -- Keeps track of location of clean/build/etc
        area_to_clean = { },   -- Slighyly smaller than area to not include walls
    }
end

-- Builder process of (re)building arena
function Builder.start(arena)
    local builder = arena.builder

    if builder.state == "idle" then
        Builder.set_state(arena, "starting")
    else
        Builder.log(arena, "Could not start builder on arena <"..arena.name.."> because it's not idle (state=<"..builder.state..">")
    end
end

-- Call this every tick during the arena rebuilding
-- stage to slowly (re)build the arena over several ticks
function Builder.iterate(arena)
    local builder = arena.builder
    local area = arena.area
    local surface = arena.surface
    local iterator = builder.iterator

    if builder.state == "starting" then
        -- Just set things up.
        builder.iterator = 0
        builder.area_to_clean = { -- Area slightly bigger than arena
            left_top={x=math.floor(area.left_top.x-1), y=math.floor(area.left_top.y-1)},
            right_bottom={x=math.ceil(area.right_bottom.x+1), y=math.ceil(area.right_bottom.y+1)}
        }
        Builder.set_state(arena, "cleaning")
    elseif builder.state == "cleaning" then

        -- Calculate area to clean this round
        local area = {
            {
                x=builder.area_to_clean.left_top.x+builder.iterator, 
                y=builder.area_to_clean.left_top.y
            },
            {
                x=builder.area_to_clean.left_top.x+builder.iterator+1, 
                y=builder.area_to_clean.right_bottom.y
            }
        }
    
        -- Clean out all rocks, trees, vehicles and trails
        for _, entity in pairs(surface.find_entities_filtered{
            area = area,
            type = {
                "car", 
                "land-mine", 
                "wall", 
                "tree",
                "unit",
                "turret",
                "artillery-flare",
                "fire", -- This is for worm spit
            },
        }) do
            if entity.name ~= "wdd-border" then
                entity.create_build_effect_smoke()
                entity.destroy{raise_destroy=false}
            end
        end

        -- Fix the tiles that might have been destroyed by a nuke
        -- Each tile will have a small chance to be fixed
        local nuclear_tiles = surface.find_tiles_filtered{
            area = area, name = "nuclear-ground"
        }
        if #nuclear_tiles > 0 then
            local tiles_to_replace = { }            
            for _, tile in pairs(nuclear_tiles) do
                if math.random(1,10) == 1 then
                    -- This tile will be changed to refined concrete
                    table.insert(tiles_to_replace, {
                        name = "refined-concrete",
                        position = tile.position
                    })
                end
            end
            surface.set_tiles(tiles_to_replace)
        end

        -- Set builder to clean next section
        builder.iterator = builder.iterator + 1
        if builder.iterator >= (builder.area_to_clean.right_bottom.x-builder.area_to_clean.left_top.x) then
            Builder.set_state(arena, "building")
            builder.iterator = 0
        end
        
    elseif builder.state == "building" then
        -- Now build

        -- Add the vehicles for the next round
        local surface = arena.surface
        for _, position in pairs(arena.starting_locations) do            
            local vehicle = surface.create_entity{
                name = "wdd-car-static",
                position = {position.x, position.y},
                direction = position.direction,
                force = "player"
            }
            if not vehicle then
                error("Something went wrong attempting to spawn vehicle at <"..wdd_util.to_string(position).."> for arena <"..arena.name..">")
            end
        end

        Builder.set_state(arena, "idle")
    end
end

-- Set the state of a builder
function Builder.set_state(arena, state)
    Builder.log(arena, "Setting builder state for arena <"..arena.name.."> to <"..state..">")
    arena.builder.state = state
end

function Builder.log(arena, msg)
    -- log("Builder <"..arena.name..">: "..msg)
end

return Builder