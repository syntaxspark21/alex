--[[
    NEX HUB - VIOLENCE DISTRICT (FULL FIX + AUTO STOP EMOTE)
    Fixed: getgenv guard, hookmetamethod existence, Drawing.Fonts, unpack, VirtualInputManager, duplicate removal.
    All features included and functional.
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
local function SafeDrawing(dtype)
    local ok, result = pcall(function() return Drawing.new(dtype) end)
    if ok then return result end
    return nil
end
local function SafeRemove(obj)
    if obj and obj.Remove then pcall(function() obj:Remove() end) end
end
local DrawingAvailable = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

-- GUARDED Drawing.Fonts
local DrawFont = DrawingAvailable and (pcall(function() return Drawing.Fonts.Monospace end) and Drawing.Fonts.Monospace or 0) or 0

-- FALLBACK unpack
local _unpack = table.unpack or unpack

-- GUARDED VirtualInputManager
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local function SimKey(down, key)
    if not VIM then return end
    pcall(function() VIM:SendKeyEvent(down, key, false, game) end)
end

-- CONFIG
local _genv = (typeof(getgenv) == "function" and getgenv()) or _G or {}
_genv.VD = _genv.VD or {
    ESP = false, MaxDistance = 2000, ShowDistance = false,
    GeneratorESP = false, GenAntiFail = false, HealAntiFail = false,
    HideSkillUI = false, Fullbright = false,
    Speed = false, SpeedValue = 16, Jump = false, JumpValue = 50,
    InfiniteJump = false, Noclip = false,
    AUTO_Generator = false, AUTO_GenMode = "Fast",
    AUTO_LeaveGen = false, AUTO_LeaveDist = 18,
    AUTO_Attack = false, AUTO_AttackRange = 12,
    HITBOX_Enabled = false, HITBOX_Size = 15,
    AUTO_TeleAway = false, AUTO_TeleAwayDist = 40,
    AUTO_Parry = false, AUTO_StopEmote = false,
    AUTO_SkillCheck = false, SURV_AutoWiggle = false, SURV_NoFall = false,
    KILLER_DestroyPallets = false, KILLER_FullGenBreak = false,
    KILLER_NoPalletStun = false, KILLER_AutoHook = false,
    KILLER_AntiBlind = false, KILLER_NoSlowdown = false,
    KILLER_DoubleTap = false, KILLER_InfiniteLunge = false,
    FLY_Enabled = false, FLY_Speed = 50, FLY_Method = "CFrame",
    NO_Fog = false, CAM_FOVEnabled = false, CAM_FOV = 90,
    CAM_ThirdPerson = false, CAM_ShiftLock = false,
    FLING_Enabled = false, FLING_Strength = 10000,
    BEAT_Survivor = false, BEAT_Killer = false, TP_Offset = 3,
    DRAWING_ESP = false, ESP_PlayerChams = false, ESP_ObjectChams = true,
    ESP_Skeleton = false, ESP_Offscreen = true, ESP_Velocity = false, ESP_ClosestHook = true,
    RADAR_Enabled = false, RADAR_Size = 120, RADAR_Circle = false,
    RADAR_Killer = true, RADAR_Survivor = true, RADAR_Generator = true, RADAR_Pallet = true,
    AIM_Enabled = false, AIM_UseRMB = true, AIM_FOV = 120, AIM_Smooth = 0.3,
    AIM_TargetPart = "Head", AIM_VisCheck = true, AIM_ShowFOV = true, AIM_Predict = true,
    SPEAR_Aimbot = false, SPEAR_Gravity = 50, SPEAR_Speed = 100,
    Destroyed = false, _BeatSurvivorDone = false, _BeatKillerDone = false,
    _LastTeleAway = 0, _KillerTarget = nil, _LastTeleportTime = 0, _TeleportCooldown = 1,
}
local VD = _genv.VD

-- SAVE ORIGINAL LIGHTING
local originalLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient
}
do
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then originalLighting.Atmosphere = {Density=atm.Density,Offset=atm.Offset,Glare=atm.Glare,Haze=atm.Haze} end
    local blur = Lighting:FindFirstChildOfClass("BlurEffect")
    if blur then originalLighting.Blur = {Size=blur.Size} end
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc then originalLighting.ColorCorrection = {Enabled=cc.Enabled} end
    local sr = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if sr then originalLighting.SunRays = {Enabled=sr.Enabled} end
end

-- CHARACTER REFS
local Character, Humanoid, Root
local function updateChar()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Root     = Character:FindFirstChild("HumanoidRootPart")
    else
        Humanoid, Root, Character = nil, nil, nil
    end
end
updateChar()
LocalPlayer.CharacterAdded:Connect(updateChar)
LocalPlayer.CharacterRemoving:Connect(function() Character, Humanoid, Root = nil, nil, nil end)

-- HELPER
local function isTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end
local TeamColor  = Color3.fromRGB(0,255,0)
local EnemyColor = Color3.fromRGB(255,0,0)
local function getPlayerColor(player)
    return isTeammate(player) and TeamColor or EnemyColor
end
local function GetRole()
    if not LocalPlayer.Team then return "Unknown" end
    local n = LocalPlayer.Team.Name
    if n == "Killer"    then return "Killer"   end
    if n == "Survivors" then return "Survivor" end
    return "Lobby"
end
local function IsKiller(p)   return p and p.Team and p.Team.Name == "Killer" end
local function IsSurvivor(p) return p and p.Team and p.Team.Name == "Survivors" end

-- ANTI-FAIL HOOK (dengan guard hookmetamethod)
local AntiFailHooked = false
local oldNamecall
local function setupAntiFail()
    if AntiFailHooked then return end
    if typeof(hookmetamethod) ~= "function" then
        warn("[NEX HUB] Anti-Fail: hookmetamethod tidak tersedia")
        return
    end
    task.spawn(function()
        local ok, err = pcall(function()
            local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            local Events  = ReplicatedStorage:WaitForChild("Events",  10)
            if not Remotes then warn("AntiFail: Remotes not found") return end
            local GenFolder  = Remotes:FindFirstChild("Generator")
            local GenResult  = GenFolder and GenFolder:FindFirstChild("SkillCheckResultEvent")
            local GenFail    = GenFolder and GenFolder:FindFirstChild("SkillCheckFailEvent")
            local HealFolder = Events and Events:FindFirstChild("Healing")
            local HealResult = HealFolder and HealFolder:FindFirstChild("SkillCheckResultEvent")
            local HealFail   = HealFolder and HealFolder:FindFirstChild("SkillCheckFailEvent")

            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if GenResult and VD.GenAntiFail then
                    if GenFail and self == GenFail and method == "FireServer" then return nil end
                    if self == GenResult and method == "FireServer" then
                        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            args[1] = true
                            return oldNamecall(self, _unpack(args))
                        else
                            return nil
                        end
                    end
                end
                if HealResult and VD.HealAntiFail then
                    if HealFail and self == HealFail and method == "FireServer" then return nil end
                    if self == HealResult and method == "FireServer" then
                        args[1] = true
                        return oldNamecall(self, _unpack(args))
                    end
                end
                return oldNamecall(self, ...)
            end)
            AntiFailHooked = true
            print("[NEX HUB] Anti-Fail: Hooked")
        end)
        if not ok then warn("[NEX HUB] Anti-Fail setup failed:", err) end
    end)
end
setupAntiFail()

-- SIMPLE ESP (Highlight + Billboard)
local SimpleESP = {}
local function createSimpleESPForCharacter(player, char)
    if not player or not char then return end
    if SimpleESP[player] and SimpleESP[player].Folder and SimpleESP[player].Folder.Parent then
        pcall(function() SimpleESP[player].Folder:Destroy() end)
    end
    local folder    = Instance.new("Folder"); folder.Name = "SimpleESP"; folder.Parent = char
    local highlight = Instance.new("Highlight"); highlight.Parent = folder
    highlight.Adornee = char; highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0; highlight.Enabled = VD.ESP
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local billboard = Instance.new("BillboardGui"); billboard.Name = "NameESP"
    billboard.Size = UDim2.new(0,160,0,30); billboard.Adornee = head
    billboard.AlwaysOnTop = true; billboard.ExtentsOffset = Vector3.new(0,2.5,0)
    billboard.Parent = folder
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1; label.TextColor3 = getPlayerColor(player)
    label.Font = Enum.Font.SourceSansBold; label.TextSize = 14; label.Text = player.Name
    label.Parent = billboard
    SimpleESP[player] = {Folder=folder,Highlight=highlight,Billboard=billboard,Label=label}
end
local function createSimpleESP(player)
    if not player or player == LocalPlayer then return end
    if player.Character then createSimpleESPForCharacter(player, player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        if VD.ESP then createSimpleESPForCharacter(player, char) end
    end)
end
local function removeSimpleESP(player)
    if SimpleESP[player] and SimpleESP[player].Folder and SimpleESP[player].Folder.Parent then
        pcall(function() SimpleESP[player].Folder:Destroy() end)
    end
    SimpleESP[player] = nil
end
local function updateSimpleESP()
    Camera = Workspace.CurrentCamera or Camera
    for player, data in pairs(SimpleESP) do
        if not player or not player.Parent or not player.Character then
            removeSimpleESP(player); continue
        end
        local char  = player.Character
        local hrp   = char:FindFirstChild("HumanoidRootPart")
        local head  = char:FindFirstChild("Head")
        local posRef = head or hrp or char.PrimaryPart
        if not posRef then
            if data.Highlight then pcall(function() data.Highlight.Enabled = false end) end
            if data.Label     then pcall(function() data.Label.Visible = false end) end
            continue
        end
        local distance = (posRef.Position - (Camera and Camera.CFrame.Position or posRef.Position)).Magnitude
        if distance > VD.MaxDistance then
            if data.Highlight then pcall(function() data.Highlight.Enabled = false end) end
            if data.Label     then pcall(function() data.Label.Visible = false end) end
            continue
        end
        local _, onScreen = Camera:WorldToViewportPoint(posRef.Position)
        if data.Label then data.Label.Visible = onScreen end
        local color = getPlayerColor(player)
        if data.Highlight then
            data.Highlight.FillColor = color; data.Highlight.OutlineColor = color
            data.Highlight.Enabled = VD.ESP
        end
        if data.Label then
            data.Label.TextColor3 = color
            data.Label.Text = VD.ShowDistance
                and string.format("%s [%.0fm]", player.Name, distance)
                or  player.Name
            if data.Billboard and (not data.Billboard.Adornee or data.Billboard.Adornee.Parent ~= char) then
                data.Billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
            end
        end
    end
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createSimpleESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createSimpleESP(p) end end)
Players.PlayerRemoving:Connect(removeSimpleESP)

-- GENERATOR ESP
local GeneratorESP = {}
local function createGeneratorESP(gen)
    if not gen or not gen:IsA("Model") or gen:FindFirstChild("GenESP") then return end
    local folder    = Instance.new("Folder", gen); folder.Name = "GenESP"
    local highlight = Instance.new("Highlight", folder)
    highlight.Adornee = gen; highlight.FillColor = Color3.fromRGB(0,255,255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    local billboard = Instance.new("BillboardGui", folder)
    billboard.Size = UDim2.new(0,80,0,40); billboard.AlwaysOnTop = true
    billboard.Adornee = gen:FindFirstChild("HitBox") or gen.PrimaryPart
    billboard.ExtentsOffset = Vector3.new(0,3,0)
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1,0,1,0); textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1,1,1); textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    GeneratorESP[gen] = folder
    task.spawn(function()
        while gen.Parent and folder.Parent and not VD.Destroyed do
            local progress = gen:GetAttribute("RepairProgress") or 0
            textLabel.Text = math.floor(progress) .. "%"
            highlight.Enabled = VD.GeneratorESP; textLabel.Visible = VD.GeneratorESP
            highlight.FillColor = progress >= 100 and Color3.new(0,1,0) or Color3.new(0,1,1)
            task.wait(1)
        end
    end)
end
task.spawn(function()
    while not VD.Destroyed do
        if VD.GeneratorESP then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name == "Generator" and obj:IsA("Model") and not obj:FindFirstChild("GenESP") then
                    createGeneratorESP(obj)
                end
            end
        end
        task.wait(3)
    end
end)

