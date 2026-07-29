-- [[ CONFIGURAÇÕES E ESTADOS DO HUB ]]
local espSettings = {
    sheriff = false,
    murderer = false,
    innocent = false,
    coins = false,
    gunDrop = false,
    tracers = false,
    aimbot = false
}

local activeTracers = {}
local activeCoinVisuals = {}
local activeGunVisual = nil

-- [[ SERVIÇOS ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local lplr = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Destruir versão anterior para evitar duplicidade
if CoreGui:FindFirstChild("HenryHubUI") then
    CoreGui.HenryHubUI:Destroy()
end

-- [[ INTERFACE (UI) ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HenryHubUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 470)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 8)

-- Título
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡  Henry Hub | MM2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitlePadding = Instance.new("UIPadding", Title)
TitlePadding.PaddingLeft = UDim.new(0, 12)

-- Botão Minimizar
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = Title
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.Size = UDim2.new(0, 30, 1, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold

-- Botão Fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Title
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.GothamBold

-- Container de Conteúdo
local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 48)
ContentFrame.Size = UDim2.new(1, -20, 1, -110)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ContentFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Status Rodapé
local statsFrame = Instance.new("Frame", MainFrame)
statsFrame.Size = UDim2.new(1, 0, 0, 45)
statsFrame.Position = UDim2.new(0, 0, 1, -45)
statsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)

local fpsL = Instance.new("TextLabel", statsFrame)
fpsL.Size = UDim2.new(1, 0, 0, 20)
fpsL.TextColor3 = Color3.fromRGB(160, 160, 170)
fpsL.TextSize = 11
fpsL.Font = Enum.Font.GothamMedium
fpsL.BackgroundTransparency = 1

local pingL = Instance.new("TextLabel", statsFrame)
pingL.Size = UDim2.new(1, 0, 0, 20)
pingL.Position = UDim2.new(0, 0, 0, 18)
pingL.TextColor3 = Color3.fromRGB(160, 160, 170)
pingL.TextSize = 11
pingL.Font = Enum.Font.GothamMedium
pingL.BackgroundTransparency = 1

-- Lógica Minimizar e Fechar
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        ContentFrame.Visible = false
        statsFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 40), "Out", "Quad", 0.2, true)
        MinimizeBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 470), "Out", "Quad", 0.2, true, function()
            ContentFrame.Visible = true
            statsFrame.Visible = true
        end)
        MinimizeBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Criador de Botões
local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = ContentFrame
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    btn.Text = name .. "  [OFF]"
    btn.TextColor3 = Color3.fromRGB(220, 80, 80)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        espSettings[settingKey] = not espSettings[settingKey]
        if espSettings[settingKey] then
            btn.Text = name .. "  [ON]"
            btn.TextColor3 = Color3.fromRGB(80, 220, 120)
            btn.BackgroundColor3 = Color3.fromRGB(40, 50, 45)
        else
            btn.Text = name .. "  [OFF]"
            btn.TextColor3 = Color3.fromRGB(220, 80, 80)
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        end
    end)
end

createToggle("ESP Sheriff", "sheriff")
createToggle("ESP Murderer", "murderer")
createToggle("ESP Innocent", "innocent")
createToggle("ESP Moedas", "coins")
createToggle("ESP Arma Dropada", "gunDrop")
createToggle("Tracers", "tracers")
createToggle("🎯 AimBot & Auto Shoot", "aimbot")

-- Atualizar FPS/Ping
task.spawn(function()
    while task.wait(0.5) do
        if not ScreenGui.Parent then break end
        pcall(function()
            fpsL.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
            local pingValue = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            pingL.Text = "PING: " .. math.floor(pingValue) .. " ms"
        end)
    end
end)

