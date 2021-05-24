

local LobbyGui = { }


function LobbyGui.build_interface(lobby, player)
    local player_global = global.players[player.index]
    if not player_global.elements then player_global.elements = { } end

    local screen_element = player.gui.left
    local main_frame = screen_element.add{
        type="frame", 
        name="ugg_main_frame", 
        caption={"lobby."..lobby.name}
    }
    main_frame.style.size = {300, 400}

    player.opened = main_frame
    player_global.elements.main_frame = main_frame

    local content_frame = main_frame.add{
        type="frame", name="content_frame", 
        direction="vertical", style="ugg_content_frame"
    }

    -- Little Info Area
    local arena_flow = content_frame.add{type="flow", name="arena_flow",
            direction="horizontal", style="ugg_controls_flow" }
    local arena_label = arena_flow.add{type="label",  name="arena_label", 
            caption={"", {"arena.arena"}, ": "}, style="heading_3_label" }
    local arena_name = arena_flow.add{type="label", name="arena_name", 
            caption={"arena."..lobby.arena_names[1]} }

    local player_count_flow = content_frame.add{type="flow", name="player_count_flow",
            direction="horizontal", style="ugg_controls_flow"}
    local player_count_label = player_count_flow.add{type="label",  name="player_count_label", 
            caption={"", {"lobby-gui.players-joined"}, ": "}, style="heading_3_label" }
    local player_count = player_count_flow.add{type="label", name="player_count", 
            caption=#lobby.players.."/"..lobby.max_players}
    
    -- Table of players
    local player_table_frame = content_frame.add{type="frame", name="button_frame", 
            direction="horizontal", style="ugg_deep_frame"}
    local button_table = player_table_frame.add{type="table", name="button_table", 
            column_count=3, direction="vertical", style="gui_players_table",
            draw_horizontal_line_after_headers=true, vertical_centering=false}
    
    button_table.add{type="label", caption={"lobby-gui.player"}, style="heading_2_label"}
    button_table.add{type="label", caption={"lobby-gui.total-score"}, style="heading_2_label"}
    button_table.add{type="label", caption={"lobby-gui.score"}, style="heading_2_label"}

    -- Dummy players
    for score, name in pairs({"Bob", "Fred", "Steve", "Jodi", "Hein", "Kevin", "Peter", "Gabriel"}) do
        button_table.add{type="label", caption=name}
        button_table.add{type="label", caption=score*2}
        button_table.add{type="label", caption=score}
    end
end

function LobbyGui.destroy(lobby, player)
    local player_global = global.players[player.index]
    local main_frame = player_global.elements.main_frame

    main_frame.destroy()
    player_global.elements = {}
end

return LobbyGui