

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local NeverLose
local success, err = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/ui/source.luau"))()
end)

if success then
    NeverLose = err
    print("Serenity loaded successfully!")
else
    warn("Failed to load Serenity: " .. tostring(err))
end

local Window = NeverLose:CreateWindow({
    Logo = NeverLose.GlobalLogo,
    Name = "Serenity",
    Content = "Prison Life",
    Size = NeverLose.Scales.Default,
    ConfigFolder = "serenity/prisonlife",
    Enable3DRenderer = false,
    Keybind = "RightShift",
})

local Notification = NeverLose:CreateNotification()

local Watermark = Window:Watermark()
Watermark:AddBlock("sword", "Serenity", NeverLose.GlobalLogo)

Window.UserSettings:AddLabel("Watermark"):AddToggle({
    Default = true,
    Callback = function(value)
        Watermark:SetRender(value)
    end,
})

Window.UserSettings:AddLabel("Menu Keybind"):AddKeybind({
    Default = "RightShift",
    Callback = function(KeyName)
        Window.Keybind = KeyName
    end,
})

local MTab = Window:AddTab({
    Name = "General",
    Icon = "sword"
}):AddSection({
    Name = "General"
})

MTab:AddButton({
    Name = "Getting hit by an electric fence won't kill you",
    Callback = function()
        local function removeAllDamageParts()
            for _, object in ipairs(workspace.Prison_Fences:GetDescendants()) do
                if object.Name == "damagePart" then
                    object:Destroy()
                end
            end
        end

        removeAllDamageParts()

        workspace.Prison_Fences.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "damagePart" then
                task.wait()
                descendant:Destroy()
            end
        end)
    end
})

local AutoArrestEnabled = false
local ArrestDistance = 15

task.spawn(function()
    while task.wait(0.25) do
        if not AutoArrestEnabled then continue end
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

        local myRoot = char.HumanoidRootPart

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == localPlayer or not plr.Character then continue end

            local team = plr.Team
            if team and (team.Name == "Prisoners" or team.Name == "Prisoner" or team.Name == "Inmates") then
                local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (myRoot.Position - targetRoot.Position).Magnitude
                    if dist <= ArrestDistance then
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ArrestPlayer"):InvokeServer(plr, 1)
                        end)
                    end
                end
            end
        end
    end
end)

MTab:AddLabel("Enable Auto Arrest Nearby"):AddToggle({
    Default = false,
    Callback = function(v)
        AutoArrestEnabled = v
    end
})

MTab:AddLabel("Arrest Distance (Studs)"):AddTextInput({
    Placeholder = "15",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            ArrestDistance = num
        end
    end
})

MTab:AddButton({
    Name = "Delete The Keycards Doors",
    Callback = function()
        if workspace:FindFirstChild("Doors") then
            workspace.Doors:Destroy()
        end
    end
})

MTab:AddButton({
    Name = "Delete The Cell Doors",
    Callback = function()
        if workspace:FindFirstChild("CellDoors") then
            workspace.CellDoors:Destroy()
        end
    end
})

MTab:AddButton({
    Name = "Delete All Toilets",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Toilet" then
                v:Destroy()
            end
        end
    end
})

local LpTab = Window:AddTab({
    Name = "Local Player",
    Icon = "person"
}):AddSection({
    Name = "Local Player"
})

local WalkSpeedEnabled = false
local WalkSpeedValue = 50

local function updateWalkSpeed()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = WalkSpeedEnabled and WalkSpeedValue or 16
    end
end

LpTab:AddLabel("Enable Walk Speed"):AddToggle({
    Default = false,
    Callback = function(v)
        WalkSpeedEnabled = v
        updateWalkSpeed()
    end
})

LpTab:AddLabel("Walk Speed"):AddTextInput({
    Placeholder = "50",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then WalkSpeedValue = num; updateWalkSpeed() end
    end
})

local JumpPowerEnabled = false
local JumpPowerValue = 50

local function updateJumpPower()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = JumpPowerEnabled and JumpPowerValue or 50
    end