-- [[ LÓGICA DE FUNÇÕES E ROLES ]]
local function getRole(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character

    if (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function getMurdererPlayer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and getRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            return p
        end
    end
    return nil
end

-- [[ BOTÃO VIRTUAL MIRA E TIRO AUTO ]]
local isAiming = false
local AimBtn = Instance.new("TextButton")
AimBtn.Name = "AimButton"
AimBtn.Parent = ScreenGui
AimBtn.Size = UDim2.new(0, 65, 0, 65)
AimBtn.Position = UDim2.new(0.8, 0, 0.5, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
AimBtn.Text = "🎯"
AimBtn.TextSize = 30
AimBtn.Active = true
AimBtn.Draggable = true
AimBtn.Visible = true

local AimCorner = Instance.new("UICorner", AimBtn)
AimCorner.CornerRadius = UDim.new(1, 0)

-- Função para atirar
local function autoShoot()
    local char = lplr.Character
    if char then
        local gun = char:FindFirstChild("Gun")
        if gun then
            -- Tenta ativar a ferramenta diretamente
            gun:Activate()
            
            -- Simula clique do mouse/tela por segurança
            local viewportSize = camera.ViewportSize
            VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 0)
        end
    end
end

AimBtn.MouseButton1Down:Connect(function() 
    isAiming = true 
    if espSettings.aimbot then
        autoShoot()
    end
end)

AimBtn.MouseButton1Up:Connect(function() isAiming = false end)
AimBtn.InputEnded:Connect(function() isAiming = false end)

-- [[ LOOP PRINCIPAL (RENDER STEPPED) ]]
RunService.RenderStepped:Connect(function()
    -- AIMBOT LOGIC
    if espSettings.aimbot and isAiming then
        local murd = getMurdererPlayer()
        if murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = murd.Character.HumanoidRootPart.Position
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
        end
    end

    -- ESP JOGADORES
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(p)
            local hrp = p.Character.HumanoidRootPart
            local shouldShow = false
            local color = Color3.new(1, 1, 1)

            if role == "Murderer" and espSettings.murderer then
                shouldShow = true
                color = Color3.fromRGB(255, 50, 50)
            elseif role == "Sheriff" and espSettings.sheriff then
                shouldShow = true
                color = Color3.fromRGB(50, 120, 255)
            elseif role == "Innocent" and espSettings.innocent then
                shouldShow = true
                color = Color3.fromRGB(50, 255, 100)
            end

            -- Highlight
            local currentHighlight = p.Character:FindFirstChild("EspHighlight")
            if shouldShow then
                if not currentHighlight then
                    currentHighlight = Instance.new("Highlight")
                    currentHighlight.Name = "EspHighlight"
                    currentHighlight.Parent = p.Character
                end
                currentHighlight.FillColor = color
                currentHighlight.OutlineColor = color
                currentHighlight.FillTransparency = 0.5
                currentHighlight.OutlineTransparency = 0
            else
                if currentHighlight then currentHighlight:Destroy() end
            end

            -- Tracers
            if espSettings.tracers and shouldShow then
                local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    if not activeTracers[p] and Drawing then
                        local line = Drawing.new("Line")
                        line.Thickness = 1.5
                        line.Transparency = 0.8
                        activeTracers[p] = line
                    end

                    local tracer = activeTracers[p]
                    if tracer then
                        tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        tracer.To = Vector2.new(vector.X, vector.Y)
                        tracer.Color = color
                        tracer.Visible = true
                    end
                else
                    if activeTracers[p] then activeTracers[p].Visible = false end
                end
            else
                if activeTracers[p] then activeTracers[p].Visible = false end
            end
        else
            if activeTracers[p] then activeTracers[p].Visible = false end
        end
    end

    -- ESP MOEDAS
    if espSettings.coins then
        local coinContainer = workspace:FindFirstChild("CoinContainer", true)
        if coinContainer then
            for _, c in pairs(coinContainer:GetChildren()) do
                if c:IsA("BasePart") and not activeCoinVisuals[c] then
                    local b = Instance.new("BoxHandleAdornment")
                    b.Name = "CoinVisual"
                    b.Adornee = c
                    b.AlwaysOnTop = true
                    b.Size = Vector3.new(1.8, 1.8, 1.8)
                    b.Color3 = Color3.fromRGB(255, 215, 0)
                    b.Transparency = 0.5
                    b.Parent = c
                    activeCoinVisuals[c] = b
                end
            end
        end
    else
        for part, visual in pairs(activeCoinVisuals) do
            if visual then pcall(function() visual:Destroy() end) end
        end
        table.clear(activeCoinVisuals)
    end

    -- ESP ARMA DROPADA
    if espSettings.gunDrop then
        local gunDrop = workspace:FindFirstChild("GunDrop", true)
        if gunDrop then
            if not activeGunVisual then
                local highlight = Instance.new("Highlight")
                highlight.Name = "GunHighlight"
                highlight.FillColor = Color3.fromRGB(255, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.2
                highlight.Parent = gunDrop
                activeGunVisual = highlight
            end
        else
            if activeGunVisual then
                pcall(function() activeGunVisual:Destroy() end)
                activeGunVisual = nil
            end
        end
    else
        if activeGunVisual then
            pcall(function() activeGunVisual:Destroy() end)
            activeGunVisual = nil
        end
    end
end)