-- FULLBRIGHT
task.spawn(function()
    while not VD.Destroyed do
        if VD.Fullbright then
            Lighting.Brightness = 2; Lighting.ClockTime = 14
            Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
            Lighting.FogStart = 0; Lighting.FogEnd = 100000
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") then v.Density=0;v.Offset=0;v.Glare=0;v.Haze=0 end
                if v:IsA("BlurEffect") then v.Size = 0 end
                if v:IsA("ColorCorrectionEffect") then v.Enabled = false end
                if v:IsA("SunRaysEffect") then v.Enabled = false end
            end
        else
            Lighting.Brightness    = originalLighting.Brightness
            Lighting.ClockTime     = originalLighting.ClockTime
            Lighting.FogEnd        = originalLighting.FogEnd
            Lighting.FogStart      = originalLighting.FogStart or 0
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") and originalLighting.Atmosphere then
                    v.Density = originalLighting.Atmosphere.Density or 0.3
                    v.Offset  = originalLighting.Atmosphere.Offset  or 0.25
                    v.Glare   = originalLighting.Atmosphere.Glare   or 0
                    v.Haze    = originalLighting.Atmosphere.Haze    or 0
                end
                if v:IsA("BlurEffect")           and originalLighting.Blur            then v.Size    = originalLighting.Blur.Size            or 0     end
                if v:IsA("ColorCorrectionEffect") and originalLighting.ColorCorrection then v.Enabled = originalLighting.ColorCorrection.Enabled or false end
                if v:IsA("SunRaysEffect")         and originalLighting.SunRays         then v.Enabled = originalLighting.SunRays.Enabled         or false end
            end
        end
        task.wait(0.5)
    end
end)

-- NOCLIP
local originalCanCollide = {}
local function enableNoclipOnce()
    local char = LocalPlayer.Character; if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalCanCollide[part] == nil then originalCanCollide[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end
local function disableNoclipRestore()
    for part, val in pairs(originalCanCollide) do
        if part and part.Parent and part:IsA("BasePart") then
            pcall(function() part.CanCollide = val end)
        end
    end
    originalCanCollide = {}
end

RunService.Heartbeat:Connect(function()
    updateChar()
    if Humanoid then
        if VD.Speed then Humanoid.WalkSpeed = VD.SpeedValue end
        if VD.Jump  then Humanoid.JumpPower = VD.JumpValue  end
    end
    if VD.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not SimpleESP[p] and p.Character then
                createSimpleESPForCharacter(p, p.Character)
            end
        end
    end
    updateSimpleESP()
    if VD.Noclip and LocalPlayer.Character then
        enableNoclipOnce()
    elseif not VD.Noclip and next(originalCanCollide) then
        disableNoclipRestore()
    end
end)

UserInputService.JumpRequest:Connect(function()
    if VD.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- HIDE SKILL CHECK UI
local cachedPlayerGui = LocalPlayer:WaitForChild("PlayerGui")
RunService.RenderStepped:Connect(function()
    if not VD.HideSkillUI then return end
    if not cachedPlayerGui then cachedPlayerGui = LocalPlayer:FindFirstChild("PlayerGui") end
    local a = cachedPlayerGui and cachedPlayerGui:FindFirstChild("SkillCheckPromptGui")
    local b = cachedPlayerGui and cachedPlayerGui:FindFirstChild("SkillCheckPromptGui-con")
    if a and a.Enabled then a.Enabled = false end
    if b and b.Enabled then b.Enabled = false end
end)

-- MAP CACHE
local NEX_Cache = {Generators={},Gates={},Hooks={},Pallets={},Windows={},ClosestHook=nil}
local function NEX_ScanMap()
    local map = Workspace:FindFirstChild("Map")
    if not map then
        NEX_Cache.Generators={}; NEX_Cache.Gates={}; NEX_Cache.Hooks={}
        NEX_Cache.Pallets={}; NEX_Cache.Windows={}
        return
    end
    local newG,newGt,newH,newP,newW = {},{},{},{},{}
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local n = obj.Name
                if     n == "Generator"                         then table.insert(newG,  {model=obj,part=part})
                elseif n == "Gate"                              then table.insert(newGt, {model=obj,part=part})
                elseif n == "Hook"                              then table.insert(newH,  {model=obj,part=part})
                elseif n == "Palletwrong" or n:lower():find("pallet") then table.insert(newP,{model=obj,part=part})
                elseif n == "Window"                            then table.insert(newW,  {model=obj,part=part})
                end
            end
        end
    end
    NEX_Cache.Generators=newG; NEX_Cache.Gates=newGt; NEX_Cache.Hooks=newH
    NEX_Cache.Pallets=newP; NEX_Cache.Windows=newW
    if Root and #NEX_Cache.Hooks > 0 then
        local closest, closestDist = nil, math.huge
        for _, hook in ipairs(NEX_Cache.Hooks) do
            if hook.part then
                local d = (hook.part.Position - Root.Position).Magnitude
                if d < closestDist then closestDist=d; closest=hook end
            end
        end
        NEX_Cache.ClosestHook = closest
    end
end

-- TELEPORT HELPER
local function NEX_TeleportToPosition(pos)
    if not pos then return false end
    local root = Root; if not root then return false end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCanCollide[part] == nil then originalCanCollide[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
    root.CFrame = CFrame.new(pos + Vector3.new(0, VD.TP_Offset, 0))
    task.delay(0.3, function()
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    pcall(function() part.CanCollide = originalCanCollide[part] ~= nil and originalCanCollide[part] or true end)
                end
            end
        end
        originalCanCollide = {}
    end)
    VD._LastTeleportTime = tick()
    return true
end

local function NEX_TeleportToGenerator(index)
    NEX_ScanMap()
    if #NEX_Cache.Generators == 0 then print("[NEX HUB] Generator tidak ditemukan") return false end
    local sorted = {}
    for _, gen in ipairs(NEX_Cache.Generators) do
        table.insert(sorted, {gen=gen, dist=Root and (gen.part.Position-Root.Position).Magnitude or math.huge})
    end
    table.sort(sorted, function(a,b) return a.dist < b.dist end)
    local target = sorted[index or 1]; if not target then return false end
    return NEX_TeleportToPosition(target.gen.part.Position)
end

local function NEX_TeleportToGate()
    NEX_ScanMap()
    if #NEX_Cache.Gates == 0 then print("[NEX HUB] Gate tidak ditemukan") return false end
    local closest, closestDist = nil, math.huge
    for _, gate in ipairs(NEX_Cache.Gates) do
        local dist = Root and (gate.part.Position-Root.Position).Magnitude or math.huge
        if dist < closestDist then closestDist=dist; closest=gate end
    end
    if not closest then return false end
    return NEX_TeleportToPosition(closest.part.Position)
end

local function NEX_TeleportToHook()
    NEX_ScanMap()
    if not NEX_Cache.ClosestHook then print("[NEX HUB] Hook tidak ditemukan") return false end
    return NEX_TeleportToPosition(NEX_Cache.ClosestHook.part.Position)
end

-- AUTO LEAVE GENERATOR
local function NEX_LeaveGenerator()
    if not VD.AUTO_LeaveGen then return end
    if GetRole() == "Killer" then return end
    if tick() - VD._LastTeleportTime < VD._TeleportCooldown then return end
    local root = Root; if not root then return end
    local nearestGen, nearestDist = nil, math.huge
    for _, gen in ipairs(NEX_Cache.Generators) do
        if gen.part then
            local dist = (gen.part.Position - root.Position).Magnitude
            if dist < nearestDist then nearestDist=dist; nearestGen=gen end
        end
    end
    if nearestGen and nearestDist <= VD.AUTO_LeaveDist then
        local dir = (root.Position - nearestGen.part.Position).Unit
        if dir ~= dir then dir = Vector3.new(1,0,0) end -- NaN guard
        NEX_TeleportToPosition(root.Position + dir * (VD.AUTO_LeaveDist + 5))
        print("[NEX HUB] Auto Leave Gen")
    end
end

-- AUTO GENERATOR
task.spawn(function()
    local repairRemote, skillRemote, lastScan, genPoints = nil, nil, 0, {}
    while not VD.Destroyed do
        if VD.AUTO_Generator then
            if not repairRemote or not skillRemote then
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("Remotes")
                    local g = r and r:FindFirstChild("Generator")
                    repairRemote = g and g:FindFirstChild("RepairEvent")
                    skillRemote  = g and g:FindFirstChild("SkillCheckResultEvent")
                end)
            end
            if tick() - lastScan > 2 then
                genPoints = {}
                local m = Workspace:FindFirstChild("Map")
                if m then
                    for _, v in ipairs(m:GetDescendants()) do
                        if v:IsA("Model") and v.Name == "Generator" then
                            for _, c in ipairs(v:GetChildren()) do
                                if c.Name:match("GeneratorPoint") then table.insert(genPoints,{gen=v,pt=c}) end
                            end
                        end
                    end
                end
                lastScan = tick()
            end
            if repairRemote and skillRemote then
                local fast = VD.AUTO_GenMode == "Fast"
                for _, data in ipairs(genPoints) do
                    pcall(function() repairRemote:FireServer(data.pt, true) end)
                    pcall(function() skillRemote:FireServer(fast and "success" or "neutral", fast and 1 or 0, data.gen, data.pt) end)
                end
            end
        end
        task.wait(0.15)
    end
end)

-- AUTO ATTACK
local LastAutoAttackTime = 0
local function NEX_AutoAttack()
    if not VD.AUTO_Attack or GetRole() ~= "Killer" then return end
    if tick() - LastAutoAttackTime < 0.5 then return end
    local root = Root; if not root then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local tHum  = player.Character:FindFirstChildOfClass("Humanoid")
        if not tRoot or not tHum or tHum.Health <= 0 then continue end
        if (tRoot.Position - root.Position).Magnitude > VD.AUTO_AttackRange then continue end
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
            local attacks = remotes:FindFirstChild("Attacks")
            local basicAttack = (attacks and attacks:FindFirstChild("BasicAttack"))
                             or remotes:FindFirstChild("BasicAttack")
                             or (remotes:FindFirstChild("Killer") and remotes:FindFirstChild("Killer"):FindFirstChild("Attack"))
            if basicAttack then basicAttack:FireServer(false); LastAutoAttackTime = tick() end
        end)
        break
    end
end

-- AUTO PARRY + AUTO STOP EMOTE
local LastParryTime = 0
local function NEX_AutoParry()
    if not VD.AUTO_Parry or GetRole() ~= "Survivor" then return end
    if tick() - LastParryTime < 0.7 then return end
    local root = Root; if not root then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if not player.Parent or not player.Character or not IsKiller(player) then continue end
        local kRoot = player.Character:FindFirstChild("HumanoidRootPart"); if not kRoot then continue end
        if (kRoot.Position - root.Position).Magnitude > 20 then continue end
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
            local function doStopEmote()
                if VD.AUTO_StopEmote then
                    local eh = remotes:FindFirstChild("EmoteHandler")
                    if eh then eh:FireServer("StopEmote") end
                end
            end
            -- Try Parrying Dagger first
            local items = remotes:FindFirstChild("Items")
            if items then
                local dagger = items:FindFirstChild("Parrying Dagger")
                if dagger then
                    local parry = dagger:FindFirstChild("parry")
                    if parry then parry:FireServer(); LastParryTime=tick(); doStopEmote(); return end
                end
            end
            -- Fallback remotes
            local parryEvent = remotes:FindFirstChild("Parry")
            if parryEvent then parryEvent:FireServer(); LastParryTime=tick(); doStopEmote(); return end
            local survivor = remotes:FindFirstChild("Survivor")
            if survivor then
                local p2 = survivor:FindFirstChild("Parry")
                if p2 then p2:FireServer(); LastParryTime=tick(); doStopEmote() end
            end
        end)
        break
    end
end

-- AUTO WIGGLE
local LastWiggleTime = 0
local function NEX_AutoWiggle()
    if not VD.SURV_AutoWiggle or GetRole() ~= "Survivor" then return end
    if tick() - LastWiggleTime < 0.3 then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local carry   = remotes:FindFirstChild("Carry"); if not carry then return end
        local selfUnhook = carry:FindFirstChild("SelfUnHookEvent")
        if selfUnhook then selfUnhook:FireServer(); LastWiggleTime=tick() end
    end)
end

