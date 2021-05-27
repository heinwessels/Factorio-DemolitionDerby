

local LobbyGui = { }


function LobbyGui.build_interface(lobby, player)
    local player_gui = lobby.player_states[player.index].gui
    if not player_gui.elements then player_gui.elements = { } end
    
    local screen_element = player.gui.left
    if #screen_element.children > 0 then LobbyGui.destroy(lobby, player) end

    local main_frame = screen_element.add{
        type="frame", 
        name="ugg_main_frame", 
        caption={"lobby."..lobby.name}
    }
    main_frame.style.size = {300, 400}

    player.opened = main_frame
    player_gui.elements.main_frame = main_frame

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
    player_gui.elements.arena_name = arena_name

    local player_count_flow = content_frame.add{type="flow", name="player_count_flow",
            direction="horizontal", style="ugg_controls_flow"}
    local player_count_label = player_count_flow.add{type="label",  name="player_count_label", 
            caption={"", {"lobby-gui.players-joined"}, ": "}, style="heading_3_label" }
    local player_count = player_count_flow.add{type="label", name="player_count", 
            caption=#lobby.players.."/"..lobby.max_players}
    player_gui.elements.player_count_flow = player_count_flow
    
    -- Table of players
    local player_table_frame = content_frame.add{type="frame", name="player_table_frame", 
            direction="horizontal", style="ugg_deep_frame"}
    local player_table = player_table_frame.add{type="table", name="player_table", 
            column_count=3, direction="vertical", style="gui_players_table",
            draw_horizontal_line_after_headers=true, vertical_centering=false}
    player_gui.elements.player_table = player_table
    
end

function LobbyGui.refresh(lobby, player)
    
    local elements = lobby.player_states[player.index].gui.elements

    local player_table = elements.player_table
    for _, child in pairs(player_table.children) do child.destroy() end
    player_table.add{type="label", caption={"lobby-gui.player"}, style="heading_2_label"}
    player_table.add{type="label", caption={"lobby-gui.total-score"}, style="heading_2_label"}
    player_table.add{type="label", caption={"lobby-gui.score"}, style="heading_2_label"}

    for _, player in pairs(lobby.players) do
        local lobby_state = lobby.player_states[player.index]
        local player_state = nil
        local arena_score = "-"
        if lobby.arena then
            local arena_player_state = lobby.arena.player_states[player.index]
            if arena_player_state then
                player_state = arena_player_state.status
                arena_score = arena_player_state.score
            end
        end

        if player_state == "playing" then
            player_table.add{type="label", caption=player.name, style="bold_green_label"}
        elseif player_state == "lost" then
            player_table.add{type="label", caption=player.name, style="bold_red_label"}
        else
            player_table.add{type="label", caption=player.name}
        end

        player_table.add{type="label", caption=lobby_state.score}
        player_table.add{type="label", caption=arena_score}
    end
end

function LobbyGui.destroy(lobby, player)
    local player_state = lobby.player_states[player.index]
    if player_state then
        local player_gui = player_state.gui
        local main_frame = player_gui.elements.main_frame
        if main_frame then main_frame.destroy() end
        player_gui.elements = {}
    end
end

return LobbyGui