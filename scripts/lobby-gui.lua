

local LobbyGui = { }


function LobbyGui.build_interface(lobby, player)
    local player_global = global.players[player.index]
    if not player_global.elements then player_global.elements = { } end

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{
        type="frame", 
        name="ugg_main_frame", 
        caption={"ugg.hello_world"}
    }
    main_frame.style.size = {385, 165}
    main_frame.auto_center = false

    player.opened = main_frame
    player_global.elements.main_frame = main_frame
end

function LobbyGui.destroy(lobby, player)
    local player_global = global.players[player.index]
    local main_frame = player_global.elements.main_frame

    main_frame.destroy()
    player_global.elements = {}
end

return LobbyGui