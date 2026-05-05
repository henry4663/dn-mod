
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

-- Configurações
local espSettings = {
	murder = false,
	sheriff = false,
	innocent = false,
	coins = false,
	tracers = false
}

local activeTracers = {} -- Tabela para gerenciar as linhas

-- Container Principal
local sg = Instance.new("ScreenGui")
sg.Name = "HenryHub_V4"
sg.ResetOnSpawn = false
sg.Parent = playerGui

-- Janela Principal
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 500, 0, 320)
main.Position = UDim2.new(0.5, -250, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = sg

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 2

-- TopBar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "HENRY HUB | MM2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 35, 0, 35)
minBtn.Position = UDim2.new(1, -40, 0, 2)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 30
minBtn.Parent = topBar

-- Containers de Abas
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 120, 1, -50)
tabContainer.Position = UDim2.new(0, 5, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = main
Instance.new("UIListLayout", tabContainer).Padding = UDim.new(0, 5)

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -140, 1, -50)
contentHolder.Position = UDim2.new(0, 130, 0, 45)
contentHolder.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
contentHolder.Parent = main
Instance.new("UICorner", contentHolder)

local pages = {}

local function createTab(name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 35)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	b.Text = name
	b.TextColor3 = Color3.fromRGB(200, 200, 200)
	b.Font = Enum.Font.GothamMedium
	b.Parent = tabContainer
	Instance.new("UICorner", b)

	local p = Instance.new("ScrollingFrame")
	p.Size = UDim2.new(1, -10, 1, -10)
	p.Position = UDim2.new(0, 5, 0, 5)
	p.BackgroundTransparency = 1
	p.Visible = false
	p.ScrollBarThickness = 0
	p.Parent = contentHolder
	Instance.new("UIListLayout", p).Padding = UDim.new(0, 5)

	b.MouseButton1Click:Connect(function()
		for _, pg in pairs(pages) do pg.Visible = false end
		p.Visible = true
	end)
	pages[name] = p
	return p
end

local function addToggle(parent, text, key)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 35)
	b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	b.Text = text .. ": OFF"
	b.TextColor3 = Color3.fromRGB(255, 50, 50)
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	Instance.new("UICorner", b)

	b.MouseButton1Click:Connect(function()
		espSettings[key] = not espSettings[key]
		local state = espSettings[key]
		b.Text = text .. (state and ": ON" or ": OFF")
		b.TextColor3 = state and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
	end)
end

-- Lógica de Cargos MM2
local function getRole(p)
	local backpack = p:FindFirstChild("Backpack")
	local char = p.Character
	if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then return "Murder" end
	if (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then return "Sheriff" end
	return "Innocent"
end

-- Função para Linhas (Tracers)
local function manageTracer(p, state, color)
	if state and not activeTracers[p] then
		local line = Drawing.new("Line")
		line.Thickness = 1.5
		line.Transparency = 1
		line.Color = color
		activeTracers[p] = line
	elseif not state and activeTracers[p] then
		activeTracers[p]:Remove()
		activeTracers[p] = nil
	end
end

-- Criar Abas
local visualPage = createTab("Visuais")
local otherPage = createTab("Outros")

addToggle(visualPage, "ESP Murder", "murder")
addToggle(visualPage, "ESP Sheriff", "sheriff")
addToggle(visualPage, "ESP Inocente", "innocent")
addToggle(visualPage, "ESP Moedas", "coins")
addToggle(visualPage, "ESP Linhas", "tracers")

-- Stats (Aba Outros)
local fpsL = Instance.new("TextLabel", otherPage)
fpsL.Size = UDim2.new(1,0,0,30); fpsL.BackgroundTransparency = 1; fpsL.TextColor3 = Color3.new(1,1,1); fpsL.Font = Enum.Font.Code; fpsL.TextSize = 14; fpsL.TextXAlignment = 0
local pingL = fpsL:Clone(); pingL.Parent = otherPage
local memL = fpsL:Clone(); memL.Parent = otherPage

task.spawn(function()
	while task.wait(1) do
		fpsL.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
		pingL.Text = "PING: " .. math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"
		memL.Text = "MEMORIA: " .. math.floor(Stats:GetTotalMemoryUsageMb()) .. "MB"
	end
end)

-- LOOP PRINCIPAL (RODANDO A TODO MOMENTO)
RunService.RenderStepped:Connect(function()
	for _, p in pairs(game.Players:GetPlayers()) do
		if p ~= player then
			local char = p.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local role = getRole(p)
				local highlight = char:FindFirstChild("HenryESP")
				
				-- Determina se deve mostrar ESP baseado no cargo
				local isTarget = (role == "Murder" and espSettings.murder) or 
								 (role == "Sheriff" and espSettings.sheriff) or 
								 (role == "Innocent" and espSettings.innocent)
				
				local roleColor = (role == "Murder" and Color3.new(1,0,0)) or (role == "Sheriff" and Color3.new(0,0,1)) or Color3.new(0,1,0)

				if isTarget then
					-- Criar ou atualizar Highlight
					if not highlight then
						highlight = Instance.new("Highlight")
						highlight.Name = "HenryESP"
						highlight.Parent = char
					end
					highlight.FillColor = roleColor
					
					-- Gerenciar Linhas (Tracers)
					if espSettings.tracers then
						manageTracer(p, true, roleColor)
						local line = activeTracers[p]
						local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(char.HumanoidRootPart.Position)
						if onScreen then
							line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
							line.To = Vector2.new(pos.X, pos.Y)
							line.Visible = true
						else
							line.Visible = false
						end
					else
						manageTracer(p, false)
					end
				else
					if highlight then highlight:Destroy() end
					manageTracer(p, false)
				end
			else
				manageTracer(p, false)
			end
		end
	end
	
	-- ESP de Moedas (Otimizado)
	if espSettings.coins then
		local container = workspace:FindFirstChild("CoinContainer", true)
		if container then
			for _, c in pairs(container:GetChildren()) do
				if c:IsA("BasePart") and not c:FindFirstChild("CoinVisual") then
					local b = Instance.new("BoxHandleAdornment", c)
					b.Name = "CoinVisual"; b.Adornee = c; b.AlwaysOnTop = true; b.Size = Vector3.new(2,2,2); b.Color3 = Color3.new(1,1,0); b.Transparency = 0.5
				end
			end
		end
	else
		-- Remove visuais de moedas se desligar
		for _, v in pairs(workspace:GetDescendants()) do
			if v.Name == "CoinVisual" then v:Destroy() end
		end
	end
end)

-- Arrastar e Minimizar
local isMin = false
minBtn.MouseButton1Click:Connect(function()
	isMin = not isMin
	tabContainer.Visible = not isMin
	contentHolder.Visible = not isMin
	main:TweenSize(isMin and UDim2.new(0, 200, 0, 40) or UDim2.new(0, 500, 0, 320), "Out", "Quart", 0.3, true)
	minBtn.Text = isMin and "+" or "-"
end)

local d, ds, sp
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = main.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then 
	local del = i.Position - ds
	main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + del.X, sp.Y.Scale, sp.Y.Offset + del.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)

visualPage.Visible = true