end

LpTab:AddLabel("Enable Jump Power"):AddToggle({
    Default = false,
    Callback = function(v)
        JumpPowerEnabled = v
        updateJumpPower()
    end
})

LpTab:AddLabel("Jump Power"):AddTextInput({
    Placeholder = "50",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then JumpPowerValue = num; updateJumpPower() end
    end
})

RunService.Heartbeat:Connect(function()
    updateWalkSpeed()
    updateJumpPower()
end)

localPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateWalkSpeed()
    updateJumpPower()
end)

local InfiniteJump = false

LpTab:AddLabel("Enable Infinite Jump"):AddToggle({
    Default = false,
    Callback = function(v) InfiniteJump = v end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

if _G.OldConnections then
    for _, v in pairs(_G.OldConnections) do
        if v then v:Disconnect() end
    end
    _G.OldConnections = nil
end

repeat task.wait() until game.Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local character, humanoid, rootPart
local characterParts = {}
local isInvisible = false

local function setupCharacter()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    characterParts = {}

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency == 0 then
            table.insert(characterParts, part)
        end
    end
end

local function setInvisibleState(state)
    isInvisible = state

    for _, part in pairs(characterParts) do
        if part and part.Parent then
            part.Transparency = isInvisible and 0.5 or 0
        end
    end
end

setupCharacter()
LocalPlayer.CharacterAdded:Connect(function()
    isInvisible = false
    setupCharacter()
end)

local connections = {}
connections[1] = RunService.Heartbeat:Connect(function()
    if isInvisible and rootPart and humanoid then
        local oldCFrame = rootPart.CFrame
        local oldCameraOffset = humanoid.CameraOffset

        local targetCFrame = oldCFrame * CFrame.new(0, -75, 0)
        local offset = targetCFrame:ToObjectSpace(CFrame.new(oldCFrame.Position)).Position

        rootPart.CFrame = targetCFrame
        humanoid.CameraOffset = offset

        RunService.RenderStepped:Wait()

        rootPart.CFrame = oldCFrame
        humanoid.CameraOffset = oldCameraOffset
    end
end)

_G.OldConnections = connections

LpTab:AddLabel("Enable Invisible"):AddToggle({
    Default = false,
    Callback = function(Value)
        setInvisibleState(Value)
    end
})

local TpTab = Window:AddTab({
    Name = "Teleport",
    Icon = "compass"
}):AddSection({
    Name = "Teleport"
})

TpTab:AddLabel("Tp", true)
TpTab:AddLabel("Teleport", true)

local tps = {
    ["police gun"] = Vector3.new(856.14, 102.62, 2256.75),
    ["Thieves' base"] = Vector3.new(-981.62, 108.12, 2056.98),
    ["outside of prison"] = Vector3.new(485.23, 97.99, 2244.82),
    ["Conjuring up a thief's car"] = Vector3.new(-915.86, 95.13, 2134.13),
    ["Conjuring up a police car"] = Vector3.new(615.49, 98.20, 2488.75),
}

for name, pos in pairs(tps) do
    TpTab:AddButton({
        Name = "Tp to " .. name,
        Callback = function()
            local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(pos)
            end
        end
    })
end

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CombatTab = Window:AddTab({
    Name = "Combat",
    Icon = "sword"
}):AddSection({
    Name = "Combat"
})

local aiming = false
local fovEnabled = false
local smoothness = 0.1
local fovRadius = 360
local aimPart = "Head"
local wallCheckEnabled = false

local fovColor = Color3.fromRGB(255, 0, 0)
local rainbowEnabled = false

local AimBlacklist = {
    Players = {},
    Teams = {
        ["Guards"] = false,
        ["Prisoners"] = false,
        ["Criminals"] = false
    }
}

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 0.5
fovCircle.NumSides = 8
fovCircle.Filled = false
fovCircle.Transparency = 1.0
fovCircle.Visible = false

local function isVisible(targetPart)
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, camera}
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getTarget()
    if not fovEnabled then return nil end
    local closest, minDist = nil, fovRadius
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(aimPart) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then

            if AimBlacklist.Players[p.Name] then continue end
            if p.Team and AimBlacklist.Teams[p.Team.Name] then continue end

            local part = p.Character[aimPart]
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist <= fovRadius and dist < minDist then

                    if wallCheckEnabled and not isVisible(part) then
                        continue
                    end

                    minDist = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

task.spawn(function()
    while task.wait() do
        pcall(function()
            if rainbowEnabled then
                local hue = (tick() % 5) / 5
                fovCircle.Color = Color3.fromHSV(hue, 1, 1)
            else
                fovCircle.Color = fovColor
            end

            if fovEnabled then
                fovCircle.Visible = true
                fovCircle.Transparency = 1.0
                fovCircle.Radius = fovRadius
                fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            else
                fovCircle.Visible = false
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if fovEnabled and aiming then
        local target = getTarget()
        if target then
            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, target.Position), smoothness)
        end
    end
end)

