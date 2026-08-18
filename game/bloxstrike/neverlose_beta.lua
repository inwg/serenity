local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local charfolder = Workspace:WaitForChild("Characters", 10)
local hitboxsafe = false
local function get_t() return charfolder and charfolder:FindFirstChild("Terrorists") end
local function get_ct() return charfolder and charfolder:FindFirstChild("Counter-Terrorists") end

local function get_player_team(player)
    if not charfolder or not player then return nil end
    local t, ct = get_t(), get_ct()
    if t and t:FindFirstChild(player.Name) then
        return "Terrorists"
    end
    if ct and ct:FindFirstChild(player.Name) then
        return "Counter-Terrorists"
    end
    return nil
end


local NeverLose = loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/ui/source.luau"))()

local registry = {}
local changedHandlers = {}

local function dispatch(name)
    local list = changedHandlers[name]
    if not list then return end
    for i = 1, #list do
        task.spawn(list[i])
    end
end

local function isHeld(keyName)
    if not keyName then return false end
    if keyName == "M1B" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif keyName == "M2B" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    local ok, code = pcall(function() return Enum.KeyCode[keyName] end)
    if ok and code then
        return UserInputService:IsKeyDown(code)
    end
    return false
end

local proxyCache = {}
local function getProxy(name)
    local cached = proxyCache[name]
    if cached then return cached end

    local proxy = setmetatable({
        OnChanged = function(self, fn)
            local list = changedHandlers[name]
            if not list then
                list = {}
                changedHandlers[name] = list
            end
            list[#list + 1] = fn
            return self
        end,
        SetValue = function(self, v)
            local el = registry[name]
            if el then el:SetValue(v) end
            return self
        end,
        GetState = function(self)
            local el = registry[name]
            local key = el and el:GetValue()
            return isHeld(key)
        end,
    }, {
        __index = function(_, k)
            if k == "Value" then
                local el = registry[name]
                if el then
                    return el:GetValue()
                end
                return nil
            end
            return nil
        end,
    })

    proxyCache[name] = proxy
    return proxy
end

local Toggles = setmetatable({}, { __index = function(_, name) return getProxy(name) end })
local Options = setmetatable({}, { __index = function(_, name) return getProxy(name) end })

local Notification = NeverLose:CreateNotification()
local Library = {}
function Library:Notify(cfg)
    if type(cfg) ~= "table" then return end
    Notification.new({
        Title = cfg.Title or "Notification",
        Content = cfg.Description or cfg.Content or "",
        Duration = cfg.Time or cfg.Duration or 5,
    })
end

local HitPartValues = {
    "HumanoidRootPart", "Head", "LeftLowerArm", "LowerTorso", "RightHand",
    "RightLowerArm", "LeftFoot", "LeftHand", "RightFoot", "RightLowerLeg",
    "LeftLowerLeg", "RightUpperArm", "LeftUpperArm", "UpperTorso",
    "RightUpperLeg", "LeftUpperLeg",
}

local function Section(tab, name, pos)
    return tab:AddSection({ Name = name, Position = pos })
end

local function Toggle(section, flag, text, default)
    local label = section:AddLabel(text)
    registry[flag] = label:AddToggle({
        Default = default and true or false,
        Flag = flag,
        Callback = function() dispatch(flag) end,
    })
    return label
end

local function Slider(section, flag, text, opts)
    local label = section:AddLabel(text)
    registry[flag] = label:AddSlider({
        Default = opts.Default,
        Min = opts.Min,
        Max = opts.Max,
        Rounding = opts.Rounding or 0,
        Type = opts.Type or "",
        Size = opts.Size,
        Flag = flag,
        Callback = function() dispatch(flag) end,
    })
    return label
end

local function Dropdown(section, flag, text, opts)
    local label = section:AddLabel(text)
    registry[flag] = label:AddDropdown({
        Values = opts.Values,
        Default = opts.Default,
        Multi = opts.Multi and true or false,
        Flag = flag,
        Callback = function() dispatch(flag) end,
    })
    return label
end

local function ColorPicker(section, flag, text, default)
    local label = section:AddLabel(text)
    registry[flag] = label:AddColorPicker({
        Default = default,
        Flag = flag,
        Callback = function() dispatch(flag) end,
    })
    return label
end

local function Dependency(parentFlag, want, labels)
    local function refresh()
        local el = registry[parentFlag]
        local on = el and el:GetValue()
        local visible = (on == want)
        for i = 1, #labels do
            labels[i]:SetVisible(visible)
        end
    end
    getProxy(parentFlag):OnChanged(refresh)
    refresh()
end

pcall(function()
    if isfolder and makefolder and not isfolder("neverlose") then
        makefolder("neverlose")
    end
end)

local Window = NeverLose:CreateWindow({
    Logo = NeverLose.GlobalLogo,
    Name = "Serenity",
    Content = "Bloxstrike",
    Size = NeverLose.Scales.Default,
    ConfigFolder = "serenity/beta/bloxstrike",
    Enable3DRenderer = false,
    Keybind = "RightShift",
})

Window:SetAccount({ Username = "Beta" })

local Watermark = Window:Watermark()
Watermark:AddBlock("cube-vertexes", "Serenity | Bloxstrike")

local Tabs = {
    Legit = Window:AddTab({ Name = "Legit", Icon = "crosshair" }),
    Rage = Window:AddTab({ Name = "Rage", Icon = "swords" }),
    Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye" }),
    SkinChanger = Window:AddTab({ Name = "SkinChanger", Icon = "paintbrush" }),
    Misc = Window:AddTab({ Name = "Misc", Icon = "settings" }),
}

Window.UserSettings:AddLabel("Menu Keybind"):AddKeybind({
    Default = "Insert",
    Callback = function(v) Window.Keybind = v end,
})

Window.UserSettings:AddLabel("Menu Scale"):AddDropdown({
    Default = "Default",
    Values = { "Default", "Large", "Mobile", "Small" },
    Callback = function(v)
        local scale = NeverLose.Scales[v]
        if scale then Window:SetSize(scale) end
    end,
})

local HitboxList = {"HumanoidRootPart","Head","LeftLowerArm","LowerTorso","RightHand","RightLowerArm","LeftFoot","LeftHand","RightFoot","RightLowerLeg","LeftLowerLeg","RightUpperArm","LeftUpperArm","UpperTorso","RightUpperLeg","LeftUpperLeg"}

do
    local WeaponModsBox = Section(Tabs.Rage, "Weapon Mods", "left")

    Toggle(WeaponModsBox, "Firerate", "Enable Firerate Changer", false)
    Slider(WeaponModsBox, "FirerateSlider", "Firerate", { Default = 0.01, Min = 0, Max = 1, Rounding = 3 })
    Toggle(WeaponModsBox, "NoRecoil", "Enable No Recoil", false)
    Toggle(WeaponModsBox, "NoSpread", "Enable No Spread", false)

    local CombatLegitBox = Section(Tabs.Legit, "Legit", "left")

    local aimbotLabel = Toggle(CombatLegitBox, "Aimbot", "Enable Aimbot", false)
    registry["AimbotHoldkey"] = aimbotLabel:AddKeybind({
        Default = "M2B",
        Callback = function() dispatch("AimbotHoldkey") end,
        Flag = "AimbotHoldkey",
    })

    local lblAimFov  = Toggle(CombatLegitBox, "AimbotUseFovCircle", "Use FOV Circle", false)
    local lblAimRad  = Slider(CombatLegitBox, "AimbotFovCircleRadius", "FOV Radius", { Default = 50, Min = 0, Max = 300, Rounding = 0 })
    local lblAimPart = Dropdown(CombatLegitBox, "AimbotHitPart", "Hit Selection", { Values = HitPartValues, Default = "Head", Multi = false })
    local lblAimTeam = Toggle(CombatLegitBox, "AimbotTeamCheck", "Enable Team Check", true)
    local lblAimWall = Toggle(CombatLegitBox, "AimbotWallCheck", "Enable Wall Check", true)

    Toggle(CombatLegitBox, "Triggerbot", "Enable Triggerbot", false)
    local lblTrigDelay = Slider(CombatLegitBox, "TriggerbotDelay", "Delay", { Default = 0.01, Min = 0, Max = 1, Rounding = 3 })

    Dependency("Aimbot", true, { lblAimFov, lblAimRad, lblAimPart, lblAimTeam, lblAimWall })
    Dependency("Triggerbot", true, { lblTrigDelay })

    local HitboxBox = Section(Tabs.Legit, "Hitbox Expander", "right")
    Toggle(HitboxBox, "Hitbox", "Enable Hitbox Expander", false)
    local lblHbSize  = Slider(HitboxBox, "HitboxSize", "Hitbox Size", { Default = 7, Min = 1, Max = 28, Rounding = 0 })
    local lblHbTrans = Slider(HitboxBox, "HitboxTransparency", "Hitbox Transparency", { Default = 0, Min = 0, Max = 1, Rounding = 2 })
    Dependency("Hitbox", true, { lblHbSize, lblHbTrans })

    local CombatBlatantBox = Section(Tabs.Rage, "Blatant", "left")
    local RageBlatantBox = Section(Tabs.Rage, "Rage", "right")

    Toggle(CombatBlatantBox, "SilentAim", "Enable Silent Aim", false)
    local lblSWall = Toggle(CombatBlatantBox, "SilentWallbang", "Wallbang", false)
    local lblSFov  = Toggle(CombatBlatantBox, "SilentUseFovCircle", "Use FOV Circle", false)
    local lblSRad  = Slider(CombatBlatantBox, "SilentFovCircleRadius", "FOV Radius", { Default = 50, Min = 0, Max = 300, Rounding = 0 })
    local lblSPart = Dropdown(CombatBlatantBox, "SilentHitPart", "Hit Selection", { Values = HitPartValues, Default = "Head", Multi = false })
    local lblSTeam = Toggle(CombatBlatantBox, "SilentTeamCheck", "Enable Team Check", true)
    Dependency("SilentAim", true, { lblSWall, lblSFov, lblSRad, lblSPart, lblSTeam })

    Toggle(RageBlatantBox, "Ragebot", "Enable Ragebot", false)
    local lblRDelay = Slider(RageBlatantBox, "RageDelay", "Delay", { Default = 0.01, Min = 0, Max = 1, Rounding = 3 })
    local lblRPart  = Dropdown(RageBlatantBox, "RageHitPart", "Hit Selection", { Values = HitPartValues, Default = "Head", Multi = false })
    local lblRVis   = Toggle(RageBlatantBox, "RagebotVisibleCheck", "Enable Visible Check", true)
    local lblRTeam  = Toggle(RageBlatantBox, "RagebotTeamCheck", "Enable Team Check", true)
    local lblRWall  = Toggle(RageBlatantBox, "RagebotWallCheck", "Enable Wall Check", false)
    Dependency("Ragebot", true, { lblRDelay, lblRPart, lblRVis, lblRTeam, lblRWall })

end

local function BuildBackend()

local UIS, RS, RepStore, LP = UserInputService, RunService, ReplicatedStorage, LocalPlayer
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")

local function GetUIParent()
    if gethui then return gethui() end
    return game:GetService("CoreGui")
end

local CurrentTheme = {
    Main = Color3.fromRGB(20, 20, 20),
    Item = Color3.fromRGB(30, 30, 30),
    Outline = Color3.fromRGB(60, 60, 60),
    Accent = Color3.fromRGB(255, 105, 180),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    TextStroke = Color3.fromRGB(0, 0, 0),
}
local function AddThemeObject(obj, tt)
    pcall(function() obj.TextColor3 = CurrentTheme[tt] end)
    return obj
end

do
    local targets = { game:GetService("CoreGui") }
    if gethui then pcall(function() targets[#targets + 1] = gethui() end) end
    for _, container in ipairs(targets) do
        for _, n in ipairs({ "SerenityOverlay", "ESP_Highlight_Container", "Charms_Container", "JBEB_Indicator" }) do
            local stale = container:FindFirstChild(n)
            if stale then pcall(function() stale:Destroy() end) end
        end
    end
end

local UI = Instance.new("ScreenGui")
UI.Name = "SerenityOverlay"
UI.IgnoreGuiInset = true
UI.ResetOnSpawn = false
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = GetUIParent()

local Conn, Drws = {}, {}

local function AC(c) 
    if c then 
        Conn[#Conn + 1] = c 
    end 
end

local function AD(d) 
    if d and type(d) ~= "number" then 
        Drws[#Drws + 1] = d 
    end 
end

local function Safe(f) 
    return function(...) 
        pcall(f, ...) 
    end 
end

local WorldESP = {DroppedWeapons = {}, Bomb = nil, Molotovs = {}, Smokes = {}}

local function DestroyWESP(e)
    if not e then return end
    for _, d in pairs(e.Box or {}) do 
        if d and type(d) ~= "number" then 
            pcall(d.Remove, d) 
        end 
    end
    if e.Name and type(e.Name) ~= "number" then 
        pcall(e.Name.Remove, e.Name) 
    end
    if e.HL then 
        pcall(e.HL.Destroy, e.HL) 
    end
    if e.Radius and type(e.Radius) ~= "number" then 
        pcall(e.Radius.Remove, e.Radius) 
    end
end

local G = {
    mousemoverel = mousemoverel or (mousemove and function(x, y) mousemove(x, y) end) or function() end,
    mouse1click = mouse1click or mouse_click or function() end,
    C3W = Color3.new(1, 1, 1),
    C3B = Color3.new(0, 0, 0),
    LastCharmVisCheck = 0,
    LastCharmScan = 0,
    LastCharmUpdate = 0,
    FrameCount = 0,
    lastFPSUpdate = tick(),
    LastESPUpdate = 0,
    LastGraphUpdate = 0,
    LastMovementUpdate = 0,
    lastTriggerTime = 0,
    LocalCharacter = nil,
    AimbotActive = false,
    TriggerbotActive = false,
    knifeChangerSupported = true,
    executor = (identifyexecutor and identifyexecutor()) or "Unknown",
    hasFileSystem = false,
    inspectWarningShown = false,
    LastMouseReleaseTime = 0,
    JumpBugActive = false,
    EdgeBugToggleActive = false
}

pcall(function() 
    if writefile and readfile then 
        G.hasFileSystem = true 
    end 
end)

local function SafeRequire(module)
    if not module then return nil end
    local success, result = pcall(function() return require(module) end)
    if success and result and type(result) == "table" then 
        return result 
    end
    return nil
end

local JB_VERT_BOOST = 3
local JB_HORIZ_BOOST = 2
local JB_MIN_FRAMES = 3

local jbebRP = RaycastParams.new()
jbebRP.FilterType = Enum.RaycastFilterType.Exclude
jbebRP.IgnoreWater = true
jbebRP.RespectCanCollide = true

local EB_Active = false
local JBEB_LastChar = nil
local JBActive = false
local JBCooldown = 0
local JBEB_FallFrames = 0
local JBEB_VelBuffer = {}
local JBEB_BufferSize = 15
local JBEB_WasAir = true
local JBEB_LandedFrame = false
local jbFlashTime = 0
local ebFlashTime = 0

local GndOffsets = {
    Vector3.new(0, 0, 0),
    Vector3.new(0.8, 0, 0),
    Vector3.new(-0.8, 0, 0),
    Vector3.new(0, 0, 0.8),
    Vector3.new(0, 0, -0.8)
}

local function JBEB_SetFilter(c)
    if c == JBEB_LastChar then return end
    JBEB_LastChar = c
    jbebRP.FilterDescendantsInstances = {c, workspace.CurrentCamera}
end

local function JBEB_GameGroundCheck(pos)
    for _, off in ipairs(GndOffsets) do
        local r = workspace:Raycast(pos + off, Vector3.new(0, -3.1, 0), jbebRP)
        if r and r.Normal.Y > 0.7 and r.Instance.CanCollide then 
            return true 
        end
    end
    return false
end

local function JBEB_IsNearEdge(pos)
    local center = workspace:Raycast(pos, Vector3.new(0, -3.5, 0), jbebRP)
    if center and center.Normal.Y > 0.7 then return false end

    local sideHits = 0
    local sideOffsets = {
        Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0),
        Vector3.new(0, 0, 2), Vector3.new(0, 0, -2),
        Vector3.new(1.5, 0, 1.5), Vector3.new(-1.5, 0, 1.5),
        Vector3.new(1.5, 0, -1.5), Vector3.new(-1.5, 0, -1.5)
    }
    for _, off in ipairs(sideOffsets) do
        local r = workspace:Raycast(pos + off, Vector3.new(0, -5, 0), jbebRP)
        if r and r.Normal.Y > 0.7 then 
            sideHits = sideHits + 1 
        end
    end
    if sideHits >= 2 then return true end

    local wallDirs = {Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0), Vector3.new(0, 0, 2), Vector3.new(0, 0, -2)}
    for yOff = 0, -3, -1 do
        for _, dir in ipairs(wallDirs) do
            local r = workspace:Raycast(pos + Vector3.new(0, yOff, 0), dir, jbebRP)
            if r and (pos + Vector3.new(0, yOff, 0) - r.Position).Magnitude < 2 then 
                return true 
            end
        end
    end
    return false
end

local function JBEB_StillOnEdge(pos)
    local center = workspace:Raycast(pos, Vector3.new(0, -3.5, 0), jbebRP)
    if center and center.Normal.Y > 0.7 then return false end

    for _, off in ipairs({Vector3.new(1.5, 0, 0), Vector3.new(-1.5, 0, 0), Vector3.new(0, 0, 1.5), Vector3.new(0, 0, -1.5)}) do
        local r = workspace:Raycast(pos + off, Vector3.new(0, -5, 0), jbebRP)
        if r then return true end
    end

    for _, dir in ipairs({Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0), Vector3.new(0, 0, 2), Vector3.new(0, 0, -2)}) do
        local r = workspace:Raycast(pos, dir, jbebRP)
        if r and (pos - r.Position).Magnitude < 2 then return true end
    end
    return false
end

local JBEB_IndicatorGui = nil
local JBEB_JBLabel = nil
local JBEB_EBLabel = nil

local SD = {SkinsRoot = nil, SkinSelections = {}, GloveSelections = {}, GloveFolders = {}}

pcall(function()
    SD.SkinsRoot = RepStore:FindFirstChild("Assets") and RepStore.Assets:FindFirstChild("Skins")
end)

if SD.SkinsRoot then
    pcall(function()
        for _, wf in ipairs(SD.SkinsRoot:GetChildren()) do
            local skins = {}
            for _, sf in ipairs(wf:GetChildren()) do 
                skins[#skins + 1] = sf.Name 
            end
            table.sort(skins)
            SD.SkinSelections[wf.Name] = skins
        end

        for _, folder in ipairs(SD.SkinsRoot:GetChildren()) do
            if (folder.Name:match("Glove") or folder.Name:match("Gloves") or folder.Name == "Hand Wraps") 
               and not (folder.Name:match("T Glove") or folder.Name:match("CT Glove") or folder.Name:match("T Gloves") or folder.Name:match("CT Gloves")) then
                SD.GloveFolders[#SD.GloveFolders + 1] = folder
            end
        end
    end)
end

for _, gf in ipairs(SD.GloveFolders) do
    local skins = {"Default"}
    for _, skin in ipairs(gf:GetChildren()) do 
        skins[#skins + 1] = skin.Name 
    end
    SD.GloveSelections[gf.Name] = skins
end

if string.find(G.executor, "RonixExploit", 1, true) or string.find(G.executor, "Xeno", 1, true) or string.find(G.executor, "Solara", 1, true) then 
    G.knifeChangerSupported = false 
end

if not RepStore:FindFirstChild("database") then 
    local db = Instance.new("Folder")
    db.Name = "database"
    db.Parent = RepStore 
end

local function RunOnActor(func)
    local success = false
    pcall(function()
        if not workspace:FindFirstChild("_SerenityActors") then 
            local af = Instance.new("Folder")
            af.Name = "_SerenityActors"
            af.Parent = workspace 
        end
        task.defer(func)
        success = true
    end)
    if not success then 
        pcall(func) 
    end
end

local SecondaryWeapons = {["USP-S"] = true, ["Glock-18"] = true, ["P250"] = true, ["Five-SeveN"] = true, ["Tec-9"] = true, ["Dual Berettas"] = true, ["Deagle"] = true, ["R8 Revolver"] = true, ["CZ75-Auto"] = true, ["P2000"] = true}
local ScopedWeapons = {["AWP"] = true, ["SSG 08"] = true, ["G3SG1"] = true, ["SCAR-20"] = true, ["AUG"] = true, ["SG 553"] = true}

local Camera = workspace.CurrentCamera

local Config = {
    ESP = {
        Enabled = false, Box = false, BoxOutline = false, BoxThickness = 1,
        BoxFill = false, BoxFillColor1 = Color3.fromRGB(255, 0, 0), BoxFillColor2 = Color3.fromRGB(0, 0, 255), BoxFillTransparency = 0.8, BoxFillFadeSpeed = 3,
        Name = false, NameSize = 13, Health = false, Skeleton = false, SkeletonThickness = 2,
        HeadDot = false, Highlight = false, Distance = false, TeamCheck = true, VisibilityCheck = false, MaxDistance = 2000,
        BoxColor = Color3.fromRGB(255, 255, 255), BoxVisibleColor = Color3.fromRGB(0, 255, 0), BoxNotVisibleColor = Color3.fromRGB(255, 0, 0),
        NameColor = Color3.fromRGB(255, 255, 255), NameVisibleColor = Color3.fromRGB(0, 255, 0), NameNotVisibleColor = Color3.fromRGB(255, 0, 0),
        SkeletonColor = Color3.fromRGB(255, 255, 255), SkeletonVisibleColor = Color3.fromRGB(0, 255, 0), SkeletonNotVisibleColor = Color3.fromRGB(255, 0, 0),
        HeadDotColor = Color3.fromRGB(255, 255, 255), HeadDotVisibleColor = Color3.fromRGB(0, 255, 0), HeadDotNotVisibleColor = Color3.fromRGB(255, 0, 0),
        HighlightFill = Color3.fromRGB(255, 0, 0), HighlightOutline = Color3.fromRGB(255, 255, 255),
        HighlightVisibleFill = Color3.fromRGB(0, 255, 0), HighlightHiddenFill = Color3.fromRGB(255, 0, 0),
        DistanceColor = Color3.fromRGB(255, 255, 255),
        HealthBarCustom = false, HealthBarColor = Color3.fromRGB(0, 255, 0),
        CurrentWeapon = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
        Bomb = {Enabled = false, Box = true, Highlight = true, Name = true, Color = Color3.fromRGB(255, 0, 0)},
        DroppedWeapons = {Enabled = false, Box = true, Highlight = true, Name = true, Color = Color3.fromRGB(255, 255, 255)},
        Molotovs = {Enabled = false, Highlight = true, Color = Color3.fromRGB(255, 165, 0)},
        Smokes = {Enabled = false, Highlight = true, Color = Color3.fromRGB(200, 200, 200)}
    },
    Charms = {Enabled = false, TeamCheck = true, VisibleColor = Color3.fromRGB(255, 0, 0), HiddenColor = Color3.fromRGB(255, 255, 255), Transparency = 0.5, AlwaysOnTop = true},
    SkinChanger = {Enabled = false, Skins = {}},
    KnifeChanger = {Enabled = false, Model = "Karambit"},
    GloveChanger = {Enabled = false, Gloves = {}, Model = "Sports Gloves", Skin = "Default"},
    Graph = {Enabled = false, Color = Color3.fromRGB(255, 255, 255), MaxSpeed = 50, PeakEnabled = false},
    MovementDisplay = {Enabled = false, Color = Color3.fromRGB(255, 255, 255)},
    AutoBhop = false,
    BhopKey = Enum.KeyCode.Space,
    JumpBug = {Enabled = false, Power = 1.0, Mode = "Always", Key = Enum.KeyCode.V},
    EdgeBug = {Enabled = false, MaxDuration = 2.0, Range = 8, Mode = "Always", Key = Enum.KeyCode.B},
    JBEBIndicator = true,
    JBColor = Color3.fromRGB(255, 255, 255),
    EBColor = Color3.fromRGB(255, 255, 255)
}

local ESP_ = {Players = {}}
local CharmCache = {}
local CharmVisCache = {}

for w, s in pairs(SD.SkinSelections) do 
    Config.SkinChanger.Skins[w] = s[1] or "Default" 
end
for _, gf in ipairs(SD.GloveFolders) do 
    Config.GloveChanger.Gloves[gf.Name] = "Default" 
end

local function is_enemy(plr)
    if plr == Players.LocalPlayer then return false end
    if plr.Team and Players.LocalPlayer.Team then return plr.Team ~= Players.LocalPlayer.Team end
    local mc = Players.LocalPlayer.Character
    local tc = plr.Character
    if not mc or not tc or not mc.Parent or not tc.Parent then return false end
    return mc.Parent.Name ~= tc.Parent.Name
end

local Checkifbaseknife = {"CT Knife", "T Knife", "Knife"}
local function Checkknife(w)
    if not w then return false end
    for _, k in ipairs(Checkifbaseknife) do
        if w == k then return true end
    end
    return false
end

local function MakeDraggable(obj, dh)
    local handle = dh or obj
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ds = input.Position
            local sp = obj.Position
            local ic, ie
            ic = UIS.InputChanged:Connect(function(mi)
                if mi.UserInputType == Enum.UserInputType.MouseMovement then
                    local d = mi.Position - ds
                    obj.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
                end
            end)
            ie = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if ic then ic:Disconnect() end
                    if ie then ie:Disconnect() end
                end
            end)
        end
    end)
end

local function IsHoldKeyDown(key)
    if not key then return false end
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.KeyCode then return UIS:IsKeyDown(key)
        elseif key.EnumType == Enum.UserInputType then return UIS:IsMouseButtonPressed(key) end
    end
    return false
end

local function IsJBEBActive(config)
    if config.Mode == "Always" then
        return config.Enabled
    elseif config.Mode == "Toggle" then
        if config == Config.JumpBug then
            return config.Enabled and G.JumpBugActive
        else
            return config.Enabled and G.EdgeBugToggleActive
        end
    elseif config.Mode == "Hold" then
        return config.Enabled and IsHoldKeyDown(config.Key)
    end
    return false
end

local ESPFolder
pcall(function()
    ESPFolder = Instance.new("Folder", game:GetService("CoreGui"))
    ESPFolder.Name = "ESP_Highlight_Container"
end)

local function NewDrawing(dt, props)
    local s, d = pcall(function()
        local dr = Drawing.new(dt)
        if dr and type(dr) ~= "number" then
            for k, v in pairs(props) do
                pcall(function() dr[k] = v end)
            end
            return dr
        end
        return nil
    end)
    if s and d and type(d) ~= "number" then
        AD(d)
        return d
    end
    return nil
end

local function CreatePlayerESP()
    local e = {Box = {}, BoxOutline = {}, Skeleton = {}, Fill = {}, LastVisCheck = 0, IsVisible = false, Valid = false, Root = nil, HeadPart = nil, Hum = nil, Char = nil}
    for i = 1, 4 do
        local outline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0, 0, 0), Visible = false, ZIndex = 1})
        if outline and type(outline) ~= "number" then e.BoxOutline[i] = outline end
        local box = NewDrawing("Line", {Thickness = 1, Visible = false, ZIndex = 2})
        if box and type(box) ~= "number" then e.Box[i] = box end
    end
    for i = 1, 2 do
        pcall(function()
            local tri = Drawing.new("Triangle")
            if tri and type(tri) ~= "number" then
                tri.Filled = true
                tri.Visible = false
                tri.Transparency = 0
                tri.ZIndex = 0
                AD(tri)
                e.Fill[i] = tri
            end
        end)
    end
    for i = 1, 20 do
        local skel = NewDrawing("Line", {Thickness = 2, Visible = false})
        if skel and type(skel) ~= "number" then e.Skeleton[i] = skel end
    end
    local headDot = NewDrawing("Circle", {Thickness = 1, NumSides = 30, Filled = false, Visible = false})
    if headDot and type(headDot) ~= "number" then e.HeadDot = headDot end
    local hpBg = NewDrawing("Line", {Thickness = 2, Visible = false, Color = Color3.new(0, 0, 0), Transparency = 0.5, ZIndex = 2})
    if hpBg and type(hpBg) ~= "number" then e.HpBg = hpBg end
    local hp = NewDrawing("Line", {Thickness = 2, Visible = false, ZIndex = 3})
    if hp and type(hp) ~= "number" then e.Hp = hp end
    local name = NewDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Visible = false})
    if name and type(name) ~= "number" then e.Name = name end
    local dist = NewDrawing("Text", {Size = 11, Center = true, Outline = true, Font = 2, Visible = false})
    if dist and type(dist) ~= "number" then e.Dist = dist end
    local weaponName = NewDrawing("Text", {Size = 12, Center = false, Outline = true, Font = 2, Visible = false})
    if weaponName and type(weaponName) ~= "number" then e.WeaponName = weaponName end
    pcall(function()
        if ESPFolder then
            e.HL = Instance.new("Highlight")
            e.HL.FillTransparency = 0.5
            e.HL.OutlineTransparency = 0
            e.HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            e.HL.Enabled = false
            e.HL.Parent = ESPFolder
        end
    end)
    return e
