local function getGameId()
    return game.PlaceId or game.GameId or 0
end

local function kickPlayer(message)
    local player = game.Players.LocalPlayer
    if player and player:Kick then
        player:Kick(message)
    ==[[
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "Serenity",
            Text = message,
            Duration = 5
        })
        wait(2)
        game:Shutdown()
    ]]
    end
end

local GAME_ID = getGameId()

-- 1.8 Arena
if GAME_ID == 77790193039862 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/game/1.8-arena/beta.lua"))()

-- Prison Life
elseif GAME_ID == 135564683255158 or GAME_ID == 155615604 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/game/prisonlife/prisonlife.lua"))()

-- BloxStrike
elseif GAME_ID == 114234929420007 then
    kickPlayer("BloxStrike is under maintenance.")

else
    kickPlayer("Game is not supported.")
end
