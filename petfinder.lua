-- Конфигурация
local CONFIG = {
    PETS_TO_FIND = {
        "Unicorn",
        "Raccon", 
        "Bear",
        "Golden Dragonfly"
    },
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1518242813605838994/cLUCW7ZvazCKK6mFn2KvVb5CZmYgAynx-5F9JFaCwpXnppCKs5J3LG9mtZLWlfGXSo51",
    SERVER_HOP_DELAY = 3,
    PET_PURCHASE_RANGE = 10,
    HOLD_E_DURATION = 2
}

-- Скрываем все возможные выводы
local function silenceAllOutput()
    print = function() end
    warn = function() end
    error = function() end
    if getgenv then getgenv().printoutput = false end
end

silenceAllOutput()

-- Сервисы
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Функция отправки в Discord
local function sendDiscordNotification(petName, serverId)
    local requestData = {
        content = "",
        embeds = {{
            title = "🐾 Найден питомец!",
            description = string.format("**Найден пет:** %s\n**Сервер:** %s\n**Время:** %s", 
                petName, serverId, os.date("%Y-%m-%d %H:%M:%S")),
            color = 65280,
            footer = {text = "Grow A Garden 2 - Pet Finder"}
        }}
    }
    
    local jsonData = HttpService:JSONEncode(requestData)
    
    pcall(function()
        syn.request({
            Url = CONFIG.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end)
end

-- Создание маленького уведомления в игре
local function createInGameNotification(petName)
    pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local oldNotif = playerGui:FindFirstChild("PetFoundNotification")
        if oldNotif then oldNotif:Destroy() end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PetFoundNotification"
        screenGui.Parent = playerGui
        screenGui.ResetOnSpawn = false
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 40)
        frame.Position = UDim2.new(0, 10, 1, -50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -10, 1, 0)
        textLabel.Position = UDim2.new(0, 5, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "🐾 Найден: " .. petName
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = frame
        
        frame.Position = UDim2.new(0, 10, 1, 10)
        local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {Position = UDim2.new(0, 10, 1, -50)})
        tween:Play()
        
        delay(5, function()
            pcall(function()
                local fadeTween = TweenService:Create(frame, TweenInfo.new(0.3), 
                    {BackgroundTransparency = 1})
                fadeTween:Play()
                fadeTween.Completed:Wait()
                screenGui:Destroy()
            end)
        end)
    end)
end

-- Функция поиска питомца в workspace
local function findPetInWorkspace(petNames)
    local workspace = game:GetService("Workspace")
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("Tool") then
            local objectName = obj.Name:lower()
            
            for _, petName in pairs(petNames) do
                if objectName:find(petName:lower()) then
                    return petName, obj
                end
            end
            
            local petAttribute = obj:GetAttribute("PetName")
            if petAttribute then
                for _, petName in pairs(petNames) do
                    if tostring(petAttribute):lower():find(petName:lower()) then
                        return petName, obj
                    end
                end
            end
        end
    end
    
    return nil, nil
end

-- Телепортация к объекту
local function teleportTo(target)
    if not target or not player.Character then return false end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return false end
    
    local targetPosition
    
    if target:IsA("Model") then
        local primaryPart = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
        if primaryPart then
            targetPosition = primaryPart.Position
        end
    elseif target:IsA("BasePart") then
        targetPosition = target.Position
    end
    
    if targetPosition then
        humanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
        return true
    end
    
    return false
end

-- Покупка питомца (зажатие E)
local function purchasePet()
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local purchaseObject = nil
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            if (obj.Parent.Position - character.HumanoidRootPart.Position).Magnitude < CONFIG.PET_PURCHASE_RANGE then
                purchaseObject = obj
                break
            end
        end
    end
    
    if not purchaseObject then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
        wait(CONFIG.HOLD_E_DURATION)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
        return true
    end
    
    purchaseObject:InputHoldBegin()
    wait(CONFIG.HOLD_E_DURATION)
    purchaseObject:InputHoldEnd()
    
    return true
end

-- Смена сервера
local function serverHop()
    local http = game:GetService("HttpService")
    local servers = {}
    
    pcall(function()
        local apiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
        
        local response = syn.request({
            Url = apiUrl,
            Method = "GET"
        })
        
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            
            if data and data.data then
                for _, server in pairs(data.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
            end
        end
    end)
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
    else
        TeleportService:Teleport(game.PlaceId, player)
    end
end

-- Главная функция поиска и покупки
local function searchAndPurchase()
    local foundPetName, foundPetObject = findPetInWorkspace(CONFIG.PETS_TO_FIND)
    
    if foundPetName and foundPetObject then
        if teleportTo(foundPetObject) then
            wait(0.5)
            purchasePet()
            
            local serverId = game.JobId
            sendDiscordNotification(foundPetName, serverId)
            createInGameNotification(foundPetName)
            
            wait(5)
        end
    else
        serverHop()
    end
end

-- Основной цикл
local function mainLoop()
    while true do
        pcall(function()
            searchAndPurchase()
        end)
        wait(CONFIG.SERVER_HOP_DELAY)
    end
end

-- Запуск
mainLoop()