end

local function DestroyPlayerESP(e)
    if not e then return end
    for _, d in pairs(e.Box) do if d and type(d) ~= "number" then pcall(function() d:Remove() end) end end
    for _, d in pairs(e.BoxOutline) do if d and type(d) ~= "number" then pcall(function() d:Remove() end) end end
    for _, d in pairs(e.Skeleton) do if d and type(d) ~= "number" then pcall(function() d:Remove() end) end end
    for _, d in pairs(e.Fill) do if d and type(d) ~= "number" then pcall(function() d:Remove() end) end end
    if e.HeadDot and type(e.HeadDot) ~= "number" then pcall(function() e.HeadDot:Remove() end) end
    if e.HpBg and type(e.HpBg) ~= "number" then pcall(function() e.HpBg:Remove() end) end
    if e.Hp and type(e.Hp) ~= "number" then pcall(function() e.Hp:Remove() end) end
    if e.Name and type(e.Name) ~= "number" then pcall(function() e.Name:Remove() end) end
    if e.Dist and type(e.Dist) ~= "number" then pcall(function() e.Dist:Remove() end) end
    if e.WeaponName and type(e.WeaponName) ~= "number" then pcall(function() e.WeaponName:Remove() end) end
    if e.HL then pcall(function() e.HL:Destroy() end) end
end

