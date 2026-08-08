local Players = game:GetService("Players")
local LocalPlr = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")

local success, gameInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local gameName = (success and gameInfo and gameInfo.Name) or "Unknown Game"

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "XEPHEX HUB  | " .. gameName,
    Author = ".gg/rNKGmeyAHf",
    Folder = "XEPHEX HUB",
    Theme = "Dark",
    Size = UDim2.fromOffset(600, 300),
    Icon = "rbxassetid://80283328189076",
    Background = "https://img1.pic.in.th/images/5573a1c232fced2ac60da9136ae9ea30.jpg",
    HideSearchBar = false, -- 👈 เพิ่มตรงนี้
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "XEPHEX HUB",
                Content = "สวัสดี " .. LocalPlr.Name,
                Duration = 3
            })
        end
    }
})

-- 🔧 Services
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local LocalPlr = Players.LocalPlayer

-- 🧹 ลบของเก่ากันซ้ำ
local old = LocalPlr:WaitForChild("PlayerGui"):FindFirstChild("XephexToggleGui")
if old then old:Destroy() end

-- ── ScreenGui ─────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "XephexToggleGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = LocalPlr:WaitForChild("PlayerGui")

-- ══ ปุ่ม ════════════════════════════════
local BTN_W, BTN_H = 44, 44

local circle = Instance.new("Frame")
circle.Size = UDim2.fromOffset(BTN_W, BTN_H)
circle.Position = UDim2.fromOffset(24, 200)
circle.BackgroundColor3 = Color3.fromHex("0d0d0d")
circle.BorderSizePixel = 0
circle.Parent = gui

Instance.new("UICorner", circle).CornerRadius = UDim.new(0,10)

-- 🟢 ขอบปุ่ม (ให้สีมาอยู่ตรงนี้แทน)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromHex("00FFC8")
stroke.Parent = circle

-- 🌫️ glow (ไม่ย้อมสีแล้ว)
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.fromOffset(BTN_W + 6, BTN_H + 6)
shadow.Position = UDim2.fromOffset(-3, -3)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://2"

-- ✅ ใช้สีเดิมของรูป 100%
shadow.ImageColor3 = Color3.new(1,1,1)

-- ปรับความจางเอาแทนสี
shadow.ImageTransparency = 0.6

shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24,24,276,276)
shadow.ZIndex = 0
shadow.Parent = circle

-- 🟢 ICON (ไม่โดนแตะสี)
local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Size = UDim2.fromOffset(55, 55)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://80283328189076"

-- 🔒 ล็อคสีแท้
icon.ImageColor3 = Color3.new(1,1,1)

icon.ScaleType = Enum.ScaleType.Fit
icon.ResampleMode = Enum.ResamplerMode.Default
icon.ImageTransparency = 0
icon.ClipsDescendants = true
icon.ZIndex = 2
icon.Parent = circle

-- ── ตัวแปร ─────────────────────────────
local dragging = false
local dragStart, frameStart
local hasMoved = false
local DRAG_THRESHOLD = 6
local activeInput = nil

-- 🎯 เริ่มลาก
circle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		
		activeInput = input
		dragging = true
		hasMoved = false
		dragStart = input.Position

		frameStart = Vector2.new(circle.Position.X.Offset, circle.Position.Y.Offset)
	end
end)

-- 🎯 กำลังลาก
UIS.InputChanged:Connect(function(input)
	if dragging and input == activeInput then
		
		local delta = input.Position - dragStart
		if delta.Magnitude > DRAG_THRESHOLD then
			hasMoved = true
		end

		circle.Position = UDim2.fromOffset(
			frameStart.X + delta.X,
			frameStart.Y + delta.Y
		)
	end
end)

-- 🎯 ปล่อย
UIS.InputEnded:Connect(function(input)
	if input == activeInput then
		dragging = false
		activeInput = nil

		if not hasMoved then
			if Window then
				Window:Toggle()
			end
		end
	end
end)

