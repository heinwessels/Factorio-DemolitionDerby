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
                    x = 539,
                    y = 59,
                },
            },             
        }),
    },
    lobbies = {
        achtung = {
            name = "achtung",
            arenas = {
                "achtung",
            },
            area = {
                left_top = {
                    x = 30,
                    y = 10,
                },
                right_bottom = {
                    x = 49,
                    y = 31,
                },
            },
            gates = {
                in_area = {
                    left_top = {
                        x = 28.5,
                        y = 18.5,
                    },
                    right_bottom = {
                        x = 28.5,
                        y = 22.5,
                    },
                },
                out_area = {
                    left_top = {
                        x = 30.5,
                        y = 18.5,
                    },
                    right_bottom = {
                        x = 30.5,
                        y = 22.5,
                    },
                },
            }
        },
    },
    spawn_location = {x=7.5, y=-5.5},
}