local function HidePlayerESP(e)
    if not e then return end
    for _, d in pairs(e.Box) do if d and type(d) ~= "number" then pcall(function() d.Visible = false end) end end
    for _, d in pairs(e.BoxOutline) do if d and type(d) ~= "number" then pcall(function() d.Visible = false end) end end
    for _, d in pairs(e.Skeleton) do if d and type(d) ~= "number" then pcall(function() d.Visible = false end) end end
    for _, d in pairs(e.Fill) do if d and type(d) ~= "number" then pcall(function() d.Visible = false end) end end
    if e.HeadDot and type(e.HeadDot) ~= "number" then pcall(function() e.HeadDot.Visible = false end) end
    if e.HpBg and type(e.HpBg) ~= "number" then pcall(function() e.HpBg.Visible = false end) end
    if e.Hp and type(e.Hp) ~= "number" then pcall(function() e.Hp.Visible = false end) end
    if e.Name and type(e.Name) ~= "number" then pcall(function() e.Name.Visible = false end) end
    if e.Dist and type(e.Dist) ~= "number" then pcall(function() e.Dist.Visible = false end) end
    if e.WeaponName and type(e.WeaponName) ~= "number" then pcall(function() e.WeaponName.Visible = false end) end
    if e.HL then pcall(function() e.HL.Enabled = false end) end
end

local function CreateWorldESPObject(hasName, hasRadius)
    local e = {Box = {}, HL = nil, Model = nil}
    if hasName then
        local name = NewDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Visible = false})
        if name and type(name) ~= "number" then e.Name = name end
    end
    if hasRadius then
        local radius = NewDrawing("Circle", {Thickness = 1.5, Filled = false, Visible = false, NumSides = 60})
        if radius and type(radius) ~= "number" then e.Radius = radius end
    end
    for i = 1, 4 do
        local box = NewDrawing("Line", {Thickness = 1, Visible = false, ZIndex = 2})
        if box and type(box) ~= "number" then e.Box[i] = box end
    end
    if ESPFolder then
        pcall(function()
            e.HL = Instance.new("Highlight")
            e.HL.FillTransparency = 0.5
            e.HL.OutlineTransparency = 0
            e.HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            e.HL.Enabled = false
            e.HL.Parent = ESPFolder
        end)
    end
    return e
end

local function HideWorldESPObject(e)
    if not e then return end
    for _, d in pairs(e.Box) do if d and type(d) ~= "number" then pcall(function() d.Visible = false end) end end
    if e.Name and type(e.Name) ~= "number" then pcall(function() e.Name.Visible = false end) end
    if e.Radius and type(e.Radius) ~= "number" then pcall(function() e.Radius.Visible = false end) end
    if e.HL then pcall(function() e.HL.Enabled = false end) end
end

local function HideAllWorldESP()
    for _, eo in pairs(WorldESP.DroppedWeapons) do HideWorldESPObject(eo) end
    if WorldESP.Bomb then HideWorldESPObject(WorldESP.Bomb) end
    for _, eo in pairs(WorldESP.Molotovs) do HideWorldESPObject(eo) end
    for _, eo in pairs(WorldESP.Smokes) do HideWorldESPObject(eo) end
end

local BONES_R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"LowerTorso","HumanoidRootPart"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"HumanoidRootPart","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"HumanoidRootPart","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local BONES_R6 = {{"Head","Torso"},{"Torso","HumanoidRootPart"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"HumanoidRootPart","Left Leg"},{"HumanoidRootPart","Right Leg"}}

local bonePosCache = {}

local function HideAllPlayerESP()
    for _, e in pairs(ESP_.Players) do
        HidePlayerESP(e)
    end
end

local InventoryController, GetWeaponProperties

local function InitInventory()
    if not G.knifeChangerSupported then return end
    if not InventoryController then
        pcall(function()
            local module = RepStore:FindFirstChild("Controllers") and RepStore.Controllers:FindFirstChild("InventoryController")
            if module then
                local result = SafeRequire(module)
                if result then InventoryController = result end
            end
        end)
    end
    if not GetWeaponProperties then
        pcall(function()
            local module = RepStore:FindFirstChild("Components") and RepStore.Components:FindFirstChild("Common") and RepStore.Components.Common:FindFirstChild("GetWeaponProperties")
            if module then
                local result = SafeRequire(module)
                if result then GetWeaponProperties = result end
            end
        end)
    end
end

InitInventory()
if not InventoryController then G.knifeChangerSupported = false end

local Router
pcall(function()
    local module = RepStore:FindFirstChild("Database") and RepStore.Database:FindFirstChild("Security") and RepStore.Database.Security:FindFirstChild("Router")
    if module then Router = SafeRequire(module) end
end)

local function inspectWeapon(weapon, skin, float)
    if not Router then return end
    pcall(function() Router.broadcastRouter("WeaponInspect", weapon, skin, float or 0.01, nil, nil, nil, nil, "Weapon", nil, "fake_id", nil, false) end)
end

local RP_ = {aimbot = RaycastParams.new(), trigger = RaycastParams.new(), esp = RaycastParams.new(), aa = RaycastParams.new()}
RP_.aimbot.FilterType = Enum.RaycastFilterType.Exclude
RP_.trigger.FilterType = Enum.RaycastFilterType.Exclude
RP_.esp.FilterType = Enum.RaycastFilterType.Exclude
RP_.esp.IgnoreWater = true
RP_.aa.FilterType = Enum.RaycastFilterType.Exclude

local espF = {nil, nil}

local function ESP_IsVisible(char, pos)
    if not G.LocalCharacter or not char or not char.Parent then return true end
    local op = G.LocalCharacter:FindFirstChild("Head") or G.LocalCharacter.PrimaryPart or G.LocalCharacter:FindFirstChild("HumanoidRootPart")
    if not op then return true end
    local o = op.Position
    espF[1] = G.LocalCharacter
    espF[2] = char
    pcall(function() RP_.esp.FilterDescendantsInstances = espF end)
    for _, nm in ipairs({"Head", "HumanoidRootPart"}) do
        local pt = char:FindFirstChild(nm)
        if pt and pt:IsA("BasePart") then
            local dr = pt.Position - o
            if dr.Magnitude > 1 then
                if not workspace:Raycast(o, dr.Unit * (dr.Magnitude - 0.5), RP_.esp) then return true end
            end
        end
    end
    return false
end

local function GetColor(base, vis, nvis, visible)
    if Config.ESP.VisibilityCheck then return visible and vis or nvis end
    return base
end

RunOnActor(function()
    task.spawn(function()
        while true do
            if Config.ESP.Enabled then
                for plr, e in pairs(ESP_.Players) do
                    pcall(function()
                        local ch = plr.Character
                        if not ch or not ch.Parent then e.Valid = false return end
                        local rt = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
                        local hm = ch:FindFirstChildWhichIsA("Humanoid")
                        if not rt or not hm or hm.Health <= 0 then e.Valid = false return end
                        if Config.ESP.TeamCheck and not is_enemy(plr) then e.Valid = false return end
                        e.Root = rt
                        e.HeadPart = ch:FindFirstChild("Head")
                        e.Hum = hm
                        e.Char = ch
                        e.Valid = true
                    end)
                end
            end
            task.wait(0.5)
        end
    end)
end)

local V2 = Vector2.new
local V3 = Vector3.new

local function Draw2DBox(eo, center, size, col, show)
    local hw = size.X / 2
    local hh = size.Y / 2
    local tl = V2(center.X - hw, center.Y - hh)
    local tr = V2(center.X + hw, center.Y - hh)
    local bl = V2(center.X - hw, center.Y + hh)
    local br = V2(center.X + hw, center.Y + hh)

    if show then
        if eo.Box[1] and type(eo.Box[1]) ~= "number" then eo.Box[1].From = tl eo.Box[1].To = tr eo.Box[1].Color = col eo.Box[1].Visible = true end
        if eo.Box[2] and type(eo.Box[2]) ~= "number" then eo.Box[2].From = tr eo.Box[2].To = br eo.Box[2].Color = col eo.Box[2].Visible = true end
        if eo.Box[3] and type(eo.Box[3]) ~= "number" then eo.Box[3].From = br eo.Box[3].To = bl eo.Box[3].Color = col eo.Box[3].Visible = true end
        if eo.Box[4] and type(eo.Box[4]) ~= "number" then eo.Box[4].From = bl eo.Box[4].To = tl eo.Box[4].Color = col eo.Box[4].Visible = true end
    else
        for i = 1, 4 do 
            if eo.Box[i] and type(eo.Box[i]) ~= "number" then eo.Box[i].Visible = false end 
        end
    end
    return tl
end

local function GetFolderRadius(folder)
    if not folder or not folder:IsA("Folder") then return 0 end
    local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
    local count = 0
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            local p = child.Position
            local s = child.Size
            minX = math.min(minX, p.X - s.X / 2)
            maxX = math.max(maxX, p.X + s.X / 2)
            minZ = math.min(minZ, p.Z - s.Z / 2)
            maxZ = math.max(maxZ, p.Z + s.Z / 2)
            count = count + 1
        end
    end
    if count == 0 then return 0 end
    return math.max(maxX - minX, maxZ - minZ) / 2
end

local function GetFolderCenter(folder)
    if not folder or not folder:IsA("Folder") then return nil end
    local sum = V3(0, 0, 0)
    local count = 0
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            sum = sum + child.Position
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return sum / count
end

local function UpdateWorldESP()
    if not Camera then HideAllWorldESP() return end
    local ch = G.LocalCharacter
    local hm = ch and ch:FindFirstChildWhichIsA("Humanoid")
    if not ch or not hm or hm.Health <= 0 then HideAllWorldESP() return end

    local wtvp = Camera.WorldToViewportPoint

    if Config.ESP.DroppedWeapons.Enabled then
        for item, eo in pairs(WorldESP.DroppedWeapons) do
            if not item or not item.Parent or not item.PrimaryPart then HideWorldESPObject(eo) continue end
            local pp = item.PrimaryPart
            local pos, on = wtvp(Camera, pp.Position)
            if not on or pos.Z <= 0 then HideWorldESPObject(eo) continue end
            Draw2DBox(eo, V2(pos.X, pos.Y), V2(30, 20), Config.ESP.DroppedWeapons.Color, Config.ESP.DroppedWeapons.Box)
            if eo.Name and type(eo.Name) ~= "number" then
                if Config.ESP.DroppedWeapons.Name then
                    eo.Name.Text = item:GetAttribute("Weapon") or "Weapon"
                    eo.Name.Size = 13
                    eo.Name.Position = V2(pos.X, pos.Y - 25)
                    eo.Name.Color = Config.ESP.DroppedWeapons.Color
                    eo.Name.Visible = true
                else eo.Name.Visible = false end
            end
            if eo.HL then 
                eo.HL.Adornee = item
                eo.HL.FillColor = Config.ESP.DroppedWeapons.Color
                eo.HL.OutlineColor = G.C3W
                eo.HL.Enabled = Config.ESP.DroppedWeapons.Highlight 
            end
        end
    else 
        for _, eo in pairs(WorldESP.DroppedWeapons) do HideWorldESPObject(eo) end 
    end

    if Config.ESP.Bomb.Enabled and WorldESP.Bomb and WorldESP.Bomb.Model and WorldESP.Bomb.Model.PrimaryPart then
        local eo = WorldESP.Bomb
        local item = eo.Model
        local cf, sz = item:GetBoundingBox()
        local pos, on = wtvp(Camera, cf.Position)
        if on and pos.Z > 0 then
            local topS = wtvp(Camera, cf.Position + V3(0, sz.Y / 2, 0))
            local botS = wtvp(Camera, cf.Position - V3(0, sz.Y / 2, 0))
            local sH = math.clamp(math.abs(topS.Y - botS.Y), 10, 80)
            Draw2DBox(eo, V2(pos.X, (topS.Y + botS.Y) / 2), V2(math.clamp(sH * 0.8, 10, 60), sH), Config.ESP.Bomb.Color, Config.ESP.Bomb.Box)
            if eo.Name and type(eo.Name) ~= "number" then
                if Config.ESP.Bomb.Name then 
                    eo.Name.Text = "C4"
                    eo.Name.Position = V2(pos.X, topS.Y - 15)
                    eo.Name.Color = Config.ESP.Bomb.Color
                    eo.Name.Visible = true
                else eo.Name.Visible = false end
            end
            if eo.HL then 
                eo.HL.Adornee = item
                eo.HL.FillColor = Config.ESP.Bomb.Color
                eo.HL.OutlineColor = G.C3W
                eo.HL.Enabled = Config.ESP.Bomb.Highlight 
            end
        else 
            HideWorldESPObject(eo) 
        end
    elseif WorldESP.Bomb then 
        HideWorldESPObject(WorldESP.Bomb) 
    end

    if Config.ESP.Molotovs.Enabled then
        for item, eo in pairs(WorldESP.Molotovs) do
            if not item or not item.Parent then HideWorldESPObject(eo) continue end
            local center = GetFolderCenter(item)
            local radius = GetFolderRadius(item)
            if center and radius > 0 then
                local pos, on = wtvp(Camera, center)
                if on and pos.Z > 0 then
                    local edgePos = wtvp(Camera, center + Camera.CFrame.RightVector * radius)
                    local screenRadius = math.clamp((V2(edgePos.X, edgePos.Y) - V2(pos.X, pos.Y)).Magnitude, 5, 200)
                    if eo.Radius and type(eo.Radius) ~= "number" then 
                        eo.Radius.Position = V2(pos.X, pos.Y)
                        eo.Radius.Radius = screenRadius
                        eo.Radius.Color = Config.ESP.Molotovs.Color
                        eo.Radius.Visible = true 
                    end
                    if eo.Name and type(eo.Name) ~= "number" then 
                        eo.Name.Text = "Fire"
                        eo.Name.Position = V2(pos.X, pos.Y - 15)
                        eo.Name.Color = Config.ESP.Molotovs.Color
                        eo.Name.Visible = true 
                    end
                else
                    if eo.Radius and type(eo.Radius) ~= "number" then eo.Radius.Visible = false end
                    if eo.Name and type(eo.Name) ~= "number" then eo.Name.Visible = false end
                end
            end
            if eo.HL then
                local fc
                for _, c in pairs(item:GetChildren()) do 
                    if c:IsA("BasePart") then fc = c break end 
                end
                if fc then 
                    eo.HL.Adornee = fc
                    eo.HL.FillColor = Config.ESP.Molotovs.Color
                    eo.HL.OutlineColor = G.C3W
                    eo.HL.Enabled = Config.ESP.Molotovs.Highlight 
                else 
                    eo.HL.Enabled = false 
                end
            end
            for i = 1, 4 do 
                if eo.Box[i] and type(eo.Box[i]) ~= "number" then eo.Box[i].Visible = false end 
            end
        end
    else 
        for _, eo in pairs(WorldESP.Molotovs) do HideWorldESPObject(eo) end 
    end

    if Config.ESP.Smokes.Enabled then
        for item, eo in pairs(WorldESP.Smokes) do
            if not item or not item.Parent then HideWorldESPObject(eo) continue end
            local center = GetFolderCenter(item)
            local radius = GetFolderRadius(item)
            if center and radius > 0 then
                local pos, on = wtvp(Camera, center)
                if on and pos.Z > 0 then
                    local edgePos = wtvp(Camera, center + Camera.CFrame.RightVector * radius)
                    local screenRadius = math.clamp((V2(edgePos.X, edgePos.Y) - V2(pos.X, pos.Y)).Magnitude, 5, 200)
                    if eo.Radius and type(eo.Radius) ~= "number" then 
                        eo.Radius.Position = V2(pos.X, pos.Y)
                        eo.Radius.Radius = screenRadius
                        eo.Radius.Color = Config.ESP.Smokes.Color
                        eo.Radius.Visible = true 
                    end
                    if eo.Name and type(eo.Name) ~= "number" then 
                        eo.Name.Text = "Smoke"
                        eo.Name.Position = V2(pos.X, pos.Y - 15)
                        eo.Name.Color = Config.ESP.Smokes.Color
                        eo.Name.Visible = true 
                    end
                else
                    if eo.Radius and type(eo.Radius) ~= "number" then eo.Radius.Visible = false end
                    if eo.Name and type(eo.Name) ~= "number" then eo.Name.Visible = false end
                end
            end
            if eo.HL then
                local fc
                for _, c in pairs(item:GetChildren()) do 
                    if c:IsA("BasePart") then fc = c break end 
                end
                if fc then 
                    eo.HL.Adornee = fc
                    eo.HL.FillColor = Config.ESP.Smokes.Color
                    eo.HL.OutlineColor = G.C3W
                    eo.HL.Enabled = Config.ESP.Smokes.Highlight 
                else 
                    eo.HL.Enabled = false 
                end
            end
            for i = 1, 4 do 
                if eo.Box[i] and type(eo.Box[i]) ~= "number" then eo.Box[i].Visible = false end 
            end
        end
    else 
        for _, eo in pairs(WorldESP.Smokes) do HideWorldESPObject(eo) end 
    end