-- ปิดปุ่มเดิม
if Window then
	Window:EditOpenButton({
		Enabled = false
	})
end

local ConfigManager = Window.ConfigManager
local MyConfig = ConfigManager:CreateConfig("FishIt")

local TabLog     = Window:Tab({ Title = "Log", Icon = "crown" })
local TabMain    = Window:Tab({ Title = "Main", Icon = "menu" })
local TabMise    = Window:Tab({ Title = "Misc", Icon = "sparkles" })
local TabSettings= Window:Tab({ Title = "Settings", Icon = "settings" })

TabLog:Section({ Title = "Credit" })
TabLog:Button({
    Title = "Discord",
    Desc = "ดิสพูดคุย/สอบถาม",
    Callback = function()
        setclipboard("https://discord.gg/rNKGmeyAHf")
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอก Discord Link แล้ว", Duration = 5 })
    end
})
TabLog:Button({
    Title = "YouTube",
    Desc = "ยูทูป",
    Callback = function()
        setclipboard("https://www.youtube.com/@x2Zeroo")
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอก YouTube Link แล้ว", Duration = 5 })
    end
})


TabLog:Paragraph({
    Title = "สคริปก็ให้เล่นฟรีแล้ว",
    Desc = "ฝากไปกดติดตามกันด้วยนะครับ",
    Image = "badge-check",   -- icon (optional)
    ImageSize = 20,
    Color = "White"      -- สีข้อความ (optional)
})

local MiscSec = TabMise:Section({
    Title = "Misc Tools",
    Icon = "sparkles",
    Box = true,
    TextSize = 18,
    Opened = false
})

----------------------------------------------------------
-- 💤 Anti AFK
----------------------------------------------------------
local antiAFKConn
local TogAntiAFK = MiscSec:Toggle({
    Title = "Anti AFK",
    Icon = "shield",
    Desc = "กันหลุด 20 นาที",
    Default = false,
    Callback = function(state)
        if state then
            if antiAFKConn then antiAFKConn:Disconnect() end
            local VirtualUser = game:GetService("VirtualUser")
            antiAFKConn = LocalPlr.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if antiAFKConn then antiAFKConn:Disconnect() antiAFKConn=nil end
        end
    end
})
MyConfig:Register("AntiAFK", TogAntiAFK)

----------------------------------------------------------
-- ☀️ Bright Mode
----------------------------------------------------------
local Lighting = game:GetService("Lighting")
local OriginalSettings = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
}
local LoopBright = false

local TogBright = MiscSec:Toggle({
    Title = "Bright",
    Icon = "sun",
    Desc = "ทำให้แมพสว่าง",
    Default = false,
    Callback = function(state)
        LoopBright = state
        if state then
            task.spawn(function()
                while LoopBright do
                    pcall(function()
                        Lighting.ClockTime = 12
                        Lighting.Brightness = 3
                        Lighting.Ambient = Color3.new(1,1,1)
                        Lighting.OutdoorAmbient = Color3.new(1,1,1)
                        Lighting.FogEnd = 999999
                        Lighting.GlobalShadows = false
                    end)
                    task.wait(1)
                end
            end)
        else
            pcall(function()
                for k,v in pairs(OriginalSettings) do Lighting[k]=v end
            end)
        end
    end
})
MyConfig:Register("Bright", TogBright)

----------------------------------------------------------
-- 🌫️ No Fog
----------------------------------------------------------
local OriginalFog = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd }
local TogNoFog = MiscSec:Toggle({
    Title = "No Fog",
    Icon = "cloud-off",
    Desc = "ลบหมอกในแมพ",
    Default = false,
    Callback = function(state)
        if state then
            Lighting.FogStart = 0
            Lighting.FogEnd = 999999
        else
            Lighting.FogStart = OriginalFog.FogStart
            Lighting.FogEnd = OriginalFog.FogEnd
        end
    end
})
MyConfig:Register("NoFog", TogNoFog)

