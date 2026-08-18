local currentKeys  = { 0x58, 0x43, 0x4E, 0x4D }
local activeLaneCount = 4

local HOLD_MIN_H   = 20
local TAP_HOLD_SEC = 0.07
local TOUCH_DIST   = 30
local PAST_CATCH   = 40

local PRESETS = {
    ["Strict (45px)"] = { touch = 20, past = 25 },
    ["Normal (70px)"] = { touch = 30, past = 40 },
    ["Wide (100px)"]  = { touch = 45, past = 55 },
}

local LANE_COLORS = {
    Color3.fromRGB(210,  70, 255),
    Color3.fromRGB(255,  60, 130),
    Color3.fromRGB(  0, 200, 255),
    Color3.fromRGB( 40, 220,  90),
}
local COLOR_ON_LINE = Color3.fromRGB(255, 255, 255)
local COLOR_HOLD    = Color3.fromRGB(255, 220,  70)
local LINE_COLOR    = Color3.fromRGB(255, 235,  60)
local LINE_THICK    = 4
local CIRCLE_RADIUS = 20
local CIRCLE_SIDES  = 48
local CIRCLE_THICK  = 2
local TAIL_THICK    = 5
local MAX_CIRCLES   = 12

local enabled = false
local showESP = false

local hitLine = Drawing.new("Line")
hitLine.Color = LINE_COLOR; hitLine.Thickness = LINE_THICK
hitLine.Visible = false; hitLine.ZIndex = 5

local circles = {}
local tails   = {}
for lane = 1, 4 do
    circles[lane] = {}
    tails[lane]   = {}
    for j = 1, MAX_CIRCLES do
        local c = Drawing.new("Circle")
        c.NumSides = CIRCLE_SIDES; c.Radius = CIRCLE_RADIUS
        c.Thickness = CIRCLE_THICK; c.Filled = false
        c.Visible = false; c.ZIndex = 10
        circles[lane][j] = c

        local t = Drawing.new("Line")
        t.Thickness = TAIL_THICK; t.Visible = false; t.ZIndex = 9
        tails[lane][j] = t
    end
end

local function removeAll()
    pcall(function() hitLine:Remove() end)
    for lane = 1, 4 do
        for j = 1, MAX_CIRCLES do
            pcall(function() circles[lane][j]:Remove() end)
            pcall(function() tails[lane][j]:Remove() end)
        end
    end
end

local function hideAllESP()
    hitLine.Visible = false
    for lane = 1, 4 do
        for j = 1, MAX_CIRCLES do
            circles[lane][j].Visible = false
            tails[lane][j].Visible   = false
        end
    end
end

local tapping    = {} for i = 1, 4 do tapping[i]    = false end
local tapRelease = {} for i = 1, 4 do tapRelease[i] = 0     end
local holding    = {} for i = 1, 4 do holding[i]    = nil   end
local fired      = {} for i = 1, 4 do fired[i]      = {}    end

local function releaseAllKeys()
    for i = 1, 4 do
        if currentKeys[i] then
            keyrelease(currentKeys[i])
        end
        tapping[i] = false
        holding[i] = nil
        fired[i]   = {}
    end
end

local function tryGet(fn)
    local ok, v = pcall(fn)
    if ok and v ~= nil then return v end
    return nil
end

local uiLanesContainer = nil
local uiReceptorData   = nil
local guiActive        = false

