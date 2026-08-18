local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))() or INSui

local window = lib:CreateWindow({ 
    title = "Loader", 
    size = Vector2.new(700, 580),
    menuKey  = "f1",
 })
window:SetKeybindOverlay(false)

window:ApplyThemePreset("Sky")
window:SetBackgroundImage("https://raw.githubusercontent.com/inwg/bin2/refs/heads/main/assets/Mekakucity.jpg", 0.12, 1, 1)
window:Notify("Loader", "Press F1 to toggle the menu", 4, "info")

local main = window:Tab("Main", "activity");
local sec = main:Section("Execution", "left");
sec:Divider("if you have low end pc use v2");
sec:Button("v1", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/bin2/refs/heads/main/gakuran/v1.lua"))();
end);
sec:Button("v2", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/inwg/bin2/refs/heads/main/gakuran/v2.lua"))();
end);