end

local function UpdateESP()
    if not Camera or not Config.ESP.Enabled then return end
    if tick() - G.LastESPUpdate < 0.016 then return end
    G.LastESPUpdate = tick()

    local wtvp = Camera.WorldToViewportPoint
    local camPos = Camera.CFrame.Position
    local fillT = (math.sin(tick() * (Config.ESP.BoxFillFadeSpeed or 3)) + 1) / 2
    local fillCol = Config.ESP.BoxFillColor1:Lerp(Config.ESP.BoxFillColor2, fillT)

    for plr, e in pairs(ESP_.Players) do
        if not plr or not plr.Parent then 
            DestroyPlayerESP(e)
            ESP_.Players[plr] = nil
            continue 
        end
        if not e.Valid then HidePlayerESP(e) continue end

        local char, root, headPart, hum = e.Char, e.Root, e.HeadPart, e.Hum
        if not root or not root.Parent then HidePlayerESP(e) continue end
        if hum and hum.Health <= 0 then HidePlayerESP(e) continue end

        local dist = (camPos - root.Position).Magnitude
        if dist > Config.ESP.MaxDistance then HidePlayerESP(e) continue end

        local skip = false
        pcall(function() 
            if Camera.CameraSubject then 
                local subj = Camera.CameraSubject
                if subj == char or (subj.Parent and subj:IsDescendantOf(char)) then skip = true end 
            end 
        end)
        if skip then HidePlayerESP(e) continue end

        local rootScreen, onScreen = wtvp(Camera, root.Position)
        if not onScreen or rootScreen.Z <= 0 then HidePlayerESP(e) continue end

        local isVis = e.IsVisible
        if Config.ESP.VisibilityCheck and (tick() - e.LastVisCheck > 0.1) then 
            isVis = ESP_IsVisible(char, headPart and headPart.Position or root.Position)
            e.IsVisible = isVis
            e.LastVisCheck = tick()
        elseif not Config.ESP.VisibilityCheck then 
            isVis = true
            e.IsVisible = true 
        end

        local rP = root.Position
        local hP = headPart and headPart.Position or (rP + V3(0, 2, 0))

        local topScreen = wtvp(Camera, hP + V3(0, 1, 0))
        local botScreen = wtvp(Camera, rP - V3(0, 3, 0))
        if topScreen.Z <= 0 or botScreen.Z <= 0 then HidePlayerESP(e) continue end

        local topY, botY = topScreen.Y, botScreen.Y
        local sH = math.abs(botY - topY)
        local sW = sH * 0.55
        local cx = rootScreen.X

        local tl = V2(cx - sW / 2, topY)
        local tr = V2(cx + sW / 2, topY)
        local bl = V2(cx - sW / 2, botY)
        local br = V2(cx + sW / 2, botY)

        if Config.ESP.Box then
            local col = GetColor(Config.ESP.BoxColor, Config.ESP.BoxVisibleColor, Config.ESP.BoxNotVisibleColor, isVis)
            for i = 1, 4 do 
                if e.Box[i] and type(e.Box[i]) ~= "number" then e.Box[i].Thickness = Config.ESP.BoxThickness end 
            end
            if e.Box[1] and type(e.Box[1]) ~= "number" then e.Box[1].From = tl e.Box[1].To = tr e.Box[1].Color = col e.Box[1].Visible = true end
            if e.Box[2] and type(e.Box[2]) ~= "number" then e.Box[2].From = tr e.Box[2].To = br e.Box[2].Color = col e.Box[2].Visible = true end
            if e.Box[3] and type(e.Box[3]) ~= "number" then e.Box[3].From = br e.Box[3].To = bl e.Box[3].Color = col e.Box[3].Visible = true end
            if e.Box[4] and type(e.Box[4]) ~= "number" then e.Box[4].From = bl e.Box[4].To = tl e.Box[4].Color = col e.Box[4].Visible = true end

            if Config.ESP.BoxOutline then
                for i = 1, 4 do 
                    if e.BoxOutline[i] and type(e.BoxOutline[i]) ~= "number" and e.Box[i] and type(e.Box[i]) ~= "number" then 
                        e.BoxOutline[i].From = e.Box[i].From
                        e.BoxOutline[i].To = e.Box[i].To
                        e.BoxOutline[i].Thickness = Config.ESP.BoxThickness + 2
                        e.BoxOutline[i].Color = Color3.new(0, 0, 0)
                        e.BoxOutline[i].ZIndex = 1
                        e.BoxOutline[i].Visible = true 
                    end 
                end
            else 
                for i = 1, 4 do 
                    if e.BoxOutline[i] and type(e.BoxOutline[i]) ~= "number" then e.BoxOutline[i].Visible = false end 
                end 
            end
        else
            for i = 1, 4 do 
                if e.Box[i] and type(e.Box[i]) ~= "number" then e.Box[i].Visible = false end
                if e.BoxOutline[i] and type(e.BoxOutline[i]) ~= "number" then e.BoxOutline[i].Visible = false end 
            end
        end

        if Config.ESP.BoxFill and e.Fill[1] and e.Fill[2] then
            pcall(function()
                if type(e.Fill[1]) ~= "number" then 
                    e.Fill[1].PointA = tl
                    e.Fill[1].PointB = tr
                    e.Fill[1].PointC = bl
                    e.Fill[1].Color = fillCol
                    e.Fill[1].Transparency = 1 - Config.ESP.BoxFillTransparency
                    e.Fill[1].Filled = true
                    e.Fill[1].Visible = true 
                end
                if type(e.Fill[2]) ~= "number" then 
                    e.Fill[2].PointA = tr
                    e.Fill[2].PointB = br
                    e.Fill[2].PointC = bl
                    e.Fill[2].Color = fillCol
                    e.Fill[2].Transparency = 1 - Config.ESP.BoxFillTransparency
                    e.Fill[2].Filled = true
                    e.Fill[2].Visible = true 
                end
            end)
        else 
            for i = 1, 2 do 
                if e.Fill[i] and type(e.Fill[i]) ~= "number" then pcall(function() e.Fill[i].Visible = false end) end 
            end 
        end

        local tY = tl.Y - 18

        if Config.ESP.Name and e.Name and type(e.Name) ~= "number" then 
            e.Name.Size = Config.ESP.NameSize
            e.Name.Text = plr.Name
            e.Name.Position = V2(cx, tY)
            e.Name.Color = GetColor(Config.ESP.NameColor, Config.ESP.NameVisibleColor, Config.ESP.NameNotVisibleColor, isVis)
            e.Name.Visible = true
            tY = tY + Config.ESP.NameSize
        elseif e.Name and type(e.Name) ~= "number" then 
            e.Name.Visible = false 
        end

        if Config.ESP.CurrentWeapon.Enabled and e.WeaponName and type(e.WeaponName) ~= "number" then
            local ea = plr:GetAttribute("CurrentEquipped")
            if ea and type(ea) == "string" then 
                local s, ed = pcall(HS.JSONDecode, HS, ea)
                if s and ed and ed.Name then 
                    e.WeaponName.Text = ed.Name
                    e.WeaponName.Color = Config.ESP.CurrentWeapon.Color
                    e.WeaponName.Position = V2(tr.X + 5, (tl.Y + bl.Y) / 2)
                    e.WeaponName.Visible = true 
                else 
                    e.WeaponName.Visible = false 
                end
            else 
                e.WeaponName.Visible = false 
            end
        elseif e.WeaponName and type(e.WeaponName) ~= "number" then 
            e.WeaponName.Visible = false 
        end

        if Config.ESP.HeadDot and e.HeadDot and type(e.HeadDot) ~= "number" then
            local hp = wtvp(Camera, hP)
            if hp.Z > 0 then 
                e.HeadDot.Position = V2(hp.X, hp.Y)
                e.HeadDot.Radius = math.max(sW / 10, 3)
                e.HeadDot.Color = GetColor(Config.ESP.HeadDotColor, Config.ESP.HeadDotVisibleColor, Config.ESP.HeadDotNotVisibleColor, isVis)
                e.HeadDot.Visible = true 
            else 
                e.HeadDot.Visible = false 
            end
        elseif e.HeadDot and type(e.HeadDot) ~= "number" then 
            e.HeadDot.Visible = false 
        end

        if Config.ESP.Distance and e.Dist and type(e.Dist) ~= "number" then 
            e.Dist.Size = 11
            e.Dist.Text = math.floor(dist) .. "m"
            e.Dist.Position = V2(cx, bl.Y + 2)
            e.Dist.Color = Config.ESP.DistanceColor
            e.Dist.Visible = true
        elseif e.Dist and type(e.Dist) ~= "number" then 
            e.Dist.Visible = false 
        end

        if Config.ESP.Health and hum then
            local hp, mhp = hum.Health, hum.MaxHealth
            if mhp <= 0 then mhp = 100 end
            if hp > mhp then mhp = hp end
            local hpF = math.clamp(hp / mhp, 0, 1)
            local bx = tl.X - 5
            local barH = sH * hpF
            if e.HpBg and type(e.HpBg) ~= "number" then 
                e.HpBg.From = V2(bx, bl.Y)
                e.HpBg.To = V2(bx, tl.Y)
                e.HpBg.Visible = true 
            end
            if e.Hp and type(e.Hp) ~= "number" then 
                e.Hp.From = V2(bx, bl.Y)
                e.Hp.To = V2(bx, bl.Y - barH)
                e.Hp.Color = Config.ESP.HealthBarCustom and Config.ESP.HealthBarColor or Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpF)
                e.Hp.ZIndex = 3
                e.Hp.Visible = true 
            end
        else 
            if e.HpBg and type(e.HpBg) ~= "number" then e.HpBg.Visible = false end
            if e.Hp and type(e.Hp) ~= "number" then e.Hp.Visible = false end 
        end

        if Config.ESP.Skeleton and hum and dist < 300 then
            local skelCol = GetColor(Config.ESP.SkeletonColor, Config.ESP.SkeletonVisibleColor, Config.ESP.SkeletonNotVisibleColor, isVis)
            local isR15 = char:FindFirstChild("UpperTorso") ~= nil
            local bones = isR15 and BONES_R15 or BONES_R6
            table.clear(bonePosCache)
            for i, pair in ipairs(bones) do 
                local ln = e.Skeleton[i]
                if not ln or type(ln) == "number" then continue end
                local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1 = bonePosCache[pair[1]]
                    if not s1 then 
                        local p = wtvp(Camera, p1.Position)
                        if p.Z > 0 then s1 = V2(p.X, p.Y) end
                        bonePosCache[pair[1]] = s1 
                    end
                    local s2 = bonePosCache[pair[2]]
                    if not s2 then 
                        local p = wtvp(Camera, p2.Position)
                        if p.Z > 0 then s2 = V2(p.X, p.Y) end
                        bonePosCache[pair[2]] = s2 
                    end
                    if s1 and s2 then 
                        ln.Color = skelCol
                        ln.From = s1
                        ln.To = s2
                        ln.Thickness = Config.ESP.SkeletonThickness
                        ln.Visible = true 
                    else 
                        ln.Visible = false 
                    end
                else 
                    ln.Visible = false 
                end 
            end
            for i = #bones + 1, #e.Skeleton do 
                if e.Skeleton[i] and type(e.Skeleton[i]) ~= "number" then e.Skeleton[i].Visible = false end 
            end
        else 
            for _, ln in pairs(e.Skeleton) do 
                if ln and type(ln) ~= "number" then ln.Visible = false end 
            end 
        end

        if Config.ESP.Highlight and e.HL then 
            pcall(function() 
                e.HL.Adornee = char
                e.HL.FillColor = Config.ESP.VisibilityCheck and (isVis and Config.ESP.HighlightVisibleFill or Config.ESP.HighlightHiddenFill) or Config.ESP.HighlightFill
                e.HL.OutlineColor = Config.ESP.HighlightOutline
                e.HL.Enabled = true 
            end)
        elseif e.HL then 
            pcall(function() e.HL.Enabled = false end) 
        end
    end
end

local function SetupPlayer(p)
    if p ~= LP then
        if ESP_.Players[p] then DestroyPlayerESP(ESP_.Players[p]) end
        ESP_.Players[p] = CreatePlayerESP()
        AC(p.CharacterAdded:Connect(function() 
            if ESP_.Players[p] then HidePlayerESP(ESP_.Players[p]) end 
        end))
        AC(p.CharacterRemoving:Connect(function() 
            if ESP_.Players[p] then HidePlayerESP(ESP_.Players[p]) end 
        end))
    end
end

AC(Players.PlayerAdded:Connect(Safe(SetupPlayer)))
AC(Players.PlayerRemoving:Connect(Safe(function(p)
    if ESP_.Players[p] then 
        DestroyPlayerESP(ESP_.Players[p])
        ESP_.Players[p] = nil 
    end
    if CharmCache[p] then 
        for _, box in pairs(CharmCache[p]) do pcall(function() box:Destroy() end) end
        CharmCache[p] = nil
        CharmVisCache[p] = nil 
    end
end)))

for _, p in pairs(Players:GetPlayers()) do SetupPlayer(p) end

G.CharmFolder = nil
pcall(function() 
    G.CharmFolder = Instance.new("Folder", game:GetService("CoreGui"))
    G.CharmFolder.Name = "Charms_Container" 
end)

G.GraphD = {UI = nil, Lines = {}, Label = nil, PeakLabel = nil, History = {}, LastPos = nil, LastTime = 0, Smoothed = 0, PeakHistory = {}}
G.KSD = {Frame = nil, Elements = {}}
G.AAD = {cachedThreat = nil, lastThreatCheck = 0}

G.LastWorldScan = 0
G.skinApplyDebounce = false
G.lastInvRefresh = 0

G.EB_StartTime = 0

