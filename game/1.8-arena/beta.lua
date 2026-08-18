local cloneref = cloneref or function(o) return o end
local playersService = cloneref(game:GetService("Players"))
local inputService = cloneref(game:GetService("UserInputService"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local runService = cloneref(game:GetService("RunService"))
local coreGui = cloneref(game:GetService("CoreGui"))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local islclosure = islclosure or function() return true end
local guiParent = (gethui and gethui()) or coreGui

local NeverLose
do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/ui/source.luau"))()
    end)
    if not ok then
        return warn("Failed to load Serenity: " .. tostring(res))
    end
    NeverLose = res
end

local Indicator = NeverLose:CreateIndicator();
local Window = NeverLose:CreateWindow({
    Logo = NeverLose.GlobalLogo,
    Name = "Serenity",
    Content = "1.8 Arena",
    Size = NeverLose.Scales.Default,
    ConfigFolder = "serenity/18arena",
    Enable3DRenderer = false,
    Keybind = "RightShift",
})

local Notification = NeverLose:CreateNotification()
local function notify(title, content)
    if Notification then
        Notification.new({ Title = tostring(title), Content = tostring(content), Duration = 6 })
    end
end

local Watermark = Window:Watermark()
Watermark:AddBlock(NeverLose.GlobalLogo, "Serenity")

local CombatTab = Window:AddTab({ Name = "Combat", Icon = "sword" })
local BlatantTab = Window:AddTab({ Name = "Blatant", Icon = "crosshairs-slash" })
local WorldTab = Window:AddTab({ Name = "World", Icon = "cube-vertexes" })
local VisualTab = Window:AddTab({ Name = "Visual", Icon = "eye" })

local arena: {[string]: any} = {}
local oldhit

--// calculateMoveVector
local function calculateMoveVector()
    if not arena.MoveController then return Vector3.zero end
    local vec = arena.MoveController:GetMoveVector()
    local c, s
    local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
    if R12 < 1 and R12 > -1 then
        c = R22
        s = R02
    else
        c = R00
        s = -R01 * math.sign(R12)
    end
    vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
    return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

--// entitylib
local entitylib: {[string]: any} = { List = {}, character = nil, isAlive = false }

local function localRoot()
    local subj = gameCamera.CameraSubject
    if subj and subj:IsA("BasePart") then return subj end
    local myc = workspace:FindFirstChild("LocalCharacter_" .. lplr.Name)
    return myc and (myc:FindFirstChild("PlayerHitbox") or myc:FindFirstChild("Torso"))
end

local function refreshEntities()
    local root = localRoot()
    if root then
        entitylib.isAlive = true
        entitylib.character = {
            RootPart = root,
            HipHeight = 5,
            Player = lplr,
            Character = workspace:FindFirstChild("LocalCharacter_" .. lplr.Name),
        }
    else
        entitylib.isAlive = false
        entitylib.character = nil
    end

    local list = {}
    local folder = workspace:FindFirstChild("OtherCharacters")
    if folder then
        for _, char in ipairs(folder:GetChildren()) do
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
            if torso then
                local plr = playersService:FindFirstChild(char.Name:sub(1, #char.Name - 14))
                list[#list + 1] = {
                    Character = char,
                    RootPart = torso,
                    Hitbox = char:FindFirstChild("PlayerHitbox"),
                    Head = char:FindFirstChild("Head") or torso,
                    Player = plr,
                    NPC = plr == nil,
                    Targetable = true,
                    HipHeight = 3,
                }
            end
        end
    end
    entitylib.List = list
end

task.spawn(function()
    while true do
        pcall(refreshEntities)
        runService.Heartbeat:Wait()
    end
end)

function entitylib.AllPosition(opts)
    local char = entitylib.character
    if not (char and char.RootPart) then return {} end
    local origin = char.RootPart.Position
    local part = opts.Part or "RootPart"
    local range = opts.Range or 16
    local res = {}
    for _, e in ipairs(entitylib.List) do
        if e.Targetable
            and not (e.Player and opts.Players == false)
            and not (e.NPC and not opts.NPCs) then
            local p = e[part] or e.RootPart
            if p then
                local dist = (p.Position - origin).Magnitude
                if dist <= range then
                    local blocked = false
                    if opts.Wallcheck then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = { char.Character, gameCamera, e.Character }
                        blocked = workspace:Raycast(origin, p.Position - origin, params) ~= nil
                    end
                    if not blocked then
                        res[#res + 1] = { ent = e, dist = dist }
                    end
                end
            end
        end
    end
    table.sort(res, function(a, b) return a.dist < b.dist end)
    local out = {}
    for i = 1, #res do
        if opts.Limit and i > opts.Limit then break end
        out[i] = res[i].ent
    end
    return out
end

function entitylib.EntityPosition(opts)
    return entitylib.AllPosition(opts)[1]
end

task.spawn(function()
    pcall(function()
        local charscript = lplr:WaitForChild("PlayerScripts"):WaitForChild("CharacterController")
        local env = getsenv and getsenv(charscript)
        if not (env and env.startHit) then
            local deadline = tick() + 20
            repeat
                env = getsenv and getsenv(charscript)
                task.wait()
            until (env and env.startHit) or tick() > deadline
        end
        if not (env and env.startHit) then return end

        arena.Client = env
        pcall(function() arena.PlayerState = require(charscript:FindFirstChild("PlayerState")) end)
        pcall(function() arena.Inventory = require(charscript:FindFirstChild("Inventory")) end)
        pcall(function() arena.MoveController = require(lplr.PlayerScripts:WaitForChild("PlayerModule")):GetControls() end)
        pcall(function() arena.SwingFunction = debug.getupvalue(env.startHit, 1) end)

        if getconnections then
            pcall(function()
                for _, v in getconnections(runService.Heartbeat) do
                    if v.Function and islclosure(v.Function) and debug.getconstants(v.Function)[1] == 0.05 then
                        arena.TickFunction = debug.getupvalue(v.Function, 3)
                    end
                end
            end)
            pcall(function()
                for _, v in getconnections(replicatedStorage.Remotes.LoadLocalCharacter.OnClientEvent) do
                    if v.Function then
                        arena.MoveFunction = debug.getupvalue(v.Function, 9)
                    end
                end
            end)
        end
    end)

    if arena.TickFunction and arena.MoveFunction then
        notify("Serenity - 1.8 Arena", "Loaded. All hooks found - press RightShift for the menu.")
    elseif arena.Client then
        local missing = {}
        if not arena.TickFunction then missing[#missing + 1] = "TickFunction" end
        if not arena.MoveFunction then missing[#missing + 1] = "MoveFunction" end
        notify("Serenity - 1.8 Arena", "Loaded, but missing: " .. table.concat(missing, ", ") .. ". Movement modules will be disabled.")
    else
        notify("Serenity - 1.8 Arena", "Failed to hook the game (needs getsenv + a full executor).")
    end
end)

local function ensureArena(name, ...)
    for _, f in ipairs({ ... }) do
        if not arena[f] then
            notify(name .. " unavailable", "Arena env not ready - needs a full-featured executor.")
            return false
        end
    end
    return true
end

local moduleRegistry = {}

local indicatorsEnabled = true
local function refreshIndicators()
    for _, mod in ipairs(moduleRegistry) do
        if mod.Indicator then
            mod.Indicator:SetRender(indicatorsEnabled and mod.Enabled)
        end
    end
end

inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or inputService:GetFocusedTextBox() then return end
    local keyName
    if input.UserInputType == Enum.UserInputType.Keyboard then
        keyName = input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        keyName = "M1B"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        keyName = "M2B"
    end
    if not keyName or keyName == "Unknown" then return end
    for _, mod in ipairs(moduleRegistry) do
        local bound = mod.KeybindUI and mod.KeybindUI:GetValue()
        if bound and bound == keyName then
            mod:Toggle()
        end
    end
end)

local tabSectionCounts = {}

local function createModule(tab, name, fn, tooltip, forcePosition)
    tabSectionCounts[tab] = (tabSectionCounts[tab] or 0) + 1
    local section = tab:AddSection({
        Name = name,
        Position = forcePosition or ((tabSectionCounts[tab] % 2 == 1) and "left" or "right"),
    })
    local m = { Enabled = false, Connections = {}, Section = section }

    function m:Clean(conn)
        table.insert(self.Connections, conn)
        return conn
    end

    local function disconnectAll()
        for _, c in ipairs(m.Connections) do
            if typeof(c) == "RBXScriptConnection" then
                c:Disconnect()
            elseif type(c) == "function" then
                pcall(c)
            end
        end
        table.clear(m.Connections)
    end

    function m:setState(v)
        if v == self.Enabled then return end
        self.Enabled = v
        if not v then disconnectAll() end
        if m.Indicator then m.Indicator:SetRender(indicatorsEnabled and v) end
        local ok, err = pcall(fn, v)
        if not ok then warn("[" .. name .. "] " .. tostring(err)) end
    end

    function m:Toggle()
        self.ToggleUI:SetValue(not self.Enabled)
    end

    m.Label = section:AddLabel("Enabled")
    m.ToggleUI = m.Label:AddToggle({
        Default = false,
        Callback = function(v) m:setState(v) end,
    })

    m.KeybindUI = m.Label:AddKeybind({
        Default = nil,
        Blacklist = { "RightShift" },
    })
    table.insert(moduleRegistry, m)

    m.Indicator = Indicator.new({ Name = name, Color = "White" })

    local decimalToRounding = { [10] = 1, [100] = 2, [1000] = 3 }

    function m:CreateSlider(cfg)
        local o = { Value = cfg.Default or cfg.Min or 0 }
        section:AddLabel(cfg.Name):AddSlider({
            Default = o.Value,
            Min = cfg.Min or 0,
            Max = cfg.Max or 100,
            Rounding = cfg.Decimal and decimalToRounding[cfg.Decimal] or 0,
            Callback = function(v)
                o.Value = v
                if cfg.Function then cfg.Function(v) end
            end,
        })
        return o
    end

    function m:CreateToggle(cfg)
        local o = { Enabled = cfg.Default or false }
        section:AddLabel(cfg.Name):AddToggle({
            Default = o.Enabled,
            Callback = function(v)
                o.Enabled = v
                if cfg.Function then cfg.Function(v) end
            end,
        })
        return o
    end

    function m:CreateDropdown(cfg)
        local o = { Value = cfg.Default or (cfg.List and cfg.List[1]) }
        section:AddLabel(cfg.Name):AddDropdown({
            Values = cfg.List,
            Default = o.Value,
            Multi = false,
            Callback = function(v) o.Value = v end,
        })
        return o
    end

    function m:CreateTwoSlider(cfg)
        local o = { Min = cfg.DefaultMin or cfg.Min, Max = cfg.DefaultMax or cfg.Max }
        section:AddLabel(cfg.Name .. " min"):AddSlider({
            Default = o.Min, Min = cfg.Min, Max = cfg.Max, Rounding = 0,
            Callback = function(v) o.Min = v end,
        })
        section:AddLabel(cfg.Name .. " max"):AddSlider({
            Default = o.Max, Min = cfg.Min, Max = cfg.Max, Rounding = 0,
            Callback = function(v) o.Max = v end,
        })
        function o.GetRandomValue()
            local a, b = o.Min, o.Max
            if a > b then a, b = b, a end
            return a == b and a or (a + math.random() * (b - a))
        end
        return o
    end

    function m:CreateTargets(cfg)
        cfg = cfg or {}
        local t = {
            Players = { Enabled = cfg.Players ~= false },
            NPCs = { Enabled = cfg.NPCs or false },
            Walls = { Enabled = cfg.Walls or false },
        }
        section:AddLabel("Target players"):AddToggle({ Default = t.Players.Enabled, Callback = function(v) t.Players.Enabled = v end })
        section:AddLabel("Target NPCs"):AddToggle({ Default = t.NPCs.Enabled, Callback = function(v) t.NPCs.Enabled = v end })
        section:AddLabel("Wall check"):AddToggle({ Default = t.Walls.Enabled, Callback = function(v) t.Walls.Enabled = v end })
        return t
    end

    function m:CreateColorSlider(cfg)
        local o = { Color = cfg.Default or Color3.fromRGB(255, 60, 60), Opacity = cfg.DefaultOpacity or 0.5 }
        section:AddLabel(cfg.Name):AddColorPicker({
            Default = o.Color,
            Callback = function(color) o.Color = color end,
        })
        return o
    end

    return m
end

local Killaura, Reach, AutoClicker, Sprint, Velocity
local Speed, Fly, HighJump, LongJump, Spider, NoSlowdown, HitBoxes, AutoBlock
local FastBreak, FastPlace
local Chams

-- killaura
do
    local Targets, AttackRange, AngleSlider, Max, Mouse, BoxAttackColor, Face
    local Boxes, AttackDelay = {}, tick()

    local function getAttackData()
        if Mouse.Enabled and not inputService:IsMouseButtonPressed(0) then
            return false
        end
        return true
    end

    Killaura = createModule(CombatTab, "Killaura", function(callback)
        if callback then
            if not ensureArena("Killaura", "TickFunction", "Client", "SwingFunction") then
                Killaura.ToggleUI:SetValue(false)
                return
            end

            local customvec
            local proxy = newproxy(true)
            local blockfunc = oldhit or arena.Client.startHit
            getmetatable(proxy).__index = function(_, key)
                if key == "CFrame" then
                    return customvec or gameCamera.CFrame
                end
                return nil
            end

            debug.setupvalue(arena.TickFunction, 13, proxy)

            repeat
                customvec = nil
                local interest = getAttackData()
                local attacked = {}

                if interest and entitylib.character then
                    local plrs = entitylib.AllPosition({
                        Range = AttackRange.Value,
                        Wallcheck = Targets.Walls.Enabled or nil,
                        Part = "RootPart",
                        Players = Targets.Players.Enabled,
                        NPCs = Targets.NPCs.Enabled,
                        Limit = Max.Value,
                    })

                    if #plrs > 0 then
                        local selfpos = entitylib.character.RootPart.Position
                        local localfacing = gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
                        local reblock = false

                        for _, v in ipairs(plrs) do
                            local delta = (v.RootPart.Position - selfpos)
                            local angle = math.acos(math.clamp(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit), -1, 1))
                            if angle > (math.rad(AngleSlider.Value) / 2) then continue end

                            table.insert(attacked, v)

                            if debug.getupvalue(blockfunc, 6) then
                                arena.Client.endBlockEvent:FireServer()
                                debug.setupvalue(blockfunc, 6, false)
                                reblock = true
                            end

                            if AttackDelay < tick() then
                                arena.SwingFunction()
                                AttackDelay = tick() + 0.11
                            end

                            local vec = CFrame.lookAt(selfpos, v.RootPart.Position)
                            if angle > math.rad(65) then
                                customvec = vec
                            end

                            replicatedStorage.Remotes.HitRequest:FireServer(selfpos, vec.LookVector, v.Character, v.Player)
                        end

                        if reblock then
                            arena.Client.beginBlockEvent:FireServer()
                            debug.setupvalue(blockfunc, 6, true)
                        end
                    end
                end

                for i, box in ipairs(Boxes) do
                    box.Adornee = attacked[i] and attacked[i].RootPart or nil
                    if box.Adornee then
                        box.Color3 = BoxAttackColor.Color
                        box.Transparency = 1 - BoxAttackColor.Opacity
                    end
                end

                if Face.Enabled and attacked[1] then
                    local vec = attacked[1].RootPart.Position * Vector3.new(1, 0, 1)
                    local root = entitylib.character.RootPart
                    root.CFrame = CFrame.lookAt(root.Position, Vector3.new(vec.X, root.Position.Y + 0.01, vec.Z))
                end

                task.wait(#attacked > 0 and #attacked * 0.07 or 0.016)
            until not Killaura.Enabled
        else
            pcall(debug.setupvalue, arena.TickFunction, 13, gameCamera)
            for _, box in ipairs(Boxes) do
                box.Adornee = nil
            end
        end
    end, "Attack players around you without aiming at them.")

    Targets = Killaura:CreateTargets({ Players = true })
    AttackRange = Killaura:CreateSlider({ Name = "Range", Min = 1, Max = 16, Default = 16 })
    AngleSlider = Killaura:CreateSlider({ Name = "Max angle", Min = 1, Max = 360, Default = 360 })
    Max = Killaura:CreateSlider({ Name = "Max targets", Min = 1, Max = 10, Default = 10 })
    Mouse = Killaura:CreateToggle({ Name = "Require mouse down" })
    --[[ i forgot to paste esp module & im too lazy to rewrite it so heres a shitty replacement
    Killaura:CreateToggle({
        Name = "Show target",
        Function = function(callback)
            if callback then
                for i = 1, 10 do
                    local box = Instance.new("BoxHandleAdornment")
                    box.Adornee = nil
                    box.AlwaysOnTop = true
                    box.Size = Vector3.new(3, 7, 3)
                    box.CFrame = CFrame.new(0, -0.5, 0)
                    box.ZIndex = 0
                    box.Parent = guiParent
                    Boxes[i] = box
                end
            else
                for _, v in ipairs(Boxes) do
                    v:Destroy()
                end
                table.clear(Boxes)
            end
        end,
    })
    BoxAttackColor = Killaura:CreateColorSlider({ Name = "Attack color", DefaultOpacity = 0.5 })
    ]]
    Face = Killaura:CreateToggle({ Name = "Face target" })
end

-- reach
do
    local Value, old

    Reach = createModule(CombatTab, "Reach", function(callback)
        if callback then
            if not ensureArena("Reach", "Client") then
                Reach.ToggleUI:SetValue(false)
                return
            end
            old = debug.getupvalue(oldhit or arena.Client.startHit, 4)
            debug.setupvalue(oldhit or arena.Client.startHit, 4, old + Value.Value)
        else
            if old then
                debug.setupvalue(oldhit or arena.Client.startHit, 4, old)
                old = nil
            end
        end
    end, "Extends attack reach")

    Value = Reach:CreateSlider({
        Name = "Range", Min = 0, Max = 6, Default = 6, Decimal = 10,
        Function = function(val)
            if Reach.Enabled and old then
                debug.setupvalue(oldhit or arena.Client.startHit, 4, old + val)
            end
        end,
    })
end

-- AC
do
    local CPS, Thread

    local function AutoClick()
        if not (arena.Client and arena.Client.startHit) then return end
        if Thread then task.cancel(Thread) end
        Thread = task.delay(1 / CPS.GetRandomValue(), function()
            repeat
                task.spawn(arena.Client.startHit)
                task.wait(1 / CPS.GetRandomValue())
            until not AutoClicker.Enabled
        end)
    end

    AutoClicker = createModule(CombatTab, "AutoClicker", function(callback)
        if callback then
            if not ensureArena("AutoClicker", "Client") then
                AutoClicker.ToggleUI:SetValue(false)
                return
            end
            AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    AutoClick()
                end
            end))
            AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread then
                    task.cancel(Thread)
                    Thread = nil
                end
            end))
        else
            if Thread then
                task.cancel(Thread)
                Thread = nil
            end
        end
    end, "Hold attack button to automatically click")

    CPS = AutoClicker:CreateTwoSlider({ Name = "CPS", Min = 1, Max = 9, DefaultMin = 7, DefaultMax = 7 })
end

-- sprint
Sprint = createModule(CombatTab, "Sprint", function(callback)
    if callback then
        if not ensureArena("Sprint", "PlayerState") then
            Sprint.ToggleUI:SetValue(false)
            return
        end
        repeat
            arena.PlayerState.Preferences.AutoSprint = true
            task.wait(0.016)
        until not Sprint.Enabled
    end
end, "Sets your sprinting to true.")

-- velocity
do
    local Horizontal, Vertical, Chance, Targeting
    local connection, old
    local rand = Random.new()

    local function velocityFunction(...)
        if rand:NextNumber(0, 100) > Chance.Value then return old(...) end

        local data = ...
        local check = (not Targeting.Enabled) or entitylib.EntityPosition({
            Range = 50,
            Part = "RootPart",
            Players = true,
        })

        if check and type(data) == "table" and data.vel and not data.position then
            local hort, vert = (Horizontal.Value / 100), (Vertical.Value / 100)
            if hort == 0 and vert == 0 then return end
            data.vel = Vector3.new(data.vel.X * hort, data.vel.Y * vert, data.vel.Z * hort)
        end

        return old(...)
    end

    Velocity = createModule(CombatTab, "Velocity", function(callback)
        if callback then
            if not (getconnections and hookfunction) then
                notify("Velocity unavailable", "Needs hookfunction / getconnections.")
                Velocity.ToggleUI:SetValue(false)
                return
            end
            connection = getconnections(replicatedStorage.Remotes.ClientStateUpdate.OnClientEvent)[1]
            if not connection then return end
            old = hookfunction(connection.Function, function(...)
                return velocityFunction(...)
            end)
        else
            if old and connection then
                hookfunction(connection.Function, old)
            end
            connection = nil
        end
    end, "Reduces knockback taken", "right")

    Horizontal = Velocity:CreateSlider({ Name = "Horizontal", Min = 0, Max = 100, Default = 0 })
    Vertical = Velocity:CreateSlider({ Name = "Vertical", Min = 0, Max = 100, Default = 0 })
    Chance = Velocity:CreateSlider({ Name = "Chance", Min = 0, Max = 100, Default = 100 })
    Targeting = Velocity:CreateToggle({ Name = "Only when targeting" })
end

-- speed
do
    local Value, AutoJump

    Speed = createModule(BlatantTab, "Speed", function(callback)
        if callback then
            if not ensureArena("Speed", "TickFunction", "MoveFunction") then
                Speed.ToggleUI:SetValue(false)
                return
            end
            Speed:Clean(runService.PreSimulation:Connect(function()
                if not Fly.Enabled and not LongJump.Enabled then
                    local movedir = calculateMoveVector() * Value.Value
                    local onground = debug.getupvalue(arena.MoveFunction, 4)
                    local velocity = debug.getupvalue(arena.TickFunction, 6)
                    debug.setupvalue(arena.TickFunction, 6, Vector3.new(movedir.X, AutoJump.Enabled and onground and movedir.Magnitude > 0 and 20 or velocity.Y, movedir.Z))
                end
            end))
        end
    end, "Increases your movement with various methods.")

    Value = Speed:CreateSlider({ Name = "Speed", Min = 1, Max = 90, Default = 30 })
    AutoJump = Speed:CreateToggle({ Name = "AutoJump" })
end

-- fly
do
    local Keys, Value, VerticalValue
    local up, down = 0, 0

    Fly = createModule(BlatantTab, "Fly", function(callback)
        if callback then
            if not ensureArena("Fly", "TickFunction") then
                Fly.ToggleUI:SetValue(false)
                return
            end
            Fly:Clean(runService.PreSimulation:Connect(function()
                if entitylib.isAlive then
                    local movedir = calculateMoveVector() * Value.Value
                    debug.setupvalue(arena.TickFunction, 6, Vector3.new(movedir.X, 1 + ((up + down) * VerticalValue.Value), movedir.Z))
                end
            end))

            up, down = 0, 0
            for _, ev in ipairs({ "InputBegan", "InputEnded" }) do
                Fly:Clean(inputService[ev]:Connect(function(input)
                    if not inputService:GetFocusedTextBox() then
                        local divided = Keys.Value:split("/")
                        if input.KeyCode == Enum.KeyCode[divided[1]] then
                            up = ev == "InputBegan" and 1 or 0
                        elseif input.KeyCode == Enum.KeyCode[divided[2]] then
                            down = ev == "InputBegan" and -1 or 0
                        end
                    end
                end))
            end
        end
    end, "Makes you go zoom.")

    Keys = Fly:CreateDropdown({
        Name = "Keys",
        List = { "Space/LeftControl", "Space/LeftShift", "E/Q", "Space/Q", "ButtonA/ButtonL2" },
    })
    Value = Fly:CreateSlider({ Name = "Speed", Min = 1, Max = 150, Default = 50 })
    VerticalValue = Fly:CreateSlider({ Name = "Vertical", Min = 1, Max = 150, Default = 50 })
end

-- JB
do
    local Value, AutoDisable

    local function jump()
        local onground = debug.getupvalue(arena.MoveFunction, 4)
        if onground then
            local velocity = debug.getupvalue(arena.TickFunction, 6)
            debug.setupvalue(arena.TickFunction, 6, Vector3.new(velocity.X, Value.Value, velocity.Z))
        end
    end

    HighJump = createModule(BlatantTab, "HighJump", function(callback)
        if callback then
            if not ensureArena("HighJump", "TickFunction", "MoveFunction") then
                HighJump.ToggleUI:SetValue(false)
                return
            end
            if AutoDisable.Enabled then
                jump()
                HighJump:Toggle()
            else
                HighJump:Clean(runService.RenderStepped:Connect(function()
                    if not inputService:GetFocusedTextBox() and inputService:IsKeyDown(Enum.KeyCode.Space) then
                        jump()
                    end
                end))
            end
        end
    end, "Lets you jump higher")

    Value = HighJump:CreateSlider({ Name = "Velocity", Min = 1, Max = 150, Default = 50 })
    AutoDisable = HighJump:CreateToggle({ Name = "Auto Disable", Default = true })
end

-- LJ
do
    local Value, AutoDisable

    LongJump = createModule(BlatantTab, "LongJump", function(callback)
        if callback then
            if not ensureArena("LongJump", "TickFunction", "MoveFunction") then
                LongJump.ToggleUI:SetValue(false)
                return
            end
            local exempt = tick() + 0.1
            LongJump:Clean(runService.PreSimulation:Connect(function()
                if entitylib.isAlive then
                    local movedir = calculateMoveVector() * Value.Value
                    local onground = debug.getupvalue(arena.MoveFunction, 4)

                    if onground then
                        if exempt < tick() and AutoDisable.Enabled then
                            if LongJump.Enabled then
                                LongJump:Toggle()
                            end
                        else
                            debug.setupvalue(arena.TickFunction, 6, Vector3.new(movedir.X, 30, movedir.Z))
                        end
                    end

                    local velocity = debug.getupvalue(arena.TickFunction, 6)
                    debug.setupvalue(arena.TickFunction, 6, Vector3.new(movedir.X, velocity.Y, movedir.Z))
                end
            end))
        end
    end, "Lets you jump farther")

    Value = LongJump:CreateSlider({ Name = "Speed", Min = 1, Max = 150, Default = 50 })
    AutoDisable = LongJump:CreateToggle({ Name = "Auto Disable", Default = true })
end

-- spider
do
    local Value
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local Active

    Spider = createModule(BlatantTab, "Spider", function(callback)
        if callback then
            if not ensureArena("Spider", "TickFunction") then
                Spider.ToggleUI:SetValue(false)
                return
            end
            Spider:Clean(runService.PreSimulation:Connect(function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    local chars = { gameCamera, entitylib.character.Character }
                    for _, v in ipairs(entitylib.List) do
                        table.insert(chars, v.Character)
                    end

                    rayCheck.FilterDescendantsInstances = chars
                    rayCheck.CollisionGroup = "Hitbox"

                    local vec = calculateMoveVector() * 2.5
                    local ray = workspace:Raycast(root.Position - Vector3.new(0, entitylib.character.HipHeight - 0.5, 0), vec, rayCheck)
                    if Active and not ray then
                        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                    end

                    Active = ray
                    if Active and ray.Normal.Y == 0 then
                        local velocity = debug.getupvalue(arena.TickFunction, 6)
                        debug.setupvalue(arena.TickFunction, 6, Vector3.new(velocity.X, Value.Value, velocity.Z))
                    end
                end
            end))
        else
            Active = nil
        end
    end, "Lets you climb up walls.")

    Value = Spider:CreateSlider({ Name = "Speed", Min = 0, Max = 100, Default = 30 })
end

-- noslowdown
do
    local old

    NoSlowdown = createModule(BlatantTab, "NoSlowdown", function(callback)
        if callback then
            if not ensureArena("NoSlowdown", "MoveFunction") then
                NoSlowdown.ToggleUI:SetValue(false)
                return
            end
            old = debug.getupvalue(arena.MoveFunction, 17)
            debug.setupvalue(arena.MoveFunction, 17, debug.getupvalue(arena.MoveFunction, 19))
        else
            if old then
                debug.setupvalue(arena.MoveFunction, 17, old)
                old = nil
            end
        end
    end, "Prevent you from slowing down when using items.")
end

-- HBE
do
    local Targets, Expand
    local modified = {}

    HitBoxes = createModule(BlatantTab, "HitBoxes", function(callback)
        if callback then
            repeat
                for _, v in ipairs(entitylib.List) do
                    if v.Targetable and v.Hitbox then
                        if not (not Targets.Players.Enabled and v.Player)
                            and not (not Targets.NPCs.Enabled and v.NPC) then
                            local part = v.Hitbox
                            if not modified[part] then
                                modified[part] = part.Size
                            end
                            part.Size = modified[part] + Vector3.new(Expand.Value, Expand.Value, Expand.Value)
                        end
                    end
                end
                task.wait()
            until not HitBoxes.Enabled
        else
            for part, size in pairs(modified) do
                if part and part.Parent then
                    part.Size = size
                end
            end
            table.clear(modified)
        end
    end, "Expands entities hitboxes")

    Targets = HitBoxes:CreateTargets({ Players = true })
    Expand = HitBoxes:CreateSlider({ Name = "Amount", Min = 0, Max = 6, Decimal = 10 })
end

-- auto block
AutoBlock = createModule(BlatantTab, "AutoBlock", function(callback)
    if callback then
        if not (arena.Client and arena.Client.startHit and hookfunction) then
            notify("AutoBlock unavailable", "Needs startHit / hookfunction.")
            AutoBlock.ToggleUI:SetValue(false)
            return
        end
        oldhit = hookfunction(arena.Client.startHit, function(...)
            if debug.getupvalue(oldhit, 6) then
                arena.Client.endBlockEvent:FireServer()
                debug.setupvalue(oldhit, 6, false)

                local results = table.pack(oldhit(...))
                arena.Client.beginBlockEvent:FireServer()
                debug.setupvalue(oldhit, 6, true)

                return table.unpack(results, 1, results.n)
            else
                return oldhit(...)
            end
        end)
    else
        if oldhit then
            hookfunction(arena.Client.startHit, oldhit)
            oldhit = nil
        end
    end
end, "Automatically unblock and reblock before hitting")

-- fast break
do
    local Value, old

    FastBreak = createModule(WorldTab, "FastBreak", function(callback)
        if callback then
            if not (arena.Client and arena.Client.showMiningProgress and hookfunction) then
                notify("FastBreak unavailable", "Needs showMiningProgress / hookfunction.")
                FastBreak.ToggleUI:SetValue(false)
                return
            end
            old = hookfunction(arena.Client.showMiningProgress, function(progress)
                progress = progress * Value.Value
                pcall(function() debug.setstack(3, 5, debug.getstack(3, 5) * Value.Value) end)
                return old(progress)
            end)
        else
            if old then
                hookfunction(arena.Client.showMiningProgress, old)
                old = nil
            end
        end
    end, "Break blocks faster when mining.")

    Value = FastBreak:CreateSlider({ Name = "Multiplier", Min = 0, Max = 3, Default = 3, Decimal = 10 })
end

-- fast place
do
    local Value, old

    FastPlace = createModule(WorldTab, "FastPlace", function(callback)
        if callback then
            if not ensureArena("FastPlace", "Client") then
                FastPlace.ToggleUI:SetValue(false)
                return
            end
            old = debug.getupvalue(arena.Client.startPlaceHold, 7)
            debug.setupvalue(arena.Client.startPlaceHold, 7, math.max(Value.Value, 0.001))
        else
            if old then
                debug.setupvalue(arena.Client.startPlaceHold, 7, old)
                old = nil
            end
        end
    end, "Place blocks faster while holding right click.")

    Value = FastPlace:CreateSlider({
        Name = "Delay", Min = 0, Max = 0.2, Default = 0, Decimal = 100,
        Function = function(val)
            if FastPlace.Enabled then
                debug.setupvalue(arena.Client.startPlaceHold, 7, math.max(val, 0.001))
            end
        end,
    })
end

-- esp
do
    local Players, NPCs, FillColor, OutlineColor, FillTrans, OutlineTrans, ThroughWalls
    local highlights = {}

    local function clearHighlights()
        for _, h in pairs(highlights) do
            if h then pcall(function() h:Destroy() end) end
        end
        table.clear(highlights)
    end

    Chams = createModule(VisualTab, "Chams", function(callback)
        if callback then

            Chams:Clean(clearHighlights)
            Chams:Clean(runService.RenderStepped:Connect(function()

                for char, h in pairs(highlights) do
                    if not (char and char.Parent) then
                        if h then h:Destroy() end
                        highlights[char] = nil
                    end
                end

                for _, e in ipairs(entitylib.List) do
                    local char = e.Character
                    if e.Targetable and char and char.Parent
                        and not (e.Player and not Players.Enabled)
                        and not (e.NPC and not NPCs.Enabled) then
                        local h = highlights[char]
                        if not h or not h.Parent then
                            h = Instance.new("Highlight")
                            h.Adornee = char:IsA("Model") and char or e.RootPart
                            h.Parent = guiParent
                            highlights[char] = h
                        end
                        h.FillColor = FillColor.Color
                        h.OutlineColor = OutlineColor.Color
                        h.FillTransparency = FillTrans.Value
                        h.OutlineTransparency = OutlineTrans.Value
                        h.DepthMode = ThroughWalls.Enabled and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                    end
                end
            end))
        end
    end, "Highlights entities so they are visible through walls.")

    Players = Chams:CreateToggle({ Name = "Players", Default = true })
    NPCs = Chams:CreateToggle({ Name = "NPCs" })
    FillColor = Chams:CreateColorSlider({ Name = "Fill color", Default = Color3.fromRGB(255, 60, 60) })
        FillTrans = Chams:CreateSlider({ Name = "Transp", Min = 0, Max = 1, Default = 0.5, Decimal = 100 })
    OutlineColor = Chams:CreateColorSlider({ Name = "Outline color", Default = Color3.fromRGB(255, 255, 255) })
    OutlineTrans = Chams:CreateSlider({ Name = "Transp", Min = 0, Max = 1, Default = 0, Decimal = 100 })
    ThroughWalls = Chams:CreateToggle({ Name = "Through walls", Default = true })
end

-- settings
do
    local settings = Window.UserSettings
    if settings then

        settings:AddLabel("Menu keybind"):AddKeybind({
            Default = "RightShift",
            Blacklist = { "M1B", "M2B" },
            Callback = function(key)
                Window.Keybind = key or "RightShift"
            end,
        })

        settings:AddLabel("Menu scale"):AddDropdown({
            Values = { "Small", "Mobile", "Default", "Large" },
            Default = "Default",
            Multi = false,
            Callback = function(v)
                Window:SetSize(NeverLose.Scales[v] or NeverLose.Scales.Default)
            end,
        })

        settings:AddLabel("Show indicators"):AddToggle({
            Default = true,
            Callback = function(v)
                indicatorsEnabled = v
                refreshIndicators()
            end,
        })
    end
end