----------------------------------------------------------
-- 🚫 Noclip
----------------------------------------------------------
local noclipConn
local TogNoclip = MiscSec:Toggle({
    Title = "Noclip",
    Icon = "ghost",
    Desc = "เดินทะลุสิ่งของ",
    Default = false,
    Callback = function(state)
        local char = LocalPlr.Character or LocalPlr.CharacterAdded:Wait()
        if state then
            noclipConn = RunService.Stepped:Connect(function()
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect() noclipConn=nil end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
})
MyConfig:Register("Noclip", TogNoclip)

----------------------------------------------------------
-- 🦘 Infinite Jump
----------------------------------------------------------
local infJumpConn
local TogInfJump = MiscSec:Toggle({
    Title = "Infinite Jump",
    Icon = "arrow-up",
    Desc = "กระโดดไม่จำกัด",
    Default = false,
    Callback = function(state)
        local char = LocalPlr.Character or LocalPlr.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        if state then
            infJumpConn = UIS.JumpRequest:Connect(function()
                if hum and hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if infJumpConn then infJumpConn:Disconnect() infJumpConn=nil end
        end
    end
})
MyConfig:Register("InfiniteJump", TogInfJump)

----------------------------------------------------------
-- ☁️ Float
----------------------------------------------------------
local FloatHeight = 30
local floatEnabled = false
local function getHRP() local c=LocalPlr.Character or LocalPlr.CharacterAdded:Wait() return c:WaitForChild("HumanoidRootPart") end
local function getFloat(hrp) return hrp and hrp:FindFirstChild("FloatForce") end
local function ensureFloat(hrp)
    local f=getFloat(hrp)
    if not f then
        f=Instance.new("BodyPosition")
        f.Name="FloatForce"
        f.MaxForce=Vector3.new(0,1e6,0)
        f.P=10000
        f.D=1000
        f.Parent=hrp
    end
    f.Position=hrp.Position+Vector3.new(0,FloatHeight,0)
    return f
end
local function removeFloat(hrp) local f=getFloat(hrp) if f then f:Destroy() end end

MiscSec:Input({
    Title = "Float Height",
    Icon = "sliders",
    Desc = "กำหนดความสูงของการลอย",
    Default = tostring(FloatHeight),
    Callback = function(Value)
        local v = tonumber(Value)
        if v then
            FloatHeight = v
            local hrp = getHRP()
            local f = getFloat(hrp)
            if f then f.Position = hrp.Position + Vector3.new(0, FloatHeight, 0) end
        end
    end
})

local TogFloat = MiscSec:Toggle({
    Title = "Float",
    Icon = "cloud",
    Desc = "เปิดโหมดลอยตัว",
    Default = false,
    Callback = function(state)
        floatEnabled = state
        local hrp = getHRP()
        if state then ensureFloat(hrp) else removeFloat(hrp) end
    end
})
MyConfig:Register("Float", TogFloat)

----------------------------------------------------------
-- 🚀 Nukes Section
----------------------------------------------------------
local NukesSec = TabMise:Section({
    Title = "Nukes",
    Icon = "rocket",
    Box = true,
    TextSize = 18,
    Opened = false
})

----------------------------------------------------------
-- 🚀 Nuke Tier TP (เช็ค Held Nuke + Drop จุดว่าง + Nearest-Aware + Retry Guard + Highest Tier + Sync Wait)
----------------------------------------------------------
local nukeTPRunning = false
local NUKE_TP_DELAY = 0.1

local TogNukeTP = NukesSec:Toggle({
    Title = "Nuke Tier TP",
    Icon = "rocket",
    Desc = "วาปสลับ Nuke Tier สูงสุด (เช็ค Held Nuke)",
    Default = false,
    Callback = function(state)
        if state then
            if nukeTPRunning then return end
            nukeTPRunning = true

            local Players = game:GetService("Players")
            local Workspace = game:GetService("Workspace")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local LocalPlr = Players.LocalPlayer

            local nukeRemotes = ReplicatedStorage:WaitForChild("NukeRemotes", 5)
            local dropRemote = nukeRemotes and nukeRemotes:WaitForChild("Drop", 5)

            local currentNukesFolderRef = nil

            local function getNukePart(nukeInst)
                if nukeInst:IsA("BasePart") then
                    return nukeInst
                elseif nukeInst:IsA("Model") then
                    return nukeInst.PrimaryPart or nukeInst:FindFirstChildWhichIsA("BasePart", true)
                end
                return nukeInst:FindFirstChildWhichIsA("BasePart", true)
            end

            local function getNukeStandPosition(nukeInst)
                local part = getNukePart(nukeInst)
                if not part then return nil end
                return part.Position - Vector3.new(0, part.Size.Y / 2, 0)
            end

            local function getHeldNukeTier()
                local camera = Workspace:FindFirstChild("Camera")
                if not camera then return nil end
                local heldNukeVisual = camera:FindFirstChild("HeldNukeVisual")
                if not heldNukeVisual then return nil end
                return heldNukeVisual:GetAttribute("Tier")
            end

            local function waitForHeldTierChange(previousTier, timeout)
                local startTime = os.clock()

                while os.clock() - startTime < timeout do
                    local currentTier = getHeldNukeTier()
                    if currentTier ~= previousTier and currentTier ~= nil then
                        return currentTier
                    end
                    task.wait(0.05)
                end

                return getHeldNukeTier()
            end

            local function nearestOwnedNuke(standPos)
                local basesFolder = Workspace:FindFirstChild("Bases")
                if not basesFolder then return nil, math.huge end

                local minDist = math.huge
                local nearest = nil

                for _, baseInst in ipairs(basesFolder:GetChildren()) do
                    local nukesFolder = baseInst:FindFirstChild("Nukes")
                    if nukesFolder then
                        for _, nukeInst in ipairs(nukesFolder:GetChildren()) do
                            if nukeInst:IsA("BasePart") and nukeInst:GetAttribute("OwnerUserId") == LocalPlr.UserId then
                                local dist = (nukeInst.Position - standPos).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    nearest = nukeInst
                                end
                            end
                        end
                    end
                end

                return nearest, minDist
            end

            local function findSafeStandPosition(targetNuke)
                local targetPart = getNukePart(targetNuke)
                if not targetPart then return nil end

                local margins = { 0.2, 0.1, 0.05, 0.02 }

                for _, margin in ipairs(margins) do
                    local candidatePos = targetPart.Position - Vector3.new(0, targetPart.Size.Y / 2 - margin, 0)
                    local nearest = nearestOwnedNuke(candidatePos)

                    if nearest == targetNuke then
                        return candidatePos
                    end
                end

                return targetPart.Position - Vector3.new(0, targetPart.Size.Y / 2 - 0.02, 0)
            end

            local function findClearDropPosition(hrp, nukesFolder)
                local checkRadius = 3
                local candidateOffsets = {
                    Vector3.new(0, 0, 0),
                    Vector3.new(4, 0, 0),
                    Vector3.new(-4, 0, 0),
                    Vector3.new(0, 0, 4),
                    Vector3.new(0, 0, -4),
                    Vector3.new(4, 0, 4),
                    Vector3.new(-4, 0, 4),
                    Vector3.new(4, 0, -4),
                    Vector3.new(-4, 0, -4),
                }

                local nukePositions = {}
                if nukesFolder then
                    for _, nukeInst in ipairs(nukesFolder:GetChildren()) do
                        local part = getNukePart(nukeInst)
                        if part then
                            table.insert(nukePositions, part.Position)
                        end
                    end
                end

                local bestPosition = hrp.Position
                local bestClearance = -1

                for _, offset in ipairs(candidateOffsets) do
                    local candidatePos = hrp.Position + offset

                    local minDist = math.huge
                    for _, nukePos in ipairs(nukePositions) do
                        local dist = (Vector3.new(nukePos.X, 0, nukePos.Z) - Vector3.new(candidatePos.X, 0, candidatePos.Z)).Magnitude
                        if dist < minDist then
                            minDist = dist
                        end
                    end

                    if minDist >= checkRadius then
                        return candidatePos
                    end

                    if minDist > bestClearance then
                        bestClearance = minDist
                        bestPosition = candidatePos
                    end
                end

                return bestPosition
            end

            local function dropHeldNuke()
                if not dropRemote then return end

                local character = LocalPlr.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local clearPos = findClearDropPosition(hrp, currentNukesFolderRef)
                local dropCFrame = CFrame.new(clearPos) * (hrp.CFrame - hrp.CFrame.Position)

                dropRemote:FireServer(dropCFrame)
            end

            local function findOwnedBase()
                local basesFolder = Workspace:FindFirstChild("Bases")
                if not basesFolder then return nil end
                for _, baseInst in ipairs(basesFolder:GetChildren()) do
                    local nukesFolder = baseInst:FindFirstChild("Nukes")
                    if nukesFolder then
                        for _, nukeInst in ipairs(nukesFolder:GetChildren()) do
                            if nukeInst:GetAttribute("OwnerUserId") == LocalPlr.UserId then
                                return baseInst
                            end
                        end
                    end
                end
                return nil
            end

            local function findMatchingTierPair()
                local myBase = findOwnedBase()
                if not myBase then return nil, nil, nil end

                local myNukesFolder = myBase:FindFirstChild("Nukes")
                if not myNukesFolder then return nil, nil, nil end

                currentNukesFolderRef = myNukesFolder

                local tierGroups = {}
                for _, nukeInst in ipairs(myNukesFolder:GetChildren()) do
                    local tier = nukeInst:GetAttribute("Tier")
                    if tier ~= nil then
                        if not tierGroups[tier] then
                            tierGroups[tier] = {}
                        end
                        table.insert(tierGroups[tier], nukeInst)
                    end
                end

                local highestTier = nil
                for tier, group in pairs(tierGroups) do
                    if #group >= 2 then
                        if highestTier == nil or tier > highestTier then
                            highestTier = tier
                        end
                    end
                end

                if highestTier == nil then
                    return nil, nil, nil
                end

                local group = tierGroups[highestTier]
                return group[1], group[2], highestTier
            end

            task.spawn(function()
                local firstNuke, secondNuke, pairTier = nil, nil, nil
                local toggleFlag = false
                local consecutiveFailCount = 0
                local MAX_CONSECUTIVE_FAILS = 3
                local FAIL_COOLDOWN = 3
                local lastHeldTierBeforeTP = nil

                while nukeTPRunning do
                    if not firstNuke or not firstNuke.Parent or not secondNuke or not secondNuke.Parent then
                        firstNuke, secondNuke, pairTier = findMatchingTierPair()
                        if not firstNuke or not secondNuke then
                            task.wait(NUKE_TP_DELAY)
                            continue
                        end
                    end

                    local character = LocalPlr.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        task.wait(NUKE_TP_DELAY)
                        continue
                    end

                    local targetNuke = toggleFlag and secondNuke or firstNuke

                    local safePos = findSafeStandPosition(targetNuke)
                    if not safePos then
                        task.wait(NUKE_TP_DELAY)
                        continue
                    end

                    local humanoid = character:FindFirstChild("Humanoid")
                    local hipHeight = (humanoid and humanoid.HipHeight) or 2
                    local hrpHeight = hrp.Size.Y / 2

                    lastHeldTierBeforeTP = getHeldNukeTier()
                    hrp.CFrame = CFrame.new(safePos + Vector3.new(0, hipHeight + hrpHeight, 0))

                    local heldTier = waitForHeldTierChange(lastHeldTierBeforeTP, 1)

                    if not targetNuke.Parent then
                        firstNuke, secondNuke, pairTier = nil, nil, nil
                        consecutiveFailCount = 0
                        continue
                    end

                    if heldTier == pairTier then
                        toggleFlag = not toggleFlag
                        consecutiveFailCount = 0
                    else
                        if heldTier ~= nil then
                            dropHeldNuke()
                        end
                        firstNuke, secondNuke, pairTier = nil, nil, nil

                        consecutiveFailCount += 1
                        if consecutiveFailCount >= MAX_CONSECUTIVE_FAILS then
                            consecutiveFailCount = 0
                            task.wait(FAIL_COOLDOWN)
                        end
                    end
                end
            end)
        else
            nukeTPRunning = false
        end
    end
})
MyConfig:Register("NukeTierTP", TogNukeTP)

----------------------------------------------------------
-- 🔒 Auto Lock
----------------------------------------------------------
local autoLockConn
local TogAutoLock = NukesSec:Toggle({
    Title = "Auto Lock",
    Icon = "lock",
    Desc = "ล็อค Base อัตโนมัติทุก 1 วิ",
    Default = false,
    Callback = function(state)
        if state then
            if autoLockConn then autoLockConn:Disconnect() autoLockConn = nil end

            local RunService = game:GetService("RunService")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            local nukeRemotes = ReplicatedStorage:WaitForChild("NukeRemotes", 5)
            if not nukeRemotes then return end

            local requestLockBase = nukeRemotes:WaitForChild("RequestLockBase", 5)
            if not requestLockBase then return end

            local accumulated = 0
            local INTERVAL = 1

            autoLockConn = RunService.Heartbeat:Connect(function(dt)
                accumulated += dt
                if accumulated < INTERVAL then return end
                accumulated = 0

                requestLockBase:FireServer()
            end)
        else
            if autoLockConn then autoLockConn:Disconnect() autoLockConn = nil end
        end
    end
})
MyConfig:Register("AutoLock", TogAutoLock)

----------------------------------------------------------
-- 🚀 Auto Launch
----------------------------------------------------------
local autoLaunchConn
local TogAutoLaunch = NukesSec:Toggle({
    Title = "Auto Nukes",
    Icon = "rocket",
    Desc = "ยิง Nuke อัตโนมัติทุก 1 วิ",
    Default = false,
    Callback = function(state)
        if state then
            if autoLaunchConn then autoLaunchConn:Disconnect() autoLaunchConn = nil end

            local RunService = game:GetService("RunService")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")

            local nukeRemotes = ReplicatedStorage:WaitForChild("NukeRemotes", 5)
            if not nukeRemotes then return end

            local launchRequest = nukeRemotes:WaitForChild("LaunchRequest", 5)
            if not launchRequest then return end

            local accumulated = 0
            local INTERVAL = 1

            autoLaunchConn = RunService.Heartbeat:Connect(function(dt)
                accumulated += dt
                if accumulated < INTERVAL then return end
                accumulated = 0

                launchRequest:FireServer()
            end)
        else
            if autoLaunchConn then autoLaunchConn:Disconnect() autoLaunchConn = nil end
        end
    end
})
MyConfig:Register("AutoNukes", TogAutoLaunch)

----------------------------------------------------------
-- 🎯 Enemy Base Dropdown + Auto Launch (Selected Target)
----------------------------------------------------------
-- 🎯 Enemy Base Dropdown + Auto Launch (Selected Target)
----------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlr = Players.LocalPlayer

local function getLaunchConfirmRemote()
    local packages = ReplicatedStorage:WaitForChild("Packages", 5)
    if not packages then return nil end
    local remotes = packages:WaitForChild("Remotes", 5)
    if not remotes then return nil end
    local networking = remotes:WaitForChild("Networking", 5)
    if not networking then return nil end
    return networking:WaitForChild("RE/Launch/LaunchConfirm", 5)
end

local launchConfirmRemote = getLaunchConfirmRemote()

local enemyBaseConfig = {
    selectedBaseNames = nil
}

local function getBaseCenterPosition(baseInst)
    local nukesFolder = baseInst:FindFirstChild("Nukes")
    if not nukesFolder then return nil end

    local totalPos = Vector3.new(0, 0, 0)
    local count = 0

    for _, nukeInst in ipairs(nukesFolder:GetChildren()) do
        local pos
        if nukeInst:IsA("BasePart") then
            pos = nukeInst.Position
        elseif nukeInst:IsA("Model") then
            if nukeInst.PrimaryPart then
                pos = nukeInst.PrimaryPart.Position
            else
                local ok, cframe = pcall(function() return nukeInst:GetPivot() end)
                if ok and cframe then pos = cframe.Position end
            end
        end
        if pos then
            totalPos += pos
            count += 1
        end
    end

    if count == 0 then return nil end
    return totalPos / count
end

local function scanEnemyBases()
    local result = {}
    local basesFolder = Workspace:FindFirstChild("Bases")
    if not basesFolder then return result end

    for _, baseInst in ipairs(basesFolder:GetChildren()) do
        local nukesFolder = baseInst:FindFirstChild("Nukes")
        if nukesFolder then
            local ownerUserId = nil
            for _, nukeInst in ipairs(nukesFolder:GetChildren()) do
                local oid = nukeInst:GetAttribute("OwnerUserId")
                if oid then
                    ownerUserId = oid
                    break
                end
            end

            if ownerUserId and ownerUserId ~= LocalPlr.UserId then
                local ok, name = pcall(function()
                    return Players:GetNameFromUserIdAsync(ownerUserId)
                end)
                if ok and name then
                    result[name] = baseInst
                end
            end
        end
    end

    return result
end

local enemyBaseMap = scanEnemyBases()
local enemyBaseNames = {}
for name, _ in pairs(enemyBaseMap) do
    table.insert(enemyBaseNames, name)
end

local TogEnemySelect = NukesSec:Dropdown({
    Title = "Select Enemy Base",
    Values = enemyBaseNames,
    Multi = false,
    AllowNone = true,
    Default = {},
    Desc = "เลือก base ศัตรูที่จะยิง",
    SearchBarEnabled = true,

    Callback = function(v)
        local selectedName = type(v) == "table" and v[1] or v
        enemyBaseConfig.selectedBaseNames = selectedName
    end,
})
MyConfig:Register("EnemyBaseSelect", TogEnemySelect)

local autoLaunchTargetConn
local TogAutoLaunchTarget = NukesSec:Toggle({
    Title = "Auto Launch (Selected Target)",
    Icon = "crosshair",
    Desc = "ยิงใส่ base ที่เลือกอัตโนมัติทุก 1 วิ",
    Default = false,
    Callback = function(state)
        if state then
            if autoLaunchTargetConn then autoLaunchTargetConn:Disconnect() autoLaunchTargetConn = nil end
            if not launchConfirmRemote then return end

            local accumulated = 0
            local INTERVAL = 1

            autoLaunchTargetConn = RunService.Heartbeat:Connect(function(dt)
                accumulated += dt
                if accumulated < INTERVAL then return end
                accumulated = 0

                local targetName = enemyBaseConfig.selectedBaseNames
                if not targetName or targetName == "" then return end

                local baseInst = enemyBaseMap[targetName]
                if not baseInst or not baseInst.Parent then
                    enemyBaseMap = scanEnemyBases()
                    return
                end

                local targetPos = getBaseCenterPosition(baseInst)
                if not targetPos then return end

                launchConfirmRemote:FireServer(vector.create(targetPos.X, targetPos.Y, targetPos.Z))
            end)
        else
            if autoLaunchTargetConn then autoLaunchTargetConn:Disconnect() autoLaunchTargetConn = nil end
        end
    end
})
MyConfig:Register("AutoLaunchTarget", TogAutoLaunchTarget)

----------------------------------------------------------
-- 🎯 Auto Launch (Saved Position)
----------------------------------------------------------
local launchConfirmRemote2 = getLaunchConfirmRemote()

local savedLaunchPosition = nil

if launchConfirmRemote2 and hookfunction then
    local originalFireServer
    originalFireServer = hookfunction(launchConfirmRemote2.FireServer, function(self, pos, ...)
        if self == launchConfirmRemote2 then
            savedLaunchPosition = pos
        end
        return originalFireServer(self, pos, ...)
    end)
end

local autoLaunchSavedConn
local TogAutoLaunchSaved = NukesSec:Toggle({
    Title = "Auto Launch (Saved Pos)",
    Icon = "crosshair",
    Desc = "ยิงตำแหน่งล่าสุดที่กดเองซ้ำทุก 1 วิ",
    Default = false,
    Callback = function(state)
        if state then
            if autoLaunchSavedConn then autoLaunchSavedConn:Disconnect() autoLaunchSavedConn = nil end
            if not launchConfirmRemote2 then return end

            local accumulated = 0
            local INTERVAL = 1

            autoLaunchSavedConn = RunService.Heartbeat:Connect(function(dt)
                accumulated += dt
                if accumulated < INTERVAL then return end
                accumulated = 0

                if not savedLaunchPosition then return end

                launchConfirmRemote2:FireServer(savedLaunchPosition)
            end)
        else
            if autoLaunchSavedConn then autoLaunchSavedConn:Disconnect() autoLaunchSavedConn = nil end
        end
    end
})
MyConfig:Register("AutoLaunchSavedPos", TogAutoLaunchSaved)

local Keybind = TabSettings:Keybind({
    Title = "Keybind to open ui",
    Desc = "ปุ่นเปิดปิด Ui",
    Value = "F",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

-- [FIX 3] แก้ TogKeybind → Keybind
MyConfig:Register("Keybind", Keybind)

TabSettings:Section({ Title = "JobId Tools" })
TabSettings:Button({
    Title = "Join Link",
    Desc = "คัดลอกลิ้งจอย",
    Callback = function()
        local placeId = game.PlaceId
        local jobId = game.JobId

        if jobId and jobId ~= "" then
            local joinLink = string.format(
                "https://www.roblox.com/games/start?placeId=%s&launchData=%s/%s",
                placeId, placeId, jobId
            )
            setclipboard(joinLink)
            WindUI:Notify({
                Title = "XEPHEX HUB",
                Content = "คัดลอกลิงแล้ว!",
                Duration = 5,
                Icon = "rbxassetid://80283328189076"
            })
        else
            WindUI:Notify({
                Title = "XEPHEX HUB",
                Content = "ไม่เจอ JobId ของเซิร์ฟเวอร์นี้",
                Duration = 5,
                Icon = "rbxassetid://80283328189076"
            })
        end
    end
})

local JobId = ""

TabSettings:Button({
    Title = "Copy JobId",
    Desc = "คัดลอกไอดีเซิร์ฟเวอร์",
    Callback = function()
        setclipboard(tostring(game.JobId))
        WindUI:Notify({
            Title = "XEPHEX HUB",
            Content = "คัดลอก JobId แล้ว",
            Duration = 5,
            Icon = "rbxassetid://80283328189076"
        })
    end
})

TabSettings:Input({
    Title = "JobId",
    Placeholder = "ใส่ JobId",
    Default = "",
    Callback = function(Value)
        JobId = Value or ""
    end
})

TabSettings:Button({
    Title = "Teleport To JobId",
    Desc = "จอยเซิร์ฟเวอร์ด้วย JobId",
    Callback = function()
        if JobId ~= "" then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, JobId)
        else
            WindUI:Notify({
                Title = "XEPHEX HUB",
                Content = "กรุณาใส่ JobId ก่อน",
                Duration = 5,
                Icon = "rbxassetid://80283328189076"
            })
        end
    end
})

task.defer(function()
    pcall(function()
        MyConfig:Load()
        WindUI:Notify({
            Title = "XEPHEX  HUB",
            Content = "Load",
            Duration = 1
        })
    end)
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            MyConfig:Save()
        end)
    end
end)

Window:OnClose(function()
    pcall(function()
        MyConfig:Save()
    end)
end)

LocalPlr.OnTeleport:Connect(function()
    pcall(function()
        MyConfig:Save()
    end)
end)