-- HITBOX EXPAND
local OriginalHitboxSizes = {}
local function NEX_UpdateHitboxes()
    if GetRole() ~= "Killer" or not VD.HITBOX_Enabled then
        for player, originalSize in pairs(OriginalHitboxSizes) do
            if player and player.Character then
                local r = player.Character:FindFirstChild("HumanoidRootPart")
                if r then r.Size=originalSize; r.Transparency=1; r.CanCollide=true end
            end
        end
        OriginalHitboxSizes = {}; return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum  = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                if not OriginalHitboxSizes[player] then OriginalHitboxSizes[player] = root.Size end
                local s = VD.HITBOX_Size
                root.Size=Vector3.new(s,s,s); root.CanCollide=false; root.Transparency=0.7
            end
        end
    end
end

-- DESTROY PALLETS
local LastDestroyTime = 0
local function NEX_DestroyAllPallets()
    if not VD.KILLER_DestroyPallets or GetRole() ~= "Killer" then return end
    if tick() - LastDestroyTime < 0.3 then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local pallet  = remotes:FindFirstChild("Pallet")
        local destroy = pallet and pallet:FindFirstChild("Jason") and pallet:FindFirstChild("Jason"):FindFirstChild("Destroy")
                     or remotes:FindFirstChild("DestroyPallet")
        if not destroy then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj.Name == "Palletwrong" or obj.Name:lower():find("pallet")) and obj:IsA("Model") then
                pcall(function() destroy:FireServer(obj) end)
                LastDestroyTime = tick()
            end
        end
    end)
end

-- FULL GEN BREAK
local LastGenBreakTime = 0
local function NEX_FullGenBreak()
    if not VD.KILLER_FullGenBreak or GetRole() ~= "Killer" then return end
    if tick() - LastGenBreakTime < 0.3 then return end
    local root = Root; if not root then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local g = remotes:FindFirstChild("Generator"); if not g then return end
        local breakEvent = g:FindFirstChild("BreakGenEvent"); if not breakEvent then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("generator") or obj.Name:lower():find("gen") then
                local genPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if genPart and (genPart.Position - root.Position).Magnitude <= 15 then
                    breakEvent:FireServer(obj); LastGenBreakTime=tick()
                end
            end
        end
    end)
end

-- DOUBLE TAP
local LastDoubleTapTime = 0
local function NEX_DoubleTap()
    if not VD.KILLER_DoubleTap or GetRole() ~= "Killer" then return end
    if tick() - LastDoubleTapTime < 0.5 then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks"); if not attacks then return end
        local basic   = attacks:FindFirstChild("BasicAttack"); if not basic then return end
        basic:FireServer(false); task.wait(0.05); basic:FireServer(false)
        LastDoubleTapTime = tick()
    end)
end

-- INFINITE LUNGE
local function NEX_InfiniteLunge()
    if not VD.KILLER_InfiniteLunge or GetRole() ~= "Killer" then return end
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    root.Velocity = root.CFrame.LookVector * 100 + Vector3.new(0,10,0)
end

-- NO FALL DAMAGE
local function UpdateNoFall()
    if not VD.SURV_NoFall then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    end)
end

-- NO SLOWDOWN
local function UpdateNoSlowdown()
    if not VD.KILLER_NoSlowdown or GetRole() ~= "Killer" then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
end

-- TELEPORT AWAY
local function NEX_GetKillerDistance()
    local root = Root; if not root then return math.huge, nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsKiller(player) then
            local kRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if kRoot then return (kRoot.Position-root.Position).Magnitude, kRoot.Position end
        end
    end
    return math.huge, nil
end
local function NEX_TeleportAway()
    if not VD.AUTO_TeleAway or GetRole() == "Killer" then return end
    if not VD._LastTeleAway then VD._LastTeleAway = 0 end
    if tick() - VD._LastTeleAway < 3 then return end
    local root = Root; if not root then return end
    local killerDist, killerPos = NEX_GetKillerDistance()
    if killerDist > VD.AUTO_TeleAwayDist then return end
    VD._LastTeleAway = tick()
    local bestSpot, bestDist = nil, 0
    for _, gate in ipairs(NEX_Cache.Gates) do
        if gate.part and killerPos then
            local d = (gate.part.Position - killerPos).Magnitude
            if d > bestDist then bestDist=d; bestSpot=gate.part.Position end
        end
    end
    if not bestSpot then
        for _, gen in ipairs(NEX_Cache.Generators) do
            if gen.part and killerPos then
                local d = (gen.part.Position - killerPos).Magnitude
                if d > bestDist then bestDist=d; bestSpot=gen.part.Position end
            end
        end
    end
    if not bestSpot and killerPos then
        bestSpot = root.Position + (root.Position - killerPos).Unit * 80
    end
    if bestSpot then NEX_TeleportToPosition(bestSpot) end
end

-- BEAT GAME
local function NEX_BeatGameSurvivor()
    if not VD.BEAT_Survivor or GetRole() ~= "Survivor" or VD._BeatSurvivorDone then return end
    local root = Root; if not root then return end
    local exitPos = nil
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("finish") or n:find("exit") or n:find("end")) and obj:IsA("BasePart") then
                exitPos = obj.Position; return
            end
        end
        if not exitPos then
            for _, obj in ipairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if (n:find("finish") or n:find("exit") or n:find("end")) and obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then exitPos = part.Position; return end
                end
            end
        end
        if not exitPos then
            local map = Workspace:FindFirstChild("Map")
            if map then
                if map:FindFirstChild("RooftopHitbox") then exitPos = Vector3.new(3098.16,454.04,-4918.74)
                elseif map:FindFirstChild("HooksMeat")  then exitPos = Vector3.new(1546.12,152.21,-796.72)
                elseif map:FindFirstChild("churchbell") then exitPos = Vector3.new(760.98,-20.14,-78.48) end
            end
        end
    end)
    if not exitPos then print("[NEX HUB] Exit tidak ditemukan"); return end
    root.CFrame = CFrame.new(exitPos + Vector3.new(0,3,0))
    VD._BeatSurvivorDone = true
    print("[NEX HUB] Survivor beat!")
end
local function NEX_BeatGameKiller()
    if not VD.BEAT_Killer or GetRole() ~= "Killer" then return end
    local root = Root; if not root then return end
    if not VD._KillerTarget or not VD._KillerTarget.Parent then
        local closest, closestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
                local pHum  = player.Character:FindFirstChildOfClass("Humanoid")
                local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if pHum and pHum.Health > 0 and pRoot then
                    local d = (pRoot.Position - root.Position).Magnitude
                    if d < closestDist then closestDist=d; closest=player end
                end
            end
        end
        VD._KillerTarget = closest
    end
    if not VD._KillerTarget or not VD._KillerTarget.Parent or not VD._KillerTarget.Character then
        VD._KillerTarget = nil; return
    end
    local target     = VD._KillerTarget
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local targetHum  = target.Character:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetHum or targetHum.Health <= 0 then VD._KillerTarget=nil; return end
    local dir = (targetRoot.Position - root.Position).Unit
    if dir == dir then root.CFrame = CFrame.new(root.Position + dir*2, targetRoot.Position) end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local attacks = remotes:FindFirstChild("Attacks"); if not attacks then return end
        local basic   = attacks:FindFirstChild("BasicAttack"); if not basic then return end
        basic:FireServer(false)
    end)
end

-- AUTO HOOK
local LastAutoHookTime = 0
local AutoHookState = {phase=0,target=nil,startTime=0}
local function NEX_AutoHook()
    if not VD.KILLER_AutoHook then AutoHookState.phase=0; AutoHookState.target=nil; return end
    if GetRole() ~= "Killer" then AutoHookState.phase=0; AutoHookState.target=nil; return end
    local root = Root; if not root then return end
    if tick() - LastAutoHookTime < 0.5 then return end
    local closestDowned, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local tHum  = player.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and tHum and tHum.MaxHealth > 0 then
                local pct = tHum.Health / tHum.MaxHealth
                if pct > 0 and pct <= 0.25 then
                    local d = (tRoot.Position - root.Position).Magnitude
                    if d < closestDist then closestDist=d; closestDowned={player=player,root=tRoot} end
                end
            end
        end
    end
    if closestDowned then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide=false end) end
        end
        root.CFrame = CFrame.new(closestDowned.root.Position + Vector3.new(0,3,0), closestDowned.root.Position)
        task.spawn(function()
            local endTime = tick() + 1.5
            while tick() < endTime do
                SimKey(true,  Enum.KeyCode.Space)
                task.wait(0.05)
                SimKey(false, Enum.KeyCode.Space)
                task.wait(0.08)
            end
        end)
        AutoHookState.phase=1; AutoHookState.target=closestDowned.player; AutoHookState.startTime=tick()
        task.delay(0.5, function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        pcall(function() part.CanCollide=true end)
                    end
                end
            end
        end)
        LastAutoHookTime = tick()
    end
end

-- FLING
local function NEX_FlingNearest()
    if not VD.FLING_Enabled then return end
    local root = Root; if not root then return end
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local d = (tRoot.Position - root.Position).Magnitude
                if d < closestDist then closestDist=d; closest=player end
            end
        end
    end
    if not closest or not closest.Character then return end
    local tRoot = closest.Character:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local origPos = root.CFrame
    for _ = 1, 10 do
        root.CFrame    = tRoot.CFrame
        root.Velocity  = Vector3.new(VD.FLING_Strength, VD.FLING_Strength/2, VD.FLING_Strength)
        root.RotVelocity = Vector3.new(9999,9999,9999)
        task.wait()
    end
    root.CFrame = origPos; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
end
local function NEX_FlingAll()
    if not VD.FLING_Enabled then return end
    local root = Root; if not root then return end
    local origPos = root.CFrame
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                for _ = 1, 5 do
                    root.CFrame    = tRoot.CFrame
                    root.Velocity  = Vector3.new(VD.FLING_Strength, VD.FLING_Strength/2, VD.FLING_Strength)
                    root.RotVelocity = Vector3.new(9999,9999,9999)
                    task.wait()
                end
            end
        end
    end
    root.CFrame = origPos; root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero
end

-- SKILL CHECK MONITOR
local QTEHandler = {Monitoring=false,FrameConn=nil,UIConn=nil,Elements=nil}
local function QTE_StopMonitoring()
    if QTEHandler.FrameConn then pcall(function() QTEHandler.FrameConn:Disconnect() end); QTEHandler.FrameConn=nil end
    QTEHandler.Monitoring = false
end
local function QTE_IsNeedleInZone(needleAngle, targetAngle)
    local n, t = needleAngle % 360, targetAngle % 360
    local sweet = 20
    return math.abs(n-t) < sweet or math.abs((n-360)-t) < sweet or math.abs(n-(t-360)) < sweet
end
local function QTE_SimulateInput()
    task.spawn(function()
        SimKey(true,  Enum.KeyCode.Space)
        task.wait(0.08)
        SimKey(false, Enum.KeyCode.Space)
    end)
end
local function SetupSkillCheckMonitor()
    pcall(function()
        QTE_StopMonitoring()
        if QTEHandler.UIConn then pcall(function() QTEHandler.UIConn:Disconnect() end); QTEHandler.UIConn=nil end
        task.wait(0.2)
        local pg = LocalPlayer:WaitForChild("PlayerGui", 3); if not pg then return end
        local prompt = pg:FindFirstChild("SkillCheckPromptGui") or pg:FindFirstChild("SkillCheck") or pg:FindFirstChild("SkillCheckGUI")
        if not prompt then return end
        local check  = prompt:FindFirstChild("Check") or prompt:FindFirstChild("Frame") or prompt:FindFirstChildOfClass("Frame")
        if not check  then return end
        local needle = check:FindFirstChild("Line") or check:FindFirstChild("Needle") or check:FindFirstChild("Arrow")
        local target = check:FindFirstChild("Goal") or check:FindFirstChild("Target") or check:FindFirstChild("Zone")
        if not needle or not target then return end
        QTEHandler.Elements = {frame=check,needle=needle,target=target}
        QTEHandler.UIConn = check:GetPropertyChangedSignal("Visible"):Connect(function()
            if not VD.AUTO_SkillCheck then return end
            if check.Visible then
                if not QTEHandler.Monitoring then
                    QTEHandler.Monitoring = true
                    QTEHandler.FrameConn = RunService.Heartbeat:Connect(function()
                        if not VD.AUTO_SkillCheck or not check.Visible then QTE_StopMonitoring(); return end
                        if QTE_IsNeedleInZone(needle.Rotation, target.Rotation) then
                            QTE_SimulateInput(); QTE_StopMonitoring()
                        end
                    end)
                end
            else
                QTE_StopMonitoring()
            end
        end)
    end)