local function setupGUI()
    local pg = tryGet(function() return game:GetService("Players").LocalPlayer.PlayerGui end)
    if not pg then return false end
    
    local rsUI = tryGet(function() return pg:FindFirstChild("RhythmServiceUI") end)
    if not rsUI then return false end
    
    local root = tryGet(function() return rsUI:FindFirstChild("RhythmRoot") end)
    if not root then return false end
    
    local receptors = tryGet(function() return root:FindFirstChild("Receptors") end)
    local lanesHost = tryGet(function() return root:FindFirstChild("Lanes") end)
    
    if not receptors or not lanesHost then return false end

    local newReceptors = {}
    local validLanes = 0
    
    for i = 1, 4 do
        local rec = tryGet(function() return receptors:FindFirstChild("Receptor" .. i) end)
        if rec then
            local bap = tryGet(function() return rec.AbsolutePosition end)
            local bas = tryGet(function() return rec.AbsoluteSize end)
            if bap and bas then
                newReceptors[i] = {
                    inst = rec,
                    cx   = bap.X + (bas.X / 2),
                    cy   = bap.Y + (bas.Y / 2),
                    hitY = bap.Y + (bas.Y / 2)
                }
                validLanes = validLanes + 1
            end
        end
    end

    if validLanes == 0 then return false end
    
    activeLaneCount = validLanes
    if activeLaneCount == 2 then
        currentKeys = { 0x46, 0x4A }
    else
        currentKeys = { 0x58, 0x43, 0x4E, 0x4D }
        activeLaneCount = 4
    end

    uiReceptorData   = newReceptors
    uiLanesContainer = lanesHost
    guiActive        = true

    local scale = 1
    local cam = game:GetService("Workspace").CurrentCamera
    if cam then scale = cam.ViewportSize.Y / 1080 end

    local lx = (newReceptors[1] and newReceptors[1].cx or 0) - (50 * scale)
    local rx = (newReceptors[activeLaneCount] and newReceptors[activeLaneCount].cx or 0) + (50 * scale)
    local y  = newReceptors[1].hitY
    
    hitLine.From    = Vector2.new(lx, y)
    hitLine.To      = Vector2.new(rx, y)
    
    if enabled and showESP then
        hitLine.Visible = true
    end
    
    return true
end

local function checkGone()
    local pg = tryGet(function() return game:GetService("Players").LocalPlayer.PlayerGui end)
    if not pg then return true end
    local rsUI = tryGet(function() return pg:FindFirstChild("RhythmServiceUI") end)
    return not rsUI
end

local RS        = game:GetService("RunService")
local running   = true
local lastCheck = 0

setupGUI()

