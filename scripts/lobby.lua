local Lobby = { }

function Lobby.create(lobby)
    lobby = util.merge{
        {
            name = "",
            arenas = { },
            area = {left_top={}, right_top={}},
            gates = {
                in_area = {left_top={}, right_top={}},
                out_area = {left_top={}, right_top={}},
            }
        },
        lobby
    }
    return lobby
end

function Lobby.clean(lobby)

end

return Lobby