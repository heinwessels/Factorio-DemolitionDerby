util = require("util")

function create_arena(arena)
    return util.merge{
        {
            name = nil,
            area = nil,
            surface = nil,
            max_players = nil,

            lobby = {
                area = nil,          
                gates = {
                    in_area = nil,
                    output_area = nil,
                },
            },
        },
        arena
    }
end

return {
    arenas = {
        achtung = create_arena({
            name = "achtung",
            max_players = 8,
            surface = "nauvis",
            area = {
                left_top = {
                    x = 239,
                    y = -91,
                },
                right_bottom = {
                    x = 440,
                    y = 9,
                },
            },             
        }),
    },
    lobbies = {
        ["red-lobby"] = {
            name = "red-lobby",
            max_players = 8,
            arena_names = {
                "achtung",
            },
            surface = "nauvis",
            area = {
                left_top = {
                    x = 30,
                    y = 11,
                },
                right_bottom = {
                    x = 49,
                    y = 30,
                },
            },
            portals = {
                inside = {
                    area = {
                        left_top = { x = 23, y = 19 },
                        right_bottom = { x = 26, y = 22}
                    }
                },
                outside = {
                    area = {
                        left_top = { x = 12, y = 19 },
                        right_bottom = { x = 15, y = 22}
                    },
                },
            } 
        },
    },
    spawn_location = {x=7.5, y=-5.5},
    splash = {
        position = {x=29, y=-560},
        zoom = 0.25,
    }
}