end
pcall(SetupSkillCheckMonitor)

-- NO PALLET STUN
local function SetupNoPalletStun()
    pcall(function()
        task.spawn(function()
            while not VD.Destroyed do
                if VD.KILLER_NoPalletStun and GetRole() == "Killer" then
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
                        local pallet  = remotes:FindFirstChild("Pallet"); if not pallet then return end
                        for _, child in ipairs(pallet:GetChildren()) do
                            pcall(function() if child:IsA("RemoteEvent") then child.OnServerEvent:Connect(function() return nil end) end end)
                        end
                        local jason = pallet:FindFirstChild("Jason")
                        if jason then
                            for _, child in ipairs(jason:GetChildren()) do
                                pcall(function()
                                    if child:IsA("RemoteEvent") and (child.Name=="Stun" or child.Name=="StunDrop") then
                                        child.OnServerEvent:Connect(function() return nil end)
                                    end
                                end)
                            end
                        end
                    end)
                end
                task.wait(3)
            end
        end)
    end)
end
pcall(SetupNoPalletStun)

-- ANTI BLIND
local function SetupAntiBlind()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes"); if not remotes then return end
        local items   = remotes:FindFirstChild("Items"); if not items then return end
        local fl      = items:FindFirstChild("Flashlight"); if not fl then return end
        local gb      = fl:FindFirstChild("GotBlinded")
        if gb and gb:IsA("RemoteEvent") then
            local old = gb.FireServer
            gb.FireServer = function(self, ...)
                if VD.KILLER_AntiBlind and GetRole() == "Killer" then return nil end
                return old(self, ...)
            end
        end
    end)
end
pcall(SetupAntiBlind)

-- CAMERA
local OriginalFOV = nil
local function UpdateCameraFOV()
    local cam = workspace.CurrentCamera; if not cam then return end
    if not OriginalFOV then OriginalFOV = cam.FieldOfView end
    cam.FieldOfView = VD.CAM_FOVEnabled and (VD.CAM_FOV or 90) or OriginalFOV
end

local OriginalCameraType, ThirdPersonWasActive = nil, false
local function UpdateThirdPerson()
    local cam = workspace.CurrentCamera; if not cam then return end
    local shouldBeActive = VD.CAM_ThirdPerson and GetRole() == "Killer"
    if shouldBeActive then
        if not ThirdPersonWasActive then OriginalCameraType = cam.CameraType end
        cam.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.CameraOffset = Vector3.new(2,1,8) end end
        ThirdPersonWasActive = true
    elseif ThirdPersonWasActive then
        if OriginalCameraType then cam.CameraType = OriginalCameraType; OriginalCameraType = nil end
        local char = LocalPlayer.Character
        if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.CameraOffset = Vector3.new(0,0,0) end end
        ThirdPersonWasActive = false
    end
end

local function UpdateShiftLock()
    if not VD.CAM_ShiftLock then return end
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local cam  = workspace.CurrentCamera
    if not root or not cam then return end
    local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
    root.CFrame = CFrame.new(root.Position, root.Position + flat)
end

-- NO FOG
local FogCache = {}
local function RemoveFog()
    pcall(function()
        local map = Workspace:FindFirstChild("Map")
        if map then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj.Name:lower():find("fog") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") then
                    if not FogCache[obj] then FogCache[obj]={enabled=obj:IsA("PostEffect") and obj.Enabled or true, parent=obj.Parent} end
                    if obj:IsA("PostEffect") then obj.Enabled=false else obj.Parent=nil end
                end
            end
        end
        local lighting = game:GetService("Lighting")
        for _, obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("Atmosphere") or obj.Name:lower():find("fog") then
                if not FogCache[obj] then FogCache[obj]={enabled=true,parent=obj.Parent} end
                if obj:IsA("Atmosphere") then obj.Density=0 else obj.Parent=nil end
            end
        end
        lighting.FogEnd=100000; lighting.FogStart=0
    end)
end
local function RestoreFog()
    pcall(function()
        for obj, data in pairs(FogCache) do
            if obj and data.parent then
                if obj:IsA("PostEffect") then obj.Enabled=data.enabled else obj.Parent=data.parent end
            end
        end
        FogCache={}
        game:GetService("Lighting").FogEnd = 1000
    end)
end

-- FLY
local FlyBodyVelocity, FlyBodyGyro = nil, nil
local function UpdateFly()
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if VD.FLY_Enabled then
        hum.PlatformStand = true
        if not FlyBodyVelocity then
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            FlyBodyVelocity.Velocity = Vector3.zero; FlyBodyVelocity.Parent = root
        end
        if not FlyBodyGyro then
            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
            FlyBodyGyro.P = 9e4; FlyBodyGyro.Parent = root
        end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
           UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)   then moveDir = moveDir - Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * (VD.FLY_Speed or 50) end
        if VD.FLY_Method == "Velocity" then
            FlyBodyVelocity.Velocity = moveDir
        else
            FlyBodyVelocity.Velocity = Vector3.zero
            if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + moveDir * 0.05 end
        end
        FlyBodyGyro.CFrame = cam.CFrame
    else
        if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity=nil end
        if FlyBodyGyro     then FlyBodyGyro:Destroy();     FlyBodyGyro=nil     end
        if hum then hum.PlatformStand = false end
    end
end

-- AIMBOT
local State = {AimTarget=nil,AimHolding=false,Unloaded=false}
local Aimbot = {}
function Aimbot.GetTargetPart(char)
    if not char then return nil end
    local n = VD.AIM_TargetPart or "Head"
    if n == "Head"  then return char:FindFirstChild("Head") end
    if n == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("HumanoidRootPart")
end
function Aimbot.GetClosestTarget(cam, screenCenter)
    if not cam or not VD.AIM_Enabled then return nil end
    local myRole = GetRole()
    if myRole == "Lobby" or myRole == "Unknown" then return nil end
    local closestPlayer, closestDist = nil, VD.AIM_FOV or 120
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Parent or not player.Character then continue end
        local shouldTarget = (myRole=="Survivor" and IsKiller(player)) or (myRole=="Killer" and IsSurvivor(player))
        if shouldTarget then
            local tp = Aimbot.GetTargetPart(player.Character)
            if tp then
                local passVis = true
                if VD.AIM_VisCheck then
                    pcall(function()
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Blacklist
                        params.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}
                        local dir = tp.Position - cam.CFrame.Position
                        local ray = workspace:Raycast(cam.CFrame.Position, dir.Unit*math.clamp(dir.Magnitude,1,5000), params)
                        passVis = (ray == nil)
                    end)
                end
                if passVis then
                    local sp = cam:WorldToViewportPoint(tp.Position)
                    if sp.Z > 0 then
                        local dist = (Vector2.new(sp.X,sp.Y) - screenCenter).Magnitude
                        if dist < closestDist then closestDist=dist; closestPlayer=player end
                    end
                end
            end
        end
    end
    return closestPlayer
end
function Aimbot.GetPredictedPosition(target, targetPart)
    if not target or not targetPart then return nil end
    local pos = targetPart.Position
    if VD.AIM_Predict then
        local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if root then pos = pos + (root.Velocity or Vector3.zero) * 0.08 end
    end
    return pos
end
function Aimbot.AimAt(cam, targetPos)
    if not cam or not targetPos then return end
    local smooth = math.clamp(VD.AIM_Smooth or 0.3, 0.02, 1)
    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), smooth)
end
function Aimbot.Update(cam, screenSize, screenCenter)
    if not VD.AIM_Enabled then State.AimTarget=nil; return end
    if not State.AimHolding then State.AimTarget=nil; return end
    local target = Aimbot.GetClosestTarget(cam, screenCenter)
    State.AimTarget = target
    if target and target.Character then
        local tp = Aimbot.GetTargetPart(target.Character)
        if tp then
            local pp = Aimbot.GetPredictedPosition(target, tp)
            if pp then Aimbot.AimAt(cam, pp) end
        end
    end
end

-- SPEAR AIMBOT
local function SpearAimbotCalc(targetPos)
    if not VD.SPEAR_Aimbot or GetRole() ~= "Killer" then return nil end
    local root = Root; if not root then return nil end
    local startPos = root.Position + Vector3.new(0,2,0)
    local distance = (targetPos - startPos).Magnitude
    local speed    = math.max(VD.SPEAR_Speed or 100, 1)
    local gravity  = VD.SPEAR_Gravity or 50
    local time     = distance / speed
    return targetPos + Vector3.new(0, 0.5 * gravity * time * time, 0)
end
local function UpdateSpearAim()
    if not VD.SPEAR_Aimbot or GetRole() ~= "Killer" then return end
    local root = Root; if not root then return end
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
            local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local d = (tRoot.Position - root.Position).Magnitude
                if d < closestDist then closestDist=d; closest=player end
            end
        end
    end
    if not closest or not closest.Character then return end
    local tRoot = closest.Character:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local aimPos = SpearAimbotCalc(tRoot.Position)
    if aimPos then
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos) end
    end
end

-- INPUT
UserInputService.InputBegan:Connect(function(input, _)
    if State.Unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and VD.AIM_Enabled and VD.AIM_UseRMB then
        State.AimHolding = true
    end
end)
UserInputService.InputEnded:Connect(function(input, _)
    if State.Unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and VD.AIM_Enabled and VD.AIM_UseRMB then
        State.AimHolding = false; State.AimTarget = nil
    end
end)

-- FOV CIRCLE
local FOVCircle = DrawingAvailable and SafeDrawing("Circle") or nil
if FOVCircle then
    FOVCircle.Thickness=1; FOVCircle.Color=Color3.fromRGB(220,70,70)
    FOVCircle.Filled=false; FOVCircle.NumSides=64
    FOVCircle.Transparency=0.8; FOVCircle.Visible=false
end

-- CHAMS
local Chams = {Objects={}}
function Chams.Create(target, colorData, label)
    if not target or not target:IsA("Instance") then return nil end
    local ex = target:FindFirstChild("_ViolenceChams"); if ex then ex:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.Name = "_ViolenceChams"; highlight.Adornee = target
    highlight.FillColor = colorData.fill; highlight.OutlineColor = colorData.outline
    highlight.FillTransparency = colorData.fillTrans or 0.5; highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = target
    local data = {highlight=highlight,target=target}
    if label then
        local rootPart = target:IsA("Model") and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")) or target
        if rootPart then
            local billboard = Instance.new("BillboardGui")
            billboard.Name="_ViolenceLabel"; billboard.Size=UDim2.new(0,80,0,18)
            billboard.AlwaysOnTop=true; billboard.StudsOffset=Vector3.new(0,3,0)
            billboard.Adornee=rootPart; billboard.Parent=target
            local textLabel = Instance.new("TextLabel")
            textLabel.Size=UDim2.new(1,0,1,0); textLabel.BackgroundTransparency=1
            textLabel.TextColor3=colorData.outline; textLabel.TextStrokeColor3=Color3.new(0,0,0)
            textLabel.TextStrokeTransparency=0.2; textLabel.Font=Enum.Font.Gotham
            textLabel.TextSize=10; textLabel.Text=label; textLabel.Parent=billboard
            data.billboard=billboard; data.textLabel=textLabel; data.rootPart=rootPart
        end
    end
    Chams.Objects[target] = data; return data
end
function Chams.Update(target, newLabel, newDist)
    local data = Chams.Objects[target]; if not data then return end
    if data.textLabel and newLabel then
        data.textLabel.Text = VD.ShowDistance and (newLabel.."\n"..math.floor(newDist or 0).."m") or newLabel
    end
end
function Chams.SetColor(target, colorData)
    local data = Chams.Objects[target]; if not data or not data.highlight then return end
    data.highlight.FillColor=colorData.fill; data.highlight.OutlineColor=colorData.outline
    data.highlight.FillTransparency=colorData.fillTrans or 0.5
    if data.textLabel then data.textLabel.TextColor3=colorData.outline end
end
function Chams.Remove(target)
    local data = Chams.Objects[target]
    if data then
        if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
        Chams.Objects[target] = nil
    end
    if target then
        local ex = target:FindFirstChild("_ViolenceChams"); if ex then ex:Destroy() end
        local el = target:FindFirstChild("_ViolenceLabel"); if el then el:Destroy() end
    end
