--[[
    NEX HUB - VIOLENCE DISTRICT (Final - Dropdowns Fixed)
    Semua dropdown sudah diberi parameter Value/Default.
]]

-- WINDOW SETUP & THEME (WindUI)
local WindUI
do
    local ok, result = pcall(require, "./src/Init")
    WindUI = ok and result or loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end

local Window = WindUI:CreateWindow({
    Title = "NexHub - Violence District",
    Theme = "Dark",
    Author = "Nex Hub",
    Folder = "NexHubVD",
    Icon = "rbxassetid://75522306265517",
    Transparent = true,
    Size = UDim2.fromOffset(420, 300),
    ToggleKey = Enum.KeyCode.G
})

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- SAFE DRAWING UTILS
local function SafeDrawing(typ)
    local ok, res = pcall(function() return Drawing.new(typ) end)
    return ok and res or nil
end

local function SafeRemove(obj)
    if obj and obj.Remove then pcall(function() obj:Remove() end) end
end

local DrawingAvailable = (typeof(Drawing) == "table" and Drawing.new ~= nil)

-- CONFIG (global)
getgenv().VD = getgenv().VD or {
    ESP = false,
    MaxDistance = 2000,
    ShowDistance = false,
    GeneratorESP = false,
    GenAntiFail = false,
    HealAntiFail = false,
    HideSkillUI = false,
    Fullbright = false,
    Speed = false,
    SpeedValue = 16,
    Jump = false,
    JumpValue = 50,
    InfiniteJump = false,
    Noclip = false,
    Destroyed = false,
    AUTO_Generator = false,
    AUTO_GenMode = "Fast",
    AUTO_LeaveGen = false,
    AUTO_LeaveDist = 18,
    AUTO_Attack = false,
    AUTO_AttackRange = 12,
    HITBOX_Enabled = false,
    HITBOX_Size = 15,
    AUTO_TeleAway = false,
    AUTO_TeleAwayDist = 40,
    AUTO_Parry = false,
    AUTO_ParryRange = 15,
    AUTO_ParrySensitivity = 30,
    AUTO_ParryDelay = 0.5,
    AUTO_SkillCheck = false,
    SURV_AutoWiggle = false,
    SURV_NoFall = false,
    KILLER_DestroyPallets = false,
    KILLER_FullGenBreak = false,
    KILLER_NoPalletStun = false,
    KILLER_AutoHook = false,
    KILLER_AntiBlind = false,
    KILLER_NoSlowdown = false,
    KILLER_DoubleTap = false,
    KILLER_InfiniteLunge = false,
    SPEED_Enabled = false,
    SPEED_Value = 32,
    SPEED_Method = "Attribute",
    NO_Fog = false,
    CAM_FOVEnabled = false,
    CAM_FOV = 90,
    CAM_ThirdPerson = false,
    CAM_ShiftLock = false,
    FLING_Enabled = false,
    FLING_Strength = 10000,
    BEAT_Survivor = false,
    BEAT_Killer = false,
    TP_Offset = 3,
    DRAWING_ESP = false,
    ESP_PlayerChams = false,
    ESP_ObjectChams = true,
    ESP_Skeleton = false,
    ESP_Offscreen = true,
    ESP_Velocity = false,
    ESP_ClosestHook = true,
    RADAR_Enabled = false,
    RADAR_Size = 120,
    RADAR_Circle = false,
    RADAR_Killer = true,
    RADAR_Survivor = true,
    RADAR_Generator = true,
    RADAR_Pallet = true,
    AIM_Enabled = false,
    AIM_UseRMB = true,
    AIM_FOV = 120,
    AIM_Smooth = 0.3,
    AIM_TargetPart = "Head",
    AIM_VisCheck = true,
    AIM_ShowFOV = true,
    AIM_Predict = true,
    SPEAR_Aimbot = false,
    SPEAR_Gravity = 50,
    SPEAR_Speed = 100,
    FLY_Enabled = false,
    FLY_Speed = 50,
    FLY_Method = "CFrame",
    AUTO_StopEmote = false,
    _LastTeleportTime = 0,
    _TeleportCooldown = 1,
    _BeatSurvivorDone = false,
    _BeatKillerDone = false,
    _LastTeleAway = 0,
    _KillerTarget = nil,
}

