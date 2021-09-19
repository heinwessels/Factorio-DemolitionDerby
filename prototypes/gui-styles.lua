-- These are some style prototypes that the tutorial uses
-- You don't need to understand how these work to follow along
local styles = data.raw["gui-style"].default

styles["gui_players_table_lobby"] = {
    type = "table_style",
    column_widths = {        
        { -- Player name
            column = 1,
            width = 130
        },
        { -- Rounds playec
            column = 2,
            width = 45
        },
        { -- Total Score
            column = 3,
            width = 35
        }
    },

    horizontal_spacing = 0,
    left_cell_padding = 8,
    top_cell_padding = 2,
    right_cell_padding = 8,
    bottom_cell_padding = 2,
    apply_row_graphical_set_per_column = true,
    default_row_graphical_set = {position = {208, 17},  corner_size = 8},
    hovered_graphical_set = {position = {34, 17}, corner_size = 8},
    clicked_graphical_set = {position = {51, 17}, corner_size = 8},
    selected_graphical_set = {position = {51, 17}, corner_size = 8},
    selected_hovered_graphical_set = {position = {369, 17}, corner_size = 8},
    selected_clicked_graphical_set = {position = {352, 17}, corner_size = 8}
}

styles["gui_players_table_arena"] = {
    type = "table_style",
    column_widths = {        
        { -- Player Name
            column = 1,
            width = 90
        },
        { -- Effects applied
            column = 2,
            width = 80
        },
        { -- Current (Arena) Score
            column = 3,
            width = 40
        }
    },

    horizontal_spacing = 0,
    left_cell_padding = 8,
    top_cell_padding = 2,
    right_cell_padding = 8,
    bottom_cell_padding = 2,
    apply_row_graphical_set_per_column = true,
    default_row_graphical_set = {position = {208, 17},  corner_size = 8},
    hovered_graphical_set = {position = {34, 17}, corner_size = 8},
    clicked_graphical_set = {position = {51, 17}, corner_size = 8},
    selected_graphical_set = {position = {51, 17}, corner_size = 8},
    selected_hovered_graphical_set = {position = {369, 17}, corner_size = 8},
    selected_clicked_graphical_set = {position = {352, 17}, corner_size = 8}
}

styles["ugg_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["ugg_controls_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["ugg_controls_textfield"] = {
    type = "textbox_style",
    width = 36
}

styles["ugg_deep_frame"] = {
    type = "frame_style",
    parent = "deep_frame_in_shallow_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 0,
    right_margin = 0,
    bottom_margin = 0
}

styles["wdd_player_playing"] = {
    type = "label_style",
    parent = "label",
    font_color = {0, 1, 0}
}

styles["wdd_player_lost"] = {
    type = "label_style",
    parent = "label",    
    font_color = {1, 0, 0}
}

styles["wdd_player_inactive"] = {
    type = "label_style",
    parent = "label",
    font_color = {0.7, 0.7, 0.7}
}