CombatTab:AddLabel("Enable Aim Lock"):AddToggle({
    Default = false,
    Callback = function(Value)
        aiming = Value
    end
})

CombatTab:AddLabel("Enable FOV Circle"):AddToggle({
    Default = false,
    Callback = function(Value)
        fovEnabled = Value
    end
})

CombatTab:AddLabel("Enable Wall Check"):AddToggle({
    Default = false,
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})

CombatTab:AddLabel("FOV Size"):AddTextInput({
    Placeholder = "360",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then fovRadius = num end
    end
})

local PartDropdown = CombatTab:AddLabel("locking parts"):AddDropdown({
    Multi = false,
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(Value)
        if type(Value) == "table" then
            aimPart = Value[1] or "Head"
        elseif type(Value) == "string" and Value ~= "" then
            aimPart = Value
        end
    end
})

task.spawn(function()
    task.wait(1)
    if PartDropdown and PartDropdown.SetValue then PartDropdown:SetValue("Head") end
end)

CombatTab:AddLabel("Aim Lock Blacklist", true)

CombatTab:AddLabel("Username Blacklist)"):AddTextInput({
    Placeholder = "...",
    Numeric = false,
    Callback = function(Text)
        if Text and Text ~= "" then
            AimBlacklist.Players = {}
            AimBlacklist.Players[Text] = true
        end
    end
})

CombatTab:AddLabel("Blacklist Guards Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        AimBlacklist.Teams["Guards"] = Value
    end
})

CombatTab:AddLabel("Blacklist Prisoners Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        AimBlacklist.Teams["Prisoners"] = Value
    end
})

CombatTab:AddLabel("Blacklist Criminals Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        AimBlacklist.Teams["Criminals"] = Value
    end
})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Enabled = false,
    UseTeleport = true,
    UseTween = false,
    TweenSpeed = 150,
    DelayPerPlayer = 0.1,
    BlacklistedPlayers = {},
    BlacklistedTeams = {
        ["Guards"] = false,
        ["Prisoners"] = false,
        ["Criminals"] = false
    }
}

local function getTeamName(player)
    if player.Team then return player.Team.Name end
    return ""
end

local function moveToTarget(targetPart)
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    if Settings.UseTeleport then
        localHRP.CFrame = targetPart.CFrame
    elseif Settings.UseTween then
        local distance = (localHRP.Position - targetPart.Position).Magnitude
        local duration = distance / Settings.TweenSpeed

        local tween = TweenService:Create(localHRP, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame})
        tween:Play()
        tween.Completed:Wait()
    end
end


local MainToggle = CombatTab:AddLabel("Enable Kill All Loop (risk)"):AddToggle({
    Default = false,
    Callback = function(Value)
        Settings.Enabled = Value
    end
})

local TPToggle, TweenToggle

TPToggle = CombatTab:AddLabel("Enable Teleport mode"):AddToggle({
    Default = true,
    Callback = function(Value)
        Settings.UseTeleport = Value
        if Value then
            Settings.UseTween = false
            TweenToggle:SetValue(false)
        end
    end
})

