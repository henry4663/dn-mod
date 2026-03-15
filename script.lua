local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Henry Hub | MM2 🎯",
   LoadingTitle = "Carregando Henry Hub...",
   LoadingSubtitle = "by Henry",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "HenryHub",
      FileName = "MM2Config"
   }
})

local MainTab = Window:CreateTab("Combate", 4483362458) -- Ícone de espada

-- Variáveis do Aimbot
local AimbotEnabled = false
local AimPart = "HumanoidRootPart"

-- Função de Visibilidade (Raycast)
local function isVisible(targetPart)
    local Camera = workspace.CurrentCamera
    local character = game.Players.LocalPlayer.Character
    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 500)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {character, targetPart.Parent})
    return hit == nil or hit:IsDescendantOf(targetPart.Parent)
end

MainTab:CreateToggle({
   Name = "Aimbot Inteligente (Não mira na parede)",
   CurrentValue = false,
   Callback = function(Value)
      AimbotEnabled = Value
   end,
})

-- Loop do Aimbot
game:GetService("RunService").RenderStepped:Connect(function()
    if AimbotEnabled then
        local Camera = workspace.CurrentCamera
        local mouse = game.Players.LocalPlayer:GetMouse()
        local closestPlayer = nil
        local shortestDistance = math.huge

        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild(AimPart) then
                local targetPart = player.Character[AimPart]
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen and isVisible(targetPart) then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortestDistance then
                        closestPlayer = targetPart
                        shortestDistance = dist
                    end
                end
            end
        end

        if closestPlayer then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Position)
        end
    end
end)

local VisualTab = Window:CreateTab("Visuais", 4483362458)

VisualTab:CreateButton({
   Name = "Ativar ESP (Ver através da parede)",
   Callback = function()
       -- Lógica simples de ESP Highlight
       for _, v in pairs(game.Players:GetPlayers()) do
           if v ~= game.Players.LocalPlayer and v.Character then
               local highlight = Instance.new("Highlight")
               highlight.Parent = v.Character
               highlight.FillColor = Color3.fromRGB(255, 0, 0)
           end
       end
       Rayfield:Notify({Title = "Sucesso", Content = "ESP Ativado!", Duration = 3})
   end,
})

Rayfield:Notify({Title = "Henry Hub", Content = "Script carregado com sucesso!", Duration = 5})
