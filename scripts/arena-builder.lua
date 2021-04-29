arena_builder = { }

function arena_builder.create()
    return { 
        state = "idle",
        -- Other valid states:
        --  starting
        --  cleaning
        --  building
        --  idle

        iterator = 0,   -- Keeps track of location of clean/build/etc
        size = { },     -- width and height of area to build
    }
end

-- arena_builder process of (re)building arena
function arena_builder.start(arena)
    local builder = arena.builder

    if builder.state == "idle" then
        arena_builder.set_state(arena, "starting")        
    else
        log("Could not start builder on arena <"..arena.name.."> because it's not idle (state=<"..builder.state..">")
    end
end

-- Call this every tick during the arena rebuilding
-- stage to slowly (re)build the arena over several ticks
function arena_builder.iterate(arena)
    local builder = arena.builder
    local area = arena.area
    local surface = arena.surface
    local iterator = builder.iterator

    if builder.state == "starting" then
        -- Just set things up.
        builder.iterator = 0        
        builder.size.width = area[2][1] - area[1][1]
        builder.size.height = area[2][2] - area[1][2]
        arena_builder.set_state(arena, "cleaning")
    elseif builder.state == "cleaning" then
        -- Clean out all rocks, trees, vehicles and trails
        for _, entity in pairs(surface.find_entities_filtered{
            area={
                {area[1][1]+builder.iterator, area[1][2]},
                {area[1][1]+builder.iterator+1, area[2][2]}
            },
            type = {"car", "land-mine", "wall", "tree"},
        }) do
            entity.destroy{raise_destroy=false}
        end

        if builder.iterator >= builder.size.width then
            arena_builder.set_state(arena, "building")
        else
            builder.iterator = builder.iterator + 1
        end
        
    elseif builder.state == "building" then
        -- Now build
        arena_builder.set_state(arena, "idle")
    end
end

-- Set the state of a builder
function arena_builder.set_state(arena, state)
    log("Setting builder state for arena <"..arena.name.."> to <"..state..">")
    arena.builder.state = state
end

return arena_builder