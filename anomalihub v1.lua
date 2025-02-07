local http_request_func = customrequest or (syn and syn.request) or http_request or (http and http.request)
if not http_request_func then
    error("No HTTP request function available. Your executor may not support HTTP requests.")
end

local response = http_request_func({
    Url = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    Method = "GET"
})
if not response or not response.Body then
    error("Error obtaining Rayfield. Check your connection or executor compatibility.")
end

local Rayfield = loadstring(response.Body)()

local Window = Rayfield:CreateWindow({
    Name = "Anomali Hub",
    LoadingTitle = "Anomali Hub",
    LoadingSubtitle = "by RbxAmoli",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AnomaliHub",
        FileName = "AnomaliHub"
    },
    KeySystem = false,
})

local AimTab = Window:CreateTab("Aim")
local VisualsTab = Window:CreateTab("Visuals")

local Settings = {
    AimAssist = true,
    Smoothness = 0.1,
    AimKey = "Q",
    DrawCircle = true,
    CircleSize = 100,
    ESPEnabled = true,
    ESP_PlayerDistance = true
}

-- Aim Options
AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 10,
    Callback = function(value)
        Settings.Smoothness = value / 100
    end
})
AimTab:CreateToggle({
    Name = "Aim Assist",
    CurrentValue = true,
    Callback = function(state)
        Settings.AimAssist = state
    end
})
AimTab:CreateDropdown({
    Name = "Aim Key",
    Options = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"},
    CurrentOption = "Q",
    Callback = function(option)
        local key = type(option) == "table" and option[1] or option
        Settings.AimKey = tostring(key)
    end
})
AimTab:CreateToggle({
    Name = "Aim Circle",
    CurrentValue = true,
    Callback = function(state)
        Settings.DrawCircle = state
    end
})
AimTab:CreateSlider({
    Name = "Size Circle",
    Range = {10, 300},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(value)
        Settings.CircleSize = value
    end
})

-- Visuals Options
VisualsTab:CreateToggle({
    Name = "ESP",
    CurrentValue = true,
    Callback = function(state)
        Settings.ESPEnabled = state
    end
})
VisualsTab:CreateToggle({
    Name = "Player Distance",
    CurrentValue = true,
    Callback = function(state)
        Settings.ESP_PlayerDistance = state
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local circle = Drawing.new("Circle")
circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
circle.Radius = Settings.CircleSize
circle.Filled = false
circle.Color = Color3.fromRGB(255,255,255)
circle.Thickness = 2
local MAX_DISTANCE = 500

local function GetNearestHead()
    local nearest, dist = nil, math.huge
    local lpHead = LP.Character and LP.Character:FindFirstChild("Head")
    if not lpHead then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local viewPos, visible = Camera:WorldToViewportPoint(head.Position)
            local dist3D = (head.Position - lpHead.Position).Magnitude
            local diff2D = (Vector2.new(viewPos.X, viewPos.Y) - circle.Position).Magnitude
            if visible and dist3D <= MAX_DISTANCE and diff2D <= circle.Radius and diff2D < dist then
                dist = diff2D
                nearest = head
            end
        end
    end
    return nearest
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        if Window.UI then
            Window.UI.Enabled = not Window.UI.Enabled
        end
    else
        local aimEnum = Enum.KeyCode[Settings.AimKey]
        if aimEnum and input.KeyCode == aimEnum then
            Settings.AimAssist = not Settings.AimAssist
        end
    end
end)

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = Settings.CircleSize
    circle.Visible = Settings.DrawCircle
    if Settings.AimAssist then
        local head = GetNearestHead()
        if head then
            Camera.CFrame = Camera.CFrame:lerp(CFrame.new(Camera.CFrame.Position, head.Position), Settings.Smoothness)
        end
    end
end)

local espCache = {}
local function safeWait(child, parent, timeout)
    return parent:FindFirstChild(child) or parent:WaitForChild(child, timeout or 5)
end

local function createVectorESP(player)
    if player == LP then return end
    local character
    pcall(function() character = player.Character or player.CharacterAdded:Wait(3) end)
    if not character then return end
    local rootPart = safeWait("HumanoidRootPart", character)
    if not rootPart then return end
    local marker = Instance.new("BillboardGui")
    marker.Size = UDim2.new(4, 0, 4, 0)
    marker.AlwaysOnTop = true
    marker.Enabled = false

    local line = Instance.new("Frame")
    line.BackgroundColor3 = Color3.new(1, 0, 0)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.Parent = marker

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Parent = marker

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextScaled = true
    distanceLabel.Parent = marker

    marker.Parent = character
    espCache[player] = {Marker = marker, Line = line, NameLabel = nameLabel, DistanceLabel = distanceLabel, Character = character}
end

local function updateESP()
    for player, data in pairs(espCache) do
        if player.Parent and data.Character and data.Character.Parent then
            local rootPart = data.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local _, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                data.Marker.Enabled = Settings.ESPEnabled and onScreen
                if onScreen then
                    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
                    data.DistanceLabel.Text = Settings.ESP_PlayerDistance and string.format("%.1fm", distance) or ""
                    data.NameLabel.Text = Settings.ESP_PlayerName and player.Name or ""
                    data.Line.Visible = Settings.ESP_Hitbox
                end
            end
        else
            if data.Marker then data.Marker:Destroy() end
            espCache[player] = nil
        end
    end
end

local function fastTrackPlayer(player)
    task.spawn(function()
        createVectorESP(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createVectorESP(player)
        end)
    end)
end

Players.PlayerAdded:Connect(fastTrackPlayer)
Players.PlayerRemoving:Connect(function(player)
    if espCache[player] then
        if espCache[player].Marker then espCache[player].Marker:Destroy() end
        espCache[player] = nil
    end
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP then fastTrackPlayer(player) end
end
RunService.Heartbeat:Connect(updateESP)

_G.DestroyVectorESP = function()
    for _, data in pairs(espCache) do
        if data.Marker then data.Marker:Destroy() end
    end
    espCache = {}
end