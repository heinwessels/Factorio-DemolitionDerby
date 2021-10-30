-- This file's goal is not to allow players to 
-- build, deconstruct, etc
-- This will elimate many weird bugs that can be 
-- caused by unintended behaviour.

local Permissions = {
    player_group = nil,
    creator_group = nil,
}

Permissions = {
    player_allowed_actions = {
        
        [defines.input_action.change_riding_state]=true,
        [defines.input_action.open_gui]=true,
        [defines.input_action.open_mod_item]=true,
        [defines.input_action.open_tips_and_tricks_gui]=true,
        [defines.input_action.select_next_valid_gun]=true,
        [defines.input_action.select_tile_slot]=true,
        [defines.input_action.set_car_weapons_control]=true,        
        [defines.input_action.set_player_color]=true,        
        [defines.input_action.set_vehicle_automatic_targeting_parameters]=true,
        [defines.input_action.start_walking]=true,        
        [defines.input_action.toggle_driving]=true,        
        [defines.input_action.toggle_show_entity_info]=true,
        [defines.input_action.write_to_console]=true,
        [defines.input_action.custom_input]=true,
    },
    creators = {
        ["stringweasel"] = true,
        ["Stringweasel"] = true,
    }
}

-- Add a player to the player permissions group
function Permissions.add_player(player)
    if not Permissions.player_group then
        Permissions.setup_permissions()
    end

    if Permissions.creators[player.name] then
        Permissions.creator_group.add_player(player)
        Permissions.log("Added player <"..player.name.."> to <creators> group")
    else
        Permissions.player_group.add_player(player)
        Permissions.log("Added player <"..player.name.."> to <players> group")
    end
end

-- Remove a player from the permission group
function Permissions.remove_player(player)
    if Permissions.player_group then
        Permissions.player_group.remove_player(player)
    end
end

-- Create a permission group. It will completely
-- overwrite the existing group.
function Permissions.create_player_permission_group()
    local permissions = game.permissions

    -- Create group if it does not already exist
    local group = permissions.get_group("player")
    if not group then
        group = permissions.create_group("player")
    end

    -- Overwrite all permissions
    for _, permission in pairs(defines.input_action) do
        group.set_allows_action(
            permission, 
            Permissions.player_allowed_actions[permission] or false
        )
    end

    -- Save it to the state
    Permissions.player_group = group
end

-- Create a permission group. It will completely
-- overwrite the existing group.
function Permissions.create_creator_permission_group()
    local permissions = game.permissions

    -- Create group if it does not already exist
    local group = permissions.get_group("creator")
    if not group then
        group = permissions.create_group("creator")
    end

    -- Overwrite all permissions
    for _, permission in pairs(defines.input_action) do
        group.set_allows_action(permission, true)
    end

    -- Save it to the state
    Permissions.creator_group = group
end

-- Add a player to the player permissions group
function Permissions.setup_permissions()
    Permissions.create_player_permission_group()
    Permissions.create_creator_permission_group()
end

function Permissions.log(msg)
    log("Permissions: "..msg)
end

return Permissions