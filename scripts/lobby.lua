local curvefever_util = require("scripts.curvefever-util")
local constants = require("scripts.constants")
local Arena = require("scripts.arena")

local Lobby = { }

function Lobby.create(lobby)
    if type(lobby.surface) == "string" then
        lobby.surface = game.surfaces[lobby.surface]
    end
    local vehicles = lobby.surface.find_entities_filtered{
        name = "curvefever-car",
        area = lobby.area
    }
    lobby = util.merge{
        {
            name = "",
            world = nil, -- A reference to the world
            
            status = "ready",
            -- Other statusses
            --  "countdown"
            --  "wait"  -- for world to put players in a game
            --  "busy"  -- The arena for this game is currently busy
            countdown_start = nil,

            arena_names = { },   -- Array of arena names this lobby can go to
            target_arena_name = nil,    -- Where the game will be played when in wait

            vehicles = vehicles,     -- Array of vehicles in this lobby
            players = { },

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

-- Delete everything
function Lobby.reset(lobby)
    lobby = nil
end

function Lobby.clean(lobby)

end

function Lobby.update(lobby)
    
    -- The vehicles in the lobby may not move
    if not lobby.vehicles then return end   -- Shouldn't do anything if there's no vehicles
    for _, vehicle in pairs(lobby.vehicles) do
        vehicle.speed = 0
    end
    
    -- Is there enough players    
    if lobby.status == "ready" then
        local count_ready_players = 0
        for _, vehicle in pairs(lobby.vehicles) do
            if vehicle.get_driver() ~= nil then
                count_ready_players = count_ready_players + 1
            end
        end
        if count_ready_players >= 1 then
            -- Can start the count down!

            -- TODO This should be better

            Lobby.set_status(lobby, "countdown")
            lobby.countdown_start = game.tick
            game.print("Starting countdown to move to "..lobby.name.."!")
            -- After the countdown we wil finalize the game
        end

    elseif lobby.status == "countdown" then
        local diff = game.tick - lobby.countdown_start        
        if diff % 60 == 0 then
            game.print(((constants.lobby.countdown-diff)/60) .. "...")
        end
        if diff > constants.lobby.countdown then            

            -- Finalize players and target arena            
            lobby.target_arena_name = lobby.arena_names[math.random(#lobby.arena_names)]
            lobby.players = { }
            for _, vehicle in pairs(lobby.vehicles) do
                local character = vehicle.get_driver()
                if character then
                    table.insert(lobby.players, character.player)
                end
            end
            -- Now we will wait for the arena to be ready
            Lobby.set_status(lobby, "waiting")
        end    

    elseif lobby.status == "waiting" then        
        local arena = global.world.arenas[lobby.target_arena_name]
        if arena.status == "ready" then
            -- Arena is ready! Add players to the arena.
            -- This will teleport them into the cars
            for _, player in pairs(lobby.players) do
                Arena.add_player(arena, player)
            end
        end

        -- Start the game!
        Arena.start(arena)
        if arena.status ~= "playing" then
            log("Something went wrong starting arena <"..arena.name.."> from lobby <"..lobby.name..">")
        end
        Lobby.set_status(lobby, "busy")
    
    elseif lobby.status == "busy" then
        local arena = global.world.arenas[lobby.target_arena_name]
        if arena.status ~= "playing" then
            Lobby.set_status(lobby, "ready")
        end
    end
end

function Lobby.set_status(lobby, status)
    log("Setting lobby <"..lobby.name.."> state to <"..status..">")
    lobby.status = status
end

return Lobby