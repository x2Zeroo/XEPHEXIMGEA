--// ==================== CONFIG ====================
-- ไม่มี Supabase URL/Key ในสคริปต์อีกต่อไป — ยิงผ่าน data.js (Vercel) แทนทั้งหมด
-- data.js ถือ SUPABASE_SERVICE_ROLE_KEY ไว้ฝั่ง server เท่านั้น (env var)
local API_URL            = "https://dashboard.xephex.xyz/api/data"
local GAME_SHARED_SECRET = "aJ7mQ9xLp2VnR5kTf8HyW3cDs6ZuEb1Ni4PoXv0GrCl9MsUwK2YqFt7BhJe5AzDn8CxLm3PvRq6TsHy1WkZu9EbN4GjX2fVa0McLp7Qr5" -- ต้องตรงกับ GAME_SHARED_SECRET ใน Vercel env

--// ==================== SERVICES ====================
local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// ==================== HELPERS ====================
local function kick(reason)
    LocalPlayer:Kick(reason)
end

local function getHwid()
    return RbxAnalyticsService:GetClientId()
end

-- เรียก data.js ด้วย action-based POST body (แทน supabaseRequest ตรงเดิม)
-- คืนค่า: (decodedTable, nil) เมื่อสำเร็จ, (nil, errString) เมื่อล้มเหลว
local function apiRequest(action, payload)
    local body = payload or {}
    body.action = action

    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Game-Secret"] = GAME_SHARED_SECRET
    }

    local okEnc, encoded = pcall(HttpService.JSONEncode, HttpService, body)
    if not okEnc then return nil, "Encode failed" end

    local requestFunc = (syn and syn.request)
        or (http and http.request)
        or (type(request) == "function" and request)
        or nil

    local ok, response
    if requestFunc then
        ok, response = pcall(function()
            return requestFunc({
                Url = API_URL,
                Method = "POST",
                Headers = headers,
                Body = encoded
            })
        end)
    else
        ok, response = pcall(function()
            return HttpService:RequestAsync({
                Url = API_URL,
                Method = "POST",
                Headers = headers,
                Body = encoded
            })
        end)
    end

    if not ok or not response then return nil, "Request failed" end

    local status = response.StatusCode or response.status_code
    if not status or status < 200 or status >= 300 then return nil, "HTTP " .. tostring(status) end

    local bodyRes = response.Body or response.body
    if not bodyRes or bodyRes == "" then return nil, "Empty response" end

    local okDec, decoded = pcall(HttpService.JSONDecode, HttpService, bodyRes)
    if not okDec then return nil, "Invalid response" end

    return decoded, nil
end

--// ==================== MAIN CHECK ====================
local function checkKey()
    -- 0) อ่านคีย์จาก _G.Key
    local userKey = _G.Key

    if userKey == nil or userKey == "" then
        kick("Invalid key.")
        return false
    end

    -- 1) ยืนยันคีย์ผ่าน data.js (verify_license) — server เช็ค HWID/PlaceId/status/expiry
    --    ให้ทั้งหมดในครั้งเดียว แทนที่จะ query ตรง Supabase แล้วเช็คเองฝั่ง client
    local decoded, err = apiRequest("verify_license", {
        licenseKey = userKey,
        hwid = getHwid(),
        placeId = tostring(game.PlaceId)
    })

    if err or not decoded then
        kick("Cannot reach license server. Try again.")
        return false
    end

    if not decoded.ok then
        local reason = decoded.reason
        if reason == "banned" then
            kick("Your key has been banned.")
        elseif reason == "expired" then
            kick("Your key has expired.")
        elseif reason == "hwid_mismatch" then
            kick("HWID mismatch.")
        elseif reason == "wrong_game" then
            kick("This key is not valid for this game.")
        else
            kick("Invalid key.")
        end
        return false
    end

    -- ผ่านทุกเงื่อนไข
    return true
end

--// ==================== ENTRY POINT ====================
local verified = checkKey()

if verified then
    -- TODO: โหลดสคริปต์หลักต่อจากตรงนี้ เช่น
    -- loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Reaper/XSTAHUB/main/Main.lua"))()
end


local Players = game:GetService("Players")
local LocalPlr = Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = LocalPlr

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
    Icon = "rbxassetid://81823976272367",
    Background = "https://img1.pic.in.th/images/5573a1c232fced2ac60da9136ae9ea30.jpg1",
    HideSearchBar = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "สวัสดี " .. LocalPlr.Name, Duration = 3 })
        end
    }
})

