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
        blue = create_arena({
            name = "sledgehammer",
            max_players = 8,
            surface = "nauvis",
            area = {
                left_top = {
                    x = 239,
                    y = 129,
                },
                right_bottom = {
                    x = 539,
                    y = 279,
                },
            },             
        }),
    },
    lobbies = {
        ["red-lobby"] = {
            name = "red-lobby",
            colour = {r=0.4,g=0.102,b=0.9,a=0},
            max_players = 8,
            arena_names = {
                "achtung",
            },
            surface = "nauvis",
            area = {
                left_top = {
                    x = 70,
                    y = -9,
                },
                right_bottom = {
                    x = 89,
                    y = 10,
                },w
            },
            portals = {
                inside = {
                    area = {
                        left_top = { x = 63, y = -1 },
                        right_bottom = { x = 66, y = 2}
                    }
                },
                outside = {
                    area = {
                        left_top = { x = 42, y = -1 },
                        right_bottom = { x = 45, y = 2}
                    },
                },
            } 
        },
        ["blue-lobby"] = {
            name = "blue-lobby",
            colour = {r=0.15,g=0.29,b=0.4,a=0},
            max_players = 8,
            arena_names = { "sledgehammer", },
            surface = "nauvis",
            area = {
                left_top = { x = -89,  y = -9 },
                right_bottom = { x = -70, y = -10 },
            },
            portals = {
                inside = {
                    area = {
                        left_top = { x = -66, y = -1 },
                        right_bottom = { x = -63, y = 2}
                    }
                },
                outside = {
                    area = {
                        left_top = { x = -46, y = -1 },
                        right_bottom = { x = -43, y = 2}
                    },
                },
            } 
        },
        ["green-lobby"] = {
            name = "green-lobby",
            colour = {r=0.28,g=0.38,b=0.4,a=0},
            max_players = 8,
            arena_names = { "sledgehammer", "achtung" },
            surface = "nauvis",
            area = {
                left_top = { x = -10,  y = -89 },
                right_bottom = { x = -9, y = -70 },
            },
            portals = {
                inside = {
                    area = {
                        left_top = { x = -2, y = -66 },
                        right_bottom = { x = 1, y = -63}
                    }
                },
                outside = {
                    area = {
                        left_top = { x = -2, y = -46 },
                        right_bottom = { x = 1, y = -43}
                    },
                },
            } 
        },
        ["purple-lobby"] = {
            name = "purple-lobby",
            colour = {r=0.33,g=0.17,b=0.37,a=0},
            max_players = 8,
            arena_names = { "sledgehammer", "achtung" },
            surface = "nauvis",
            area = {
                left_top = { x = -10,  y = 70 },
                right_bottom = { x = -9, y = 89 },
            },
            portals = {
                inside = {
                    area = {
                        left_top = { x = -2, y = 63 },
                        right_bottom = { x = 1, y = 66}
                    }
                },
                outside = {
                    area = {
                        left_top = { x = -2, y = 43 },
                        right_bottom = { x = 1, y = 46}
                    },
                },
            } 
        },
    },
    spawn_location = {x=0, y=0},
    splash = {
        position = {x=29, y=-560},
        zoom = 0.25,
    }
}