-- SAVE ORIGINAL LIGHTING (tetap sama seperti sebelumnya, saya singkat untuk hemat tempat)
-- ... (salin bagian originalLighting dari script final sebelumnya)
-- (karena panjang, saya asumsikan sudah ada)

-- =====================================================
-- FUNGSI UTAMA (sama seperti script final sebelumnya)
-- =====================================================
-- (salin semua fungsi dari script final yang sudah saya kirim sebelumnya,
--  dari updateChar() sampai OnRenderStep, dll.)
--  Karena terlalu panjang, saya akan fokus pada bagian UI yang diperbaiki.
--  Jika kamu sudah punya script final sebelumnya, cukup ganti bagian UI dengan yang di bawah ini.
-- =====================================================

-- UI TABS (dengan dropdown yang sudah ditambahkan Value/Default)
local Main = Window:Section({ Title = "Violence District" })
local PlayerTab = Main:Tab({ Title = "Player" })
local ESPTab = Main:Tab({ Title = "ESP" })
local MapTab = Main:Tab({ Title = "Map" })
local AimTab = Main:Tab({ Title = "Aim" })
local FOVTab = Main:Tab({ Title = "FOV" })
local SurvivorTab = Main:Tab({ Title = "Survivor" })
local KillerTab = Main:Tab({ Title = "Killer" })
local GeneratorTab = Main:Tab({ Title = "Generator" })
local FlingTab = Main:Tab({ Title = "Fling Feature" })
local ResetTab = Main:Tab({ Title = "Reset" })