-- Toggle Button
local old = LocalPlr:WaitForChild("PlayerGui"):FindFirstChild("XephexToggleGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "XephexToggleGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = LocalPlr:WaitForChild("PlayerGui")

local BTN_W, BTN_H = 44, 44
local circle = Instance.new("Frame")
circle.Size = UDim2.fromOffset(BTN_W, BTN_H)
circle.Position = UDim2.fromOffset(24, 200)
circle.BackgroundColor3 = Color3.fromHex("0d0d0d")
circle.BorderSizePixel = 0
circle.Parent = gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromHex("00FFC8")
stroke.Parent = circle

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.fromOffset(BTN_W + 6, BTN_H + 6)
shadow.Position = UDim2.fromOffset(-3, -3)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://2"
shadow.ImageColor3 = Color3.new(1, 1, 1)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = 0
shadow.Parent = circle

local icon = Instance.new("ImageLabel")
icon.Name = "Icon"
icon.Size = UDim2.fromOffset(55, 55)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.new(0.5, 0, 0.5, 0)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://81823976272367"
icon.ImageColor3 = Color3.new(1, 1, 1)
icon.ScaleType = Enum.ScaleType.Fit
icon.ResampleMode = Enum.ResamplerMode.Default
icon.ImageTransparency = 0
icon.ClipsDescendants = true
icon.ZIndex = 2
icon.Parent = circle

local dragging, hasMoved, activeInput = false, false, nil
local dragStart, frameStart
local DRAG_THRESHOLD = 6

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

UIS.InputChanged:Connect(function(input)
    if dragging and input == activeInput then
        local delta = input.Position - dragStart
        if delta.Magnitude > DRAG_THRESHOLD then hasMoved = true end
        circle.Position = UDim2.fromOffset(frameStart.X + delta.X, frameStart.Y + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == activeInput then
        dragging = false
        activeInput = nil
        if not hasMoved then
            if Window then Window:Toggle() end
        end
    end
end)

if Window then Window:EditOpenButton({ Enabled = false }) end

-- Tabs
local ConfigManager = Window.ConfigManager
local MyConfig = ConfigManager:CreateConfig("FishIt")

local TabLog      = Window:Tab({ Title = "Log",      Icon = "crown"    })
local TabMain     = Window:Tab({ Title = "Main",     Icon = "menu"     })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Log Tab
TabLog:Section({ Title = "Credit" })
TabLog:Button({
    Title = "Discord", Desc = "ดิสพูดคุย/สอบถาม",
    Callback = function()
        setclipboard("https://discord.gg/rNKGmeyAHf")
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอก Discord Link แล้ว", Duration = 5 })
    end
})
TabLog:Button({
    Title = "YouTube", Desc = "ยูทูป",
    Callback = function()
        setclipboard("https://www.youtube.com/@x2Zeroo")
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอก YouTube Link แล้ว", Duration = 5 })
    end
})

-- Key Website Section (ปุ่ม Generate Key อยู่ด้านล่างของไฟล์ หลังจุดที่ประกาศ
-- apiKey/RegisterAPIKey แล้ว เพื่อไม่ให้ callback อ้างถึงตัวแปรที่ยังไม่มีอยู่)
local KeySec = TabMain:Section({ Title = "Key Website", Icon = "key", Box = true, TextSize = 18, Opened = false })

KeySec:Paragraph({
    Title = "คำเตือน",
    Desc = "คีย์ของคุณเป็นข้อมูลลับ ห้ามเผยแพร่คีย์ของคุณให้คนอื่นรู้โดยเด็ดขาด หากเผยแพร่ทางเราจะไม่รับผิดชอบทุกกรณี",
    Image = "shield-alert",
    ImageSize = 20,
    Color = "White"
})

local mailboxConfig = {
    targetName = "", note = "",
    selectedSpecialSeeds = {},
    selectedSeeds = {}, selectedGear = {}, selectedCrates = {}, selectedPets = {}, selectedSeedPacks = {},
    quantity = 1
}

local categoryItems = {
    SpecialSeeds = {
        "Gold Seed", "Mega Seed", "Rainbow Seed"
    },
    Seeds = {
        "Carrot","Strawberry","Blueberry","Tulip","Tomato","Apple","Bamboo","Corn","Cactus","Pineapple",
        "Mushroom","Green Bean","Banana","Grape","Coconut","Mango","Rocket Pop","Dragon Fruit","Acorn","Cherry",
        "Sunflower","Fire Fern","Venus Fly Trap","Pomegranate","Poison Apple","Venom Spitter","Briar Rose",
        "Moon Bloom","Hypno Bloom","Dragon's Breath","Ghost Pepper","Poison Ivy","Baby Cactus","Glow Mushroom",
        "Romanesco","Horned Melon"
    },
    Gear = {
        "Common Sprinkler","Common Watering Can","Sign","Uncommon Sprinkler","Rare Sprinkler","Trowel",
        "Jump Mushroom","Speed Mushroom","Lantern","Megaphone","Shrink Mushroom","Supersize Mushroom","Gnome",
        "Flashbang","Basic Pot","Legendary Sprinkler","Teleporter","Invisibility Mushroom","Wheelbarrow",
        "Player Magnet","Strawberry Sniper","Super Watering Can","Super Sprinkler","Grappling Hook"
    },
    Pets = {
        "Frog","Bunny","Owl","Deer","Turtle","Robin","Bee","Butterfly","Monkey","Golden Dragonfly",
        "Unicorn","Bear","Bald Eagle","Firefly","Raccoon","Black Dragon","Ice Serpent"
    },
    Crates = {
        "Ladder Crate","Bench Crate","Light Crate","Sign Crate","Arch Crate","Roleplay Crate",
        "Picture Frame Crate","Bridge Crate","Spring Crate","Seesaw Crate","Conveyor Crate",
        "Owner Door Crate","Bear Trap Crate","Fence Crate","Teleporter Pad Crate"
    },
    SeedPacks = {
        "Common Seed Pack","Uncommon Seed Pack","Rare Seed Pack","Legendary Seed Pack",
        "Mythic Seed Pack","Super Seed Pack","Secret Seed Pack"
    }
}

local itemToRealCategory = {
    ["Common Sprinkler"]      = "Sprinklers",
    ["Uncommon Sprinkler"]    = "Sprinklers",
    ["Rare Sprinkler"]        = "Sprinklers",
    ["Legendary Sprinkler"]   = "Sprinklers",
    ["Super Sprinkler"]       = "Sprinklers",
    ["Common Watering Can"]   = "WateringCans",
    ["Super Watering Can"]    = "WateringCans",
    ["Jump Mushroom"]         = "Mushrooms",
    ["Speed Mushroom"]        = "Mushrooms",
    ["Shrink Mushroom"]       = "Mushrooms",
    ["Supersize Mushroom"]    = "Mushrooms",
    ["Invisibility Mushroom"] = "Mushrooms",
    ["Gnome"]                 = "Gnomes",
    ["Trowel"]                = "Trowels",
    ["Sign"]                  = "Props",
    ["Lantern"]               = "Props",
    ["Megaphone"]             = "Props",
    ["Flashbang"]             = "Props",
    ["Basic Pot"]             = "EmptyPots",
    ["Teleporter"]            = "Props",
    ["Wheelbarrow"]           = "Props",
    ["Player Magnet"]         = "Props",
    ["Strawberry Sniper"]     = "Props",
    ["Grappling Hook"]        = "Props",
    ["Common Seed Pack"]      = "SeedPacks",
    ["Uncommon Seed Pack"]    = "SeedPacks",
    ["Rare Seed Pack"]        = "SeedPacks",
    ["Legendary Seed Pack"]   = "SeedPacks",
    ["Mythic Seed Pack"]      = "SeedPacks",
    ["Super Seed Pack"]       = "SeedPacks",
    ["Secret Seed Pack"]      = "SeedPacks",
    ["Raccoon"]               = "Raccoons",
}

local function ResolveGearCategory(itemName)
    return itemToRealCategory[itemName] or "Gear"
end

local function StripSeedSuffix(name)
    return name:gsub(" Seed$", "")
end

-- ========================================
-- API Config (ผ่าน data.js — ไม่มี Supabase key ในสคริปต์อีกต่อไป)
-- ========================================

local MAILBOX_API_URL    = "https://dashboard.xephex.xyz/api/data"
local MAILBOX_GAME_SECRET = "aJ7mQ9xLp2VnR5kTf8HyW3cDs6ZuEb1Ni4PoXv0GrCl9MsUwK2YqFt7BhJe5AzDn8CxLm3PvRq6TsHy1WkZu9EbN4GjX2fVa0McLp7Qr5" -- ต้องตรงกับ GAME_SHARED_SECRET ใน Vercel env
local POLL_INTERVAL      = 2
local MAX_POLL_BACKOFF   = 60 -- วินาที เพดาน backoff กัน request ถี่เกินตอน server ล่ม/network มีปัญหาต่อเนื่อง
local apiKey = nil

-- ========================================
-- Persist apiKey across sessions (writefile/readfile)
-- ========================================
-- เดิม apiKey เป็นแค่ local variable ในหน่วยความจำ -> รีเซ็ตเป็น nil ทุกครั้งที่
-- join server ใหม่ ทำให้ RegisterAPIKey() เรียก action "register" โดยไม่มี apiKey
-- แนบไปด้วยเสมอ (เพราะตอนนั้น apiKey ยังเป็น nil) ซึ่งพอฝั่ง server เปลี่ยนมาบังคับ
-- ต้องพิสูจน์ apiKey เดิมสำหรับ user ที่เคย register แล้ว จะทำให้ผู้เล่นเดิมโดน
-- "apiKey mismatch" ทุกครั้งที่ join ใหม่ ต้องเก็บ apiKey ลงไฟล์ให้ข้าม session ได้จริง
--
-- ไฟล์เดียวใช้ร่วมกันทุก account (xephex_apikey.txt) เก็บเป็น JSON list ของ
-- {userId, username, apiKey} รองรับหลาย account บนเครื่อง/executor เดียวกัน
-- แทนที่จะแยกไฟล์ตาม userId แบบเดิม (xephex_apikey_<id>.txt)
local API_KEY_FILE = "xephex_apikey.txt"

-- อ่านทั้งไฟล์ออกมาเป็น list ของ entry ({userId, username, apiKey})
-- คืนค่า {} เสมอถ้าไฟล์ไม่มี/อ่านไม่ได้/parse ไม่ได้ (กัน error ต่อเนื่อง ไม่ throw)
local function LoadApiKeyStore()
    if not (isfile and readfile) then return {} end
    local ok, exists = pcall(isfile, API_KEY_FILE)
    if not ok or not exists then return {} end
    local okRead, content = pcall(readfile, API_KEY_FILE)
    if not okRead or not content or content == "" then return {} end
    local okDec, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    if not okDec or type(decoded) ~= "table" then return {} end
    return decoded
end

local function SaveApiKeyStore(store)
    if not writefile then return end
    local okEnc, encoded = pcall(HttpService.JSONEncode, HttpService, store)
    if not okEnc then return end
    pcall(writefile, API_KEY_FILE, encoded)
end

-- หา apiKey ของ userId ปัจจุบันจากไฟล์รวม (ไม่เจอ -> nil)
local function LoadSavedApiKey()
    local store = LoadApiKeyStore()
    local userId = LocalPlayer.UserId
    for _, entry in ipairs(store) do
        if entry.userId == userId then
            return (entry.apiKey and entry.apiKey ~= "") and entry.apiKey or nil
        end
    end
    return nil
end

-- update entry เดิมถ้ามี userId นี้อยู่แล้ว หรือเพิ่ม entry ใหม่ต่อท้าย -- ไม่แตะ
-- entry ของ userId อื่นเลย เพื่อรองรับหลาย account ในไฟล์เดียวกัน
local function SaveApiKey(key)
    if not (key and key ~= "") then return end
    local userId = LocalPlayer.UserId
    local username = LocalPlayer.Name
    local store = LoadApiKeyStore()

    local found = false
    for _, entry in ipairs(store) do
        if entry.userId == userId then
            entry.apiKey = key
            entry.username = username
            found = true
            break
        end
    end
    if not found then
        table.insert(store, { userId = userId, username = username, apiKey = key })
    end

    SaveApiKeyStore(store)
end

-- ลบเฉพาะ entry ของ userId นี้ออกจากไฟล์รวม (ไม่แตะ entry ของ account อื่น)
local function RemoveApiKeyEntry(userId)
    local store = LoadApiKeyStore()
    local newStore = {}
    for _, entry in ipairs(store) do
        if entry.userId ~= userId then
            table.insert(newStore, entry)
        end
    end
    SaveApiKeyStore(newStore)
end

local Networking, PlayerState, MailboxItemCatalog

repeat task.wait() until LocalPlayer and LocalPlayer:IsA("Player")

apiKey = LoadSavedApiKey()

local s, r
s, r = pcall(function() return require(ReplicatedStorage.SharedModules.Networking) end)
if s then Networking = r end
s, r = pcall(function() return require(ReplicatedStorage.ClientModules.PlayerStateClient) end)
if s then PlayerState = r end
s, r = pcall(function() return require(LocalPlayer.PlayerScripts.Controllers.MailboxController.MailboxItemCatalog) end)
if s then MailboxItemCatalog = r end

-- ========================================
-- API HTTP
-- ========================================

-- เรียก data.js ด้วย action-based POST body (แทน SupabaseRequest ตรงเดิมทั้งหมด)
-- คืนค่า: decodedTable เมื่อสำเร็จ, nil เมื่อ request ล้มเหลว/ไม่ใช่ 2xx/parse ไม่ได้

local function ApiRequest(action, payload)
    local body = payload or {}
    body.action = action
    if apiKey then body.apiKey = apiKey end

    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Game-Secret"] = MAILBOX_GAME_SECRET
    }

    local okEnc, encoded = pcall(HttpService.JSONEncode, HttpService, body)
    if not okEnc then
        return nil
    end

    local requestFunc = (syn and syn.request)
        or (http and http.request)
        or (type(request) == "function" and request)
        or nil

    local ok, response

    if requestFunc then
        ok, response = pcall(function()
            return requestFunc({
                Url = MAILBOX_API_URL,
                Method = "POST",
                Headers = headers,
                Body = encoded
            })
        end)
    else
        ok, response = pcall(function()
            return HttpService:RequestAsync({
                Url = MAILBOX_API_URL,
                Method = "POST",
                Headers = headers,
                Body = encoded
            })
        end)
    end

    if not ok or not response then
        return nil
    end

    local status = response.StatusCode or response.status_code
    local bodyRes = response.Body or response.body

    -- เดิม non-2xx คืน nil ทันที ทำให้ caller เห็นแค่ "ล้มเหลว" แยกแยะไม่ได้ว่า
    -- เป็น network error หรือ server ปฏิเสธด้วยเหตุผลที่ระบุ (เช่น 403 "apiKey
    -- mismatch") ตอนนี้ยัง parse body ให้ก่อน แล้วแนบ status/ok ให้ caller เช็คเอง
    if not status then return nil end

    if not bodyRes or bodyRes == "" then
        if status >= 200 and status < 300 then return true end
        return nil
    end

    local okDec, decoded = pcall(HttpService.JSONDecode, HttpService, bodyRes)
    if not okDec then
        return nil
    end

    if status < 200 or status >= 300 then
        if type(decoded) == "table" then
            decoded._httpStatus = status
            return decoded
        end
        return nil
    end

    return decoded
end

-- Helpers
local function GetInventory()
    if not PlayerState then return {} end
    local ok, replica = pcall(function() return PlayerState:GetLocalReplica() end)
    if not ok or not replica then return {} end
    return (replica.Data and replica.Data.Inventory) or {}
end

local function GetRbxThumb(userId)
    local ok, res = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    if ok and res and res ~= "" then return res end
    return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function GetUserIdByName(playerName)
    if type(playerName) == "number" then return playerName, nil end
    if not playerName or playerName == "" then return nil, "ไม่ระบุชื่อ" end
    for _, player in Players:GetPlayers() do
        if player.Name:lower() == playerName:lower()
            or player.DisplayName:lower() == playerName:lower() then
            return player.UserId, nil
        end
    end
    if Networking and Networking.Mailbox and Networking.Mailbox.LookupPlayer then
        local s1, r1 = pcall(function() return Networking.Mailbox.LookupPlayer:InvokeServer(playerName) end)
        if s1 and r1 and r1 > 0 then return r1, nil end
        local s2, r2 = pcall(function() return Networking.Mailbox.LookupPlayer:Fire(playerName) end)
        if s2 and r2 and r2 > 0 then return r2, nil end
    end
    return nil, "ไม่พบผู้เล่นชื่อ " .. tostring(playerName)
end

local function SendGift(targetUserId, items, note)
    if not targetUserId or targetUserId <= 0 then return false, "Invalid target user" end
    if not items or #items == 0 then return false, "No items to send" end
    if not Networking or not PlayerState or not MailboxItemCatalog then
        return false, "Dependencies not loaded"
    end
    local replica
    local ok0, rep = pcall(function() return PlayerState:GetLocalReplica() end)
    if ok0 then replica = rep end
    if not replica or not replica.Data or not replica.Data.Inventory then
        return false, "Cannot access inventory"
    end
    local inventory = replica.Data.Inventory
    local validItems = {}
    for _, item in ipairs(items) do
        local category = item.Category
        local itemKey = item.ItemKey
        local count = item.Count or 1
        local giftable
        local okG, resG = pcall(function() return MailboxItemCatalog.IsGiftable(category) end)
        if okG then giftable = resG end
        if not giftable then return false, string.format("Category '%s' is not giftable", category) end
        local invData = inventory[category]
        if not invData then return false, string.format("No '%s' in inventory", category) end
        local available = 0
        if category == "Pets" or category == "HarvestedFruits" then
            for id in pairs(invData) do if id == itemKey then available = 1 break end end
        else
            available = invData[itemKey] or 0
        end
        if available < count then
            return false, string.format("Not enough '%s' (have %d, need %d)", itemKey, available, count)
        end
        table.insert(validItems, { Category = category, ItemKey = itemKey, Count = count })
    end
    if #validItems == 0 then return false, "No valid items to send" end
    local ok, res = pcall(function()
        return Networking.Mailbox.SendBatch:Fire(targetUserId, validItems, note or "")
    end)
    if not ok then return false, "Failed to send: " .. tostring(res) end
    return true, "Gift sent successfully"
end

-- ========================================
-- SendGiftChunked: ส่งจำนวนมาก (สูงสุด 200000 ตาม data.js) แบ่งเป็น chunk
-- ละไม่เกิน 9999 ต่อครั้ง (กัน mailbox limit ของเกม) พร้อม verify-after-send
-- เพราะ SendGift ยิงแบบ fire-and-forget ไม่มี ack จาก server ว่าของหายจริง —
-- ถ้าโดนคูลดาวน์ mailbox ของฝั่งเกม การ Fire จะไม่ error แต่ inventory ก็จะ
-- ไม่ลด ต้องอ่าน inventory เทียบก่อน-หลังทุก chunk เพื่อยืนยัน
--
-- ข้อจำกัดที่ต้องรู้: GetInventory() อ่านจาก PlayerState replica (client-side
-- cache) ซึ่ง sync จาก server แบบ async — มี "หน่วงตามธรรมชาติ" ก่อนที่ตัวเลข
-- ในกระเป๋าจะอัปเดตตามการส่งจริง ถ้า sync ช้ากว่า 0.1s ที่รอ อาจเห็นว่า "ยัง
-- ไม่ลด" ทั้งที่จริงส่งสำเร็จแล้วรอ replicate อยู่ -> โค้ดนี้จะ retry ส่งซ้ำ
-- ซึ่งอาจทำให้ส่งเกินจำนวนจริงได้เล็กน้อยถ้า replica sync ช้ากว่าที่คาด (แลก
-- กับความเรียบง่ายตามที่ผู้ใช้ยืนยันไว้ — ไม่ implement ack-based confirmation
-- เพราะ SendBatch เป็น RemoteEvent ไม่มี return value ให้ใช้)
--
-- Pets / HarvestedFruits เป็น unique-id item (นับเป็น 1 เสมอ ไม่มี "จำนวน" ให้
-- แบ่ง chunk) — ถ้า Count > available (รวมถึง Count > 1 ตอน available = 1)
-- ปฏิเสธ item นั้นทันทีตาม validation เดิมใน SendGift (available < count)
-- ไม่ retry เพราะของไม่มีทางเพิ่มขึ้นเองระหว่างรอ
--
-- คืนค่า: itemResult = {
--   ItemKey, Category, Requested, Sent, Status ("sent" | "partial" | "rejected"),
--   Reason (string, เฉพาะตอน rejected/partial)
-- }
local MAX_PER_SEND = 9999
local MAX_RETRY_PER_CHUNK = 10
local RETRY_WAIT = 0.1

local function GetAvailableCount(category, itemKey)
    local inventory = GetInventory()
    local invData = inventory[category]
    if not invData then return 0 end
    if category == "Pets" or category == "HarvestedFruits" then
        for id in pairs(invData) do
            if id == itemKey then return 1 end
        end
        return 0
    end
    return invData[itemKey] or 0
end

local function SendGiftChunked(targetUserId, category, itemKey, totalCount, note)
    local itemResult = {
        ItemKey = itemKey, Category = category,
        Requested = totalCount, Sent = 0,
        Status = "rejected", Reason = nil
    }

    if not targetUserId or targetUserId <= 0 then
        itemResult.Reason = "Invalid target user"
        return itemResult
    end
    if not totalCount or totalCount <= 0 then
        itemResult.Reason = "Invalid count"
        return itemResult
    end

    -- ตรวจของในกระเป๋าก่อนเริ่มทั้งหมด — ถ้าน้อยกว่าที่ขอ ปฏิเสธทันที ไม่ส่งเลย
    -- แม้แต่ chunk แรก ตามที่ผู้ใช้ยืนยัน (ไม่ใช่ "ส่งเท่าที่มี")
    local availableAtStart = GetAvailableCount(category, itemKey)
    if availableAtStart < totalCount then
        itemResult.Reason = string.format(
            "ของในกระเป๋าไม่พอ: มี %d ต้องการส่ง %d", availableAtStart, totalCount)
        return itemResult
    end

    local remaining = totalCount
    local totalSent = 0

    while remaining > 0 do
        local chunkTarget = math.min(remaining, MAX_PER_SEND)
        local chunkSentSoFar = 0
        local retries = 0

        while chunkSentSoFar < chunkTarget do
            local needNow = chunkTarget - chunkSentSoFar

            -- เช็คของก่อนยิงรอบนี้ (เผื่อของหมดกลางทางจากสาเหตุอื่น เช่น trade พร้อมกัน)
            local availableNow = GetAvailableCount(category, itemKey)
            if availableNow < needNow then
                itemResult.Sent = totalSent
                itemResult.Status = (totalSent > 0) and "partial" or "rejected"
                itemResult.Reason = string.format(
                    "ของในกระเป๋าไม่พอระหว่างส่ง: มี %d ต้องการอีก %d", availableNow, needNow)
                return itemResult
            end

            local beforeCount = GetAvailableCount(category, itemKey)
            local ok, msg = SendGift(targetUserId, {
                { Category = category, ItemKey = itemKey, Count = needNow }
            }, note)

            if not ok then
                -- ส่งไม่สำเร็จระดับ request (ไม่ใช่คูลดาวน์) — validation ล้มเหลว/
                -- dependencies ไม่โหลด ฯลฯ ไม่มีประโยชน์ที่จะ retry ซ้ำแบบเดิม
                itemResult.Sent = totalSent
                itemResult.Status = (totalSent > 0) and "partial" or "rejected"
                itemResult.Reason = "SendGift error: " .. tostring(msg)
                return itemResult
            end

            task.wait(RETRY_WAIT)

            local afterCount = GetAvailableCount(category, itemKey)
            local actualDelta = beforeCount - afterCount

            if actualDelta >= needNow then
                -- ลดตรง (หรือมากกว่า กรณี replica sync คลาดเคลื่อนเล็กน้อย) ถือว่า
                -- chunk ย่อยนี้สำเร็จเต็มจำนวนที่ขอรอบนี้
                chunkSentSoFar = chunkSentSoFar + needNow
                totalSent = totalSent + needNow
                retries = 0
            elseif actualDelta > 0 then
                -- ลดบางส่วน (โดนคูลดาวน์กันครึ่งทาง) — นับเท่าที่ลดจริง แล้ว retry
                -- ส่วนที่เหลือในรอบถัดไปของ while เดิม (ไม่เพิ่ม retries เพราะมี
                -- ความคืบหน้าจริง ไม่ใช่ค้างสนิท)
                chunkSentSoFar = chunkSentSoFar + actualDelta
                totalSent = totalSent + actualDelta
            else
                -- ไม่ลดเลย — โดนคูลดาวน์เต็มๆ นับ retry
                retries = retries + 1
                if retries >= MAX_RETRY_PER_CHUNK then
                    itemResult.Sent = totalSent
                    itemResult.Status = (totalSent > 0) and "partial" or "rejected"
                    itemResult.Reason = string.format(
                        "ครบ %d ครั้ง ยังส่งไม่สำเร็จ (คูลดาวน์ค้าง) ที่ %d/%d",
                        MAX_RETRY_PER_CHUNK, totalSent, totalCount)
                    return itemResult
                end
            end
        end

        remaining = remaining - chunkTarget
    end

    itemResult.Sent = totalSent
    itemResult.Status = "sent"
    return itemResult
end

-- ========================================
-- API Actions (แทน Supabase Actions เดิม)
-- ========================================

local function RegisterAPIKey()
    if apiKey then return end
    local userId = LocalPlayer.UserId
    local username = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName or username

    local decoded = ApiRequest("register", {
        userId = userId,
        username = username,
        displayName = displayName,
        inventory = GetInventory()
    })

    if decoded and decoded.ok and decoded.apiKey then
        apiKey = decoded.apiKey
        SaveApiKey(apiKey) -- เก็บลงไฟล์ทันที กัน apiKey หายตอน join server ใหม่
        return
    end

    -- apiKey ที่เคยเซฟไว้ไม่ตรงกับที่ server มี (เช่น ถูกลบ/รีเซ็ตฝั่ง admin) —
    -- ล้างไฟล์เก่าทิ้งแล้วลองสมัครใหม่อีกครั้งแบบไม่มี apiKey แนบไป (เข้าเงื่อนไข
    -- "ยังไม่เคย register" ฝั่ง server ถ้า user_id นั้นถูกลบออกจากตารางไปแล้วจริงๆ)
    if decoded and decoded.error == "apiKey mismatch" then
        RemoveApiKeyEntry(userId)
        decoded = ApiRequest("register", {
            userId = userId,
            username = username,
            displayName = displayName,
            inventory = GetInventory()
        })
        if decoded and decoded.ok and decoded.apiKey then
            apiKey = decoded.apiKey
            SaveApiKey(apiKey)
        end
    end
    -- ล้มเหลว: apiKey ยังเป็น nil — ปุ่ม "Generate Key" แจ้ง error ให้ผู้เล่นเห็นเอง
    -- (ไม่ auto-retry ที่นี่ กัน spam request ตอน network มีปัญหาต่อเนื่อง)
end

local function SyncInventory()
    if not apiKey then return end
    ApiRequest("sync_inventory", { inventory = GetInventory() })
    -- best-effort: ไม่เช็ค return, รอบถัดไปจาก loop จะ sync ใหม่เองอยู่แล้ว
end

-- รวม mark status + record history เป็น 1 เรียก HTTP (ตรงกับ action "mark_command"
-- ฝั่ง server ที่ atomic กว่าเดิม — กัน race ที่ PATCH status สำเร็จแต่ POST history ล้มเหลว
-- แล้ว response กลายเป็น error ทั้งที่ status อัปเดตไปแล้วจริง)
local function MarkCommandProcessed(commandId, targetName, items, note, status)
    ApiRequest("mark_command", {
        commandId = commandId,
        targetName = targetName,
        items = items,
        note = note,
        status = status
    })
end

local pollFailCount = 0

local function PollCommands()
    while true do
        -- exponential backoff แบบมีเพดาน กัน spam request ตอน server ล่ม/network หลุดต่อเนื่อง
        local waitTime = POLL_INTERVAL
        if pollFailCount > 0 then
            waitTime = math.min(POLL_INTERVAL * (2 ^ math.min(pollFailCount, 6)), MAX_POLL_BACKOFF)
        end
        task.wait(waitTime)

        if not apiKey then continue end

        local decoded = ApiRequest("poll_command", {})
        if not decoded then
            pollFailCount = pollFailCount + 1
            continue
        end
        pollFailCount = 0

        if not decoded.command then continue end
        local command = decoded.command
        local targetName = command.target_name
        local items = command.items or {}
        local note = command.note or ""

        local targetId, err = GetUserIdByName(targetName)
        if not targetId then
            MarkCommandProcessed(command.id, targetName, items, note, "failed")
            continue
        end

        -- ส่งทีละ item ด้วย SendGiftChunked (แทนยิงรวมทุก item ผ่าน SendGift ครั้งเดียว)
        -- เพราะแต่ละ item อาจมี Count สูงถึง 200000 ต้อง chunk+verify แยกต่อ item —
        -- Count ผูกกับ ItemKey เฉพาะตัว ไม่ใช่ pool รวม
        local anySent = false
        local breakdownParts = {}

        for _, item in ipairs(items) do
            local result = SendGiftChunked(targetId, item.Category, item.ItemKey, item.Count or 1, note)
            if result.Status == "sent" or result.Status == "partial" then
                anySent = true
            end

            local statusLabel = (result.Status == "sent" and "สำเร็จ")
                or (result.Status == "partial" and "บางส่วน")
                or "ไม่สำเร็จ"

            local part = string.format("%s x%d: %s (%d/%d)",
                result.ItemKey, result.Requested, statusLabel, result.Sent, result.Requested)
            if result.Reason then
                part = part .. " - " .. result.Reason
            end
            table.insert(breakdownParts, part)
        end

        -- data.js รองรับ status แค่ "sent"/"failed" (ไม่มี "partial") — mark "sent"
        -- ถ้ามีอย่างน้อย 1 item สำเร็จ/บางส่วน ตามที่ผู้ใช้ยืนยัน โดยแนบ breakdown
        -- ต่อ item ไว้ใน note เพื่อให้เห็นว่าอันไหนสำเร็จ/ไม่สำเร็จจริง
        local breakdownNote = note
        if #breakdownParts > 0 then
            local breakdownStr = table.concat(breakdownParts, " | ")
            breakdownNote = (note ~= "" and (note .. " || ") or "") .. breakdownStr
        end

        local finalStatus = anySent and "sent" or "failed"
        MarkCommandProcessed(command.id, targetName, items, breakdownNote, finalStatus)
    end
end


-- ========================================
-- Main Tab — Mailbox UI
-- ========================================

local MailSec = TabMain:Section({ Title = "Mailbox", Icon = "gift", Box = true, TextSize = 18, Opened = false })

KeySec:Button({
    Title = "Generate Key", Desc = "สร้างคีย์",
    Callback = function()
        if not apiKey or apiKey == "" then
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "กำลังสร้างคีย์...", Duration = 3 })
            task.spawn(function()
                RegisterAPIKey()
                task.wait(0.1)
                if apiKey and apiKey ~= "" then
                    if setclipboard then
                        setclipboard(apiKey)
                        WindUI:Notify({ Title = "XEPHEX HUB", Content = "Key ถูกคัดลอกไปคลิปบอร์ดแล้ว", Duration = 4 })
                    else
                        WindUI:Notify({ Title = "XEPHEX HUB", Content = "Key: " .. apiKey, Duration = 6 })
                    end
                else
                    WindUI:Notify({ Title = "XEPHEX HUB", Content = "ล้มเหลว! โปรดติดต่อแอดมิน", Duration = 4 })
                end
            end)
            return
        end
        if setclipboard then
            setclipboard(apiKey)
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "Key ถูกคัดลอกไปคลิปบอร์ดแล้ว", Duration = 4 })
        else
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "Key: " .. apiKey, Duration = 6 })
        end
    end
})