local conn = RS.Heartbeat:Connect(function()
    if not running then return end
    if not isrbxactive() then return end
    
    local now = os.clock()

    if now - lastCheck >= 0.5 then
        lastCheck = now
        if guiActive then
            if checkGone() then
                guiActive = false
                hideAllESP()
                releaseAllKeys()
                return
            end
        else
            setupGUI()
        end
    end

    if not guiActive or not uiReceptorData then return end

    if not enabled then
        hideAllESP()
        return
    end

    local scale = 1
    local cam = game:GetService("Workspace").CurrentCamera
    if cam then scale = cam.ViewportSize.Y / 1080 end

    if showESP then
        hitLine.Thickness = LINE_THICK * scale
        hitLine.Visible = true
    else
        hideAllESP()
    end

    for lane = 1, 4 do
        for j = 1, MAX_CIRCLES do
            circles[lane][j].Visible = false
            tails[lane][j].Visible   = false
        end
    end

    for lane = 1, activeLaneCount do
        local vk = currentKeys[lane]
        
        if tapping[lane] and now >= tapRelease[lane] then
            keyrelease(vk)
            tapping[lane] = false
        end

        if holding[lane] then
            local h       = holding[lane]
            local release = not tryGet(function() return h.inst.Parent end)
            if not release then
                local head = tryGet(function() return h.inst:FindFirstChild("Head") end)
                if head then
                    local ap  = tryGet(function() return head.AbsolutePosition end)
                    local as  = tryGet(function() return head.AbsoluteSize end)
                    if ap and as then
                        local headCY = ap.Y + (as.Y / 2)
                        local tail = tryGet(function() return h.inst:FindFirstChild("Tail") end)
                        local tailH = (tail and tryGet(function() return tail.AbsoluteSize.Y end)) or 0
                        local hitY = uiReceptorData[lane].hitY

                        if tailH < 4 or (headCY - tailH) >= hitY - 2 then
    release = true
end
                    else
                        release = true
                    end
                else
                    release = true
                end
            end
            if release then
                keyrelease(vk)
                holding[lane] = nil
            end
        end
    end

    local activeNotes = tryGet(function() return uiLanesContainer:GetChildren() end)
    if not activeNotes then return end
    
    local laneNotes = { {}, {}, {}, {} }

    for _, note in ipairs(activeNotes) do
        if tryGet(function() return note.ClassName end) ~= "Frame" then continue end
        if tryGet(function() return note.Name end) ~= "NoteTemplate" then continue end
        
        local head = tryGet(function() return note:FindFirstChild("Head") end)
        if not head then continue end
        
        local ap = tryGet(function() return head.AbsolutePosition end)
        local as = tryGet(function() return head.AbsoluteSize end)
        if not ap or not as then continue end
        
        local headCX = ap.X + (as.X / 2)
        local headCY = ap.Y + (as.Y / 2)

        local bestLane = nil
        local minDist  = math.huge
        for i = 1, activeLaneCount do
            if not uiReceptorData[i] then continue end
            local recCX = uiReceptorData[i].cx
            local distX = math.abs(headCX - recCX)
            if distX < minDist then
                minDist = distX
                bestLane = i
            end
        end
        
        if not bestLane or minDist > 100 then continue end
        
        local laneF = fired[bestLane]
        if laneF[note] then
            if not tryGet(function() return note.Parent end) then laneF[note] = nil end
            continue
        end
        
        local hitY = uiReceptorData[bestLane].hitY
        local distY = headCY - hitY
        
        if distY > PAST_CATCH then
            laneF[note] = true
            continue
        end
        
        local tail = tryGet(function() return note:FindFirstChild("Tail") end)
        local tailH = (tail and tryGet(function() return tail.AbsoluteSize.Y end)) or 0
        local isHold = tailH > HOLD_MIN_H
        
        table.insert(laneNotes[bestLane], {
            note   = note,
            headCY = headCY,
            dist   = distY,
            isHold = isHold,
            tailH  = tailH
        })
    end

    for lane = 1, activeLaneCount do
        local vk = currentKeys[lane]
        if not uiReceptorData[lane] then continue end
        local cx = uiReceptorData[lane].cx
        local notes = laneNotes[lane]
        local laneF = fired[lane]
        
        table.sort(notes, function(a, b) return a.headCY > b.headCY end)
        
        for j, e in ipairs(notes) do
            if j > MAX_CIRCLES then break end
            local onLine = e.dist >= -TOUCH_DIST and e.dist <= PAST_CATCH
            
            if showESP then
                local c      = circles[lane][j]
                local t      = tails[lane][j]
                local col    = onLine and COLOR_ON_LINE or (e.isHold and COLOR_HOLD or LANE_COLORS[lane])

                local offX = (activeLaneCount == 2) and (15 * scale) or 0
                local offY = (activeLaneCount == 2) and (15 * scale) or 0

                c.Color     = col
                c.Radius    = CIRCLE_RADIUS * scale
                c.Thickness = CIRCLE_THICK * scale
                c.Filled    = e.isHold and not onLine
                c.Position  = Vector2.new(cx - offX, e.headCY - offY)
                c.Visible   = true

                if e.isHold and e.tailH > 0 then
                    t.From      = Vector2.new(cx - offX, e.headCY - offY)
                    t.To        = Vector2.new(cx - offX, e.headCY - e.tailH - offY)
                    t.Thickness = TAIL_THICK * scale
                    t.Color     = col
                    t.Visible   = true
                end
            end

            if onLine and not tapping[lane] and not holding[lane] then
                laneF[e.note] = true
                if e.isHold then
                    keypress(vk)
                    holding[lane] = { inst = e.note }
                else
                    keypress(vk)
                    tapping[lane]    = true
                    tapRelease[lane] = now + TAP_HOLD_SEC
                end
                break
            end
        end
    end
end)

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))() or INSui
local win = Lib:CreateWindow({
    title    = "Serenity",
    subtitle    = "V2", 
    size     = Vector2.new(700, 580),
    menuKey  = "f1",
    
})

win:ApplyThemePreset("Sky")
win:SetBackgroundImage("https://raw.githubusercontent.com/inwg/serenity/refs/heads/main/matcha/assets/Mekakucity.jpg", 0.12, 1, 1)
win:Notify("Serenity", "Press F1 to toggle the menu", 4, "info")

local mainTab = win:Tab("Main", "bot")
local settingsSec = mainTab:Section("Settings", "Full")

settingsSec:Toggle("Serenity", false, function(v)
    enabled = v
    if not enabled then
        releaseAllKeys()
        hideAllESP()
    end
end)

settingsSec:Toggle("Visual", false, function(v)
    showESP = v
    if not showESP then hideAllESP() end
end)

settingsSec:Dropdown("Hit Window", "default (strict)", {"strict (45px)", "normal (70px)", "wide (100px)"}, function(selected)
    local preset = PRESETS[selected]
    if preset then
        TOUCH_DIST = preset.touch
        PAST_CATCH = preset.past
    end
end)

pcall(function()
    notify("loaded")
end)