TweenToggle = CombatTab:AddLabel("Enable Tween mode"):AddToggle({
    Default = false,
    Callback = function(Value)
        Settings.UseTween = Value
        if Value then
            Settings.UseTeleport = false
            TPToggle:SetValue(false)
        end
    end
})

CombatTab:AddLabel("Tween Speed"):AddTextInput({
    Placeholder = "...",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Settings.TweenSpeed = num end
    end
})

CombatTab:AddLabel("Delay (s)"):AddTextInput({
    Placeholder = "...",
    Numeric = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then Settings.DelayPerPlayer = num end
    end
})

CombatTab:AddLabel("Username Blacklist)"):AddTextInput({
    Placeholder = "...",
    Numeric = false,
    Callback = function(Text)
        if Text and Text ~= "" then
            Settings.BlacklistedPlayers = {}
            Settings.BlacklistedPlayers[Text] = true
            Notification.new({Title = "Blacklist", Content = "Exempting player: " .. Text, Duration = 5})
        end
    end
})

CombatTab:AddLabel("Team Blacklist", true)

CombatTab:AddLabel("Blacklist Guards Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        Settings.BlacklistedTeams["Guards"] = Value
    end
})

CombatTab:AddLabel("Blacklist Prisoners Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        Settings.BlacklistedTeams["Prisoners"] = Value
    end
})

CombatTab:AddLabel("Blacklist Criminals Team"):AddToggle({
    Default = false,
    Callback = function(Value)
        Settings.BlacklistedTeams["Criminals"] = Value
    end
})

task.spawn(function()
    while true do
        task.wait(0.1)
        if Settings.Enabled then
            for _, v in next, Players:GetChildren() do
                if not Settings.Enabled then break end

                pcall(function()
                    if v == LocalPlayer then return end
                    if Settings.BlacklistedPlayers[v.Name] then return end
                    if Settings.BlacklistedTeams[getTeamName(v)] then return end

                    local targetChar = v.Character
                    if not targetChar then return end

                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")

                    if targetChar:FindFirstChildOfClass("ForceField") then return end
                    if not targetHumanoid or targetHumanoid.Health <= 0 then return end

                    while Settings.Enabled and targetHumanoid and targetHumanoid.Health > 0 and not targetChar:FindFirstChildOfClass("ForceField") do
                        task.wait()

                        moveToTarget(targetHRP)

                        for _, c in next, Players:GetChildren() do
                            if c ~= LocalPlayer and not Settings.BlacklistedPlayers[c.Name] and not Settings.BlacklistedTeams[getTeamName(c)] then
                                ReplicatedStorage.meleeEvent:FireServer(c)
                            end
                        end
                    end
                end)

                task.wait(Settings.DelayPerPlayer)
            end
        end
    end
end)

local punchAuraEnabled = false

local function getClosestAuraPlayer()
    local closestDist, closestPlr = math.huge, nil
    for _, v in next, Players:GetPlayers() do
        if v == LocalPlayer then continue end

        pcall(function()
            local dist = LocalPlayer:DistanceFromCharacter(v.Character.PrimaryPart.Position)
            if dist < 6 and dist < closestDist then
                closestDist = dist
                closestPlr = v
            end
        end)
    end

    return closestPlr
end

CombatTab:AddLabel("Punch Aura", true)

CombatTab:AddLabel("Enable Punch Aura"):AddToggle({
    Default = false,
    Callback = function(Value)
        punchAuraEnabled = Value
    end
})

task.spawn(function()
    while task.wait() do
        if punchAuraEnabled then
            local plr = getClosestAuraPlayer()
            if plr then
                ReplicatedStorage.meleeEvent:FireServer(plr)
            end
        end
    end
end)

local WTab = Window:AddTab({
    Name = "Weapon",
    Icon = "bullet-flying"
}):AddSection({
    Name = "Weapon"
})