MailSec:Input({
    Title = "UserName", Desc = "ชื่อ", Default = "",
    Callback = function(Value)
        local name = Value:match("^%s*(.-)%s*$") or ""
        mailboxConfig.targetName = name
        mailboxConfig._resolvedId = nil
        if name == "" then return end
        local userId, err = GetUserIdByName(name)
        if userId then
            mailboxConfig._resolvedId = userId
            task.spawn(function()
                local rbxIcon = GetRbxThumb(userId)
                WindUI:Notify({
                    Title = "XEPHEX HUB", Content = "พบผู้เล่น: " .. name,
                    Icon = rbxIcon, Background = rbxIcon,
                    BackgroundImageTransparency = 0.5, Duration = 5,
                })
            end)
        else
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "" .. err, Duration = 3 })
        end
    end
})

MailSec:Input({
    Title = "Note", Desc = "ข้อความ", Default = "",
    Callback = function(Value) mailboxConfig.note = Value end
})

MailSec:Dropdown({
    Title = "Select Special Seeds", Values = categoryItems["SpecialSeeds"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกเมล็ดพิเศษ", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedSpecialSeeds = type(v) == "table" and v or {v} end
})
MailSec:Dropdown({
    Title = "Select Seeds", Values = categoryItems["Seeds"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกเมล็ด", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedSeeds = type(v) == "table" and v or {v} end
})
MailSec:Dropdown({
    Title = "Select Gear", Values = categoryItems["Gear"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกเกียร์", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedGear = type(v) == "table" and v or {v} end
})
MailSec:Dropdown({
    Title = "Select Crates", Values = categoryItems["Crates"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกกล่อง", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedCrates = type(v) == "table" and v or {v} end
})
MailSec:Dropdown({
    Title = "Select Pets", Values = categoryItems["Pets"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกสัตว์", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedPets = type(v) == "table" and v or {v} end
})
MailSec:Dropdown({
    Title = "Select Seed Packs", Values = categoryItems["SeedPacks"],
    Multi = true, AllowNone = true, Default = {}, Desc = "เลือกซองเมล็ด", SearchBarEnabled = true,
    Callback = function(v) mailboxConfig.selectedSeedPacks = type(v) == "table" and v or {v} end
})

MailSec:Input({
    Title = "Amount", Desc = "จำนวน", Default = "1",
    Callback = function(Value)
        local q = tonumber(Value)
        mailboxConfig.quantity = (q and q > 0) and math.floor(q) or 1
    end
})

MailSec:Button({
    Title = "Send Gift", Desc = "ส่งของ",
    Callback = function()
        if mailboxConfig.targetName == "" then
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "❌ กรุณากรอกชื่อผู้เล่น", Duration = 3 })
            return
        end
        local targetId = mailboxConfig._resolvedId
        if not targetId then
            local err
            targetId, err = GetUserIdByName(mailboxConfig.targetName)
            if not targetId then
                WindUI:Notify({ Title = "XEPHEX HUB", Content = "❌ " .. err, Duration = 3 })
                return
            end
            mailboxConfig._resolvedId = targetId
        end
        local allItems = {}
        for _, sp   in ipairs(mailboxConfig.selectedSpecialSeeds) do table.insert(allItems, { Category = "Seeds",                  ItemKey = StripSeedSuffix(sp), Count = mailboxConfig.quantity }) end
        for _, seed in ipairs(mailboxConfig.selectedSeeds)        do table.insert(allItems, { Category = "Seeds",                  ItemKey = seed,                Count = mailboxConfig.quantity }) end
        for _, gear in ipairs(mailboxConfig.selectedGear)         do table.insert(allItems, { Category = ResolveGearCategory(gear), ItemKey = gear,                Count = mailboxConfig.quantity }) end
        for _, crate in ipairs(mailboxConfig.selectedCrates)      do table.insert(allItems, { Category = "Crates",                 ItemKey = crate,               Count = mailboxConfig.quantity }) end
        for _, pet  in ipairs(mailboxConfig.selectedPets)         do table.insert(allItems, { Category = "Pets",                   ItemKey = pet,                 Count = mailboxConfig.quantity }) end
        for _, sp2  in ipairs(mailboxConfig.selectedSeedPacks)    do table.insert(allItems, { Category = "SeedPacks",              ItemKey = sp2,                 Count = mailboxConfig.quantity }) end

        if #allItems == 0 then
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "❌ โปรดเลือกสิ่งของที่ต้องการส่ง", Duration = 3 })
            return
        end

        local sendChunks = {}
        for _, item in ipairs(allItems) do
            local remaining = item.Count
            while remaining > 0 do
                local chunkCount = math.min(remaining, MAX_PER_SEND)
                table.insert(sendChunks, { Category = item.Category, ItemKey = item.ItemKey, Count = chunkCount })
                remaining = remaining - chunkCount
            end
        end

        WindUI:Notify({ Title = "XEPHEX HUB", Content = "⏳ กำลังส่ง " .. #allItems .. " รายการ (" .. #sendChunks .. " ครั้ง) ให้ " .. mailboxConfig.targetName, Duration = 3 })
        task.spawn(function()
            local failedItems = {}
            for _, chunk in ipairs(sendChunks) do
                local ok, msg = SendGift(targetId, { chunk }, mailboxConfig.note)
                if not ok then
                    table.insert(failedItems, chunk.ItemKey .. " x" .. chunk.Count)
                end
            end
            local sent = #sendChunks - #failedItems
            if #failedItems == 0 then
                WindUI:Notify({ Title = "XEPHEX HUB", Content = "✅ ส่งครบ " .. sent .. "/" .. #sendChunks .. " ครั้งให้ " .. mailboxConfig.targetName .. " สำเร็จ!", Duration = 5 })
            else
                WindUI:Notify({ Title = "XEPHEX HUB", Content = "⚠️ ส่งสำเร็จ " .. sent .. "/" .. #sendChunks .. " ครั้ง\n❌ ล้มเหลว: " .. table.concat(failedItems, ", "), Duration = 6 })
            end
        end)
    end
})

local Keybind = TabSettings:Keybind({
    Title = "Keybind to open ui",
    Desc = "ปุ่นเปิดปิด Ui",
    Value = "F",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

TabSettings:Section({ Title = "JobId Tools" })
TabSettings:Button({
    Title = "Join Link", Desc = "คัดลอกลิ้งจอย",
    Callback = function()
        local placeId = game.PlaceId
        local jobId = game.JobId
        if jobId and jobId ~= "" then
            local joinLink = string.format(
                "https://www.roblox.com/games/start?placeId=%s&launchData=%s/%s",
                placeId, placeId, jobId)
            setclipboard(joinLink)
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอกลิงแล้ว!", Duration = 5, Icon = "rbxassetid://80283328189076" })
        else
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "ไม่เจอ JobId ของเซิร์ฟเวอร์นี้", Duration = 5, Icon = "rbxassetid://80283328189076" })
        end
    end
})
TabSettings:Button({
    Title = "Copy JobId", Desc = "คัดลอกไอดีเซิร์ฟเวอร์",
    Callback = function()
        setclipboard(tostring(game.JobId))
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "คัดลอก JobId แล้ว", Duration = 5, Icon = "rbxassetid://80283328189076" })
    end
})

local JobId = ""
TabSettings:Input({
    Title = "JobId", Placeholder = "ใส่ JobId", Default = "",
    Callback = function(Value) JobId = Value or "" end
})
TabSettings:Button({
    Title = "Teleport To JobId", Desc = "จอยเซิร์ฟเวอร์ด้วย JobId",
    Callback = function()
        if JobId ~= "" then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, JobId)
        else
            WindUI:Notify({ Title = "XEPHEX HUB", Content = "กรุณาใส่ JobId ก่อน", Duration = 5, Icon = "rbxassetid://80283328189076" })
        end
    end
})

-- ========================================
-- Startup
-- ========================================

task.spawn(RegisterAPIKey)

task.spawn(function()
    while true do
        task.wait(5)
        SyncInventory()
    end
end)

task.spawn(PollCommands)

task.defer(function()
    pcall(function()
        MyConfig:Load()
        WindUI:Notify({ Title = "XEPHEX HUB", Content = "Load", Duration = 1 })
    end)
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function() MyConfig:Save() end)
    end
end)

Window:OnClose(function()
    pcall(function() MyConfig:Save() end)
end)

LocalPlr.OnTeleport:Connect(function()
    pcall(function() MyConfig:Save() end)
end)