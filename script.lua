local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function addESP(player)
	if player == LocalPlayer then return end
	
	player.CharacterAdded:Connect(function(char)
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 0, 0) -- vermelho
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.5
		highlight.Parent = char
	end)
end

-- pra quem já tá no jogo
for _, player in pairs(Players:GetPlayers()) do
	addESP(player)
end

-- pra quem entrar depois
Players.PlayerAdded:Connect(addESP)