local function UpdateCharms(evf)
    if not Config.Charms.Enabled or not G.CharmFolder then
        for plr, parts in pairs(CharmCache) do 
            for _, box in pairs(parts) do pcall(function() box:Destroy() end) end 
        end
        table.clear(CharmCache)
        table.clear(CharmVisCache)
        return
    end

    local nt = tick()
    local scv = (nt - G.LastCharmVisCheck) > 0.2
    if scv then G.LastCharmVisCheck = nt end

    local ds = (nt - G.LastCharmScan) > 1
    if ds then G.LastCharmScan = nt end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local ch = plr.Character
            local chm = ch and ch:FindFirstChildWhichIsA("Humanoid")
            if ch and ch:FindFirstChild("HumanoidRootPart") and chm and chm.Health > 0 then
                if Config.Charms.TeamCheck and not is_enemy(plr) then 
                    if CharmCache[plr] then 
                        for _, box in pairs(CharmCache[plr]) do pcall(function() box:Destroy() end) end
                        CharmCache[plr] = nil
                        CharmVisCache[plr] = nil 
                    end
                    continue 
                end

                if not CharmCache[plr] then CharmCache[plr] = {} end

                local chHead = ch:FindFirstChild("Head") or ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart")
                local iv = CharmVisCache[plr]
                if scv then 
                    iv = false
                    if chHead and evf then iv = evf(ch, chHead.Position) end
                    CharmVisCache[plr] = iv 
                elseif iv == nil then 
                    iv = false 
                end

                local col = iv and Config.Charms.VisibleColor or Config.Charms.HiddenColor

                for pt, box in pairs(CharmCache[plr]) do 
                    local isValid = false
                    pcall(function() 
                        if pt and pt.Parent and pt:IsDescendantOf(ch) and box and box.Parent then isValid = true end 
                    end)
                    if not isValid then 
                        pcall(function() box:Destroy() end)
                        CharmCache[plr][pt] = nil 
                    end 
                end

                for pt, box in pairs(CharmCache[plr]) do 
                    pcall(function() 
                        if pt.Parent and pt:IsDescendantOf(ch) and box:IsA("BoxHandleAdornment") then 
                            box.Size = pt.Size + Vector3.new(0.05, 0.05, 0.05)
                            box.Adornee = pt
                            box.CFrame = CFrame.new()
                            box.SizeRelativeOffset = Vector3.new(0, 0, 0)
                            box.Color3 = col
                            box.Transparency = Config.Charms.Transparency
                            box.AlwaysOnTop = Config.Charms.AlwaysOnTop
                            box.Visible = true 
                        end 
                    end) 
                end

                if ds then
                    local validNames = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
                    for _, pt in ipairs(ch:GetDescendants()) do 
                        pcall(function() 
                            if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" and pt.Transparency < 1 and not CharmCache[plr][pt] then 
                                local validPart = false
                                for _, vn in ipairs(validNames) do 
                                    if pt.Name == vn then validPart = true break end 
                                end
                                if validPart then 
                                    local box = Instance.new("BoxHandleAdornment")
                                    box.Name = "Charm_" .. pt.Name
                                    box.Adornee = pt
                                    box.Size = pt.Size + Vector3.new(0.05, 0.05, 0.05)
                                    box.CFrame = CFrame.new()
                                    box.SizeRelativeOffset = Vector3.new(0, 0, 0)
                                    box.Color3 = col
                                    box.Transparency = Config.Charms.Transparency
                                    box.AlwaysOnTop = Config.Charms.AlwaysOnTop
                                    box.ZIndex = 5
                                    box.Parent = G.CharmFolder
                                    CharmCache[plr][pt] = box 
                                end 
                            end 
                        end) 
                    end
                end
            elseif CharmCache[plr] then 
                for _, box in pairs(CharmCache[plr]) do pcall(function() box:Destroy() end) end
                CharmCache[plr] = nil
                CharmVisCache[plr] = nil 
            end
        end
    end

    for plr, parts in pairs(CharmCache) do 
        local valid = false
        pcall(function() 
            if plr and plr.Parent and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then valid = true end 
        end)
        if not valid then 
            for _, box in pairs(parts) do pcall(function() box:Destroy() end) end
            CharmCache[plr] = nil
            CharmVisCache[plr] = nil 
        end 
    end
end

local function InitGraphUI()
    if G.GraphD.UI then return end
    G.GraphD.UI = Instance.new("Frame")
    G.GraphD.UI.Name = "SpeedGraph"
    G.GraphD.UI.Size = UDim2.new(0, 200, 0, 120)
    G.GraphD.UI.Position = UDim2.new(0.5, -100, 0.85, 0)
    G.GraphD.UI.BackgroundTransparency = 1
    G.GraphD.UI.Parent = UI
    MakeDraggable(G.GraphD.UI)

    G.GraphD.Label = Instance.new("TextLabel")
    G.GraphD.Label.Size = UDim2.new(1, 0, 0, 20)
    G.GraphD.Label.Position = UDim2.new(0, 0, 1, -20)
    G.GraphD.Label.BackgroundTransparency = 1
    G.GraphD.Label.Font = Enum.Font.GothamBold
    G.GraphD.Label.TextSize = 18
    G.GraphD.Label.TextStrokeTransparency = 0
    G.GraphD.Label.Text = "0"
    G.GraphD.Label.Parent = G.GraphD.UI
    AddThemeObject(G.GraphD.Label, "Text")

    G.GraphD.PeakLabel = Instance.new("TextLabel")
    G.GraphD.PeakLabel.Size = UDim2.new(1, 0, 0, 18)
    G.GraphD.PeakLabel.Position = UDim2.new(0, 0, 1, -38)
    G.GraphD.PeakLabel.BackgroundTransparency = 1
    G.GraphD.PeakLabel.Font = Enum.Font.GothamBold
    G.GraphD.PeakLabel.TextSize = 16
    G.GraphD.PeakLabel.TextStrokeTransparency = 0
    G.GraphD.PeakLabel.Text = ""
    G.GraphD.PeakLabel.Visible = false
    G.GraphD.PeakLabel.Parent = G.GraphD.UI

    for i = 1, 59 do 
        local ln = Instance.new("Frame")
        ln.BorderSizePixel = 0
        ln.AnchorPoint = Vector2.new(0.5, 0.5)
        ln.BackgroundColor3 = Config.Graph.Color
        ln.Parent = G.GraphD.UI
        G.GraphD.Lines[i] = ln 
    end
end