end
function Chams.ClearAll()
    for target,_ in pairs(Chams.Objects) do Chams.Remove(target) end
    Chams.Objects = {}
end

-- DRAWING ESP
local DrawingESP = {cache={},objectCache={},velocityData={}}
local function DrawingESP_create()
    local skel = {}
    for i = 1, 14 do
        skel[i] = SafeDrawing("Line")
        if skel[i] then skel[i].Thickness=1; skel[i].Visible=false end
    end
    local box = {}
    for i = 1, 4 do
        box[i] = SafeDrawing("Line")
        if box[i] then box[i].Thickness=1; box[i].Visible=false end
    end
    return {
        Box=box, Name=SafeDrawing("Text"), Dist=SafeDrawing("Text"), Skel=skel,
        HealthBg=SafeDrawing("Square"), HealthBar=SafeDrawing("Square"),
        Offscreen=SafeDrawing("Triangle"), VelLine=SafeDrawing("Line"), VelArrow=SafeDrawing("Triangle")
    }
end
local function DrawingESP_setup(esp)
    if not esp then return end
    for _, l in ipairs(esp.Box) do if l then l.Thickness=1; l.Visible=false end end
    if esp.Name then
        esp.Name.Size=14; esp.Name.Font=DrawFont
        esp.Name.Center=true; esp.Name.Outline=true; esp.Name.Visible=false
    end
    if esp.Dist then
        esp.Dist.Size=12; esp.Dist.Font=DrawFont
        esp.Dist.Center=true; esp.Dist.Outline=true
        esp.Dist.Color=Color3.fromRGB(180,180,180); esp.Dist.Visible=false
    end
    for _, l in ipairs(esp.Skel) do if l then l.Thickness=1; l.Visible=false end end
    if esp.HealthBg  then esp.HealthBg.Filled=true;  esp.HealthBg.Color=Color3.fromRGB(25,25,25); esp.HealthBg.Visible=false end
    if esp.HealthBar then esp.HealthBar.Filled=true;  esp.HealthBar.Visible=false end
    if esp.Offscreen then esp.Offscreen.Filled=true;  esp.Offscreen.Visible=false end
    if esp.VelLine   then esp.VelLine.Thickness=2;    esp.VelLine.Color=Color3.fromRGB(0,255,255); esp.VelLine.Visible=false end
    if esp.VelArrow  then esp.VelArrow.Filled=true;   esp.VelArrow.Color=Color3.fromRGB(0,255,255); esp.VelArrow.Visible=false end
end

local Bones_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local Bones_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function DrawingESP_cleanup()
    local validPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do validPlayers[p] = true end
    for player, esp in pairs(DrawingESP.cache) do
        if not validPlayers[player] then
            if esp then
                pcall(function()
                    for _, l in ipairs(esp.Box) do if l then SafeRemove(l) end end
                    if esp.Name then SafeRemove(esp.Name) end
                    if esp.Dist then SafeRemove(esp.Dist) end
                    for _, l in ipairs(esp.Skel) do if l then SafeRemove(l) end end
                    if esp.HealthBg then SafeRemove(esp.HealthBg) end
                    if esp.HealthBar then SafeRemove(esp.HealthBar) end
                    if esp.Offscreen then SafeRemove(esp.Offscreen) end
                    if esp.VelLine then SafeRemove(esp.VelLine) end
                    if esp.VelArrow then SafeRemove(esp.VelArrow) end
                end)
            end
            DrawingESP.cache[player] = nil
            DrawingESP.velocityData[player] = nil
        end
    end
end

local function DrawingESP_render(esp, player, char, cam, screenSize, screenCenter)
    if not esp or not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not head then
        for _, l in ipairs(esp.Box) do if l then l.Visible = false end end
        if esp.Name then esp.Name.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
        if esp.HealthBg then esp.HealthBg.Visible = false end
        if esp.HealthBar then esp.HealthBar.Visible = false end
        if esp.VelLine then esp.VelLine.Visible = false end
        if esp.VelArrow then esp.VelArrow.Visible = false end
        return
    end

    local myRoot = Root
    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
    if dist > VD.MaxDistance then
        for _, l in ipairs(esp.Box) do if l then l.Visible = false end end
        if esp.Name then esp.Name.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
        if esp.HealthBg then esp.HealthBg.Visible = false end
        if esp.HealthBar then esp.HealthBar.Visible = false end
        if esp.VelLine then esp.VelLine.Visible = false end
        if esp.VelArrow then esp.VelArrow.Visible = false end
        return
    end

    local isKillerPlayer = IsKiller(player)
    local visible = true
    if VD.AIM_VisCheck or VD.AIM_Enabled then
        local camPos = cam.CFrame.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {cam, LocalPlayer.Character, char}
        local ray = workspace:Raycast(camPos, head.Position - camPos, params)
        visible = (ray == nil)
    end

    local col = isKillerPlayer and (visible and Color3.fromRGB(255,120,120) or Color3.fromRGB(255,65,65)) or (visible and Color3.fromRGB(120,255,170) or Color3.fromRGB(65,220,130))
    local skelCol = visible and Color3.fromRGB(150,255,150) or Color3.fromRGB(255,255,255)

    local headPos = head.Position + Vector3.new(0,0.5,0)
    local feetPos = root.Position - Vector3.new(0,3,0)

    local rs = cam:WorldToViewportPoint(root.Position)
    local hs = cam:WorldToViewportPoint(headPos)
    local fs = cam:WorldToViewportPoint(feetPos)

    local onScreen = rs.Z > 0 and rs.X > 0 and rs.X < screenSize.X and rs.Y > 0 and rs.Y < screenSize.Y

    if not onScreen then
        for _, l in ipairs(esp.Box) do if l then l.Visible = false end end
        if esp.Name then esp.Name.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
        if esp.HealthBg then esp.HealthBg.Visible = false end
        if esp.HealthBar then esp.HealthBar.Visible = false end
        if esp.VelLine then esp.VelLine.Visible = false end
        if esp.VelArrow then esp.VelArrow.Visible = false end

        if VD.ESP_Offscreen then
            local dx = rs.X - screenCenter.X
            local dy = rs.Y - screenCenter.Y
            local angle = math.atan2(dy, dx)
            local edge = 50
            local arrowX = math.clamp(screenCenter.X + math.cos(angle) * (screenSize.X/2 - edge), edge, screenSize.X - edge)
            local arrowY = math.clamp(screenCenter.Y + math.sin(angle) * (screenSize.Y/2 - edge), edge, screenSize.Y - edge)
            local fwd = Vector2.new(math.cos(angle), math.sin(angle))
            local right = Vector2.new(-fwd.Y, fwd.X)
            local pos = Vector2.new(arrowX, arrowY)
            local arrowSize = 12
            if esp.Offscreen then
                esp.Offscreen.PointA = pos + fwd * arrowSize
                esp.Offscreen.PointB = pos - fwd * arrowSize/2 - right * arrowSize/2
                esp.Offscreen.PointC = pos - fwd * arrowSize/2 + right * arrowSize/2
                esp.Offscreen.Color = col
                esp.Offscreen.Visible = true
            end
        else
            if esp.Offscreen then esp.Offscreen.Visible = false end
        end
        return
    end

    if esp.Offscreen then esp.Offscreen.Visible = false end

    local boxTop = hs.Y
    local boxBottom = fs.Y
    local boxHeight = math.abs(boxBottom - boxTop)
    local boxWidth = boxHeight * 0.6
    local cx = rs.X

    -- box
    if esp.Box[1] then esp.Box[1].From = Vector2.new(cx - boxWidth/2, boxTop); esp.Box[1].To = Vector2.new(cx + boxWidth/2, boxTop); esp.Box[1].Color = col; esp.Box[1].Visible = true end
    if esp.Box[2] then esp.Box[2].From = Vector2.new(cx + boxWidth/2, boxTop); esp.Box[2].To = Vector2.new(cx + boxWidth/2, boxBottom); esp.Box[2].Color = col; esp.Box[2].Visible = true end
    if esp.Box[3] then esp.Box[3].From = Vector2.new(cx + boxWidth/2, boxBottom); esp.Box[3].To = Vector2.new(cx - boxWidth/2, boxBottom); esp.Box[3].Color = col; esp.Box[3].Visible = true end
    if esp.Box[4] then esp.Box[4].From = Vector2.new(cx - boxWidth/2, boxBottom); esp.Box[4].To = Vector2.new(cx - boxWidth/2, boxTop); esp.Box[4].Color = col; esp.Box[4].Visible = true end

    -- name
    if esp.Name then
        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(cx, boxTop - 18)
        esp.Name.Color = col
        esp.Name.Visible = true
    end

    -- distance
    if esp.Dist then
        esp.Dist.Text = math.floor(dist) .. "m"
        esp.Dist.Position = Vector2.new(cx, boxBottom + 4)
        esp.Dist.Visible = true
    end

    -- skeleton
    if VD.ESP_Skeleton and hum then
        local bones = (char:FindFirstChild("Torso") and Bones_R6) or Bones_R15
        for i, b in ipairs(bones) do
            if esp.Skel[i] then
                local p1 = char:FindFirstChild(b[1])
                local p2 = char:FindFirstChild(b[2])
                if p1 and p2 then
                    local s1 = cam:WorldToViewportPoint(p1.Position)
                    local s2 = cam:WorldToViewportPoint(p2.Position)
                    if s1.Z > 0 and s2.Z > 0 then
                        esp.Skel[i].From = Vector2.new(s1.X, s1.Y)
                        esp.Skel[i].To = Vector2.new(s2.X, s2.Y)
                        esp.Skel[i].Color = skelCol
                        esp.Skel[i].Visible = true
                    else
                        esp.Skel[i].Visible = false
                    end
                else
                    esp.Skel[i].Visible = false
                end
            end
        end
    else
        for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
    end

    -- velocity
    local vd = DrawingESP.velocityData[player]
    if not vd then
        vd = {pos = root.Position, vel = Vector3.zero, time = tick()}
        DrawingESP.velocityData[player] = vd
    end
    local now = tick()
    local dt = now - vd.time
    if dt > 0.03 then
        local rawVel = (root.Position - vd.pos) / dt
        vd.vel = vd.vel * 0.7 + rawVel * 0.3
        vd.pos = root.Position
        vd.time = now
    end

    if VD.ESP_Velocity then
        local velFlat = Vector3.new(vd.vel.X, 0, vd.vel.Z)
        local velMag = velFlat.Magnitude
        if velMag > 2 then
            local futurePos = root.Position + velFlat.Unit * math.clamp(velMag * 0.4, 5, 20)
            local futureScreen = cam:WorldToViewportPoint(futurePos)
            if futureScreen.Z > 0 then
                if esp.VelLine then esp.VelLine.From = Vector2.new(rs.X, rs.Y); esp.VelLine.To = Vector2.new(futureScreen.X, futureScreen.Y); esp.VelLine.Visible = true end
                local dx, dy = futureScreen.X - rs.X, futureScreen.Y - rs.Y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 5 and esp.VelArrow then
                    local fx, fy = dx/len, dy/len
                    esp.VelArrow.PointA = Vector2.new(futureScreen.X, futureScreen.Y)
                    esp.VelArrow.PointB = Vector2.new(futureScreen.X - fx*10 + fy*5, futureScreen.Y - fy*10 - fx*5)
                    esp.VelArrow.PointC = Vector2.new(futureScreen.X - fx*10 - fy*5, futureScreen.Y - fy*10 + fx*5)
                    esp.VelArrow.Visible = true
                else
                    if esp.VelArrow then esp.VelArrow.Visible = false end
                end
            else
                if esp.VelLine then esp.VelLine.Visible = false end
                if esp.VelArrow then esp.VelArrow.Visible = false end
            end
        else
            if esp.VelLine then esp.VelLine.Visible = false end
            if esp.VelArrow then esp.VelArrow.Visible = false end
        end
    else
        if esp.VelLine then esp.VelLine.Visible = false end
        if esp.VelArrow then esp.VelArrow.Visible = false end
    end
end

