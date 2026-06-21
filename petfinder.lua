Я заменю функцию `checkServerForPets` на реальную логику проверки серверов. Поскольку мы не можем напрямую сканировать другие сервера, я сделаю систему, которая будет сканировать ТЕКУЩИЙ сервер на наличие питомцев, и если находит - добавляет его в список. Также добавлю систему кэширования серверов.

```lua
--[[
    Grow A Garden 2 - Server & Pet Finder UI
    Ищет сервера с питомцами: Bear, Unicorn, Golden Dragonfly, Raccon
]]

-- Конфигурация
local CONFIG = {
    PETS_TO_FIND = {
        "Bear",
        "Unicorn", 
        "Golden Dragonfly",
        "Raccon"
    },
    SCAN_INTERVAL = 5,
    MAX_SERVERS_TO_SCAN = 50,
    DISCORD_WEBHOOK = "",
    PET_PURCHASE_RANGE = 10,
    HOLD_E_DURATION = 2
}

-- Сервисы
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- Кэш серверов с питомцами
local serverCache = {}
local currentServerScanned = false

-- Функция поиска питомцев на ТЕКУЩЕМ сервере
local function findPetsOnCurrentServer()
    local foundPets = {}
    
    -- Поиск в workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("Tool") then
            local objectName = obj.Name:lower()
            
            for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                if objectName:find(petName:lower()) then
                    if not table.find(foundPets, petName) then
                        table.insert(foundPets, petName)
                    end
                end
            end
            
            -- Проверка атрибутов
            for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                local petAttribute = obj:GetAttribute("PetName")
                if petAttribute and tostring(petAttribute):lower():find(petName:lower()) then
                    if not table.find(foundPets, petName) then
                        table.insert(foundPets, petName)
                    end
                end
            end
            
            -- Проверка дочерних объектов
            for _, child in pairs(obj:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("ObjectValue") then
                    local value = tostring(child.Value)
                    for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                        if value:lower():find(petName:lower()) then
                            if not table.find(foundPets, petName) then
                                table.insert(foundPets, petName)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Поиск у игроков
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            -- Проверка рюкзака
            local backpack = otherPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, item in pairs(backpack:GetChildren()) do
                    for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                        if item.Name:lower():find(petName:lower()) then
                            if not table.find(foundPets, petName) then
                                table.insert(foundPets, petName)
                            end
                        end
                    end
                end
            end
            
            -- Проверка персонажа
            local character = otherPlayer.Character
            if character then
                for _, item in pairs(character:GetChildren()) do
                    for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                        if item.Name:lower():find(petName:lower()) then
                            if not table.find(foundPets, petName) then
                                table.insert(foundPets, petName)
                            end
                        end
                    end
                end
            end
            
            -- Проверка PlayerGui на наличие UI питомцев
            local playerGui = otherPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                        for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                            if gui.Text:lower():find(petName:lower()) then
                                if not table.find(foundPets, petName) then
                                    table.insert(foundPets, petName)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Поиск в ReplicatedStorage (питомцы могут храниться там)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    for _, obj in pairs(replicatedStorage:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("Folder") then
            for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                if obj.Name:lower():find(petName:lower()) then
                    if not table.find(foundPets, petName) then
                        table.insert(foundPets, petName)
                    end
                end
            end
        end
    end
    
    -- Поиск в ServerStorage (если доступен)
    pcall(function()
        local serverStorage = game:GetService("ServerStorage")
        for _, obj in pairs(serverStorage:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("Folder") then
                for _, petName in pairs(CONFIG.PETS_TO_FIND) do
                    if obj.Name:lower():find(petName:lower()) then
                        if not table.find(foundPets, petName) then
                            table.insert(foundPets, petName)
                        end
                    end
                end
            end
        end
    end)
    
    return foundPets
end

-- Функция телепортации к питомцу
local function teleportToPet(petName)
    local target = nil
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("Tool") then
            if obj.Name:lower():find(petName:lower()) then
                target = obj
                break
            end
        end
    end
    
    if target and player.Character then
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
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
        end
    end
    
    return false
end

-- Функция покупки питомца
local function purchasePet()
    local character = player.Character
    if not character then return false end
    
    -- Поиск ProximityPrompt
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            if character:FindFirstChild("HumanoidRootPart") then
                local distance = (obj.Parent.Position - character.HumanoidRootPart.Position).Magnitude
                if distance < CONFIG.PET_PURCHASE_RANGE then
                    obj:InputHoldBegin()
                    wait(CONFIG.HOLD_E_DURATION)
                    obj:InputHoldEnd()
                    return true
                end
            end
        end
    end
    
    -- Зажатие E если нет ProximityPrompt
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
    wait(CONFIG.HOLD_E_DURATION)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
    
    return true
end

-- Функция проверки сервера на наличие питомцев (реальная версия)
local function checkServerForPets(serverId)
    -- Для текущего сервера - реальная проверка
    if serverId == game.JobId then
        if not currentServerScanned then
            local foundPets = findPetsOnCurrentServer()
            currentServerScanned = true
            
            if #foundPets > 0 then
                -- Кэшируем результат
                serverCache[serverId] = {
                    pets = foundPets,
                    players = #Players:GetPlayers(),
                    maxPlayers = Players.MaxPlayers,
                    timestamp = os.time()
                }
                
                return foundPets[1] -- Возвращаем первого найденного питомца
            end
        else
            -- Используем кэш если уже сканировали
            if serverCache[serverId] and serverCache[serverId].pets and #serverCache[serverId].pets > 0 then
                return serverCache[serverId].pets[1]
            end
        end
        
        return nil
    end
    
    -- Для других серверов - используем кэш или возвращаем nil
    if serverCache[serverId] and serverCache[serverId].pets and #serverCache[serverId].pets > 0 then
        -- Проверяем не устарел ли кэш (старше 5 минут)
        if os.time() - serverCache[serverId].timestamp < 300 then
            return serverCache[serverId].pets[1]
        end
    end
    
    return nil
end

-- Создание GUI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetServerFinder"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title Text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🐾 Server Pet Finder"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 22
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(0.93, 0, 0.5, -15)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Minimize Button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(0.85, 0, 0.5, -15)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = 18
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 8)
    minCorner.Parent = minimizeButton
    
    local minimized = false
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 500, 0, 50)
        else
            mainFrame.Size = UDim2.new(0, 500, 0, 400)
        end
    end)
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🔍 Scanning current server..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 16
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Auto Buy Toggle
    local autoBuyButton = Instance.new("TextButton")
    autoBuyButton.Size = UDim2.new(0.3, 0, 0, 25)
    autoBuyButton.Position = UDim2.new(0.65, 0, 0, 62)
    autoBuyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    autoBuyButton.Text = "Auto Buy: OFF"
    autoBuyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBuyButton.Font = Enum.Font.GothamBold
    autoBuyButton.TextSize = 12
    autoBuyButton.BorderSizePixel = 0
    autoBuyButton.Parent = mainFrame
    
    local autoBuyCorner = Instance.new("UICorner")
    autoBuyCorner.CornerRadius = UDim.new(0, 6)
    autoBuyCorner.Parent = autoBuyButton
    
    local autoBuyEnabled = false
    
    autoBuyButton.MouseButton1Click:Connect(function()
        autoBuyEnabled = not autoBuyEnabled
        if autoBuyEnabled then
            autoBuyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            autoBuyButton.Text = "Auto Buy: ON"
        else
            autoBuyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            autoBuyButton.Text = "Auto Buy: OFF"
        end
    end)
    
    -- Servers List Frame
    local serversFrame = Instance.new("ScrollingFrame")
    serversFrame.Name = "ServersFrame"
    serversFrame.Size = UDim2.new(1, -20, 0, 250)
    serversFrame.Position = UDim2.new(0, 10, 0, 100)
    serversFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    serversFrame.BorderSizePixel = 0
    serversFrame.ScrollBarThickness = 6
    serversFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    serversFrame.Parent = mainFrame
    
    local serversCorner = Instance.new("UICorner")
    serversCorner.CornerRadius = UDim.new(0, 8)
    serversCorner.Parent = serversFrame
    
    local serversList = Instance.new("UIListLayout")
    serversList.Padding = UDim.new(0, 5)
    serversList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    serversList.SortOrder = Enum.SortOrder.LayoutOrder
    serversList.Parent = serversFrame
    
    -- Buttons Frame
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, -20, 0, 40)
    buttonsFrame.Position = UDim2.new(0, 10, 1, -50)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = mainFrame
    
    -- Refresh Button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0.48, 0, 1, 0)
    refreshButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    refreshButton.Text = "🔄 Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 16
    refreshButton.BorderSizePixel = 0
    refreshButton.Parent = buttonsFrame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    -- Auto Join Toggle
    local autoJoinButton = Instance.new("TextButton")
    autoJoinButton.Size = UDim2.new(0.48, 0, 1, 0)
    autoJoinButton.Position = UDim2.new(0.52, 0, 0, 0)
    autoJoinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    autoJoinButton.Text = "Auto Join: OFF"
    autoJoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoJoinButton.Font = Enum.Font.GothamBold
    autoJoinButton.TextSize = 16
    autoJoinButton.BorderSizePixel = 0
    autoJoinButton.Parent = buttonsFrame
    
    local autoJoinCorner = Instance.new("UICorner")
    autoJoinCorner.CornerRadius = UDim.new(0, 8)
    autoJoinCorner.Parent = autoJoinButton
    
    local autoJoinEnabled = false
    
    autoJoinButton.MouseButton1Click:Connect(function()
        autoJoinEnabled = not autoJoinEnabled
        if autoJoinEnabled then
            autoJoinButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            autoJoinButton.Text = "Auto Join: ON"
        else
            autoJoinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            autoJoinButton.Text = "Auto Join: OFF"
        end
    end)
    
    -- Server Hop Button
    local serverHopButton = Instance.new("TextButton")
    serverHopButton.Size = UDim2.new(1, -20, 0, 35)
    serverHopButton.Position = UDim2.new(0, 10, 1, -95)
    serverHopButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    serverHopButton.Text = "🚀 Server Hop (Find New Servers)"
    serverHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    serverHopButton.Font = Enum.Font.GothamBold
    serverHopButton.TextSize = 14
    serverHopButton.BorderSizePixel = 0
    serverHopButton.Parent = mainFrame
    
    local hopCorner = Instance.new("UICorner")
    hopCorner.CornerRadius = UDim.new(0, 8)
    hopCorner.Parent = serverHopButton
    
    serverHopButton.MouseButton1Click:Connect(function()
        serverHopButton.Text = "🔄 Hopping..."
        pcall(function()
            local servers = {}
            
            local apiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
            local response = syn.request({Url = apiUrl, Method = "GET"})
            
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
            
            if #servers > 0 then
                local randomServer = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
            else
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
    end)
    
    return {
        screenGui = screenGui,
        serversFrame = serversFrame,
        serversList = serversList,
        statusLabel = statusLabel,
        refreshButton = refreshButton,
        autoJoinButton = autoJoinButton,
        getAutoJoinEnabled = function() return autoJoinEnabled end,
        getAutoBuyEnabled = function() return autoBuyEnabled end
    }
end

-- Функция для создания карточки сервера
local function createServerCard(parent, serverData, petName)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Current Server Badge
    if serverData.id == game.JobId then
        local currentBadge = Instance.new("TextLabel")
        currentBadge.Size = UDim2.new(0, 100, 0, 20)
        currentBadge.Position = UDim2.new(0, 10, 0, 5)
        currentBadge.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        currentBadge.Text = "CURRENT"
        currentBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentBadge.Font = Enum.Font.GothamBold
        currentBadge.TextSize = 12
        currentBadge.Parent = card
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = currentBadge
    end
    
    -- Server Info
    local serverName = Instance.new("TextLabel")
    serverName.Size = UDim2.new(0.6, 0, 0, 30)
    serverName.Position = UDim2.new(0, 10, 0, 30)
    serverName.BackgroundTransparency = 1
    serverName.Text = "🌍 Server: " .. serverData.id:sub(1, 8) .. "..."
    serverName.TextColor3 = Color3.fromRGB(255, 255, 255)
    serverName.Font = Enum.Font.GothamBold
    serverName.TextSize = 16
    serverName.TextXAlignment = Enum.TextXAlignment.Left
    serverName.Parent = card
    
    -- Pet Found Info
    local petInfo = Instance.new("TextLabel")
    petInfo.Size = UDim2.new(0.6, 0, 0, 20)
    petInfo.Position = UDim2.new(0, 10, 0, 55)
    petInfo.BackgroundTransparency = 1
    petInfo.Text = "🐾 Found: " .. petName
    petInfo.TextColor3 = Color3.fromRGB(50, 255, 50)
    petInfo.Font = Enum.Font.Gotham
    petInfo.TextSize = 14
    petInfo.TextXAlignment = Enum.TextXAlignment.Left
    petInfo.Parent = card
    
    -- Players Info
    local playersInfo = Instance.new("TextLabel")
    playersInfo.Size = UDim2.new(0.6, 0, 0, 20)
    playersInfo.Position = UDim2.new(0, 10, 0, 75)
    playersInfo.BackgroundTransparency = 1
    playersInfo.Text = "👥 Players: " .. serverData.playing .. "/" .. serverData.maxPlayers
    playersInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    playersInfo.Font = Enum.Font.Gotham
    playersInfo.TextSize = 12
    playersInfo.TextXAlignment = Enum.TextXAlignment.Left
    playersInfo.Parent = card
    
    -- Join Button
    local joinButton = Instance.new("TextButton")
    joinButton.Size = UDim2.new(0, 100, 0, 35)
    joinButton.Position = UDim2.new(0.75, 0, 0.5, -17)
    joinButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    joinButton.Text = "JOIN"
    joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinButton.Font = Enum.Font.GothamBlack
    joinButton.TextSize = 18
    joinButton.BorderSizePixel = 0
    joinButton.Parent = card
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 8)
    joinCorner.Parent = joinButton
    
    -- Disable join button for current server
    if serverData.id == game.JobId then
        joinButton.Text = "HERE"
        joinButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    -- Glow effect on hover
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://6014261993"
    glow.ImageColor3 = Color3.fromRGB(50, 255, 50)
    glow.ImageTransparency = 0.8
    glow.Visible = false
    glow.Parent = joinButton
    
    joinButton.MouseEnter:Connect(function()
        if serverData.id ~= game.JobId then
            glow.Visible = true
            joinButton.BackgroundColor3 = Color3.fromRGB(70, 255, 70)
        end
    end)
    
    joinButton.MouseLeave:Connect(function()
        if serverData.id ~= game.JobId then
            glow.Visible = false
            joinButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        end
    end)
    
    joinButton.MouseButton1Click:Connect(function()
        if serverData.id ~= game.JobId then
            joinButton.Text = "JOINING..."
            joinButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, player)
            end)
        end
    end)
    
    -- Buy Pet Button (только для текущего сервера)
    if serverData.id == game.JobId then
        local buyButton = Instance.new("TextButton")
        buyButton.Size = UDim2.new(0, 100, 0, 30)
        buyButton.Position = UDim2.new(0.75, 0, 0.7, 0)
        buyButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        buyButton.Text = "BUY PET"
        buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyButton.Font = Enum.Font.GothamBold
        buyButton.TextSize = 14
        buyButton.BorderSizePixel = 0
        buyButton.Parent = card
        
        local buyCorner = Instance.new("UICorner")
        buyCorner.CornerRadius = UDim.new(0, 8)
        buyCorner.Parent = buyButton
        
        buyButton.MouseButton1Click:Connect(function()
            buyButton.Text = "BUYING..."
            teleportToPet(petName)
            wait(0.5)
            purchasePet()
            buyButton.Text = "BOUGHT!"
            wait(1)
            buyButton.Text = "BUY PET"
        end)
    end
    
    return card
end

-- Функция получения списка серверов
local function getServers()
    local servers = {}
    
    pcall(function()
        local apiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=" .. CONFIG.MAX_SERVERS_TO_SCAN
        
        local response = syn.request({
            Url = apiUrl,
            Method = "GET"
        })
        
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            
            if data and data.data then
                for _, server in pairs(data.data) do
                    if server.playing < server.maxPlayers then
                        table.insert(servers, server)
                    end
                end
            end
        end
    end)
    
    -- Добавляем текущий сервер если его нет в списке
    local currentServerInList = false
    for _, server in pairs(servers) do
        if server.id == game.JobId then
            currentServerInList = true
            break
        end
    end
    
    if not currentServerInList then
        table.insert(servers, 1, {
            id = game.JobId,
            playing = #Players:GetPlayers(),
            maxPlayers = Players.MaxPlayers
        })
    end
    
    return servers
end

-- Функция обновления списка серверов
local function updateServersList(uiElements)
    uiElements.statusLabel.Text = "🔍 Scanning servers..."
    currentServerScanned = false
    
    -- Очищаем старый список
    for _, child in pairs(uiElements.serversFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Сканируем текущий сервер на питомцев
    local currentPets = findPetsOnCurrentServer()
    currentServerScanned = true
    
    local servers = getServers()
    local serversWithPets = {}
    
    -- Проверяем текущий сервер
    if #currentPets > 0 then
        for _, server in pairs(servers) do
            if server.id == game.JobId then
                for _, pet in pairs(currentPets) do
                    table.insert(serversWithPets, {
                        server = server,
                        pet = pet
                    })
                end
                break
            end
        end
    end
    
    -- Проверяем кэшированные сервера
    for _, server in pairs(servers) do
        if server.id ~= game.JobId and serverCache[server.id] and serverCache[server.id].pets then
            if os.time() - serverCache[server.id].timestamp < 300 then -- 5 минут
                for _, pet in pairs(serverCache[server.id].pets) do
                    table.insert(serversWithPets, {
                        server = server,
                        pet = pet
                    })
                end
            end
        end
    end
    
    -- Удаляем дубликаты
    local uniqueServers = {}
    local seenServers = {}
    
    for _, data in pairs(serversWithPets) do
        local key = data.server.id .. "_" .. data.pet
        if not seenServers[key] then
            seenServers[key] = true
            table.insert(uniqueServers, data)
        end
    end
    
    -- Сортируем: текущий сервер первый, потом по приоритету питомцев
    table.sort(uniqueServers, function(a, b)
        if a.server.id == game.JobId then return true end
        if b.server.id == game.JobId then return false end
        
        local priorityA = table.find(CONFIG.PETS_TO_FIND, a.pet) or 999
        local priorityB = table.find(CONFIG.PETS_TO_FIND, b.pet) or 999
        return priorityA < priorityB
    end)
    
    -- Обновляем UI
    if #uniqueServers > 0 then
        uiElements.statusLabel.Text = "✅ Found " .. #currentPets .. " pets on current server! (" .. #uniqueServers .. " total)"
        
        for _, data in pairs(uniqueServers) do
            createServerCard(uiElements.serversFrame, data.server, data.pet)
        end
        
        -- Автоматическая покупка если включена и мы на текущем сервере
        if uiElements.getAutoBuyEnabled() and #currentPets > 0 then
            uiElements.statusLabel.Text = "🎯 Auto-buying " .. currentPets[1] .. "..."
            
            for _, pet in pairs(currentPets) do
                teleportToPet(pet)
                wait(0.5)
                purchasePet()
                wait(0.5)
            end
        end
        
        -- Автоматическое присоединение если включено
        if uiElements.getAutoJoinEnabled() then
            for _, data in pairs(uniqueServers) do
                if data.server.id ~= game.JobId then
                    uiElements.statusLabel.Text = "🚀 Auto-joining server with " .. data.pet .. "..."
                    wait(1)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, data.server.id,