-- Player Tab (Movement + Teleport + Fly)
do
    local movSection = PlayerTab:Section({
        Title = "Movement",
        Icon = "solar:running-round-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    movSection:Toggle({
        Title = "Speed Hack",
        Callback = function(v) VD.Speed = v; if not v then local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.WalkSpeed = 16 end) end end end
    })
    movSection:Slider({
        Title = "Speed Value",
        Value = { Min = 16, Max = 200, Default = 16 },
        Callback = function(v) VD.SpeedValue = v end
    })
    movSection:Toggle({
        Title = "Jump Hack",
        Callback = function(v) VD.Jump = v; if not v then local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.JumpPower = 50 end) end end
    })
    movSection:Slider({
        Title = "Jump Power",
        Value = { Min = 50, Max = 300, Default = 50 },
        Callback = function(v) VD.JumpValue = v end
    })
    movSection:Toggle({ Title = "Infinite Jump", Callback = function(v) VD.InfiniteJump = v end })
    movSection:Toggle({ Title = "Noclip", Callback = function(v) VD.Noclip = v end })

    PlayerTab:Space({ Columns = 0.5 })

    -- Fly Section
    local flySection = PlayerTab:Section({
        Title = "Fly",
        Icon = "solar:wing-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })
    flySection:Toggle({ Title = "Enable Fly", Callback = function(v) VD.FLY_Enabled = v end })
    flySection:Slider({
        Title = "Fly Speed",
        Value = { Min = 10, Max = 200, Default = 50 },
        Callback = function(v) VD.FLY_Speed = v end
    })
    -- Dropdown dengan Value
    pcall(function()
        flySection:Dropdown({
            Title = "Fly Method",
            Options = { "CFrame", "Velocity" },
            Value = VD.FLY_Method or "CFrame",
            Callback = function(v) VD.FLY_Method = v end
        })
    end)

    PlayerTab:Space({ Columns = 0.5 })

    local tpSection = PlayerTab:Section({
        Title = "Teleport",
        Icon = "solar:map-point-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })
    tpSection:Button({ Title = "TP to Gen", Callback = function() pcall(NEX_TeleportToGenerator, 1) end })
    tpSection:Button({ Title = "TP to Gate", Callback = function() pcall(NEX_TeleportToGate) end })
    tpSection:Button({ Title = "TP to Hook", Callback = function() pcall(NEX_TeleportToHook) end })
end

-- ESP Tab
do
    local basicEsp = ESPTab:Section({
        Title = "Basic ESP",
        Icon = "solar:eye-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    basicEsp:Toggle({
        Title = "Enable ESP (Highlight + Name)",
        Callback = function(v) VD.ESP = v; if v then for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then createSimpleESPForCharacter(p, p.Character) end end else for p,_ in pairs(SimpleESP) do removeSimpleESP(p) end end end
    })
    basicEsp:Toggle({ Title = "Show Distance", Callback = function(v) VD.ShowDistance = v end })
    basicEsp:Slider({
        Title = "Max ESP Distance",
        Value = { Min = 500, Max = 5000, Default = 2000 },
        Callback = function(v) VD.MaxDistance = v end
    })

    ESPTab:Space({ Columns = 0.5 })

    local advEsp = ESPTab:Section({
        Title = "Advanced ESP",
        Icon = "solar:magnifer-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    advEsp:Toggle({ Title = "Drawing Advanced ESP (boxes/skeleton/offscreen)", Callback = function(v) VD.DRAWING_ESP = v end })
    advEsp:Toggle({ Title = "Player Chams (model highlight)", Callback = function(v) VD.ESP_PlayerChams = v end })
    advEsp:Toggle({ Title = "Object Chams (gates/hooks/pallets/windows)", Callback = function(v) VD.ESP_ObjectChams = v end })
    advEsp:Toggle({ Title = "ESP Skeleton", Callback = function(v) VD.ESP_Skeleton = v end })
    advEsp:Toggle({ Title = "ESP Velocity Arrows", Callback = function(v) VD.ESP_Velocity = v end })
    advEsp:Toggle({ Title = "ESP Offscreen Arrows", Callback = function(v) VD.ESP_Offscreen = v end })
    advEsp:Toggle({ Title = "Closest Hook Highlight", Callback = function(v) VD.ESP_ClosestHook = v end })
end

-- Map Tab (Radar)
do
    local radarSection = MapTab:Section({
        Title = "Radar",
        Icon = "solar:radar-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    radarSection:Toggle({ Title = "Radar Enable", Callback = function(v) VD.RADAR_Enabled = v end })
    radarSection:Slider({
        Title = "Radar Size",
        Value = { Min = 80, Max = 300, Default = 120 },
        Callback = function(v) VD.RADAR_Size = v end
    })
    radarSection:Toggle({ Title = "Radar Circle Mode", Callback = function(v) VD.RADAR_Circle = v end })

    MapTab:Space({ Columns = 0.5 })

    local radarFilter = MapTab:Section({
        Title = "Radar Filters",
        Icon = "solar:filter-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    radarFilter:Toggle({ Title = "Radar show Killer", Callback = function(v) VD.RADAR_Killer = v end })
    radarFilter:Toggle({ Title = "Radar show Survivor", Callback = function(v) VD.RADAR_Survivor = v end })
    radarFilter:Toggle({ Title = "Radar show Generator", Callback = function(v) VD.RADAR_Generator = v end })
    radarFilter:Toggle({ Title = "Radar show Pallet", Callback = function(v) VD.RADAR_Pallet = v end })
end

-- Aim Tab
do
    local aimbotSection = AimTab:Section({
        Title = "Aimbot",
        Icon = "solar:target-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    aimbotSection:Toggle({ Title = "Enable Aimbot", Callback = function(v) VD.AIM_Enabled = v end })
    aimbotSection:Toggle({ Title = "Use RMB to aim", Callback = function(v) VD.AIM_UseRMB = v end })
    aimbotSection:Toggle({ Title = "Show Aim FOV (circle)", Callback = function(v) VD.AIM_ShowFOV = v end })
    aimbotSection:Slider({
        Title = "FOV Size (aim radius on screen)",
        Value = { Min = 50, Max = 400, Default = 120 },
        Callback = function(v) VD.AIM_FOV = v end
    })
    aimbotSection:Slider({
        Title = "Smoothness",
        Value = { Min = 0.1, Max = 1, Default = 0.3 },
        Callback = function(v) VD.AIM_Smooth = v end
    })
    -- Dropdown Target Part
    pcall(function()
        aimbotSection:Dropdown({
            Title = "Target Part",
            Options = { "Head", "Torso", "Root" },
            Value = VD.AIM_TargetPart or "Head",
            Callback = function(v) VD.AIM_TargetPart = v end
        })
    end)
    aimbotSection:Toggle({ Title = "Visibility Check", Callback = function(v) VD.AIM_VisCheck = v end })
    aimbotSection:Toggle({ Title = "Prediction", Callback = function(v) VD.AIM_Predict = v end })

    AimTab:Space({ Columns = 0.5 })

    local spearSection = AimTab:Section({
        Title = "Spear Aimbot",
        Icon = "solar:sword-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    spearSection:Toggle({ Title = "Spear Aimbot", Callback = function(v) VD.SPEAR_Aimbot = v end })
    spearSection:Slider({
        Title = "Spear Gravity",
        Value = { Min = 10, Max = 200, Default = 50 },
        Callback = function(v) VD.SPEAR_Gravity = v end
    })
    spearSection:Slider({
        Title = "Spear Speed",
        Value = { Min = 50, Max = 300, Default = 100 },
        Callback = function(v) VD.SPEAR_Speed = v end
    })
end

-- FOV Tab
do
    local camSection = FOVTab:Section({
        Title = "Camera",
        Icon = "solar:camera-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    camSection:Toggle({ Title = "Enable Camera FOV override", Callback = function(v) VD.CAM_FOVEnabled = v end })
    camSection:Slider({
        Title = "Camera FOV",
        Value = { Min = 30, Max = 140, Default = 90 },
        Callback = function(v) VD.CAM_FOV = v end
    })
    camSection:Toggle({ Title = "Third Person (Killer only)", Callback = function(v) VD.CAM_ThirdPerson = v end })
    camSection:Toggle({ Title = "Shift Lock (auto face camera)", Callback = function(v) VD.CAM_ShiftLock = v end })

    FOVTab:Space({ Columns = 0.5 })

    local visualSection = FOVTab:Section({
        Title = "Visual",
        Icon = "solar:sun-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    visualSection:Toggle({ Title = "No Fog (remove fog/post effects)", Callback = function(v) VD.NO_Fog = v end })
    visualSection:Toggle({ Title = "Fullbright (lighting preset)", Callback = function(v) VD.Fullbright = v end })
end

-- Survivor Tab
do
    local combatSurv = SurvivorTab:Section({
        Title = "Combat",
        Icon = "solar:shield-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    combatSurv:Toggle({ Title = "Auto Parry", Callback = function(v) VD.AUTO_Parry = v end })
    combatSurv:Slider({
        Title = "Parry Range (studs)",
        Value = { Min = 5, Max = 30, Default = 15 },
        Callback = function(v) VD.AUTO_ParryRange = v end
    })
    combatSurv:Slider({
        Title = "Face Killer Sensitivity (deg)",
        Value = { Min = 0, Max = 180, Default = 30 },
        Callback = function(v) VD.AUTO_ParrySensitivity = v end
    })
    combatSurv:Slider({
        Title = "Auto Parry Delay (s)",
        Value = { Min = 0.1, Max = 2, Default = 0.5, Step = 0.05 },
        Callback = function(v) VD.AUTO_ParryDelay = v end
    })
    combatSurv:Toggle({ Title = "Auto Stop Emote (after parry)", Callback = function(v) VD.AUTO_StopEmote = v end })
    combatSurv:Toggle({ Title = "Auto Wiggle", Callback = function(v) VD.SURV_AutoWiggle = v end })
    combatSurv:Toggle({
        Title = "Auto SkillCheck (QTE)",
        Callback = function(v) VD.AUTO_SkillCheck = v; if v then pcall(SetupSkillCheckMonitor) end
    })
    combatSurv:Toggle({ Title = "No Fall Damage", Callback = function(v) VD.SURV_NoFall = v end })

    SurvivorTab:Space({ Columns = 0.5 })

    local escapeSurv = SurvivorTab:Section({
        Title = "Escape",
        Icon = "solar:exit-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    escapeSurv:Toggle({ Title = "Flee Killer (Auto TeleAway)", Callback = function(v) VD.AUTO_TeleAway = v end })
    escapeSurv:Slider({
        Title = "Flee Distance",
        Value = { Min = 20, Max = 120, Default = 40 },
        Callback = function(v) VD.AUTO_TeleAwayDist = v end
    })
    escapeSurv:Toggle({ Title = "Beat Survivor (auto exit)", Callback = function(v) VD.BEAT_Survivor = v end })
end

-- Killer Tab
do
    local combatKiller = KillerTab:Section({
        Title = "Combat",
        Icon = "solar:danger-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    combatKiller:Toggle({ Title = "Auto Attack", Callback = function(v) VD.AUTO_Attack = v end })
    combatKiller:Slider({
        Title = "Attack Range",
        Value = { Min = 5, Max = 20, Default = 12 },
        Callback = function(v) VD.AUTO_AttackRange = v end
    })
    combatKiller:Toggle({ Title = "Hitbox Expand", Callback = function(v) VD.HITBOX_Enabled = v end })
    combatKiller:Slider({
        Title = "Hitbox Size",
        Value = { Min = 5, Max = 40, Default = 15 },
        Callback = function(v) VD.HITBOX_Size = v end
    })
    combatKiller:Toggle({ Title = "Double Tap", Callback = function(v) VD.KILLER_DoubleTap = v end })
    combatKiller:Toggle({ Title = "Infinite Lunge", Callback = function(v) VD.KILLER_InfiniteLunge = v end })

    KillerTab:Space({ Columns = 0.5 })

    local mapKiller = KillerTab:Section({
        Title = "Map Control",
        Icon = "solar:map-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    mapKiller:Toggle({ Title = "Destroy Pallets", Callback = function(v) VD.KILLER_DestroyPallets = v end })
    mapKiller:Toggle({ Title = "Full Gen Break", Callback = function(v) VD.KILLER_FullGenBreak = v end })

    KillerTab:Space({ Columns = 0.5 })

    local utilKiller = KillerTab:Section({
        Title = "Utilities",
        Icon = "solar:settings-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    utilKiller:Toggle({ Title = "Auto Hook", Callback = function(v) VD.KILLER_AutoHook = v end })
    utilKiller:Toggle({
        Title = "Anti Blind (Flashlight)",
        Callback = function(v) VD.KILLER_AntiBlind = v; pcall(SetupAntiBlind)
    })
    utilKiller:Toggle({
        Title = "No Pallet Stun (metamethod)",
        Callback = function(v) VD.KILLER_NoPalletStun = v; pcall(SetupNoPalletStun)
    })
    utilKiller:Toggle({ Title = "No Slowdown", Callback = function(v) VD.KILLER_NoSlowdown = v end })
    utilKiller:Toggle({ Title = "Beat Killer (auto kill)", Callback = function(v) VD.BEAT_Killer = v end })
end

-- Generator Tab
do
    local genVisual = GeneratorTab:Section({
        Title = "Visual",
        Icon = "solar:lightbulb-bolt-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    genVisual:Toggle({
        Title = "Generator ESP",
        Callback = function(v) VD.GeneratorESP = v; if not v then for _, folder in pairs(GeneratorESP) do if folder and folder.Parent then pcall(function() folder:Destroy() end) end end GeneratorESP = {} end
    })

    GeneratorTab:Space({ Columns = 0.5 })

    local genAuto = GeneratorTab:Section({
        Title = "Automation",
        Icon = "solar:bolt-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    genAuto:Toggle({ Title = "AntiFail Generator", Callback = function(v) VD.GenAntiFail = v end })
    genAuto:Toggle({ Title = "Auto Generator (Repair)", Callback = function(v) VD.AUTO_Generator = v end })
    -- Dropdown Gen Speed
    pcall(function()
        genAuto:Dropdown({
            Title = "Gen Speed",
            Options = { "Fast", "Slow" },
            Value = VD.AUTO_GenMode or "Fast",
            Callback = function(v) VD.AUTO_GenMode = v end
        })
    end)
    genAuto:Toggle({ Title = "Auto Leave Gen (when killer near)", Callback = function(v) VD.AUTO_LeaveGen = v end })
    genAuto:Slider({
        Title = "Leave Distance",
        Value = { Min = 10, Max = 30, Default = 18 },
        Callback = function(v) VD.AUTO_LeaveDist = v end
    })
    genAuto:Button({ Title = "Leave Gen Now", Callback = function() pcall(NEX_LeaveGenerator) end })
end

-- Fling Tab
do
    local flingSection = FlingTab:Section({
        Title = "Fling",
        Icon = "solar:wind-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    flingSection:Toggle({ Title = "Enable Fling", Callback = function(v) VD.FLING_Enabled = v end })
    flingSection:Slider({
        Title = "Fling Strength",
        Value = { Min = 1000, Max = 50000, Default = 10000 },
        Callback = function(v) VD.FLING_Strength = v end
    })

    FlingTab:Space({ Columns = 0.5 })

    local flingActions = FlingTab:Section({
        Title = "Actions",
        Icon = "solar:cursor-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    flingActions:Button({ Title = "Fling Nearest", Callback = function() pcall(NEX_FlingNearest) end })
    flingActions:Button({ Title = "Fling All", Callback = function() pcall(NEX_FlingAll) end })
end

-- Reset Tab
do
    local resetSection = ResetTab:Section({
        Title = "Unload",
        Icon = "solar:trash-bin-trash-bold",
        Box = true,
        BoxBorder = true,
        Opened = false,
    })

    resetSection:Button({
        Title = "Unload Script (cleanup)",
        Callback = function()
            VD.Destroyed = true
            VD.Fullbright = false
            VD.Noclip = false
            VD.GenAntiFail = false
            VD.HealAntiFail = false
            disableNoclipRestore()
            for p,_ in pairs(SimpleESP) do removeSimpleESP(p) end
            for _, folder in pairs(GeneratorESP) do if folder and folder.Parent then pcall(function() folder:Destroy() end) end end
            GeneratorESP = {}
            if DrawingAvailable then
                pcall(function()
                    for target,_ in pairs(Chams.Objects or {}) do
                        pcall(function() if target and target:FindFirstChild("_ViolenceChams") then target:FindFirstChild("_ViolenceChams"):Destroy() end end)
                        pcall(function() if target and target:FindFirstChild("_ViolenceLabel") then target:FindFirstChild("_ViolenceLabel"):Destroy() end end)
                    end
                end)
            end
            print("NEX HUB Violence District Unloaded")
        end
    })
end

print("NEX HUB Violence District Loaded (Full Features merged with UI fixes)")

-- =====================================================
-- (Di sini salin semua fungsi pendukung dari script final sebelumnya:
--  Role helpers, NEX_ScanMap, teleport, auto features, Chams, DrawingESP, Radar, Aimbot, dll.
--  Karena sangat panjang, saya tidak tulis ulang seluruhnya di sini.
--  Gunakan script final yang sudah saya kirim sebelumnya sebagai body lengkap.
--  Yang penting di atas adalah perubahan dropdown.
-- =====================================================

-- (Pastikan semua fungsi yang dipanggil di UI (NEX_TeleportToGenerator, NEX_TeleportToGate, NEX_TeleportToHook, dll.) sudah ada di bawah sini)
