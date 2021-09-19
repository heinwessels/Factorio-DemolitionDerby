

local LobbyGui = { }
local effect_constants = require("constants").effects

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
    
    -- Get ready for table of players    
    local player_table_frame = content_frame.add{type="frame", name="player_table_frame", 
            direction="horizontal", style="ugg_deep_frame"}
    player_gui.elements.player_table_frame = player_table_frame
    player_gui.elements.player_table = nil  -- Will build on first refresh
    player_gui.last_table_type = "-"    -- Either "lobby" or "arena". Will build on first refresh
    
end

function LobbyGui.refresh(lobby, player)
        
    -- First get lobby state because if changes what we will show
    local playing  = (lobby.status == "busy" and true) or false
    
    -- Get access to the GUI
    local player_gui = lobby.player_states[player.index].gui
    local elements = player_gui.elements
    local player_table = elements.player_table
    local arena = lobby.arena
    
    -- Make sure that we're using the correct style of player table
    -- Will also add the headings
    if playing then
        if player_gui.last_table_type ~= "arena" then
            -- Using the wrong table style. Destroy and create a new one
            if elements.player_table then elements.player_table.destroy() end
            elements.player_table = elements.player_table_frame.add{type="table", name="player_table", 
                column_count=3, direction="vertical", style="gui_players_table_arena",
                draw_horizontal_line_after_headers=true, vertical_centering=false}
            player_table = elements.player_table
        else
            -- Using the correct table style. Just destory the children
            player_table.clear()
        end
        player_gui.last_table_type = "arena"

        -- Add headings
        player_table.add{type="label", caption={"lobby-gui.player"}, style="heading_2_label"}
        player_table.add{type="label", caption={"lobby-gui.effects"}, style="heading_2_label"}
        player_table.add{type="label", caption={"lobby-gui.score"}, style="heading_2_label"}
    else
        if player_gui.last_table_type ~= "lobby" then
            -- Using the wrong table table. Destroy and create a new one
            if elements.player_table then elements.player_table.destroy() end
            elements.player_table = elements.player_table_frame.add{type="table", name="player_table", 
                column_count=3, direction="vertical", style="gui_players_table_lobby",
                draw_horizontal_line_after_headers=true, vertical_centering=false}
            player_table = elements.player_table
        else
            -- Using the correct table style. Just destory the children
            player_table.clear()
        end
        player_gui.last_table_type = "lobby"

        -- Add headings
        player_table.add{type="label", caption={"lobby-gui.player"}, style="heading_2_label"}
        player_table.add{type="label", caption={"lobby-gui.number-rounds"}, style="heading_2_label"}
        player_table.add{type="label", caption={"lobby-gui.total-score"}, style="heading_2_label"}
    end    
    
    -- Now create the player data table and sort it
    local player_data = { }
    for _, player in pairs(lobby.players) do

        -- Get the different states of the player
        local player_lobby_state = lobby.player_states[player.index]
        local player_arena_state = arena and arena.player_states[player.index] or nil        

        table.insert(player_data, {
            name = player.name,
            player = player,
            player_arena_state = player_arena_state,
            rounds = "TODO",
            total_score = player_lobby_state.score,
            arena_score = player_arena_state and player_arena_state.score or "-",
            state = player_arena_state and player_arena_state.status or "idle" -- Idle means not in arena
        })
    end
    table.sort(player_data, function (left, right)
        -- Sort based on score based on playing or not
        return (left.arena_score < right.arena_score) and playing 
                or (left.total_score < right.total_score)
    end)

    -- Now populate the table with the player data we just created
    for _, data in pairs(player_data) do        

        -- Add player name
        if playing then
            if data.state == "playing" then
                player_table.add{type="label", caption=data.name, style="wdd_player_playing"}
            elseif data.state == "lost" then
                player_table.add{type="label", caption=data.name, style="wdd_player_lost"}
            else
                -- Player likely entered lobby while round already started.
                player_table.add{type="label", caption=data.name, style="wdd_player_inactive"}
            end
        else
            -- While not playing just add without any style
            player_table.add{type="label", caption=data.name}
        end
        
        -- Add score
        if playing then
            
            -- Build effects string
            local effects_str = ""
            for effect_type, effect in pairs(data.player_arena_state.effects) do
                if not effect_constants[effect_type].ignore_in_gui then
                    effects_str = effects_str.."[img=item/wdd-effect-"..effect_type.."-"..effect.source.."]"
                end
            end

            player_table.add{type="label", caption=effects_str}
            player_table.add{type="label", caption=data.arena_score}
        else
            player_table.add{type="label", caption=data.round}
            player_table.add{type="label", caption=data.lobby_score}
        end
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