local function DrawingESP_renderObject(esp, pos, label, color, cam)
    if not esp or not pos then return end
    local myRoot = Root
    local dist = myRoot and (pos - myRoot.Position).Magnitude or 0
    if dist > VD.MaxDistance then
        for _, l in ipairs(esp.Box) do if l then l.Visible = false end end
        if esp.Label then esp.Label.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        return
    end
    local screen = cam:WorldToViewportPoint(pos)
    if screen.Z <= 0 then
        for _, l in ipairs(esp.Box) do if l then l.Visible = false end end
        if esp.Label then esp.Label.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        return
    end
    local size = math.clamp(800 / screen.Z, 16, 60)
    if esp.Box[1] then esp.Box[1].From = Vector2.new(screen.X - size/2, screen.Y - size/2); esp.Box[1].To = Vector2.new(screen.X + size/2, screen.Y - size/2); esp.Box[1].Color = color; esp.Box[1].Visible = true end
    if esp.Box[2] then esp.Box[2].From = Vector2.new(screen.X + size/2, screen.Y - size/2); esp.Box[2].To = Vector2.new(screen.X + size/2, screen.Y + size/2); esp.Box[2].Color = color; esp.Box[2].Visible = true end
    if esp.Box[3] then esp.Box[3].From = Vector2.new(screen.X + size/2, screen.Y + size/2); esp.Box[3].To = Vector2.new(screen.X - size/2, screen.Y + size/2); esp.Box[3].Color = color; esp.Box[3].Visible = true end
    if esp.Box[4] then esp.Box[4].From = Vector2.new(screen.X - size/2, screen.Y + size/2); esp.Box[4].To = Vector2.new(screen.X - size/2, screen.Y - size/2); esp.Box[4].Color = color; esp.Box[4].Visible = true end
    if esp.Label then esp.Label.Text = label; esp.Label.Position = Vector2.new(screen.X, screen.Y - size/2 - 14); esp.Label.Color = color; esp.Label.Visible = true end
    if esp.Dist then esp.Dist.Text = math.floor(dist) .. "m"; esp.Dist.Position = Vector2.new(screen.X, screen.Y + size/2 + 2); esp.Dist.Visible = true end
end

-- RADAR
local Radar = {
    bg = DrawingAvailable and SafeDrawing("Square") or nil,
    circleBg = DrawingAvailable and SafeDrawing("Circle") or nil,
    border = DrawingAvailable and SafeDrawing("Square") or nil,
    circleBorder = DrawingAvailable and SafeDrawing("Circle") or nil,
    cross1 = DrawingAvailable and SafeDrawing("Line") or nil,
    cross2 = DrawingAvailable and SafeDrawing("Line") or nil,
    center = DrawingAvailable and SafeDrawing("Triangle") or nil,
    dots = {},
    objectDots = {},
    palletSquares = {}
}
if DrawingAvailable then
    if Radar.bg then Radar.bg.Filled = true; Radar.bg.Color = Color3.fromRGB(20,20,20); Radar.bg.Transparency = 0.8 end
    if Radar.circleBg then Radar.circleBg.Filled = true; Radar.circleBg.Color = Color3.fromRGB(20,20,20); Radar.circleBg.Transparency = 0.8; Radar.circleBg.NumSides = 64 end
    if Radar.border then Radar.border.Filled = false; Radar.border.Color = Color3.fromRGB(255,65,65); Radar.border.Thickness = 2 end
    if Radar.circleBorder then Radar.circleBorder.Filled = false; Radar.circleBorder.Color = Color3.fromRGB(255,65,65); Radar.circleBorder.Thickness = 2; Radar.circleBorder.NumSides = 64 end
    if Radar.cross1 then Radar.cross1.Color = Color3.fromRGB(40,40,40); Radar.cross1.Thickness = 1 end
    if Radar.cross2 then Radar.cross2.Color = Color3.fromRGB(40,40,40); Radar.cross2.Thickness = 1 end
    if Radar.center then Radar.center.Filled = true; Radar.center.Color = Color3.fromRGB(0,255,0) end
    for i = 1, 100 do
        local d = SafeDrawing("Triangle")
        if d then d.Filled = true; d.Visible = false end
        table.insert(Radar.dots, d)
    end
    for i = 1, 100 do
        local d = SafeDrawing("Circle")
        if d then d.Filled = true; d.Visible = false; d.NumSides = 16 end
        table.insert(Radar.objectDots, d)
    end
    for i = 1, 100 do
        local d = SafeDrawing("Square")
        if d then d.Filled = true; d.Visible = false end
        table.insert(Radar.palletSquares, d)
    end
end

local function Radar_hideAll()
    if not DrawingAvailable then return end
    if Radar.bg then Radar.bg.Visible = false end
    if Radar.circleBg then Radar.circleBg.Visible = false end
    if Radar.border then Radar.border.Visible = false end
    if Radar.circleBorder then Radar.circleBorder.Visible = false end
    if Radar.center then Radar.center.Visible = false end
    if Radar.cross1 then Radar.cross1.Visible = false end
    if Radar.cross2 then Radar.cross2.Visible = false end
    for _, d in pairs(Radar.dots) do if d then d.Visible = false end end
    for _, d in pairs(Radar.objectDots) do if d then d.Visible = false end end
    for _, d in pairs(Radar.palletSquares) do if d then d.Visible = false end end
end

local function Radar_step(cam)
    if not DrawingAvailable then return end
    if not VD.RADAR_Enabled then Radar_hideAll(); return end

    local size = VD.RADAR_Size
    local pos = Vector2.new(cam.ViewportSize.X - size - 20, 20)
    local center = pos + Vector2.new(size/2, size/2)

    if VD.RADAR_Circle then
        if Radar.bg then Radar.bg.Visible = false end
        if Radar.border then Radar.border.Visible = false end
        if Radar.circleBg then Radar.circleBg.Position = center; Radar.circleBg.Radius = size/2; Radar.circleBg.Visible = true end
        if Radar.circleBorder then Radar.circleBorder.Position = center; Radar.circleBorder.Radius = size/2; Radar.circleBorder.Visible = true end
    else
        if Radar.circleBg then Radar.circleBg.Visible = false end
        if Radar.circleBorder then Radar.circleBorder.Visible = false end
        if Radar.bg then Radar.bg.Position = pos; Radar.bg.Size = Vector2.new(size, size); Radar.bg.Visible = true end
        if Radar.border then Radar.border.Position = pos; Radar.border.Size = Vector2.new(size, size); Radar.border.Visible = true end
    end

    if Radar.cross1 then Radar.cross1.From = Vector2.new(center.X, pos.Y + 10); Radar.cross1.To = Vector2.new(center.X, pos.Y + size - 10); Radar.cross1.Visible = true end
    if Radar.cross2 then Radar.cross2.From = Vector2.new(pos.X + 10, center.Y); Radar.cross2.To = Vector2.new(pos.X + size - 10, center.Y); Radar.cross2.Visible = true end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myLook = cam.CFrame.LookVector
    if not myRoot then
        if Radar.center then Radar.center.Visible = false end
        for _, d in pairs(Radar.dots) do if d then d.Visible = false end end
        for _, d in pairs(Radar.objectDots) do if d then d.Visible = false end end
        for _, d in pairs(Radar.palletSquares) do if d then d.Visible = false end end
        return
    end

    local myAngle = math.atan2(-myLook.X, -myLook.Z)
    local cosA, sinA = math.cos(myAngle), math.sin(myAngle)
    local scale = (size/2 - 10) / 150
    local idx = 1
    local objIdx = 1
    local palletIdx = 1

    if VD.RADAR_Killer then
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if idx > #Radar.dots then break end
            if not IsKiller(player) then continue end
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local rx, rz = root.Position.X - myRoot.Position.X, root.Position.Z - myRoot.Position.Z
                    local dist2D = math.sqrt(rx^2 + rz^2)
                    if dist2D < 150 then
                        local rotX = rx * cosA - rz * sinA
                        local rotZ = rx * sinA + rz * cosA
                        local radarX, radarY = rotX * scale, rotZ * scale
                        local maxD = size/2 - 8
                        local rDist = math.sqrt(radarX^2 + radarY^2)
                        if rDist > maxD then
                            radarX, radarY = radarX/rDist*maxD, radarY/rDist*maxD
                        end
                        local dotPos = center + Vector2.new(radarX, radarY)
                        local dot = Radar.dots[idx]
                        if dot then
                            local head = char:FindFirstChild("Head")
                            local eAngle = head and math.atan2(-head.CFrame.LookVector.X, -head.CFrame.LookVector.Z) - myAngle or 0
                            local eFwd = Vector2.new(-math.sin(eAngle), -math.cos(eAngle))
                            local eRight = Vector2.new(-eFwd.Y, eFwd.X)
                            dot.PointA = dotPos + eFwd * 5
                            dot.PointB = dotPos - eFwd * 2.5 + eRight * 2.5
                            dot.PointC = dotPos - eFwd * 2.5 - eRight * 2.5
                            dot.Color = Color3.fromRGB(255,65,65)
                            dot.Visible = true
                        end
                        idx = idx + 1
                    end
                end
            end
        end
    end

    if VD.RADAR_Survivor then
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if idx > #Radar.dots then break end
            if not IsSurvivor(player) then continue end
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local rx, rz = root.Position.X - myRoot.Position.X, root.Position.Z - myRoot.Position.Z
                    local dist2D = math.sqrt(rx^2 + rz^2)
                    if dist2D < 150 then
                        local rotX = rx * cosA - rz * sinA
                        local rotZ = rx * sinA + rz * cosA
                        local radarX, radarY = rotX * scale, rotZ * scale
                        local maxD = size/2 - 8
                        local rDist = math.sqrt(radarX^2 + radarY^2)
                        if rDist > maxD then
                            radarX, radarY = radarX/rDist*maxD, radarY/rDist*maxD
                        end
                        local dotPos = center + Vector2.new(radarX, radarY)
                        local dot = Radar.dots[idx]
                        if dot then
                            local head = char:FindFirstChild("Head")
                            local eAngle = head and math.atan2(-head.CFrame.LookVector.X, -head.CFrame.LookVector.Z) - myAngle or 0
                            local eFwd = Vector2.new(-math.sin(eAngle), -math.cos(eAngle))
                            local eRight = Vector2.new(-eFwd.Y, eFwd.X)
                            dot.PointA = dotPos + eFwd * 5
                            dot.PointB = dotPos - eFwd * 2.5 + eRight * 2.5
                            dot.PointC = dotPos - eFwd * 2.5 - eRight * 2.5
                            dot.Color = Color3.fromRGB(65,220,130)
                            dot.Visible = true
                        end
                        idx = idx + 1
                    end
                end
            end
        end
    end

    -- objects
    if VD.RADAR_Generator then
        for _, gen in ipairs(NEX_Cache.Generators) do
            if objIdx > #Radar.objectDots then break end
            if gen.part and gen.part.Parent then
                local rx, rz = gen.part.Position.X - myRoot.Position.X, gen.part.Position.Z - myRoot.Position.Z
                local dist2D = math.sqrt(rx^2 + rz^2)
                if dist2D < 150 then
                    local rotX = rx * cosA - rz * sinA
                    local rotZ = rx * sinA + rz * cosA
                    local radarX, radarY = rotX * scale, rotZ * scale
                    local maxD = size/2 - 8
                    local rDist = math.sqrt(radarX^2 + radarY^2)
                    if rDist > maxD then
                        radarX, radarY = radarX/rDist*maxD, radarY/rDist*maxD
                    end
                    local dotPos = center + Vector2.new(radarX, radarY)
                    local dot = Radar.objectDots[objIdx]
                    if dot then
                        dot.Position = dotPos
                        dot.Radius = 3
                        dot.Color = Color3.fromRGB(255,180,50)
                        dot.Visible = true
                    end
                    objIdx = objIdx + 1
                end
            end
        end
    end

    if VD.RADAR_Pallet then
        for _, pallet in ipairs(NEX_Cache.Pallets) do
            if palletIdx > #Radar.palletSquares then break end
            if pallet.part and pallet.part.Parent then
                local rx, rz = pallet.part.Position.X - myRoot.Position.X, pallet.part.Position.Z - myRoot.Position.Z
                local dist2D = math.sqrt(rx^2 + rz^2)
                if dist2D < 150 then
                    local rotX = rx * cosA - rz * sinA
                    local rotZ = rx * sinA + rz * cosA
                    local radarX, radarY = rotX * scale, rotZ * scale
                    local maxD = size/2 - 8
                    local rDist = math.sqrt(radarX^2 + radarY^2)
                    if rDist > maxD then
                        radarX, radarY = radarX/rDist*maxD, radarY/rDist*maxD
                    end
                    local dotPos = center + Vector2.new(radarX, radarY)
                    local square = Radar.palletSquares[palletIdx]
                    if square then
                        local squareSize = 5
                        square.Position = dotPos - Vector2.new(squareSize/2, squareSize/2)
                        square.Size = Vector2.new(squareSize, squareSize)
                        square.Color = Color3.fromRGB(220,180,100)
                        square.Visible = true
                    end
                    palletIdx = palletIdx + 1
                end
            end
        end
    end

    for i = idx, #Radar.dots do if Radar.dots[i] then Radar.dots[i].Visible = false end end
    for i = objIdx, #Radar.objectDots do if Radar.objectDots[i] then Radar.objectDots[i].Visible = false end end
    for i = palletIdx, #Radar.palletSquares do if Radar.palletSquares[i] then Radar.palletSquares[i].Visible = false end end

    if Radar.center then
        Radar.center.PointA = center + Vector2.new(0, -8)
        Radar.center.PointB = center + Vector2.new(-4, 4)
        Radar.center.PointC = center + Vector2.new(4, 4)
        Radar.center.Visible = true
    end
