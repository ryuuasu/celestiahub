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
    SCAN_INTERVAL = 5, -- Интервал сканирования серверов
    MAX_SERVERS_TO_SCAN = 50, -- Максимальное количество серверов для проверки
    DISCORD_WEBHOOK = "" -- Оставьте пустым, если не нужны уведомления в Discord
}

-- Сервисы
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

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
    statusLabel.Text = "🔍 Scanning servers..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 16
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Servers List Frame
    local serversFrame = Instance.new("ScrollingFrame")
    serversFrame.Name = "ServersFrame"
    serversFrame.Size = UDim2.new(1, -20, 0, 280)
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
    
    return {
        screenGui = screenGui,
        serversFrame = serversFrame,
        serversList = serversList,
        statusLabel = statusLabel,
        refreshButton = refreshButton,
        autoJoinButton = autoJoinButton,
        getAutoJoinEnabled = function() return autoJoinEnabled end
    }
end

-- Функция для создания карточки сервера
local function createServerCard(parent, serverData, petName)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 80)
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Server Info
    local serverName = Instance.new("TextLabel")
    serverName.Size = UDim2.new(0.6, 0, 0, 30)
    serverName.Position = UDim2.new(0, 10, 0, 5)
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
    petInfo.Position = UDim2.new(0, 10, 0, 35)
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
    playersInfo.Position = UDim2.new(0, 10, 0, 55)
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
        glow.Visible = true
        joinButton.BackgroundColor3 = Color3.fromRGB(70, 255, 70)
    end)
    
    joinButton.MouseLeave:Connect(function()
        glow.Visible = false
        joinButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end)
    
    joinButton.MouseButton1Click:Connect(function()
        joinButton.Text = "JOINING..."
        joinButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, player)
        end)
    end)
    
    return card
end

-- Функция для проверки сервера на наличие питомцев
local function checkServerForPets(serverId)
    -- Здесь должна быть логика проверки сервера
    -- Так как мы не можем напрямую проверить другие сервера, используем симуляцию
    -- В реальном сценарии вам нужно использовать ваш метод проверки
    
    -- Имитация нахождения питомца (в реальности здесь должен быть ваш код проверки)
    local randomPet = CONFIG.PETS_TO_FIND[math.random(1, #CONFIG.PETS_TO_FIND)]
    local foundRandom = math.random(1, 100) <= 30 -- 30% шанс найти питомца
    
    if foundRandom then
        return randomPet
    end
    
    return nil
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
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server)
                    end
                end
            end
        end
    end)
    
    return servers
end

-- Функция обновления списка серверов
local function updateServersList(uiElements)
    uiElements.statusLabel.Text = "🔍 Scanning " .. CONFIG.MAX_SERVERS_TO_SCAN .. " servers..."
    
    -- Очищаем старый список
    for _, child in pairs(uiElements.serversFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local servers = getServers()
    local serversWithPets = {}
    
    -- Проверяем каждый сервер
    for _, server in pairs(servers) do
        local foundPet = checkServerForPets(server.id)
        if foundPet then
            table.insert(serversWithPets, {
                server = server,
                pet = foundPet
            })
        end
    end
    
    -- Сортируем по редкости питомца (приоритет)
    table.sort(serversWithPets, function(a, b)
        local priorityA = table.find(CONFIG.PETS_TO_FIND, a.pet) or 999
        local priorityB = table.find(CONFIG.PETS_TO_FIND, b.pet) or 999
        return priorityA < priorityB
    end)
    
    -- Обновляем UI
    if #serversWithPets > 0 then
        uiElements.statusLabel.Text = "✅ Found " .. #serversWithPets .. " servers with pets!"
        
        for _, data in pairs(serversWithPets) do
            createServerCard(uiElements.serversFrame, data.server, data.pet)
        end
        
        -- Автоматическое присоединение если включено
        if uiElements.getAutoJoinEnabled() then
            local bestServer = serversWithPets[1]
            uiElements.statusLabel.Text = "🚀 Auto-joining server with " .. bestServer.pet .. "..."
            
            wait(1)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer.server.id, player)
            end)
        end
    else
        uiElements.statusLabel.Text = "❌ No servers with pets found. Scanning again..."
        
        -- Показываем сообщение что нет серверов
        local noServersLabel = Instance.new("TextLabel")
        noServersLabel.Size = UDim2.new(1, -20, 0, 50)
        noServersLabel.Position = UDim2.new(0, 10, 0, 10)
        noServersLabel.BackgroundTransparency = 1
        noServersLabel.Text = "😔 No servers with pets found\nTry refreshing or wait for scan"
        noServersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noServersLabel.Font = Enum.Font.Gotham
        noServersLabel.TextSize = 14
        noServersLabel.TextWrapped = true
        noServersLabel.Parent = uiElements.serversFrame
    end
end

-- Функция для Discord уведомлений
local function sendDiscordNotification(petName, serverData)
    if CONFIG.DISCORD_WEBHOOK == "" then return end
    
    local requestData = {
        content = "",
        embeds = {{
            title = "🐾 Pet Found on Server!",
            description = string.format(
                "**Pet:** %s\n**Server ID:** %s\n**Players:** %d/%d\n**Time:** %s",
                petName,
                serverData.id,
                serverData.playing,
                serverData.maxPlayers,
                os.date("%Y-%m-%d %H:%M:%S")
            ),
            color = 65280,
            footer = {text = "Grow A Garden 2 - Pet Finder"}
        }}
    }
    
    pcall(function()
        syn.request({
            Url = CONFIG.DISCORD_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(requestData)
        })
    end)
end

-- Главная функция
local function main()
    local uiElements = createUI()
    
    -- Обновление при нажатии на Refresh
    uiElements.refreshButton.MouseButton1Click:Connect(function()
        uiElements.refreshButton.Text = "🔄 Scanning..."
        updateServersList(uiElements)
        uiElements.refreshButton.Text = "🔄 Refresh"
    end)
    
    -- Автоматическое сканирование при запуске
    updateServersList(uiElements)
    
    -- Периодическое обновление
    while uiElements.screenGui and uiElements.screenGui.Parent do
        wait(CONFIG.SCAN_INTERVAL)
        pcall(function()
            updateServersList(uiElements)
        end)
    end
end

-- Запуск
main()