WTab:AddButton({
    Name = "Tp to Mp5 (Guards Room)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(814.1622924804688,102.8799819946289,2229.063232421875)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp To Remington 870 (Guards Room)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(820.2584838867188,102.8799819946289,2229.033447265625)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp To Remington 870 (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-939.0526123046875,96.30850219726562,2039.330810546875)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to Ak47 (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-931.7821044921875,96.368408203125,2039.4932861328125)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to M700 [GamePass] (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-919.5140991210938, 96.86885070800781, 2036.7769775390625)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to FAL [GamePass] (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-902.1759033203125, 96.43677520751953, 2046.9830322265625)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to C4 [GamePass] (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-900.9798583984375, 96.82874298095703, 2041.475830078125)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to Revolver [GamePass] (Criminals)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(-915.18896484375, 96.82882690429688, 2035.864013671875)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to Riot Shield [Game Pass] (Guards Room)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(841.4751586914062, 102.12140655517578, 2230.52880859375)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

WTab:AddButton({
    Name = "Tp to M4A1 [GamePass] (Guards Room)",
    Callback = function()
        local plr = game.Players.LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local oldPos = hrp.CFrame
        hrp.CFrame = CFrame.new(847.034912109375, 102.88017272949219, 2228.777587890625)
        task.wait(2)
        hrp.CFrame = oldPos
    end
})

local EspTab = Window:AddTab({
    Name = "ESP",
    Icon = "eye"
}):AddSection({
    Name = "ESP"
})

local ESPNameEnabled = false
local ESPTeamEnabled = false
local ESPDistanceEnabled = false

local ESPObjects = {}

local function GetTeamColor(player)
    local teamName = player.Team and player.Team.Name or ""

    if teamName == "Guards" or teamName == "Police" then
        return Color3.fromRGB(0,170,255)

    elseif teamName == "Inmates" then
        return Color3.fromRGB(255,170,0)

    elseif teamName == "Criminals" then
        return Color3.fromRGB(255,0,0)

    end

    return Color3.fromRGB(255,255,255)
end

local function CreateESP(player)
    if player == localPlayer then
        return
    end

    local function Setup(character)
        local head = character:WaitForChild("Head",5)

        if not head then
            return
        end

        if head:FindFirstChild("ZeionESP") then
            head.ZeionESP:Destroy()
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ZeionESP"
        billboard.Size = UDim2.new(0,200,0,80)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0,2.5,0)
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1,1)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.TextSize = 10
        label.Font = Enum.Font.SourceSansBold
        label.TextStrokeTransparency = 0
        label.Parent = billboard

        ESPObjects[player] = billboard

        RunService.RenderStepped:Connect(function()

            if not billboard.Parent then
                return
            end

            local myCharacter = localPlayer.Character
            if not myCharacter then
                return
            end

            local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
            local targetRoot = character:FindFirstChild("HumanoidRootPart")

            if not myRoot or not targetRoot then
                return
            end

            local distance = math.floor(
                (myRoot.Position - targetRoot.Position).Magnitude
            )

            local teamName = player.Team and player.Team.Name or "Unknown"

            local text = ""

            if ESPNameEnabled then
                text = text .. player.Name
            end

            if ESPTeamEnabled then
                if text ~= "" then
                    text = text .. "\n"
                end

                text = text .. "[" .. teamName .. "]"
            end

            if ESPDistanceEnabled then
                if text ~= "" then
                    text = text .. "\n"
                end

                text = text .. "[" .. distance .. "m]"
            end

            label.Text = text
            label.TextColor3 = GetTeamColor(player)
        end)
    end

    if player.Character then
        Setup(player.Character)
    end

    player.CharacterAdded:Connect(Setup)
end

for _,player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)

EspTab:AddLabel("Enable ESP Name"):AddToggle({
    Default = false,
    Callback = function(v)
        ESPNameEnabled = v
    end
})

EspTab:AddLabel("Enable ESP Team"):AddToggle({
    Default = false,
    Callback = function(v)
        ESPTeamEnabled = v
    end
})

EspTab:AddLabel("Enable ESP Distance"):AddToggle({
    Default = false,
    Callback = function(v)
        ESPDistanceEnabled = v
    end
})