end

-- RENDER STEP (Drawing ESP, Radar, Aimbot, Camera)
local function OnRenderStep()
    if VD.Destroyed then
        if DrawingAvailable then
            for _, esp in pairs(DrawingESP.cache) do
                if esp then
                    for _, l in ipairs(esp.Box) do if l then SafeRemove(l) end end
                    if esp.Name then SafeRemove(esp.Name) end
                    if esp.Dist then SafeRemove(esp.Dist) end
                    for _, l in ipairs(esp.Skel) do if l then SafeRemove(l) end end
                    if esp.HealthBg then SafeRemove(esp.HealthBg) end
                    if esp.HealthBar then SafeRemove(esp.HealthBar) end
                    if esp.Offscreen then SafeRemove(esp.Offscreen) end
                    if esp.VelLine then SafeRemove(esp.VelLine) end
                    if esp.VelArrow then SafeRemove(esp.VelArrow) end
                end
            end
            DrawingESP.cache = {}
            Chams.ClearAll()
            Radar_hideAll()
            if FOVCircle then SafeRemove(FOVCircle) end
        end
        return
    end

    Camera = Workspace.CurrentCamera or Camera
    local cam = Camera
    if not cam then return end
    local screenSize = cam.ViewportSize
    local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

    -- Drawing ESP & RADAR
    if DrawingAvailable then
        if VD.DRAWING_ESP then
            DrawingESP_cleanup()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if not DrawingESP.cache[player] then
                        DrawingESP.cache[player] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.cache[player])
                    end
                    DrawingESP_render(DrawingESP.cache[player], player, player.Character, cam, screenSize, screenCenter)
                end
            end

            -- Objects
            for _, obj in ipairs(NEX_Cache.Generators) do
                local target = obj.model or obj.part
                if VD.ESP_ObjectChams then
                    if not Chams.Objects[target] then
                        Chams.Create(target, {fill = Color3.fromRGB(200,140,30), outline = Color3.fromRGB(255,200,80), fillTrans = 0.5}, "GEN")
                    else
                        Chams.SetColor(target, {fill = Color3.fromRGB(200,140,30), outline = Color3.fromRGB(255,200,80), fillTrans = 0.5})
                    end
                    Chams.Update(target, "GEN", (Root and (obj.part.Position - Root.Position).Magnitude) or 0)
                else
                    local key = tostring(target)
                    if not DrawingESP.objectCache[key] then
                        DrawingESP.objectCache[key] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.objectCache[key])
                    end
                    DrawingESP_renderObject(DrawingESP.objectCache[key], obj.part.Position, "GEN", Color3.fromRGB(255,180,50), cam)
                    Chams.Remove(target)
                end
            end
            for _, obj in ipairs(NEX_Cache.Gates) do
                local target = obj.model or obj.part
                if VD.ESP_ObjectChams then
                    if not Chams.Objects[target] then
                        Chams.Create(target, {fill = Color3.fromRGB(150,150,170), outline = Color3.fromRGB(220,220,255), fillTrans = 0.5}, "GATE")
                    else
                        Chams.SetColor(target, {fill = Color3.fromRGB(150,150,170), outline = Color3.fromRGB(220,220,255), fillTrans = 0.5})
                    end
                    Chams.Update(target, "GATE", (Root and (obj.part.Position - Root.Position).Magnitude) or 0)
                else
                    local key = tostring(target)
                    if not DrawingESP.objectCache[key] then
                        DrawingESP.objectCache[key] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.objectCache[key])
                    end
                    DrawingESP_renderObject(DrawingESP.objectCache[key], obj.part.Position, "GATE", Color3.fromRGB(200,200,220), cam)
                    Chams.Remove(target)
                end
            end
            for _, obj in ipairs(NEX_Cache.Hooks) do
                local target = obj.model or obj.part
                local isClosest = VD.ESP_ClosestHook and obj == NEX_Cache.ClosestHook
                local useColor = isClosest and Color3.fromRGB(255,230,80) or Color3.fromRGB(255,100,100)
                local useChams = isClosest and {fill = Color3.fromRGB(200,180,40), outline = Color3.fromRGB(255,240,100), fillTrans = 0.4} or {fill = Color3.fromRGB(180,60,60), outline = Color3.fromRGB(255,100,100), fillTrans = 0.5}
                local useLabel = isClosest and "HOOK!" or "HOOK"
                if VD.ESP_ObjectChams then
                    if not Chams.Objects[target] then
                        Chams.Create(target, useChams, useLabel)
                    else
                        Chams.SetColor(target, useChams)
                    end
                    Chams.Update(target, useLabel, (Root and (obj.part.Position - Root.Position).Magnitude) or 0)
                else
                    local key = tostring(target)
                    if not DrawingESP.objectCache[key] then
                        DrawingESP.objectCache[key] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.objectCache[key])
                    end
                    DrawingESP_renderObject(DrawingESP.objectCache[key], obj.part.Position, useLabel, useColor, cam)
                    Chams.Remove(target)
                end
            end
            for _, obj in ipairs(NEX_Cache.Pallets) do
                local target = obj.model or obj.part
                if VD.ESP_ObjectChams then
                    if not Chams.Objects[target] then
                        Chams.Create(target, {fill = Color3.fromRGB(180,140,70), outline = Color3.fromRGB(255,210,130), fillTrans = 0.5}, "PALLET")
                    else
                        Chams.SetColor(target, {fill = Color3.fromRGB(180,140,70), outline = Color3.fromRGB(255,210,130), fillTrans = 0.5})
                    end
                    Chams.Update(target, "PALLET", (Root and (obj.part.Position - Root.Position).Magnitude) or 0)
                else
                    local key = tostring(target)
                    if not DrawingESP.objectCache[key] then
                        DrawingESP.objectCache[key] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.objectCache[key])
                    end
                    DrawingESP_renderObject(DrawingESP.objectCache[key], obj.part.Position, "PALLET", Color3.fromRGB(220,180,100), cam)
                    Chams.Remove(target)
                end
            end
            for _, obj in ipairs(NEX_Cache.Windows) do
                local target = obj.model or obj.part
                if VD.ESP_ObjectChams then
                    if not Chams.Objects[target] then
                        Chams.Create(target, {fill = Color3.fromRGB(60,140,200), outline = Color3.fromRGB(120,200,255), fillTrans = 0.5}, "WINDOW")
                    else
                        Chams.SetColor(target, {fill = Color3.fromRGB(60,140,200), outline = Color3.fromRGB(120,200,255), fillTrans = 0.5})
                    end
                    Chams.Update(target, "WINDOW", (Root and (obj.part.Position - Root.Position).Magnitude) or 0)
                else
                    local key = tostring(target)
                    if not DrawingESP.objectCache[key] then
                        DrawingESP.objectCache[key] = DrawingESP_create()
                        DrawingESP_setup(DrawingESP.objectCache[key])
                    end
                    DrawingESP_renderObject(DrawingESP.objectCache[key], obj.part.Position, "WINDOW", Color3.fromRGB(100,180,255), cam)
                    Chams.Remove(target)
                end
            end
        else
            for _, esp in pairs(DrawingESP.cache) do
                if esp then
                    for _, l in ipairs(esp.Box) do if l then SafeRemove(l) end end
                    if esp.Name then SafeRemove(esp.Name) end
                    if esp.Dist then SafeRemove(esp.Dist) end
                    for _, l in ipairs(esp.Skel) do if l then SafeRemove(l) end end
                    if esp.HealthBg then SafeRemove(esp.HealthBg) end
                    if esp.HealthBar then SafeRemove(esp.HealthBar) end
                    if esp.Offscreen then SafeRemove(esp.Offscreen) end
                    if esp.VelLine then SafeRemove(esp.VelLine) end
                    if esp.VelArrow then SafeRemove(esp.VelArrow) end
                end
            end
            DrawingESP.cache = {}
            DrawingESP.objectCache = {}
            Chams.ClearAll()
            Radar_hideAll()
        end
        if DrawingAvailable then Radar_step(cam) end
    else
        Chams.ClearAll()
        if DrawingAvailable then Radar_hideAll() end
    end

    -- Aimbot
    pcall(function()
        if VD.AIM_Enabled then
            if (VD.AIM_UseRMB and State.AimHolding) or (not VD.AIM_UseRMB) then
                Aimbot.Update(cam, screenSize, screenCenter)
            end
        end
    end)

    pcall(UpdateSpearAim)
    UpdateCameraFOV()
    UpdateThirdPerson()
    UpdateShiftLock()

    if FOVCircle and DrawingAvailable then
        if VD.AIM_Enabled and VD.AIM_ShowFOV then
            FOVCircle.Position = screenCenter
            FOVCircle.Radius = VD.AIM_FOV or 120
            FOVCircle.Color = (State.AimTarget and Color3.fromRGB(90,220,120)) or Color3.fromRGB(220,70,70)
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end
end

if DrawingAvailable then
    RunService.RenderStepped:Connect(OnRenderStep)
else
    RunService.Heartbeat:Connect(function()
        if VD.Destroyed then return end
        local cam = workspace.CurrentCamera
        if cam then
            UpdateCameraFOV()
            UpdateThirdPerson()
            UpdateShiftLock()
            if VD.AIM_Enabled then
                if (VD.AIM_UseRMB and State.AimHolding) or (not VD.AIM_UseRMB) then
                    Aimbot.Update(cam, cam.ViewportSize, Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2))
                end
            end
        end
    end)
end

-- MAIN AUTO LOOP
task.spawn(function()
    while not VD.Destroyed do
        pcall(NEX_AutoAttack); pcall(NEX_AutoParry); pcall(NEX_AutoWiggle)
        pcall(NEX_UpdateHitboxes); pcall(NEX_DestroyAllPallets); pcall(NEX_FullGenBreak)
        pcall(NEX_DoubleTap); pcall(NEX_InfiniteLunge); pcall(NEX_TeleportAway)
        pcall(NEX_LeaveGenerator); pcall(NEX_BeatGameSurvivor); pcall(NEX_BeatGameKiller)
        pcall(NEX_AutoHook); pcall(UpdateNoFall); pcall(UpdateNoSlowdown); pcall(UpdateFly)
        task.wait(0.12)
    end
end)

-- UI SETUP (WindUI)
local Main = Window:Section({Title="Violence District"})
local PlayerTab = Main:Tab({Title="Player"})
local ESPTab = Main:Tab({Title="ESP"})
local MapTab = Main:Tab({Title="Map"})
local AimTab = Main:Tab({Title="Aim"})
local FOVTab = Main:Tab({Title="FOV"})
local SurvivorTab = Main:Tab({Title="Survivor"})
local KillerTab = Main:Tab({Title="Killer"})
local GeneratorTab = Main:Tab({Title="Generator"})
local FlingTab = Main:Tab({Title="Fling Feature"})
local ResetTab = Main:Tab({Title="Reset"})

