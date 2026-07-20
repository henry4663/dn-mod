-- [[ CONFIGURAÇÕES E ESTADOS DE ESP ]]
local espSettings = {
    sheriff = false,
    murderer = false,
    innocent = false,
    coins = false,
    tracers = false
}

local activeTracers = {}
local activeCoinVisuals = {}

-- [[ CRIAÇÃO DA INTERFACE (UI) SEGURA ]]
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ContentFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local MinimizeBtn = Instance.new("TextButton") -- Novo Botão de Minimizar

ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "HenryHubUI"

MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true -- Garante que o conteúdo suma ao encolher

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡ Henry Hub | MM2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold

-- Configuração do Botão de Minimizar
MinimizeBtn.Parent = Title
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(1, -35, 0, 0)
MinimizeBtn.Size = UDim2.new(0, 35, 1, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 24
MinimizeBtn.Font = Enum.Font.SourceSansBold

ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 50)
ContentFrame.Size = UDim2.new(1, -20, 1, -60)

UIListLayout.Parent = ContentFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

-- Status do Servidor no Rodapé
local statsFrame = Instance.new("Frame", MainFrame)
statsFrame.Size = UDim2.new(1, 0, 0, 60)
statsFrame.Position = UDim2.new(0, 0, 1, -60)
statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local fpsL = Instance.new("TextLabel", statsFrame)
fpsL.Size = UDim2.new(1, 0, 0, 20)
fpsL.TextColor3 = Color3.fromRGB(200, 200, 200)
fpsL.TextSize = 12
fpsL.BackgroundTransparency = 1

local pingL = Instance.new("TextLabel", statsFrame)
pingL.Size = UDim2.new(1, 0, 0, 20)
pingL.Position = UDim2.new(0, 0, 0, 20)
pingL.TextColor3 = Color3.fromRGB(200, 200, 200)
pingL.TextSize = 12
pingL.BackgroundTransparency = 1

-- Lógica para Minimizar / Expandir
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- Esconde as partes internas e encolhe o frame principal (deixa só o título)
        ContentFrame.Visible = false
        statsFrame.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 40), "Out", "Quad", 0.2, true)
        MinimizeBtn.Text = "+"
    else
        -- Aumenta o frame de volta e mostra o conteúdo de novo
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 400), "Out", "Quad", 0.2, true, function()
            ContentFrame.Visible = true
            statsFrame.Visible = true
        end)
        MinimizeBtn.Text = "-"
    end
end)

-- Função auxiliar para criar botões de alternar (Toggle)
local function createToggle(name, settingKey)
    local btn = Instance.new("TextButton")
    btn.Parent = ContentFrame
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 50, 50)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16

    btn.MouseButton1Click:Connect(function()
        espSettings[settingKey] = not espSettings[settingKey]
        if espSettings[settingKey] then
            btn.Text = name .. ": ON"
            btn.TextColor3 = Color3.fromRGB(50, 200, 50)
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        else
            btn.Text = name .. ": OFF"
            btn.TextColor3 = Color3.fromRGB(200, 50, 50)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        end
    end)
end

createToggle("ESP Sheriff", "sheriff")
createToggle("ESP Murderer", "murderer")
createToggle("ESP Innocent", "innocent")
createToggle("ESP Moedas", "coins")
createToggle("Tracers", "tracers")

-- Loop seguro para atualizar FPS/Ping sem crashar
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            fpsL.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
            
            local success, pingValue = pcall(function()
                return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            
            if success then
                pingL.Text = "PING: " .. math.floor(pingValue) .. "ms"
            else
                pingL.Text = "PING: Carregando..."
            end
        end)
    end
end)

-- [[ LÓGICA DO JOGO (ESP / TRACERS) ]]
local camera = workspace.CurrentCamera
local lplr = game.Players.LocalPlayer

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

game.Players.PlayerRemoving:Connect(function(p)
    if activeTracers[p] then
        pcall(function() activeTracers[p]:Destroy() end)
        activeTracers[p] = nil
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= lplr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(p)
            local hrp = p.Character.HumanoidRootPart
            
            local shouldShow = false
            local color = Color3.new(1, 1, 1)
            
            if role == "Murderer" and espSettings.murderer then
                shouldShow = true
                color = Color3.new(1, 0, 0)
            elseif role == "Sheriff" and espSettings.sheriff then
                shouldShow = true
                color = Color3.new(0, 0, 1)
            elseif role == "Innocent" and espSettings.innocent then
                shouldShow = true
                color = Color3.new(0, 1, 0)
            end
            
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
                if currentHighlight then
                    currentHighlight:Destroy()
                end
            end
            
            if espSettings.tracers and shouldShow then
                local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    if not activeTracers[p] then
                        if Drawing then
                            local line = Drawing.new("Line")
                            line.Thickness = 2
                            line.Transparency = 1
                            activeTracers[p] = line
                        end
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
    
    if espSettings.coins then
        local coinContainer = workspace:FindFirstChild("CoinContainer", true)
        if coinContainer then
            for _, c in pairs(coinContainer:GetChildren()) do
                if c:IsA("BasePart") and not activeCoinVisuals[c] then
                    local b = Instance.new("BoxHandleAdornment")
                    b.Name = "CoinVisual"
                    b.Adornee = c
                    b.AlwaysOnTop = true
                    b.Size = Vector3.new(2, 2, 2)
                    b.Color3 = Color3.new(1, 1, 0)
                    b.Transparency = 0.6
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
end)
