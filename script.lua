local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

if pgui:FindFirstChild("HenryHub_V1") then pgui.HenryHub_V1:Destroy() end

local ScreenGui = Instance.new("ScreenGui", pgui)
ScreenGui.Name = "HenryHub_V1"
ScreenGui.ResetOnSpawn = false

-- [[ BOTÃO PARA ABRIR ]] --
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 80, 0, 30)
OpenBtn.Position = UDim2.new(0.5, -40, 0, 10)
OpenBtn.Text = "ABRIR "
OpenBtn.Visible = false
OpenBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.Draggable = true

-- [[ JANELA PRINCIPAL ]] --
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 400, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -45, 1, 0)
Title.Text = " HENRY HUB V1 | MM2 V1 BY HENRY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -40, 0, 0)
MinBtn.Text = "_"
MinBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 25

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.Size = UDim2.new(1, -20, 1, -60)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 2, 0)
Container.ScrollBarThickness = 5

local function AddToggle(name, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.Position = UDim2.new(0, 0, 0, (#Container:GetChildren() - 1) * 55)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = color
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = name .. (enabled and ": ON" or ": OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(70, 110, 70) or Color3.fromRGB(40, 40, 40)
        callback(enabled)
    end)
end

-- Lógica de Highlight com PRIORIDADE
local function ApplyESP(p, color, state)
    if not p or not p.Character then return end
    local char = p.Character
    local esp = char:FindFirstChild("HenryESP")
    
    if state then
        if esp then
            -- Se a cor mudar (ex: era inocente e virou murder), atualiza a cor
            if esp.FillColor ~= color then esp.FillColor = color end
        else
            local h = Instance.new("Highlight")
            h.Name = "HenryESP"
            h.FillColor = color
            h.FillTransparency = 0.4
            h.OutlineTransparency = 0
            h.Parent = char
        end
    else
        if esp then esp:Destroy() end
    end
end

-- [[ FUNÇÕES V1 COM PRIORIDADE ]] --

-- Loop Único para não bugar (Melhor performance)
task.spawn(function()
    while true do
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character then
                local isMurder = p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife")
                local isSheriff = p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun")
                
                if isMurder and _G.Murd then
                    ApplyESP(p, Color3.fromRGB(255, 0, 0), true)
                elseif isSheriff and _G.Sher then
                    ApplyESP(p, Color3.fromRGB(0, 150, 255), true)
                elseif _G.Inno then
                    ApplyESP(p, Color3.fromRGB(200, 200, 200), true)
                else
                    ApplyESP(p, nil, false)
                end
            end
        end
        
        -- ESP GUN DROP (Fora do loop de players)
        if _G.GunESP then
            local gun = workspace:FindFirstChild("GunDrop") or workspace:FindFirstChild("Gun")
            if gun and not gun:FindFirstChild("HenryESP") then
                local h = Instance.new("Highlight", gun)
                h.Name = "HenryESP"
                h.FillColor = Color3.fromRGB(0, 255, 100)
            end
        end
        
        task.wait(0.2) -- Check rápido para tirar o delay
    end
end)

AddToggle("ESP MURDERER", Color3.fromRGB(255, 0, 0), function(v) _G.Murd = v end)
AddToggle("ESP XERIFE", Color3.fromRGB(0, 150, 255), function(v) _G.Sher = v end)
AddToggle("ESP GUN DROP", Color3.fromRGB(0, 255, 100), function(v) _G.GunESP = v end)
AddToggle("ESP INOCENTES", Color3.fromRGB(255, 255, 255), function(v) _G.Inno = v end)