local function UpdateGraph()
    if not Config.Graph.Enabled then 
        if G.GraphD.UI then G.GraphD.UI.Visible = false end
        return 
    end
    if tick() - G.LastGraphUpdate < 0.05 then return end
    G.LastGraphUpdate = tick()

    InitGraphUI()
    G.GraphD.UI.Visible = true

    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local spd = 0
    if hrp then
        local n = tick()
        local gp = hrp.Position
        if G.GraphD.LastPos and G.GraphD.LastTime then
            local dtt = n - G.GraphD.LastTime
            if dtt > 0 then 
                spd = Vector3.new(gp.X - G.GraphD.LastPos.X, 0, gp.Z - G.GraphD.LastPos.Z).Magnitude / dtt 
            end
        end
        G.GraphD.LastPos = gp
        G.GraphD.LastTime = n
    end

    G.GraphD.Smoothed = G.GraphD.Smoothed + ((spd - G.GraphD.Smoothed) * 0.3)
    G.GraphD.History[#G.GraphD.History + 1] = math.min(G.GraphD.Smoothed, Config.Graph.MaxSpeed)
    if #G.GraphD.History > 60 then table.remove(G.GraphD.History, 1) end

    G.GraphD.Label.Text = string.format("%.1f", math.floor(G.GraphD.Smoothed * 100 + 0.5) / 10)
    G.GraphD.Label.TextColor3 = Config.Graph.Color

    if Config.Graph.PeakEnabled and G.GraphD.PeakLabel then
        local now = tick()
        G.GraphD.PeakHistory[#G.GraphD.PeakHistory + 1] = {time = now, speed = G.GraphD.Smoothed}
        while #G.GraphD.PeakHistory > 0 and (now - G.GraphD.PeakHistory[1].time) > 5 do 
            table.remove(G.GraphD.PeakHistory, 1) 
        end
        local peak = 0
        for _, entry in ipairs(G.GraphD.PeakHistory) do 
            if entry.speed > peak then peak = entry.speed end 
        end
        G.GraphD.PeakLabel.Text = string.format("%.1f", math.floor(peak * 100 + 0.5) / 10)
        if peak >= 30 then G.GraphD.PeakLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        elseif peak >= 20 then G.GraphD.PeakLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
        else G.GraphD.PeakLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end
        G.GraphD.PeakLabel.Visible = true
    elseif G.GraphD.PeakLabel then 
        G.GraphD.PeakLabel.Visible = false 
    end

    local w = G.GraphD.UI.AbsoluteSize.X
    local h = G.GraphD.UI.AbsoluteSize.Y - 40
    local step = w / 60

    for i = 1, 59 do 
        local gl = G.GraphD.Lines[i]
        if gl and i < #G.GraphD.History then
            local p1 = G.GraphD.History[i] or 0
            local p2 = G.GraphD.History[i + 1] or 0
            local h1 = (p1 / Config.Graph.MaxSpeed) * h
            local h2 = (p2 / Config.Graph.MaxSpeed) * h
            local x1 = (i - 1) * step
            local y1 = h - h1
            local x2 = i * step
            local y2 = h - h2
            local gv = Vector2.new(x2 - x1, y2 - y1)
            local ct = Vector2.new((x1 + x2) / 2, (y1 + y2) / 2)
            gl.Position = UDim2.new(0, ct.X, 0, ct.Y)
            gl.Size = UDim2.new(0, gv.Magnitude, 0, 2)
            gl.Rotation = math.deg(math.atan2(gv.Y, gv.X))
            gl.BackgroundColor3 = Config.Graph.Color
            gl.Visible = true
        elseif gl then 
            gl.Visible = false 
        end 
    end
end

local function InitKeystrokesUI()
    if G.KSD.Frame then return end
    G.KSD.Frame = Instance.new("Frame")
    G.KSD.Frame.Name = "Keystrokes"
    G.KSD.Frame.Size = UDim2.new(0, 170, 0, 140)
    G.KSD.Frame.Position = UDim2.new(0.98, -170, 0.02, 63)
    G.KSD.Frame.BackgroundTransparency = 1
    G.KSD.Frame.Parent = UI
    MakeDraggable(G.KSD.Frame)

    local function CK(id, t, sz, kp)
        local f = Instance.new("Frame")
        f.Name = id
        f.Size = sz
        f.Position = kp
        f.BackgroundColor3 = CurrentTheme.Item
        f.BorderSizePixel = 0
        f.Parent = G.KSD.Frame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = t
        l.Font = Enum.Font.GothamBold
        l.TextSize = 20
        l.TextColor3 = CurrentTheme.Text
        l.TextStrokeTransparency = 0
        l.Parent = f

        G.KSD.Elements[id] = {Frame = f, Label = l}
    end

    CK("W", "W", UDim2.new(0, 50, 0, 50), UDim2.new(0.5, -25, 0, 0))
    CK("A", "A", UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0, 55))
    CK("S", "S", UDim2.new(0, 50, 0, 50), UDim2.new(0.5, -25, 0, 55))
    CK("D", "D", UDim2.new(0, 50, 0, 50), UDim2.new(1, -50, 0, 55))
    CK("C", "C", UDim2.new(0, 50, 0, 30), UDim2.new(0, 0, 0, 110))
    CK("Space", "", UDim2.new(0, 115, 0, 30), UDim2.new(0, 55, 0, 110))
end

local function UpdateMovementDisplay()
    if not Config.MovementDisplay.Enabled then 
        if G.KSD.Frame then G.KSD.Frame.Visible = false end
        return 
    end
    if tick() - G.LastMovementUpdate < 0.05 then return end
    G.LastMovementUpdate = tick()

    InitKeystrokesUI()
    G.KSD.Frame.Visible = true

    local km = {
        {Id = "W", Input = Enum.KeyCode.W},
        {Id = "A", Input = Enum.KeyCode.A},
        {Id = "S", Input = Enum.KeyCode.S},
        {Id = "D", Input = Enum.KeyCode.D},
        {Id = "C", Input = {Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.C}},
        {Id = "Space", Input = Enum.KeyCode.Space}
    }

    for _, kd in ipairs(km) do 
        local el = G.KSD.Elements[kd.Id]
        if el then
            local pr = false
            if type(kd.Input) == "table" then
                for _, kc in ipairs(kd.Input) do 
                    if UIS:IsKeyDown(kc) then pr = true break end 
                end
            else 
                pr = UIS:IsKeyDown(kd.Input) 
            end
            el.Frame.BackgroundColor3 = pr and CurrentTheme.Accent or CurrentTheme.Item
            el.Label.TextColor3 = CurrentTheme.Text
        end 
    end
end

local function UpdateInventoryNames()
    local invGui = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("MainGui")
    if not invGui then return end
    local gameplay = invGui:FindFirstChild("Gameplay")
    if not gameplay then return end
    local bottom = gameplay:FindFirstChild("Bottom")
    if not bottom then return end
    local inv = bottom:FindFirstChild("Inventory")
    if not inv then return end

    local meleeSlot = inv:FindFirstChild("Melee")
    if meleeSlot and Config.KnifeChanger.Enabled then
        local weapon = meleeSlot:FindFirstChild("Weapon")
        if weapon then
            local weaponName = weapon:FindFirstChild("WeaponName")
            if weaponName and weaponName:IsA("TextLabel") then
                local knifeModel = Config.KnifeChanger.Model
                local sel = Config.SkinChanger.Skins[knifeModel]
                local star = utf8.char(9733)
                if sel and sel ~= "Default" then
                    weaponName.Text = star .. " " .. knifeModel .. " | " .. sel
                else
                    weaponName.Text = star .. " " .. knifeModel
                end
            end
            local meleeImg = weapon:FindFirstChild("Melee")
            if meleeImg and meleeImg:IsA("ImageLabel") then
                pcall(function()
                    local knifeModel = Config.KnifeChanger.Model
                    local weaponDB = RepStore:FindFirstChild("Database") and RepStore.Database:FindFirstChild("Custom") and RepStore.Database.Custom:FindFirstChild("Weapons")
                    if weaponDB then
                        local weaponModule = weaponDB:FindFirstChild(knifeModel)
                        if weaponModule then
                            local weaponData = SafeRequire(weaponModule)
                            if weaponData and type(weaponData) == "table" and weaponData.Icon then
                                meleeImg.Image = weaponData.Icon
                            end
                        end
                    end
                end)
            end
        end
    end

    for _, child in ipairs(inv:GetDescendants()) do
        if child:IsA("TextLabel") and child.Name == "WeaponName" then
            if meleeSlot and child:IsDescendantOf(meleeSlot) then continue end
            if not child.Text:find("|") then continue end
            local baseName = child.Text:split(" | ")[1]:gsub("%s+$", "")
            local sel = Config.SkinChanger.Skins[baseName]
            if sel and sel ~= "Default" then
                child.Text = baseName .. " | " .. sel
            else
                child.Text = baseName
            end
        end
    end
end

local function GetWeaponModel()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    for _, ch in pairs(cam:GetChildren()) do
        if ch:IsA("Model") and ch.Name ~= "Arms" and ch.Name ~= "Arms1" and ch.Name ~= "Arms2" and ch.Name ~= "Viewmodel" then
            return ch
        end
    end
    return nil
end

local function ApplySkin()
    if not SD.SkinsRoot then return end
    local wm = GetWeaponModel()
    if not wm then return end
    local own = wm.Name
    local ewn = own
    local ca = false
    if Checkknife(own) then
        if Config.KnifeChanger.Enabled then ewn = Config.KnifeChanger.Model ca = true end
    else
        if Config.SkinChanger.Enabled then ca = true end
    end
    if not ca then return end

    local cur = wm:GetAttribute("BankrollSkin")
    local sel = Config.SkinChanger.Skins[ewn]
    if not sel or sel == "Default" then return end
    if cur == sel then return end

    local wsf = SD.SkinsRoot:FindFirstChild(ewn)
    if not wsf then return end
    local sf = wsf:FindFirstChild(sel)
    if not sf then return end
    local cf = sf:FindFirstChild("Camera")
    if not cf then return end
    local fn = cf:FindFirstChild("Factory New")
    if not fn then return end

    for _, sa in pairs(fn:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            local pt = wm:FindFirstChild(sa.Name, true)
            if pt and (pt:IsA("BasePart") or pt:IsA("MeshPart")) then
                for _, old in pairs(pt:GetChildren()) do
                    if old:IsA("SurfaceAppearance") then old:Destroy() end
                end
                sa:Clone().Parent = pt
            end
        end
    end

    wm:SetAttribute("BankrollSkin", sel)
    UpdateInventoryNames()
end

local function ApplyGloves()
    if not Config.GloveChanger.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    local am
    for _, ch in ipairs(cam:GetChildren()) do
        if ch:IsA("Model") and (ch.Name:match("Arms") or ch:FindFirstChild("Right Arm")) then
            am = ch
            break
        end
    end
    if not am then return end

    local la = am:FindFirstChild("Left Arm")
    local ra = am:FindFirstChild("Right Arm")
    if not la or not ra then return end

    local lg = la:FindFirstChild("Glove")
    local rg = ra:FindFirstChild("Glove")
    if not lg or not rg then return end

    for _, old in pairs(lg:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end
    for _, old in pairs(rg:GetChildren()) do if old:IsA("SurfaceAppearance") then old:Destroy() end end

    local selectedModel = Config.GloveChanger.Model
    if not selectedModel then return end
    local sel = Config.GloveChanger.Gloves[selectedModel]
    if not sel or sel == "Default" then return end

    if not SD.SkinsRoot then return end
    local gloveSkinFolder = SD.SkinsRoot:FindFirstChild(selectedModel)
    if not gloveSkinFolder then return end
    local skinVariant = gloveSkinFolder:FindFirstChild(sel)
    if not skinVariant then return end
    local cameraFolder = skinVariant:FindFirstChild("Camera")
    if not cameraFolder then return end
    local factoryNew = cameraFolder:FindFirstChild("Factory New")
    if not factoryNew then return end

    for _, sa in pairs(factoryNew:GetChildren()) do
        if sa:IsA("SurfaceAppearance") then
            sa:Clone().Parent = lg
            sa:Clone().Parent = rg
        end
    end
end

local function TrySkinApply()
    if G.skinApplyDebounce then return end
    G.skinApplyDebounce = true
    task.spawn(function()
        task.wait(0.2)
        pcall(function()
            if Config.SkinChanger.Enabled or Config.KnifeChanger.Enabled then ApplySkin() end
            if Config.GloveChanger.Enabled then ApplyGloves() end
        end)
        task.wait(0.3)
        pcall(UpdateInventoryNames)
        G.skinApplyDebounce = false
    end)
end

    local function InitKnifeChanger()
        local su, re = pcall(function()
            local SM = RepStore:FindFirstChild("Database") and RepStore.Database:FindFirstChild("Components") and RepStore.Database.Components:FindFirstChild("Libraries") and RepStore.Database.Components.Libraries:FindFirstChild("Skins")
            local VM = RepStore:FindFirstChild("Classes") and RepStore.Classes:FindFirstChild("WeaponComponent") and RepStore.Classes.WeaponComponent:FindFirstChild("Classes") and RepStore.Classes.WeaponComponent.Classes:FindFirstChild("Viewmodel")
            if not SM or not VM then return false end

            local Sk = SafeRequire(SM)
            local Vm = SafeRequire(VM)
            if not Sk or not Vm then return false end
            if type(Sk) ~= "table" or type(Vm) ~= "table" then return false end
            if not Sk.GetCameraModel or not Sk.GetCharacterModel or not Vm.new then return false end

            local oGCM = Sk.GetCameraModel
            Sk.GetCameraModel = function(w, sk, ...)
                local success, result
                if Config.KnifeChanger.Enabled and w and Checkknife(w) then
                    local newKnife = Config.KnifeChanger.Model
                    local newSkin = Config.SkinChanger.Skins[newKnife] or "Vanilla"
                    success, result = pcall(oGCM, newKnife, newSkin, ...)
                    if success and result then return result end
                end
                success, result = pcall(oGCM, w, sk, ...)
                if success then return result end
                return nil
            end

            local oGChM = Sk.GetCharacterModel
            Sk.GetCharacterModel = function(w, sk, ...)
                local success, result
                if Config.KnifeChanger.Enabled and w and Checkknife(w) then
                    local newKnife = Config.KnifeChanger.Model
                    local newSkin = Config.SkinChanger.Skins[newKnife] or "Vanilla"
                    success, result = pcall(oGChM, newKnife, newSkin, ...)
                    if success and result then return result end
                end
                success, result = pcall(oGChM, w, sk, ...)
                if success then return result end
                return nil
            end

            local oVN = Vm.new
            Vm.new = function(vc, w, sk, ...)
                local success, result
                if Config.KnifeChanger.Enabled and w and Checkknife(w) then
                    local newKnife = Config.KnifeChanger.Model
                    local newSkin = Config.SkinChanger.Skins[newKnife] or "Vanilla"
                    success, result = pcall(oVN, vc, newKnife, newSkin, ...)
                    if success and result then return result end
                end
                success, result = pcall(oVN, vc, w, sk, ...)
                if success then return result end
                return nil
            end

            if Sk.GetGloves then
                local oGG = Sk.GetGloves
                Sk.GetGloves = function(g, sk)
                    local success, result
                    if Config.GloveChanger.Enabled and Config.GloveChanger.Model then
                        local gModel = Config.GloveChanger.Model
                        local ts = Config.GloveChanger.Gloves[gModel] or "Vanilla"
                        success, result = pcall(oGG, gModel, ts)
                        if success and result then return result end
                    end
                    success, result = pcall(oGG, g, sk)
                    if success then return result end
                    return nil
                end
            end
            return true
        end)
        return su and re
    end

do
    local function bind(flag, tbl, key)
        local el = registry[flag]
        if not el then return end
        tbl[key] = el:GetValue()
        getProxy(flag):OnChanged(function()
            local e = registry[flag]
            if e then tbl[key] = e:GetValue() end
        end)
    end

    local function toEnumKey(name)
        if name == "M1B" then return Enum.UserInputType.MouseButton1 end
        if name == "M2B" then return Enum.UserInputType.MouseButton2 end
        if name == "M3B" then return Enum.UserInputType.MouseButton3 end
        local ok, code = pcall(function() return Enum.KeyCode[name] end)
        if ok and code then return code end
        return nil
    end

    local function bindKey(flag, tbl, key)
        local el = registry[flag]
        if not el then return end
        local function apply()
            local e = registry[flag]
            local k = e and toEnumKey(e:GetValue())
            if k then tbl[key] = k end
        end
        apply()
        getProxy(flag):OnChanged(apply)
    end

    local function Keybind(section, flag, text, default)
        local label = section:AddLabel(text)
        registry[flag] = label:AddKeybind({
            Default = default,
            Flag = flag,
            Callback = function() dispatch(flag) end,
        })
        return label
    end

    local pesp = Section(Tabs.Visuals, "Player ESP", "left")
    Toggle(pesp, "v_enabled", "Enabled", false); bind("v_enabled", Config.ESP, "Enabled")
    getProxy("v_enabled"):OnChanged(function()
        local e = registry["v_enabled"]
        if e and not e:GetValue() then pcall(HideAllPlayerESP) end
    end)
    Toggle(pesp, "v_box", "Box", false); bind("v_box", Config.ESP, "Box")
    Toggle(pesp, "v_boxoutline", "Box Outline", false); bind("v_boxoutline", Config.ESP, "BoxOutline")
    Slider(pesp, "v_boxthick", "Box Thickness", { Default = 1, Min = 1, Max = 5, Rounding = 0 }); bind("v_boxthick", Config.ESP, "BoxThickness")
    Toggle(pesp, "v_boxfill", "Box Fill", false); bind("v_boxfill", Config.ESP, "BoxFill")
    ColorPicker(pesp, "v_boxfill1", "Box Fill Color 1", Color3.fromRGB(255, 0, 0)); bind("v_boxfill1", Config.ESP, "BoxFillColor1")
    ColorPicker(pesp, "v_boxfill2", "Box Fill Color 2", Color3.fromRGB(0, 0, 255)); bind("v_boxfill2", Config.ESP, "BoxFillColor2")
    Slider(pesp, "v_boxfilltrans", "Box Fill Transparency", { Default = 0.8, Min = 0, Max = 1, Rounding = 2 }); bind("v_boxfilltrans", Config.ESP, "BoxFillTransparency")
    Slider(pesp, "v_boxfillfade", "Box Fill Fade Speed", { Default = 3, Min = 1, Max = 10, Rounding = 1 }); bind("v_boxfillfade", Config.ESP, "BoxFillFadeSpeed")
    Toggle(pesp, "v_name", "Name", false); bind("v_name", Config.ESP, "Name")
    Slider(pesp, "v_namesize", "Name Size", { Default = 13, Min = 8, Max = 24, Rounding = 0 }); bind("v_namesize", Config.ESP, "NameSize")
    Toggle(pesp, "v_health", "Health Bar", false); bind("v_health", Config.ESP, "Health")
    Toggle(pesp, "v_healthcustom", "Health Custom Color", false); bind("v_healthcustom", Config.ESP, "HealthBarCustom")
    ColorPicker(pesp, "v_healthcolor", "Health Bar Color", Color3.fromRGB(0, 255, 0)); bind("v_healthcolor", Config.ESP, "HealthBarColor")
    Toggle(pesp, "v_skeleton", "Skeleton", false); bind("v_skeleton", Config.ESP, "Skeleton")
    Slider(pesp, "v_skelthick", "Skeleton Thickness", { Default = 2, Min = 1, Max = 5, Rounding = 1 }); bind("v_skelthick", Config.ESP, "SkeletonThickness")
    Toggle(pesp, "v_headdot", "Head Dot", false); bind("v_headdot", Config.ESP, "HeadDot")
    Toggle(pesp, "v_highlight", "Highlight (Chams)", false); bind("v_highlight", Config.ESP, "Highlight")
    Toggle(pesp, "v_distance", "Distance", false); bind("v_distance", Config.ESP, "Distance")
    Toggle(pesp, "v_curweapon", "Current Weapon", false); bind("v_curweapon", Config.ESP.CurrentWeapon, "Enabled")
    ColorPicker(pesp, "v_curweaponcolor", "Current Weapon Color", Color3.fromRGB(255, 255, 255)); bind("v_curweaponcolor", Config.ESP.CurrentWeapon, "Color")

    local ecolors = Section(Tabs.Visuals, "ESP Colors", "left")
    ColorPicker(ecolors, "v_boxcolor", "Box Color", Color3.fromRGB(255, 255, 255)); bind("v_boxcolor", Config.ESP, "BoxColor")
    ColorPicker(ecolors, "v_namecolor", "Name Color", Color3.fromRGB(255, 255, 255)); bind("v_namecolor", Config.ESP, "NameColor")
    ColorPicker(ecolors, "v_skelcolor", "Skeleton Color", Color3.fromRGB(255, 255, 255)); bind("v_skelcolor", Config.ESP, "SkeletonColor")
    ColorPicker(ecolors, "v_headdotcolor", "Head Dot Color", Color3.fromRGB(255, 255, 255)); bind("v_headdotcolor", Config.ESP, "HeadDotColor")
    ColorPicker(ecolors, "v_distcolor", "Distance Color", Color3.fromRGB(255, 255, 255)); bind("v_distcolor", Config.ESP, "DistanceColor")
    ColorPicker(ecolors, "v_hlfill", "Highlight Fill", Color3.fromRGB(255, 0, 0)); bind("v_hlfill", Config.ESP, "HighlightFill")
    ColorPicker(ecolors, "v_hloutline", "Highlight Outline", Color3.fromRGB(255, 255, 255)); bind("v_hloutline", Config.ESP, "HighlightOutline")

    local esettings = Section(Tabs.Visuals, "ESP Settings", "right")
    Toggle(esettings, "v_teamcheck", "Team Check", true); bind("v_teamcheck", Config.ESP, "TeamCheck")
    Toggle(esettings, "v_vischeck", "Visibility Check", false); bind("v_vischeck", Config.ESP, "VisibilityCheck")
    Slider(esettings, "v_maxdist", "Max Distance", { Default = 2000, Min = 100, Max = 5000, Rounding = 0 }); bind("v_maxdist", Config.ESP, "MaxDistance")
    ColorPicker(esettings, "v_boxvis", "Box Visible Color", Color3.fromRGB(0, 255, 0)); bind("v_boxvis", Config.ESP, "BoxVisibleColor")
    ColorPicker(esettings, "v_boxnotvis", "Box Not-Visible Color", Color3.fromRGB(255, 0, 0)); bind("v_boxnotvis", Config.ESP, "BoxNotVisibleColor")
    ColorPicker(esettings, "v_hlvisfill", "Highlight Visible Fill", Color3.fromRGB(0, 255, 0)); bind("v_hlvisfill", Config.ESP, "HighlightVisibleFill")
    ColorPicker(esettings, "v_hlhidfill", "Highlight Hidden Fill", Color3.fromRGB(255, 0, 0)); bind("v_hlhidfill", Config.ESP, "HighlightHiddenFill")
    esettings:AddLabel("Reset ESP"):AddButton({ Name = "Reset", Callback = function() pcall(HideAllPlayerESP) end })

    local charms = Section(Tabs.Visuals, "Charms", "right")
    Toggle(charms, "c_enabled", "Enabled", false); bind("c_enabled", Config.Charms, "Enabled")
    getProxy("c_enabled"):OnChanged(function()
        local e = registry["c_enabled"]
        if e and not e:GetValue() then
            for p, boxes in pairs(CharmCache) do
                for _, box in pairs(boxes) do pcall(function() box:Destroy() end) end
                CharmCache[p] = nil
                CharmVisCache[p] = nil
            end
        end
    end)
    Toggle(charms, "c_teamcheck", "Team Check", true); bind("c_teamcheck", Config.Charms, "TeamCheck")
    ColorPicker(charms, "c_viscolor", "Visible Color", Color3.fromRGB(255, 0, 0)); bind("c_viscolor", Config.Charms, "VisibleColor")
    ColorPicker(charms, "c_hidcolor", "Hidden Color", Color3.fromRGB(255, 255, 255)); bind("c_hidcolor", Config.Charms, "HiddenColor")
    Slider(charms, "c_trans", "Transparency", { Default = 0.5, Min = 0, Max = 1, Rounding = 2 }); bind("c_trans", Config.Charms, "Transparency")
    Toggle(charms, "c_ontop", "Always On Top", true); bind("c_ontop", Config.Charms, "AlwaysOnTop")

    local wesp = Section(Tabs.Visuals, "World ESP", "right")
    Toggle(wesp, "w_dw", "Dropped Weapons", false); bind("w_dw", Config.ESP.DroppedWeapons, "Enabled")
    Toggle(wesp, "w_dwbox", "  Box", true); bind("w_dwbox", Config.ESP.DroppedWeapons, "Box")
    Toggle(wesp, "w_dwname", "  Name", true); bind("w_dwname", Config.ESP.DroppedWeapons, "Name")
    Toggle(wesp, "w_dwhl", "  Highlight", true); bind("w_dwhl", Config.ESP.DroppedWeapons, "Highlight")
    ColorPicker(wesp, "w_dwcolor", "  Color", Color3.fromRGB(255, 255, 255)); bind("w_dwcolor", Config.ESP.DroppedWeapons, "Color")
    Toggle(wesp, "w_bomb", "Bomb", false); bind("w_bomb", Config.ESP.Bomb, "Enabled")
    Toggle(wesp, "w_bombbox", "  Box", true); bind("w_bombbox", Config.ESP.Bomb, "Box")
    Toggle(wesp, "w_bombname", "  Name", true); bind("w_bombname", Config.ESP.Bomb, "Name")
    Toggle(wesp, "w_bombhl", "  Highlight", true); bind("w_bombhl", Config.ESP.Bomb, "Highlight")
    ColorPicker(wesp, "w_bombcolor", "  Color", Color3.fromRGB(255, 0, 0)); bind("w_bombcolor", Config.ESP.Bomb, "Color")
    Toggle(wesp, "w_molo", "Molotovs", false); bind("w_molo", Config.ESP.Molotovs, "Enabled")
    Toggle(wesp, "w_molohl", "  Highlight", true); bind("w_molohl", Config.ESP.Molotovs, "Highlight")
    ColorPicker(wesp, "w_molocolor", "  Color", Color3.fromRGB(255, 165, 0)); bind("w_molocolor", Config.ESP.Molotovs, "Color")
    Toggle(wesp, "w_smoke", "Smokes", false); bind("w_smoke", Config.ESP.Smokes, "Enabled")
    Toggle(wesp, "w_smokehl", "  Highlight", true); bind("w_smokehl", Config.ESP.Smokes, "Highlight")
    ColorPicker(wesp, "w_smokecolor", "  Color", Color3.fromRGB(200, 200, 200)); bind("w_smokecolor", Config.ESP.Smokes, "Color")

    local KM = { "Karambit", "Butterfly Knife", "Flip Knife", "Gut Knife", "M9 Bayonet" }
    local EW = { "Driver Gloves", "Sports Gloves", "Operator Gloves", "Hand Wraps" }

    local skLeft = Section(Tabs.SkinChanger, "Weapon Skins", "left")
    Toggle(skLeft, "sk_enabled", "Enable Skins", false); bind("sk_enabled", Config.SkinChanger, "Enabled")
    getProxy("sk_enabled"):OnChanged(function() pcall(TrySkinApply) end)
    do
        local names = {}
        for w in pairs(SD.SkinSelections) do names[#names + 1] = w end
        table.sort(names)
        for _, w in ipairs(names) do
            if not table.find(KM, w) and not table.find(EW, w) then
                local vals = { "Default" }
                for _, s in ipairs(SD.SkinSelections[w]) do vals[#vals + 1] = s end
                skLeft:AddLabel(w):AddDropdown({
                    Values = vals, Default = "Default", Multi = false,
                    Callback = function(v) Config.SkinChanger.Skins[w] = v; pcall(ApplySkin) end,
                })
            end
        end
    end

    local skRight = Section(Tabs.SkinChanger, "Glove Changer", "right")
    Toggle(skRight, "gl_enabled", "Enable Gloves", false); bind("gl_enabled", Config.GloveChanger, "Enabled")
    getProxy("gl_enabled"):OnChanged(function() pcall(ApplyGloves) end)
    do
        local gnames = {}
        for g in pairs(SD.GloveSelections) do gnames[#gnames + 1] = g end
        table.sort(gnames)
        if #gnames > 0 then
            local gdefault = Config.GloveChanger.Model
            if not SD.GloveSelections[gdefault] then gdefault = gnames[1] end
            Config.GloveChanger.Model = gdefault
            skRight:AddLabel("Glove Model"):AddDropdown({
                Values = gnames, Default = gdefault, Multi = false,
                Callback = function(v) Config.GloveChanger.Model = v; pcall(ApplyGloves) end,
            })
            for _, g in ipairs(gnames) do
                skRight:AddLabel(g .. " Skin"):AddDropdown({
                    Values = SD.GloveSelections[g], Default = "Default", Multi = false,
                    Callback = function(v) Config.GloveChanger.Gloves[g] = v; pcall(ApplyGloves) end,
                })
            end
        else
            skRight:AddLabel("No glove skins found in this game")
        end
    end

    local knSec = Section(Tabs.SkinChanger, "Knife Changer", "right")
    if G.knifeChangerSupported and InitKnifeChanger() then
        Toggle(knSec, "kn_enabled", "Enable Knife Changer", false); bind("kn_enabled", Config.KnifeChanger, "Enabled")
        getProxy("kn_enabled"):OnChanged(function() pcall(TrySkinApply) end)
        knSec:AddLabel("Knife Model (next round)"):AddDropdown({
            Values = KM, Default = Config.KnifeChanger.Model, Multi = false,
            Callback = function(v) Config.KnifeChanger.Model = v; pcall(ApplySkin) end,
        })
        for _, kn in ipairs(KM) do
            local ks = SD.SkinSelections[kn]
            if ks then
                local vals = { "Default" }
                for _, s in ipairs(ks) do vals[#vals + 1] = s end
                knSec:AddLabel(kn .. " Skin"):AddDropdown({
                    Values = vals, Default = "Default", Multi = false,
                    Callback = function(v) Config.SkinChanger.Skins[kn] = v; pcall(ApplySkin) end,
                })
            end
        end
    else
        knSec:AddLabel("Your executor (" .. tostring(G.executor) .. ") does not support the Knife Changer")
    end

    local rem = Section(Tabs.Misc, "Removals", "left")
    Toggle(rem, "Antiflashbang", "Enable No Flashbang", false)
    Toggle(rem, "Antismoke", "Enable No Smoke", false)

    local mv = Section(Tabs.Misc, "Movement", "left")
    Toggle(mv, "m_bhop", "Auto Bhop", false); bind("m_bhop", Config, "AutoBhop")
    Keybind(mv, "m_bhopkey", "Bhop Key", "Space"); bindKey("m_bhopkey", Config, "BhopKey")
    Toggle(mv, "m_jb", "Jump Bug", false); bind("m_jb", Config.JumpBug, "Enabled")
    Slider(mv, "m_jbpower", "Jump Bug Power", { Default = 1, Min = 0, Max = 5, Rounding = 1 }); bind("m_jbpower", Config.JumpBug, "Power")
    Dropdown(mv, "m_jbmode", "Jump Bug Mode", { Values = { "Always", "Toggle", "Hold" }, Default = "Always", Multi = false }); bind("m_jbmode", Config.JumpBug, "Mode")
    Keybind(mv, "m_jbkey", "Jump Bug Key", "V"); bindKey("m_jbkey", Config.JumpBug, "Key")
    Toggle(mv, "m_eb", "Edge Bug", false); bind("m_eb", Config.EdgeBug, "Enabled")
    Slider(mv, "m_ebdur", "Edge Bug Max Duration", { Default = 2, Min = 0, Max = 5, Rounding = 1 }); bind("m_ebdur", Config.EdgeBug, "MaxDuration")
    Dropdown(mv, "m_ebmode", "Edge Bug Mode", { Values = { "Always", "Toggle", "Hold" }, Default = "Always", Multi = false }); bind("m_ebmode", Config.EdgeBug, "Mode")
    Keybind(mv, "m_ebkey", "Edge Bug Key", "B"); bindKey("m_ebkey", Config.EdgeBug, "Key")

    local mvis = Section(Tabs.Misc, "Movement Visuals", "right")
    Toggle(mvis, "m_jbebind", "JB/EB Indicator", true); bind("m_jbebind", Config, "JBEBIndicator")
    ColorPicker(mvis, "m_jbcolor", "Jump Bug Color", Color3.fromRGB(255, 255, 255)); bind("m_jbcolor", Config, "JBColor")
    ColorPicker(mvis, "m_ebcolor", "Edge Bug Color", Color3.fromRGB(255, 255, 255)); bind("m_ebcolor", Config, "EBColor")
    Toggle(mvis, "m_graph", "Speed Graph", false); bind("m_graph", Config.Graph, "Enabled")
    ColorPicker(mvis, "m_graphcolor", "Speed Graph Color", Color3.fromRGB(255, 255, 255)); bind("m_graphcolor", Config.Graph, "Color")
    Slider(mvis, "m_graphmax", "Speed Graph Max", { Default = 50, Min = 10, Max = 200, Rounding = 0 }); bind("m_graphmax", Config.Graph, "MaxSpeed")
    Toggle(mvis, "m_graphpeak", "Speed Graph Peak", false); bind("m_graphpeak", Config.Graph, "PeakEnabled")
    Toggle(mvis, "m_ks", "Keystrokes", false); bind("m_ks", Config.MovementDisplay, "Enabled")
    ColorPicker(mvis, "m_kscolor", "Keystrokes Accent", Color3.fromRGB(255, 105, 180)); bind("m_kscolor", CurrentTheme, "Accent")
end

AC(RS.Heartbeat:Connect(function(dt)
    local jbOn = IsJBEBActive(Config.JumpBug)
    local ebOn = IsJBEBActive(Config.EdgeBug)
    if not jbOn and not ebOn then return end

    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not root or not hum then return end

    JBEB_SetFilter(char)

    local vel = root.AssemblyLinearVelocity
    local pos = root.Position
    local vy = vel.Y
    local floor = hum.FloorMaterial
    local inAir = floor == Enum.Material.Air
    local onGround = JBEB_GameGroundCheck(pos)

    if JBCooldown > 0 then JBCooldown = JBCooldown - dt end

    if EB_Active then
        if not ebOn then 
            EB_Active = false
            ebFlashTime = tick()
        elseif (onGround and vy <= 1) or not JBEB_StillOnEdge(pos) or (tick() - G.EB_StartTime > Config.EdgeBug.MaxDuration) then
            EB_Active = false
            ebFlashTime = tick()
        else
            root.AssemblyLinearVelocity = Vector3.new(vel.X * 0.995, 0, vel.Z * 0.995)
            return
        end
    end

    local gameThinkGround = (onGround and vy <= 1) or not inAir

    if not gameThinkGround then
        JBEB_WasAir = true
        JBEB_LandedFrame = false
        if vy < -1 then
            JBEB_FallFrames = JBEB_FallFrames + 1
            JBEB_VelBuffer[#JBEB_VelBuffer + 1] = vy
            if #JBEB_VelBuffer > JBEB_BufferSize then table.remove(JBEB_VelBuffer, 1) end
        end
    end

    if gameThinkGround and JBEB_WasAir then
        JBEB_LandedFrame = true
        JBEB_WasAir = false
    elseif gameThinkGround and not JBEB_WasAir then
        JBEB_LandedFrame = false
    end

    if jbOn and JBEB_LandedFrame and JBCooldown <= 0 and JBEB_FallFrames >= JB_MIN_FRAMES then
        local hSpeed = math.sqrt(vel.X ^ 2 + vel.Z ^ 2)
        local power = Config.JumpBug.Power or 1.0
        local newH = math.min(hSpeed + (JB_HORIZ_BOOST * power), 24.5)
        local newVY = vy + (JB_VERT_BOOST * power)
        if hSpeed > 0.5 then
            local dir = Vector3.new(vel.X, 0, vel.Z).Unit
            root.AssemblyLinearVelocity = Vector3.new(dir.X * newH, newVY, dir.Z * newH)
        else
            root.AssemblyLinearVelocity = Vector3.new(vel.X, newVY, vel.Z)
        end
        JBCooldown = 0.4
        JBActive = true
        jbFlashTime = tick()
        JBEB_FallFrames = 0
        table.clear(JBEB_VelBuffer)
        task.delay(0.2, function() JBActive = false end)
    end

    if gameThinkGround and not JBEB_LandedFrame then
        JBEB_FallFrames = 0
        table.clear(JBEB_VelBuffer)
    end

    if ebOn and not gameThinkGround and vy < -8 and not EB_Active and not JBActive then
        if JBEB_IsNearEdge(pos) then
            EB_Active = true
            G.EB_StartTime = tick()
            ebFlashTime = tick()
            JBEB_FallFrames = 0
            table.clear(JBEB_VelBuffer)
            root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
        end
    end
end))

task.spawn(function()
    task.wait(0.5)
    local gui = Instance.new("ScreenGui")
    gui.Name = "JBEB_Indicator"
    gui.ResetOnSpawn = false
    pcall(function() gui.Parent = GetUIParent() end)
    JBEB_IndicatorGui = gui

    local function CreateIndicatorLabel(text, xPos)
        local container = Instance.new("Frame", gui)
        container.Size = UDim2.new(0, 40, 0, 30)
        container.Position = UDim2.new(0.5, xPos, 1, -50)
        container.BackgroundTransparency = 1
        container.Visible = false

        local main = Instance.new("TextLabel", container)
        main.Name = "Main"
        main.Size = UDim2.new(1, 0, 1, 0)
        main.BackgroundTransparency = 1
        main.Font = Enum.Font.GothamBold
        main.TextSize = 18
        main.Text = text
        main.TextColor3 = Color3.fromRGB(255, 255, 255)
        main.TextStrokeTransparency = 0
        main.TextStrokeColor3 = Color3.new(0, 0, 0)
        main.TextXAlignment = Enum.TextXAlignment.Center

        return container
    end

    JBEB_JBLabel = CreateIndicatorLabel("jb", -35)
    JBEB_EBLabel = CreateIndicatorLabel("eb", 5)

    AC(RS.RenderStepped:Connect(function()
        if Config.JBEBIndicator then
            if JBEB_JBLabel then 
                JBEB_JBLabel.Visible = JBActive
                if JBActive then 
                    local m = JBEB_JBLabel:FindFirstChild("Main")
                    if m then m.TextColor3 = Config.JBColor end 
                end 
            end
            if JBEB_EBLabel then 
                JBEB_EBLabel.Visible = EB_Active
                if EB_Active then 
                    local m = JBEB_EBLabel:FindFirstChild("Main")
                    if m then m.TextColor3 = Config.EBColor end 
                end 
            end
        else
            if JBEB_JBLabel then JBEB_JBLabel.Visible = false end
            if JBEB_EBLabel then JBEB_EBLabel.Visible = false end
        end
    end))
end)

task.spawn(Safe(function()
    while true do
        local cam = workspace.CurrentCamera
        if cam then
            AC(cam.ChildAdded:Connect(Safe(function()
                if Config.SkinChanger.Enabled or Config.KnifeChanger.Enabled or Config.GloveChanger.Enabled then
                    TrySkinApply()
                end
            end)))
            break
        end
        task.wait(1)
    end
end))

pcall(function()
    AC(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(Safe(function()
        local nc = workspace.CurrentCamera
        if nc then
            AC(nc.ChildAdded:Connect(Safe(function()
                if Config.SkinChanger.Enabled or Config.KnifeChanger.Enabled or Config.GloveChanger.Enabled then
                    TrySkinApply()
                end
            end)))
        end
    end)))
end)

AC(UIS.InputBegan:Connect(Safe(function(input)
    if Config.JumpBug.Key and (input.KeyCode == Config.JumpBug.Key or input.UserInputType == Config.JumpBug.Key) then
        if Config.JumpBug.Mode == "Toggle" then G.JumpBugActive = not G.JumpBugActive end
    end
    if Config.EdgeBug.Key and (input.KeyCode == Config.EdgeBug.Key or input.UserInputType == Config.EdgeBug.Key) then
        if Config.EdgeBug.Mode == "Toggle" then G.EdgeBugToggleActive = not G.EdgeBugToggleActive end
    end
end)))

AC(RS.RenderStepped:Connect(Safe(function()
    G.FrameCount = G.FrameCount + 1
    local ch = LP.Character
    G.LocalCharacter = ch

    local lHum = ch and ch:FindFirstChildWhichIsA("Humanoid")
    local lRoot = ch and ch:FindFirstChild("HumanoidRootPart")

    Camera = workspace.CurrentCamera
    if not Camera then return end

    if Config.AutoBhop and lHum and lRoot then
        if IsHoldKeyDown(Config.BhopKey) then
            if lHum.FloorMaterial ~= Enum.Material.Air then
                lHum.Jump = true
            end
        end
    end

    if Config.ESP.Enabled then pcall(UpdateESP) end
    pcall(UpdateWorldESP)

    if Config.Charms.Enabled and (tick() - G.LastCharmUpdate > 0.1) then
        G.LastCharmUpdate = tick()
        pcall(UpdateCharms, ESP_IsVisible)
    end

    if Config.Graph.Enabled then pcall(UpdateGraph) end
    pcall(UpdateMovementDisplay)
end)))

AC(RS.Heartbeat:Connect(Safe(function()
    if tick() - G.LastWorldScan < 0.2 then return end
    G.LastWorldScan = tick()

    local debris = workspace:FindFirstChild("Debris")
    if not debris then return end

    local cdw, cmol, csmk = {}, {}, {}
    local bf = false

    for _, item in ipairs(debris:GetChildren()) do
        if Config.ESP.DroppedWeapons.Enabled and item:IsA("Model") and item:GetAttribute("Weapon") and item:GetAttribute("CanPickup") == true then
            cdw[item] = true
            if not WorldESP.DroppedWeapons[item] then
                WorldESP.DroppedWeapons[item] = CreateWorldESPObject(true, false)
                WorldESP.DroppedWeapons[item].Model = item
            end
        end
        if Config.ESP.Bomb.Enabled and item:IsA("Model") and item.Name == "Character" and item:GetAttribute("BombPlanted") then
            bf = true
            if WorldESP.Bomb and WorldESP.Bomb.Model ~= item then
                DestroyWESP(WorldESP.Bomb)
                WorldESP.Bomb = nil
            end
            if not WorldESP.Bomb then
                WorldESP.Bomb = CreateWorldESPObject(true, false)
                WorldESP.Bomb.Model = item
            end
        end
        if Config.ESP.Molotovs.Enabled and item:IsA("Folder") and item.Name:match("^VoxelFire") then
            cmol[item] = true
            if not WorldESP.Molotovs[item] then
                WorldESP.Molotovs[item] = CreateWorldESPObject(true, true)
                WorldESP.Molotovs[item].Model = item
            end
        end
        if Config.ESP.Smokes.Enabled and item:IsA("Folder") and item.Name:match("^VoxelSmoke") then
            csmk[item] = true
            if not WorldESP.Smokes[item] then
                WorldESP.Smokes[item] = CreateWorldESPObject(true, true)
                WorldESP.Smokes[item].Model = item
            end
        end
    end

    for item, eo in pairs(WorldESP.DroppedWeapons) do 
        if not cdw[item] then 
            DestroyWESP(eo)
            WorldESP.DroppedWeapons[item] = nil 
        end 
    end
    for item, eo in pairs(WorldESP.Molotovs) do 
        if not cmol[item] then 
            DestroyWESP(eo)
            WorldESP.Molotovs[item] = nil 
        end 
    end
    for item, eo in pairs(WorldESP.Smokes) do 
        if not csmk[item] then 
            DestroyWESP(eo)
            WorldESP.Smokes[item] = nil 
        end 
    end
    if not bf and WorldESP.Bomb then 
        DestroyWESP(WorldESP.Bomb)
        WorldESP.Bomb = nil 
    end
end)))

AC(RS.Heartbeat:Connect(Safe(function()
    if (Config.SkinChanger.Enabled or Config.KnifeChanger.Enabled) and tick() - G.lastInvRefresh > 2 then
        G.lastInvRefresh = tick()
        pcall(UpdateInventoryNames)
    end
end)))

end

BuildBackend()
local SilentFovCircle = Drawing.new("Circle")
SilentFovCircle.Position = Workspace.CurrentCamera.ViewportSize / 2
SilentFovCircle.Radius = 70
SilentFovCircle.Color = Color3.fromRGB(255, 0, 0)
SilentFovCircle.Filled = false
SilentFovCircle.NumSides = 128
SilentFovCircle.Thickness = 1
SilentFovCircle.Visible = false

local AimbotFovCircle = Drawing.new("Circle")
AimbotFovCircle.Position = Workspace.CurrentCamera.ViewportSize / 2
AimbotFovCircle.Radius = 70
AimbotFovCircle.Color = Color3.fromRGB(0, 255, 0)
AimbotFovCircle.Filled = false
AimbotFovCircle.NumSides = 128
AimbotFovCircle.Thickness = 1
AimbotFovCircle.Visible = false

local SilentTarget = nil
local AimbotTarget = nil
local RageTarget = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local frameCounter = 0

local function isVisible(target)
    rayParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    local result = Workspace:Raycast(Workspace.CurrentCamera.CFrame.Position, target.Position - Workspace.CurrentCamera.CFrame.Position, rayParams)
    if result then
        return Players:GetPlayerFromCharacter(result.Instance:FindFirstAncestorOfClass("Model")) ~= nil
    end
    return true
end

local function FindAllTargets()
    local camera = Workspace.CurrentCamera
    local lchar = Players.LocalPlayer.Character
    if not lchar or not lchar:FindFirstChild("Head") then return end
    local lHeadPos = lchar.Head.Position
    local myTeam = get_player_team(LocalPlayer)
    local screenCenter = camera.ViewportSize / 2

    local sDist, sClose = math.huge, nil
    local aDist, aClose = math.huge, nil
    local rDist, rClose = math.huge, nil

    for _, v in next, Players:GetPlayers() do
        if v == LocalPlayer then continue end
        local char = v.Character
        if not char then continue end
        if char:GetAttribute("Dead") then continue end
        if char:GetAttribute("Invincible") then continue end

        local vTeam = get_player_team(v)
        local isTeam = myTeam == vTeam

        local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)

        if Toggles.Ragebot.Value and not isTeam then
            local rPart = char:FindFirstChild(Options.RageHitPart.Value) or targetPart
            local alive = true
            if Toggles.RagebotVisibleCheck.Value and not onScreen then alive = false end
            if alive and Toggles.RagebotWallCheck.Value and not isVisible(rPart) then alive = false end
            if alive then
                local rd = (lHeadPos - rPart.Position).Magnitude
                if rd < rDist then rDist = rd; rClose = rPart end
            end
        end

        if Toggles.SilentAim.Value and not isTeam and onScreen then
            if not Toggles.SilentTeamCheck.Value or not isTeam then
                local sd = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if sd <= ((Toggles.SilentUseFovCircle.Value and SilentFovCircle.Radius) or 999999) then
                    if sd < sDist then 
                        if not Toggles.SilentWallbang.Value then
                            if not isVisible(targetPart) then
                                continue
                            end
                        end
                        sDist = sd; 
                        sClose = targetPart 
                    end
                end
            end
        end

        if Toggles.Aimbot.Value and onScreen then
            if not Toggles.AimbotTeamCheck.Value or not isTeam then
                local ad = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if ad <= ((Toggles.AimbotUseFovCircle.Value and AimbotFovCircle.Radius) or 999999) then
                    if not Toggles.AimbotWallCheck.Value or isVisible(targetPart) then
                        if ad < aDist then aDist = ad; aClose = targetPart end
                    end
                end
            end
        end
    end

    SilentTarget = sClose
    AimbotTarget = aClose
    RageTarget = rClose
end

RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1

    SilentFovCircle.Position = Workspace.CurrentCamera.ViewportSize / 2
    AimbotFovCircle.Position = Workspace.CurrentCamera.ViewportSize / 2
    SilentFovCircle.Visible = Toggles.SilentAim.Value and Toggles.SilentUseFovCircle.Value
    AimbotFovCircle.Visible = Toggles.Aimbot.Value and Toggles.AimbotUseFovCircle.Value
    SilentFovCircle.Radius = Options.SilentFovCircleRadius.Value
    AimbotFovCircle.Radius = Options.AimbotFovCircleRadius.Value

    if frameCounter % 3 == 0 then
        FindAllTargets()
    end

    for _, player in next, Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if Toggles.Hitbox.Value and get_player_team(player) ~= get_player_team(LocalPlayer) and hitboxsafe then
                hrp.Size = Vector3.new(Options.HitboxSize.Value, Options.HitboxSize.Value, Options.HitboxSize.Value)
                hrp.Transparency = Options.HitboxTransparency.Value
            else
                if hrp.Size.X ~= Vector3.new(2,2,2) then
                    hrp.Size = Vector3.new(2, 2, 2)
                    hrp.Transparency = 1
                end
            end
        end
    end
end)

local original = {}
local firerateobjs = {}
local SendFunc = nil
local updateCam = nil
local getCurrentEquipped = nil

pcall(function()
    for _, obj in next, getgc(true) do  
        if type(obj) == "table" and rawget(obj, "FireRate") then
            pcall(function()
                table.insert(original, table.clone(obj))
                table.insert(firerateobjs, obj)
            end)
        end
        if type(obj) == "table" and rawget(obj, "setWeaponRecoil") then
            pcall(function()
                local oldSetWeaponRecoil
                oldSetWeaponRecoil = hookfunction(obj.setWeaponRecoil, function(...)
                    if Toggles.NoRecoil.Value then
                        return
                    end
                    return oldSetWeaponRecoil(...)
                end)
            end)
        end
        if type(obj) == "function" and debug.getinfo(obj).name == "calculateRecoilOffset" then
            pcall(function()
                local calculateRecoilOffset
                calculateRecoilOffset = hookfunction(obj, function(...) 
                    if Toggles.NoRecoil.Value then
                        return UDim2.new() 
                    end
                    return calculateRecoilOffset(...)
                end)
            end)
        end 
        if type(obj) == "table" and rawget(obj, "weaponKick") then
            pcall(function()
                local oldweaponkick
                oldweaponkick = hookfunction(obj.weaponKick, function(p1,p2)
                    if Toggles.NoRecoil.Value then
                        return
                    end
                    return oldweaponkick(p1,p2)
                end)
            end)
        end 
        
        if type(obj) == "table" and rawget(obj, "getTrueSpread") then
            pcall(function()
                local oldgettruespread
                oldgettruespread = hookfunction(obj.getTrueSpread, function(p1)  
                    if Toggles.NoSpread.Value then
                        return 0
                    end
                    return oldgettruespread(p1)
                end)
            end)
        end

        if type(obj) == "function" and debug.getinfo(obj).name == "Flash" then
            pcall(function()
                local oldflash
                oldflash = hookfunction(obj, function(...)
                    if Toggles.Antiflashbang.Value then
                        return
                    end
                    return oldflash(...)
                end)
            end)
        end 
        if type(obj) == "function" and debug.getinfo(obj).name == "CreateVoxel" and debug.getupvalue(obj, 1) and tostring(debug.getupvalue(obj, 1)) == "Smoke" then
            pcall(function()
                local oldsmoke
                oldsmoke = hookfunction(obj, function(...) 
                    if Toggles.Antismoke.Value then
                        return
                    end
                    return oldsmoke(...)
                end) 
            end)
        end
        if type(obj) == "table" and rawget(obj, "shoot") then
            if obj.shoot and typeof(obj.shoot) == "function" and #debug.getupvalues(obj.shoot) == 25 then
                pcall(function()
                    SendFunc = debug.getupvalue(obj.shoot, 13).Inventory.ShootWeapon.Send
                end)
            end
        end
        if type(obj) == 'table' and rawget(obj, "getCurrentEquipped") then
            pcall(function()
                getCurrentEquipped = obj.getCurrentEquipped
            end)
        end
    end
end)

pcall(function(...)
    updateCam = filtergc("table", {Keys = {"updateCamera"}}, true).updateCamera
end)

local function getEquipped()
    local success, result = pcall(function()
        return debug.getupvalue(getCurrentEquipped, 1).CurrentEquipped
    end)

    if not success then
        return nil    
    end

    return result
end

local Weapon = nil

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if getEquipped then
                Weapon = getEquipped()
            end
        end)
    end
end)


local oldUpdateCam
local succes, errorms = pcall(function(...)
    oldUpdateCam = hookfunction(updateCam, function(p1)
        if Toggles.Aimbot and Toggles.Aimbot.Value and AimbotTarget
            and Options.AimbotHoldkey and Options.AimbotHoldkey:GetState() then
            local ok, lookCF = pcall(function()
                return CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, AimbotTarget.Position)
            end)
            if ok and lookCF then p1 = lookCF end
        end
        return oldUpdateCam(p1)
    end)
end)

local old56
pcall(function()
    old56 = hookfunction(task.wait, function(t)
        if t == 5 then
            hitboxsafe = true
            t = 9e9
        end 
        return old56(t)
    end)
end)

task.spawn(function()
    repeat 
        wait()
    until hitboxsafe

    Library:Notify({
        Title = "Success",
        Description = "Script is detected.",
        Time = 4,
    })
end)

task.spawn(function()
    while true do
        task.wait(Options.RageDelay.Value or 0.02)  
        if Toggles.Ragebot.Value and RageTarget and Weapon and Weapon.IsEquipped and Weapon.Rounds > 0 then
            Weapon:shoot()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Options.TriggerbotDelay.Value or 0)
        if Toggles.Triggerbot.Value then
            local mouse = LocalPlayer:GetMouse()
            if mouse and mouse.Target then
                local char = mouse.Target:FindFirstAncestorOfClass("Model")
                if not char then continue end

                local player = Players:GetPlayerFromCharacter(char)
                if not player then continue end 

                if char:GetAttribute("Dead") then continue end
                if char:GetAttribute("Invincible") then continue end

                if get_player_team(LocalPlayer) == get_player_team(player) then
                    continue
                end

                if Weapon and Weapon.IsEquipped and Weapon.Rounds > 0 then
                    Weapon:shoot()
                end
            end
        end 
    end
end)

local oldshoot
local success3, errormessage3 = pcall(function(...)
    oldshoot = hookfunction(SendFunc, function(...)
        local args = {...}
        if args[1].Bullets[1].Hits[1] then
            if Toggles.Ragebot.Value and RageTarget then
                args[1].Bullets[1].Hits[1].Instance = RageTarget
                args[1].Bullets[1].Hits[1].Position = RageTarget.Position
            end
            if Toggles.SilentAim.Value and SilentTarget then
                args[1].Bullets[1].Hits[1].Instance = SilentTarget
                args[1].Bullets[1].Hits[1].Position = SilentTarget.Position
            end
        end
        return oldshoot(unpack(args))
    end)
end)

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if Toggles.Firerate.Value then
                for _, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", math.max(Options.FirerateSlider.Value, 0.01))
                        setreadonly(obj, true)
                    end)
                end
            else
                for i, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", original[i].FireRate) 
                        setreadonly(obj, true)
                    end)
                end
            end
        end)
    end
end)