-- PLAYER (movement)
PlayerTab:Toggle({ Title="Speed Hack", Callback=function(v) VD.Speed = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end) end
end})
PlayerTab:Slider({ Title="Speed Value", Value={Min=16,Max=200,Default=16}, Callback=function(v) VD.SpeedValue = v end})
PlayerTab:Toggle({ Title="Jump Hack", Callback=function(v) VD.Jump = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50 end) end
end})
PlayerTab:Slider({ Title="Jump Power", Value={Min=50,Max=300,Default=50}, Callback=function(v) VD.JumpValue = v end})
PlayerTab:Toggle({ Title="Infinite Jump", Callback=function(v) VD.InfiniteJump = v end})
PlayerTab:Toggle({ Title="Noclip", Callback=function(v) VD.Noclip = v end})
PlayerTab:Button({ Title="TP to Gen", Callback=function() pcall(function() NEX_TeleportToGenerator(1) end) end})
PlayerTab:Button({ Title="TP to Gate", Callback=function() pcall(NEX_TeleportToGate) end})
PlayerTab:Button({ Title="TP to Hook", Callback=function() pcall(NEX_TeleportToHook) end})

-- FLY
local flySection = PlayerTab:Section({
    Title = "Fly",
    Icon = "solar:wing-bold",
    Box = true,
    BoxBorder = true,
    Opened = false,
})
flySection:Toggle({ Title = "Enable Fly", Callback = function(v) VD.FLY_Enabled = v end })
flySection:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 200, Default = 50 }, Callback = function(v) VD.FLY_Speed = v end })
flySection:Dropdown({ Title = "Fly Method", Options = { "CFrame", "Velocity" }, Callback = function(v) VD.FLY_Method = v end })

-- ESP Tab
ESPTab:Toggle({ Title="Enable ESP (Highlight + Name)", Callback=function(v)
    VD.ESP = v
    if v then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then createSimpleESPForCharacter(p, p.Character) end end
    else
        for p,_ in pairs(SimpleESP) do removeSimpleESP(p) end
    end
end})
ESPTab:Toggle({ Title="Show Distance", Callback=function(v) VD.ShowDistance = v end})
ESPTab:Slider({ Title="Max ESP Distance", Value={Min=500,Max=5000,Default=2000}, Callback=function(v) VD.MaxDistance = v end})
ESPTab:Toggle({ Title="Drawing Advanced ESP (boxes/skeleton/offscreen)", Callback=function(v) VD.DRAWING_ESP = v end})
ESPTab:Toggle({ Title="Player Chams (model highlight)", Callback=function(v) VD.ESP_PlayerChams = v end})
ESPTab:Toggle({ Title="Object Chams (gates/hooks/pallets/Windows)", Callback=function(v) VD.ESP_ObjectChams = v end})
ESPTab:Toggle({ Title="ESP Skeleton", Callback=function(v) VD.ESP_Skeleton = v end})
ESPTab:Toggle({ Title="ESP Velocity Arrows", Callback=function(v) VD.ESP_Velocity = v end})
ESPTab:Toggle({ Title="ESP Offscreen Arrows", Callback=function(v) VD.ESP_Offscreen = v end})
ESPTab:Toggle({ Title="Closest Hook Highlight", Callback=function(v) VD.ESP_ClosestHook = v end})

-- Map Tab (radar)
MapTab:Toggle({ Title="Radar Enable", Callback=function(v) VD.RADAR_Enabled = v end})
MapTab:Slider({ Title="Radar Size", Value={Min=80,Max=300,Default=120}, Callback=function(v) VD.RADAR_Size = v end})
MapTab:Toggle({ Title="Radar Circle Mode", Callback=function(v) VD.RADAR_Circle = v end})
MapTab:Toggle({ Title="Radar show Killer", Callback=function(v) VD.RADAR_Killer = v end})
MapTab:Toggle({ Title="Radar show Survivor", Callback=function(v) VD.RADAR_Survivor = v end})
MapTab:Toggle({ Title="Radar show Generator", Callback=function(v) VD.RADAR_Generator = v end})
MapTab:Toggle({ Title="Radar show Pallet", Callback=function(v) VD.RADAR_Pallet = v end})

-- AIM Tab (aim options)
AimTab:Toggle({ Title="Enable Aimbot", Callback=function(v) VD.AIM_Enabled = v end})
AimTab:Toggle({ Title="Use RMB to aim", Callback=function(v) VD.AIM_UseRMB = v end})
AimTab:Toggle({ Title="Show Aim FOV (circle)", Callback=function(v) VD.AIM_ShowFOV = v end})
AimTab:Slider({ Title="FOV Size (aim radius on screen)", Value={Min=50,Max=400,Default=120}, Callback=function(v) VD.AIM_FOV = v end})
AimTab:Slider({ Title="Smoothness", Value={Min=0.02,Max=1,Default=0.3,Dec=2}, Callback=function(v) VD.AIM_Smooth = v end})
AimTab:Dropdown({ Title="Target Part", Options={"Head","Torso","Root"}, Callback=function(v) VD.AIM_TargetPart = v end})
AimTab:Toggle({ Title="Visibility Check", Callback=function(v) VD.AIM_VisCheck = v end})
AimTab:Toggle({ Title="Prediction", Callback=function(v) VD.AIM_Predict = v end})
AimTab:Toggle({ Title="Spear Aimbot", Callback=function(v) VD.SPEAR_Aimbot = v end})
AimTab:Slider({ Title="Spear Gravity", Value={Min=10,Max=200,Default=50}, Callback=function(v) VD.SPEAR_Gravity = v end})
AimTab:Slider({ Title="Spear Speed", Value={Min=50,Max=300,Default=100}, Callback=function(v) VD.SPEAR_Speed = v end})

-- FOV Tab (camera related settings)
FOVTab:Toggle({ Title="Enable Camera FOV override", Callback=function(v) VD.CAM_FOVEnabled = v end})
FOVTab:Slider({ Title="Camera FOV", Value={Min=30,Max=140,Default=90}, Callback=function(v) VD.CAM_FOV = v end})
FOVTab:Toggle({ Title="Third Person (Killer only)", Callback=function(v) VD.CAM_ThirdPerson = v end})
FOVTab:Toggle({ Title="Shift Lock (auto face camera)", Callback=function(v) VD.CAM_ShiftLock = v end})
FOVTab:Toggle({ Title="No Fog (remove fog/post effects)", Callback=function(v) VD.NO_Fog = v if v then RemoveFog() else RestoreFog() end end})
FOVTab:Toggle({ Title="Fullbright (lighting preset)", Callback=function(v) VD.Fullbright = v end})

-- Survivor Tab
SurvivorTab:Toggle({ Title="Auto Parry", Callback=function(v) VD.AUTO_Parry = v end})
SurvivorTab:Toggle({ Title="Auto Wiggle", Callback=function(v) VD.SURV_AutoWiggle = v end})
SurvivorTab:Toggle({ Title="Auto SkillCheck (QTE)", Callback=function(v) VD.AUTO_SkillCheck = v; if v then pcall(SetupSkillCheckMonitor) end end})
SurvivorTab:Toggle({ Title="No Fall Damage", Callback=function(v) VD.SURV_NoFall = v end})
SurvivorTab:Toggle({ Title="Flee Killer (Auto TeleAway)", Callback=function(v) VD.AUTO_TeleAway = v end})
SurvivorTab:Slider({ Title="Flee Distance", Value={Min=20,Max=120,Default=40}, Callback=function(v) VD.AUTO_TeleAwayDist = v end})
SurvivorTab:Toggle({ Title="Beat Survivor (auto exit)", Callback=function(v) VD.BEAT_Survivor = v end})
SurvivorTab:Toggle({ Title="Auto Stop Emote (after parry)", Callback=function(v) VD.AUTO_StopEmote = v end})

-- Killer Tab
KillerTab:Toggle({ Title="Auto Attack", Callback=function(v) VD.AUTO_Attack = v end})
KillerTab:Slider({ Title="Attack Range", Value={Min=5,Max=20,Default=12}, Callback=function(v) VD.AUTO_AttackRange = v end})
KillerTab:Toggle({ Title="Hitbox Expand", Callback=function(v) VD.HITBOX_Enabled = v end})
KillerTab:Slider({ Title="Hitbox Size", Value={Min=5,Max=40,Default=15}, Callback=function(v) VD.HITBOX_Size = v end})
KillerTab:Toggle({ Title="Destroy Pallets", Callback=function(v) VD.KILLER_DestroyPallets = v end})
KillerTab:Toggle({ Title="Full Gen Break", Callback=function(v) VD.KILLER_FullGenBreak = v end})
KillerTab:Toggle({ Title="Double Tap", Callback=function(v) VD.KILLER_DoubleTap = v end})
KillerTab:Toggle({ Title="Infinite Lunge", Callback=function(v) VD.KILLER_InfiniteLunge = v end})
KillerTab:Toggle({ Title="Auto Hook", Callback=function(v) VD.KILLER_AutoHook = v end})
KillerTab:Toggle({ Title="Anti Blind (Flashlight)", Callback=function(v) VD.KILLER_AntiBlind = v; pcall(SetupAntiBlind) end})
KillerTab:Toggle({ Title="No Pallet Stun (metamethod)", Callback=function(v) VD.KILLER_NoPalletStun = v; pcall(SetupNoPalletStun) end})
KillerTab:Toggle({ Title="No Slowdown", Callback=function(v) VD.KILLER_NoSlowdown = v end})
KillerTab:Toggle({ Title="Beat Killer (auto kill)", Callback=function(v) VD.BEAT_Killer = v end})

-- Generator Tab
GeneratorTab:Toggle({ Title="Generator ESP", Callback=function(v) VD.GeneratorESP = v
    if not v then for gen,folder in pairs(GeneratorESP) do if folder and folder.Parent then pcall(function() folder:Destroy() end) end end GeneratorESP = {} end
end})
GeneratorTab:Toggle({ Title="AntiFail Generator", Callback=function(v) VD.GenAntiFail = v end})
GeneratorTab:Toggle({ Title="Auto Generator (Repair)", Callback=function(v) VD.AUTO_Generator = v end})
GeneratorTab:Dropdown({ Title="Gen Speed", Options={"Fast","Slow"}, Callback=function(v) VD.AUTO_GenMode = v end})
GeneratorTab:Toggle({ Title="Auto Leave Gen (when killer near)", Callback=function(v) VD.AUTO_LeaveGen = v end})
GeneratorTab:Slider({ Title="Leave Distance", Value={Min=10,Max=30,Default=18}, Callback=function(v) VD.AUTO_LeaveDist = v end})
GeneratorTab:Button({ Title="Leave Gen Now", Callback=function() pcall(NEX_LeaveGenerator) end})

-- Fling Feature Tab
FlingTab:Toggle({ Title="Enable Fling", Callback=function(v) VD.FLING_Enabled = v end})
FlingTab:Slider({ Title="Fling Strength", Value={Min=1000,Max=50000,Default=10000}, Callback=function(v) VD.FLING_Strength = v end})
FlingTab:Button({ Title="Fling Nearest", Callback=function() pcall(NEX_FlingNearest) end})
FlingTab:Button({ Title="Fling All", Callback=function() pcall(NEX_FlingAll) end})

-- Reset Tab
ResetTab:Button({ Title="Unload Script (cleanup)", Callback=function()
    VD.Destroyed = true
    for p,_ in pairs(SimpleESP) do removeSimpleESP(p) end
    for gen,folder in pairs(GeneratorESP) do if folder and folder.Parent then pcall(function() folder:Destroy() end) end end
    GeneratorESP = {}
    VD.Fullbright = false
    VD.Noclip = false
    disableNoclipRestore()
    VD.GenAntiFail = false; VD.HealAntiFail = false
    if DrawingAvailable then
        pcall(function()
            for target,_ in pairs(Chams.Objects or {}) do
                if target and target:FindFirstChild("_ViolenceChams") then target:FindFirstChild("_ViolenceChams"):Destroy() end
                if target and target:FindFirstChild("_ViolenceLabel") then target:FindFirstChild("_ViolenceLabel"):Destroy() end
            end
        end)
    end
    print("[NEX HUB] Violence District Unloaded")
end})

-- RECOVERY AFTER RESPAWN/HOOK
local function ForceRefresh()
    updateChar()
    if VD.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Character and not SimpleESP[p] then
                    createSimpleESPForCharacter(p, p.Character)
                end
            end
        end
    end
    NEX_ScanMap()
    VD._BeatSurvivorDone = false
    VD._BeatKillerDone = false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    ForceRefresh()
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(ForceRefresh)

print("[NEX HUB] Violence District Final Loaded (All features fixed, auto stop emote added, auto leave gen cooldown)")
