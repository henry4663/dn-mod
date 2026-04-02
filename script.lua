
--[[
    ============================================================
    SISTEMA AVANÇADO DE NOCLIP / ATRAVESSAR PAREDES
    ============================================================
    Autor: Sistema Completo de Noclip
    Tipo: LocalScript
    Local: StarterPlayerScripts ou StarterCharacterScripts
    
    CONTROLES:
    - Pressione "N" para ativar/desativar o noclip
    - Pressione "F" para ativar o modo fantasma (transparência)
    - Pressione "G" para ativar o modo voar
    - Pressione "B" para ativar o speed boost
    - Pressione "H" para esconder a GUI
    - Pressione "T" para teleport ao cursor
    - Pressione "J" para ativar trail fantasma
    - Pressione "K" para ativar partículas
    - Pressione "L" para ativar som de fantasma
    - Pressione "M" para mudar cor do efeito
    ============================================================
--]]

-- ============================================================
-- SERVIÇOS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera

-- ============================================================
-- VARIÁVEIS DO JOGADOR
-- ============================================================
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()

-- ============================================================
-- ESTADOS DO SISTEMA
-- ============================================================
local NoclipEnabled = false
local GhostModeEnabled = false
local FlyEnabled = false
local SpeedBoostEnabled = false
local GUIVisible = true
local TrailEnabled = false
local ParticlesEnabled = false
local SoundEnabled = false
local TeleportEnabled = false

-- ============================================================
-- CONFIGURAÇÕES
-- ============================================================
local Config = {
    -- Noclip
    NoclipKey = Enum.KeyCode.N,
    NoclipCheckInterval = 0.01,
    
    -- Ghost Mode
    GhostKey = Enum.KeyCode.F,
    GhostTransparency = 0.6,
    GhostTransparencyMin = 0.3,
    GhostTransparencyMax = 0.9,
    GhostPulseSpeed = 2,
    
    -- Fly
    FlyKey = Enum.KeyCode.G,
    FlySpeed = 80,
    FlySpeedMin = 20,
    FlySpeedMax = 200,
    FlyAcceleration = 5,
    FlyDeceleration = 3,
    
    -- Speed Boost
    SpeedKey = Enum.KeyCode.B,
    SpeedBoostAmount = 80,
    NormalSpeed = 16,
    SpeedBoostMax = 200,
    
    -- GUI
    GUIToggleKey = Enum.KeyCode.H,
    
    -- Teleport
    TeleportKey = Enum.KeyCode.T,
    
    -- Trail
    TrailKey = Enum.KeyCode.J,
    TrailLifetime = 0.5,
    TrailColor1 = Color3.fromRGB(0, 170, 255),
    TrailColor2 = Color3.fromRGB(170, 0, 255),
    
    -- Particles
    ParticlesKey = Enum.KeyCode.K,
    ParticleRate = 50,
    ParticleLifetime = 1,
    ParticleSpeed = 5,
    
    -- Sound
    SoundKey = Enum.KeyCode.L,
    SoundId = "rbxassetid://9114727805",
    SoundVolume = 0.3,
    
    -- Color Cycle
    ColorKey = Enum.KeyCode.M,
    ColorCycleSpeed = 1,
    
    -- Efeitos visuais
    EffectColors = {
        Color3.fromRGB(0, 170, 255),
        Color3.fromRGB(170, 0, 255),
        Color3.fromRGB(0, 255, 170),
        Color3.fromRGB(255, 85, 0),
        Color3.fromRGB(255, 0, 85),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 0, 255),
    },
    CurrentColorIndex = 1,
}

-- ============================================================
-- VARIÁVEIS DE CONTROLE INTERNAS
-- ============================================================
local NoclipConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local CurrentFlySpeed = 0
local TargetFlySpeed = 0
local GhostPulseTime = 0
local OriginalTransparencies = {}
local TrailObject = nil
local ParticleEmitter = nil
local GhostSound = nil
local ActiveTweens = {}
local EffectParts = {}
local ConnectionsList = {}
local IsMoving = false
local LastPosition = Vector3.new(0, 0, 0)
local DistanceTraveled = 0
local NoclipActivationCount = 0
local TotalNoclipTime = 0
local NoclipStartTime = 0
local SessionStartTime = tick()

-- ============================================================
-- MÓDULO DE UTILIDADES
-- ============================================================
local Utilities = {}

function Utilities.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[NoclipSystem] Erro: " .. tostring(result))
    end
    return success, result
end

function Utilities.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utilities.LerpColor3(c1, c2, t)
    return Color3.new(
        Utilities.Lerp(c1.R, c2.R, t),
        Utilities.Lerp(c1.G, c2.G, t),
        Utilities.Lerp(c1.B, c2.B, t)
    )
end

function Utilities.HSVtoColor3(h, s, v)
    return Color3.fromHSV(h % 1, s, v)
end

function Utilities.GetRainbowColor(speed)
    local hue = (tick() * (speed or 1)) % 1
    return Color3.fromHSV(hue, 1, 1)
end

function Utilities.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

function Utilities.CreateSound(parent, soundId, volume, looped)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.Looped = looped or false
    sound.Parent = parent
    return sound
end

function Utilities.CleanupInstance(instance)
    if instance and instance.Parent then
        instance:Destroy()
    end
end

function Utilities.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utilities.RoundToDecimal(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utilities.GetCharacterParts()
    local parts = {}
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(parts, part)
            end
        end
    end
    return parts
end

function Utilities.IsAlive()
    return Character 
        and Character.Parent 
        and Humanoid 
        and Humanoid.Health > 0
        and HumanoidRootPart 
        and HumanoidRootPart.Parent
end

function Utilities.CalculateVelocity()
    if HumanoidRootPart then
        return HumanoidRootPart.Velocity.Magnitude
    end
    return 0
end

function Utilities.GetDirection()
    local moveDirection = Humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        return moveDirection.Unit
    end
    return Vector3.new(0, 0, 0)
end

-- ============================================================
-- MÓDULO DE INTERFACE (GUI)
-- ============================================================
local GUI = {}

function GUI.Create()
    -- Remover GUI existente se houver
    local existingGui = Player.PlayerGui:FindFirstChild("NoclipGUI")
    if existingGui then
        existingGui:Destroy()
    end
    
    -- ScreenGui principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NoclipGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = Player.PlayerGui
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 520)
    MainFrame.Position = UDim2.new(0, 15, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- Cantos arredondados do MainFrame
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Stroke do MainFrame
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Name = "MainStroke"
    MainStroke.Color = Config.EffectColors[Config.CurrentColorIndex]
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.3
    MainStroke.Parent = MainFrame
    
    -- Gradiente de fundo
    local BGGradient = Instance.new("UIGradient")
    BGGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 40)),
    })
    BGGradient.Rotation = 45
    BGGradient.Parent = MainFrame
    
    -- Sombra
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Header / Título
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 55)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    -- Fix para cantos inferiores do header
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Name = "HeaderFix"
    HeaderFix.Size = UDim2.new(1, 0, 0, 15)
    HeaderFix.Position = UDim2.new(0, 0, 1, -15)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    -- Gradiente do Header
    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Name = "HeaderGradient"
    HeaderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 200)),
    })
    HeaderGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0.7),
    })
    HeaderGradient.Parent = Header
    
    -- Ícone de fantasma (emoji texto)
    local GhostIcon = Instance.new("TextLabel")
    GhostIcon.Name = "GhostIcon"
    GhostIcon.Size = UDim2.new(0, 40, 0, 40)
    GhostIcon.Position = UDim2.new(0, 10, 0.5, -20)
    GhostIcon.BackgroundTransparency = 1
    GhostIcon.Text = "👻"
    GhostIcon.TextSize = 28
    GhostIcon.Font = Enum.Font.SourceSans
    GhostIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    GhostIcon.Parent = Header
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -60, 0, 25)
    Title.Position = UDim2.new(0, 55, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "NOCLIP SYSTEM"
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Subtítulo
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(1, -60, 0, 18)
    Subtitle.Position = UDim2.new(0, 55, 0, 28)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Pressione N para ativar"
    Subtitle.TextSize = 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Header
    
    -- Separador
    local Separator1 = Instance.new("Frame")
    Separator1.Name = "Separator1"
    Separator1.Size = UDim2.new(0.9, 0, 0, 1)
    Separator1.Position = UDim2.new(0.05, 0, 0, 58)
    Separator1.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    Separator1.BorderSizePixel = 0
    Separator1.Parent = MainFrame
    
    -- Container de Scroll para botões
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Name = "ScrollFrame"
    ScrollFrame.Size = UDim2.new(1, -20, 1, -130)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 65)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 200)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    ScrollFrame.Parent = MainFrame
    
    -- Layout para botões
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Name = "ListLayout"
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 6)
    ListLayout.Parent = ScrollFrame
    
    -- Padding do scroll
    local ScrollPadding = Instance.new("UIPadding")
    ScrollPadding.PaddingTop = UDim.new(0, 5)
    ScrollPadding.Parent = ScrollFrame
    
    -- ============================================================
    -- FUNÇÃO PARA CRIAR BOTÕES TOGGLE
    -- ============================================================
    local function CreateToggleButton(name, displayText, keyText, layoutOrder, defaultState)
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Name = name .. "Frame"
        ButtonFrame.Size = UDim2.new(1, 0, 0, 42)
        ButtonFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        ButtonFrame.BorderSizePixel = 0
        ButtonFrame.LayoutOrder = layoutOrder
        ButtonFrame.Parent = ScrollFrame
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 8)
        BtnCorner.Parent = ButtonFrame
        
        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Name = "BtnStroke"
        BtnStroke.Color = Color3.fromRGB(60, 60, 90)
        BtnStroke.Thickness = 1
        BtnStroke.Transparency = 0.5
        BtnStroke.Parent = ButtonFrame
        
        -- Indicador de estado (bolinha)
        local StatusIndicator = Instance.new("Frame")
        StatusIndicator.Name = "StatusIndicator"
        StatusIndicator.Size = UDim2.new(0, 12, 0, 12)
        StatusIndicator.Position = UDim2.new(0, 12, 0.5, -6)
        StatusIndicator.BackgroundColor3 = defaultState and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
        StatusIndicator.BorderSizePixel = 0
        StatusIndicator.Parent = ButtonFrame
        
        local StatusCorner = Instance.new("UICorner")
        StatusCorner.CornerRadius = UDim.new(1, 0)
        StatusCorner.Parent = StatusIndicator
        
        -- Glow do indicador
        local StatusGlow = Instance.new("ImageLabel")
        StatusGlow.Name = "StatusGlow"
        StatusGlow.Size = UDim2.new(0, 24, 0, 24)
        StatusGlow.Position = UDim2.new(0.5, -12, 0.5, -12)
        StatusGlow.BackgroundTransparency = 1
        StatusGlow.Image = "rbxassetid://5554236805"
        StatusGlow.ImageColor3 = defaultState and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
        StatusGlow.ImageTransparency = 0.6
        StatusGlow.Parent = StatusIndicator
        
        -- Nome do toggle
        local BtnLabel = Instance.new("TextLabel")
        BtnLabel.Name = "BtnLabel"
        BtnLabel.Size = UDim2.new(1, -100, 1, 0)
        BtnLabel.Position = UDim2.new(0, 32, 0, 0)
        BtnLabel.BackgroundTransparency = 1
        BtnLabel.Text = displayText
        BtnLabel.TextSize = 14
        BtnLabel.Font = Enum.Font.GothamSemibold
        BtnLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
        BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
        BtnLabel.Parent = ButtonFrame
        
        -- Tecla de atalho
        local KeyLabel = Instance.new("TextLabel")
        KeyLabel.Name = "KeyLabel"
        KeyLabel.Size = UDim2.new(0, 35, 0, 24)
        KeyLabel.Position = UDim2.new(1, -50, 0.5, -12)
        KeyLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        KeyLabel.BorderSizePixel = 0
        KeyLabel.Text = keyText
        KeyLabel.TextSize = 12
        KeyLabel.Font = Enum.Font.GothamBold
        KeyLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
        KeyLabel.Parent = ButtonFrame
        
        local KeyCorner = Instance.new("UICorner")
        KeyCorner.CornerRadius = UDim.new(0, 6)
        KeyCorner.Parent = KeyLabel
        
        -- Botão invisível para click
        local ClickButton = Instance.new("TextButton")
        ClickButton.Name = "ClickButton"
        ClickButton.Size = UDim2.new(1, 0, 1, 0)
        ClickButton.BackgroundTransparency = 1
        ClickButton.Text = ""
        ClickButton.ZIndex = 5
        ClickButton.Parent = ButtonFrame
        
        return ButtonFrame, ClickButton, StatusIndicator, BtnStroke
    end
    
    -- ============================================================
    -- CRIAR TODOS OS BOTÕES TOGGLE
    -- ============================================================
    local NoclipFrame, NoclipBtn, NoclipStatus, NoclipStroke = 
        CreateToggleButton("Noclip", "🚪 Noclip (Atravessar)", "N", 1, false)
    
    local GhostFrame, GhostBtn, GhostStatus, GhostStroke = 
        CreateToggleButton("Ghost", "👻 Modo Fantasma", "F", 2, false)
    
    local FlyFrame, FlyBtn, FlyStatus, FlyStroke = 
        CreateToggleButton("Fly", "🦅 Voar", "G", 3, false)
    
    local SpeedFrame, SpeedBtn, SpeedStatus, SpeedStroke = 
        CreateToggleButton("Speed", "⚡ Speed Boost", "B", 4, false)
    
    local TrailFrame, TrailBtn, TrailStatus, TrailStroke = 
        CreateToggleButton("Trail", "✨ Trail Fantasma", "J", 5, false)
    
    local ParticleFrame, ParticleBtn, ParticleStatus, ParticleStroke = 
        CreateToggleButton("Particles", "🌟 Partículas", "K", 6, false)
    
    local SoundFrame, SoundBtn, SoundStatus, SoundStroke = 
        CreateToggleButton("Sound", "🔊 Som Fantasma", "L", 7, false)
    
    local TeleportFrame, TeleportBtn, TeleportStatus, TeleportStroke = 
        CreateToggleButton("Teleport", "🎯 Teleport Cursor", "T", 8, false)
    
    local ColorFrame, ColorBtn, ColorStatus, ColorStroke = 
        CreateToggleButton("Color", "🎨 Mudar Cor", "M", 9, false)
    
    -- ============================================================
    -- PAINEL DE INFORMAÇÕES (Status)
    -- ============================================================
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Name = "InfoFrame"
    InfoFrame.Size = UDim2.new(1, -20, 0, 55)
    InfoFrame.Position = UDim2.new(0, 10, 1, -62)
    InfoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    InfoFrame.BorderSizePixel = 0
    InfoFrame.Parent = MainFrame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    local InfoStroke = Instance.new("UIStroke")
    InfoStroke.Color = Color3.fromRGB(50, 50, 80)
    InfoStroke.Thickness = 1
    InfoStroke.Transparency = 0.5
    InfoStroke.Parent = InfoFrame
    
    -- Velocidade
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Name = "SpeedLabel"
    SpeedLabel.Size = UDim2.new(0.5, 0, 0, 20)
    SpeedLabel.Position = UDim2.new(0, 10, 0, 5)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "Velocidade: 0"
    SpeedLabel.TextSize = 11
    SpeedLabel.Font = Enum.Font.Gotham
    SpeedLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = InfoFrame
    
    -- Posição
    local PosLabel = Instance.new("TextLabel")
    PosLabel.Name = "PosLabel"
    PosLabel.Size = UDim2.new(0.5, 0, 0, 20)
    PosLabel.Position = UDim2.new(0.5, 0, 0, 5)
    PosLabel.BackgroundTransparency = 1
    PosLabel.Text = "Pos: 0, 0, 0"
    PosLabel.TextSize = 11
    PosLabel.Font = Enum.Font.Gotham
    PosLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    PosLabel.TextXAlignment = Enum.TextXAlignment.Left
    PosLabel.Parent = InfoFrame
    
    -- Tempo de sessão
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Name = "TimeLabel"
    TimeLabel.Size = UDim2.new(0.5, 0, 0, 20)
    TimeLabel.Position = UDim2.new(0, 10, 0, 25)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "Sessão: 00:00"
    TimeLabel.TextSize = 11
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = InfoFrame
    
    -- Ativações
    local ActivationsLabel = Instance.new("TextLabel")
    ActivationsLabel.Name = "ActivationsLabel"
    ActivationsLabel.Size = UDim2.new(0.5, 0, 0, 20)
    ActivationsLabel.Position = UDim2.new(0.5, 0, 0, 25)
    ActivationsLabel.BackgroundTransparency = 1
    ActivationsLabel.Text = "Ativações: 0"
    ActivationsLabel.TextSize = 11
    ActivationsLabel.Font = Enum.Font.Gotham
    ActivationsLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    ActivationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ActivationsLabel.Parent = InfoFrame
    
    -- Watermark
    local Watermark = Instance.new("TextLabel")
    Watermark.Name = "Watermark"
    Watermark.Size = UDim2.new(1, 0, 0, 15)
    Watermark.Position = UDim2.new(0, 0, 1, -17)
    Watermark.BackgroundTransparency = 1
    Watermark.Text = "v2.0 | Noclip System"
    Watermark.TextSize = 10
    Watermark.Font = Enum.Font.Gotham
    Watermark.TextColor3 = Color3.fromRGB(80, 80, 120)
    Watermark.Parent = MainFrame
    
    -- ============================================================
    -- NOTIFICAÇÃO FLUTUANTE
    -- ============================================================
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Name = "NotifFrame"
    NotifFrame.Size = UDim2.new(0, 280, 0, 50)
    NotifFrame.Position = UDim2.new(0.5, -140, 0, -60)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Visible = false
    NotifFrame.ZIndex = 100
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame
    
    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Name = "NotifStroke"
    NotifStroke.Color = Config.EffectColors[1]
    NotifStroke.Thickness = 2
    NotifStroke.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Name = "NotifText"
    NotifText.Size = UDim2.new(1, -20, 1, 0)
    NotifText.Position = UDim2.new(0, 10, 0, 0)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = ""
    NotifText.TextSize = 14
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.TextXAlignment = Enum.TextXAlignment.Center
    NotifText.ZIndex = 101
    NotifText.Parent = NotifFrame
    
    -- ============================================================
    -- BARRA DE PROGRESSO (para speed/fly)
    -- ============================================================
    local ProgressBarBG = Instance.new("Frame")
    ProgressBarBG.Name = "ProgressBarBG"
    ProgressBarBG.Size = UDim2.new(0, 200, 0, 6)
    ProgressBarBG.Position = UDim2.new(0.5, -100, 1, -30)
    ProgressBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    ProgressBarBG.BorderSizePixel = 0
    ProgressBarBG.Visible = false
    ProgressBarBG.ZIndex = 100
    ProgressBarBG.Parent = ScreenGui
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(1, 0)
    ProgressCorner.Parent = ProgressBarBG
    
    local ProgressFill = Instance.new("Frame")
    ProgressFill.Name = "ProgressFill"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = Config.EffectColors[1]
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBarBG
    
    local ProgressFillCorner = Instance.new("UICorner")
    ProgressFillCorner.CornerRadius = UDim.new(1, 0)
    ProgressFillCorner.Parent = ProgressFill
    
    local ProgressGradient = Instance.new("UIGradient")
    ProgressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255)),
    })
    ProgressGradient.Parent = ProgressFill
    
    -- Retornar referências
    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        MainStroke = MainStroke,
        Header = Header,
        HeaderGradient = HeaderGradient,
        Title = Title,
        Subtitle = Subtitle,
        GhostIcon = GhostIcon,
        ScrollFrame = ScrollFrame,
        -- Botões e status
        NoclipBtn = NoclipBtn, NoclipStatus = NoclipStatus, NoclipStroke = NoclipStroke, NoclipFrame = NoclipFrame,
        GhostBtn = GhostBtn, GhostStatus = GhostStatus, GhostStroke = GhostStroke, GhostFrame = GhostFrame,
        FlyBtn = FlyBtn, FlyStatus = FlyStatus, FlyStroke = FlyStroke, FlyFrame = FlyFrame,
        SpeedBtn = SpeedBtn, SpeedStatus = SpeedStatus, SpeedStroke = SpeedStroke, SpeedFrame = SpeedFrame,
        TrailBtn = TrailBtn, TrailStatus = TrailStatus, TrailStroke = TrailStroke, TrailFrame = TrailFrame,
        ParticleBtn = ParticleBtn, ParticleStatus = ParticleStatus, ParticleStroke = ParticleStroke, ParticleFrame = ParticleFrame,
        SoundBtn = SoundBtn, SoundStatus = SoundStatus, SoundStroke = SoundStroke, SoundFrame = SoundFrame,
        TeleportBtn = TeleportBtn, TeleportStatus = TeleportStatus, TeleportStroke = TeleportStroke, TeleportFrame = TeleportFrame,
        ColorBtn = ColorBtn, ColorStatus = ColorStatus, ColorStroke = ColorStroke, ColorFrame = ColorFrame,
        -- Info
        SpeedLabel = SpeedLabel,
        PosLabel = PosLabel,
        TimeLabel = TimeLabel,
        ActivationsLabel = ActivationsLabel,
        InfoFrame = InfoFrame,
        -- Notificação
        NotifFrame = NotifFrame,
        NotifText = NotifText,
        NotifStroke = NotifStroke,
        -- Progress Bar
        ProgressBarBG = ProgressBarBG,
        ProgressFill = ProgressFill,
    }
end

-- Referências da GUI
local GUIElements = nil

-- ============================================================
-- SISTEMA DE NOTIFICAÇÕES
-- ============================================================
local NotificationQueue = {}
local IsShowingNotification = false

local function ShowNotification(text, color, duration)
    if not GUIElements then return end
    
    duration = duration or 2
    color = color or Config.EffectColors[Config.CurrentColorIndex]
    
    table.insert(NotificationQueue, {text = text, color = color, duration = duration})
    
    if IsShowingNotification then return end
    IsShowingNotification = true
    
    local function ProcessNext()
        if #NotificationQueue == 0 then
            IsShowingNotification = false
            return
        end
        
        local notif = table.remove(NotificationQueue, 1)
        
        Utilities.SafeCall(function()
            GUIElements.NotifText.Text = notif.text
            GUIElements.NotifStroke.Color = notif.color
            GUIElements.NotifFrame.Position = UDim2.new(0.5, -140, 0, -60)
            GUIElements.NotifFrame.Visible = true
            GUIElements.NotifFrame.BackgroundTransparency = 0
            
            -- Animação de entrada
            local tweenIn = TweenService:Create(
                GUIElements.NotifFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -140, 0, 20)}
            )
            tweenIn:Play()
            
            -- Esperar duração
            task.delay(notif.duration, function()
                -- Animação de saída
                local tweenOut = TweenService:Create(
                    GUIElements.NotifFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {Position = UDim2.new(0.5, -140, 0, -60), BackgroundTransparency = 1}
                )
                tweenOut:Play()
                tweenOut.Completed:Connect(function()
                    GUIElements.NotifFrame.Visible = false
                    ProcessNext()
                end)
            end)
        end)
    end
    
    ProcessNext()
end

-- ============================================================
-- ATUALIZAR ESTADO DOS BOTÕES NA GUI
-- ============================================================
local function UpdateButtonState(statusIndicator, stroke, frame, enabled)
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local color = enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
        local bgColor = enabled and Color3.fromRGB(30, 50, 40) or Color3.fromRGB(35, 35, 55)
        local strokeColor = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 90)
        
        -- Tween do indicador
        TweenService:Create(
            statusIndicator,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {BackgroundColor3 = color}
        ):Play()
        
        -- Glow do indicador
        local glow = statusIndicator:FindFirstChild("StatusGlow")
        if glow then
            TweenService:Create(
                glow,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {ImageColor3 = color}
            ):Play()
        end
        
        -- Tween do frame
        TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {BackgroundColor3 = bgColor}
        ):Play()
        
        -- Tween do stroke
        TweenService:Create(
            stroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {Color = strokeColor}
        ):Play()
    end)
end

-- ============================================================
-- MÓDULO NOCLIP (ATRAVESSAR PAREDES)
-- ============================================================
local NoclipModule = {}

function NoclipModule.Enable()
    if NoclipEnabled then return end
    NoclipEnabled = true
    NoclipActivationCount = NoclipActivationCount + 1
    NoclipStartTime = tick()
    
    -- Salvar transparências originais
    OriginalTransparencies = {}
    for _, part in pairs(Utilities.GetCharacterParts()) do
        OriginalTransparencies[part] = part.CanCollide
    end
    
    -- Loop de noclip
    NoclipConnection = RunService.Stepped:Connect(function()
        if not Utilities.IsAlive() then return end
        if not NoclipEnabled then return end
        
        -- Desabilitar colisão de todas as partes do personagem
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    
    -- Efeito visual de ativação
    NoclipModule.PlayActivationEffect()
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.NoclipStatus, GUIElements.NoclipStroke, GUIElements.NoclipFrame, true)
        GUIElements.Subtitle.Text = "Noclip ATIVADO"
        GUIElements.Subtitle.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
    
    ShowNotification("🚪 NOCLIP ATIVADO", Color3.fromRGB(0, 255, 100), 1.5)
end

function NoclipModule.Disable()
    if not NoclipEnabled then return end
    NoclipEnabled = false
    
    -- Calcular tempo de uso
    if NoclipStartTime > 0 then
        TotalNoclipTime = TotalNoclipTime + (tick() - NoclipStartTime)
        NoclipStartTime = 0
    end
    
    -- Desconectar loop
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    -- Restaurar colisão
    Utilities.SafeCall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        -- Manter HumanoidRootPart sem colisão se necessário
        if HumanoidRootPart then
            HumanoidRootPart.CanCollide = true
        end
    end)
    
    -- Efeito visual de desativação
    NoclipModule.PlayDeactivationEffect()
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.NoclipStatus, GUIElements.NoclipStroke, GUIElements.NoclipFrame, false)
        GUIElements.Subtitle.Text = "Pressione N para ativar"
        GUIElements.Subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    end
    
    ShowNotification("🚪 NOCLIP DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function NoclipModule.Toggle()
    if NoclipEnabled then
        NoclipModule.Disable()
    else
        NoclipModule.Enable()
    end
end

function NoclipModule.PlayActivationEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Criar anel de ativação
        for i = 1, 3 do
            task.spawn(function()
                local ring = Instance.new("Part")
                ring.Name = "NoclipRing"
                ring.Shape = Enum.PartType.Cylinder
                ring.Size = Vector3.new(0.2, 2, 2)
                ring.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
                ring.Anchored = true
                ring.CanCollide = false
                ring.Material = Enum.Material.Neon
                ring.Color = Config.EffectColors[Config.CurrentColorIndex]
                ring.Transparency = 0.3
                ring.Parent = Workspace
                
                table.insert(EffectParts, ring)
                
                local targetSize = Vector3.new(0.1, 15 + (i * 3), 15 + (i * 3))
                
                task.delay(i * 0.15, function()
                    local tween = TweenService:Create(
                        ring,
                        TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = targetSize, Transparency = 1}
                    )
                    tween:Play()
                    tween.Completed:Connect(function()
                        ring:Destroy()
                    end)
                end)
            end)
        end
        
        -- Flash no personagem
        for _, part in pairs(Utilities.GetCharacterParts()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                task.spawn(function()
                    local origColor = part.Color
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Config.EffectColors[Config.CurrentColorIndex]
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.Parent = Character
                    
                    local tween = TweenService:Create(
                        highlight,
                        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {FillTransparency = 1, OutlineTransparency = 1}
                    )
                    tween:Play()
                    tween.Completed:Connect(function()
                        highlight:Destroy()
                    end)
                end)
            end
        end
    end)
end

function NoclipModule.PlayDeactivationEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Partículas de desativação
        for i = 1, 12 do
            task.spawn(function()
                local particle = Instance.new("Part")
                particle.Name = "DeactivateParticle"
                particle.Size = Vector3.new(0.3, 0.3, 0.3)
                particle.Shape = Enum.PartType.Ball
                particle.CFrame = HumanoidRootPart.CFrame * CFrame.new(
                    math.random(-3, 3),
                    math.random(-3, 3),
                    math.random(-3, 3)
                )
                particle.Anchored = true
                particle.CanCollide = false
                particle.Material = Enum.Material.Neon
                particle.Color = Color3.fromRGB(255, 60, 60)
                particle.Transparency = 0
                particle.Parent = Workspace
                
                local targetPos = particle.CFrame * CFrame.new(
                    math.random(-5, 5),
                    math.random(-5, 5),
                    math.random(-5, 5)
                )
                
                local tween = TweenService:Create(
                    particle,
                    TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CFrame = targetPos, Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
                )
                tween:Play()
                tween.Completed:Connect(function()
                    particle:Destroy()
                end)
            end)
        end
    end)
end

-- ============================================================
-- MÓDULO GHOST MODE (MODO FANTASMA)
-- ============================================================
local GhostModule = {}

function GhostModule.Enable()
    if GhostModeEnabled then return end
    GhostModeEnabled = true
    
    -- Salvar transparências originais
    GhostModule.OriginalData = {}
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            GhostModule.OriginalData[part] = {
                Transparency = part.Transparency,
                Material = part.Material,
                Color = part.Color,
            }
        end
    end
    
    -- Aplicar efeito fantasma
    GhostModule.ApplyGhostEffect()
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.GhostStatus, GUIElements.GhostStroke, GUIElements.GhostFrame, true)
    end
    
    ShowNotification("👻 MODO FANTASMA ATIVADO", Color3.fromRGB(170, 0, 255), 1.5)
end

function GhostModule.Disable()
    if not GhostModeEnabled then return end
    GhostModeEnabled = false
    
    -- Restaurar aparência
    Utilities.SafeCall(function()
        if GhostModule.OriginalData then
            for part, data in pairs(GhostModule.OriginalData) do
                if part and part.Parent then
                    part.Transparency = data.Transparency
                    part.Material = data.Material
                    part.Color = data.Color
                end
            end
        end
        
        -- Remover highlight se existir
        local highlight = Character:FindFirstChildOfClass("Highlight")
        if highlight and highlight.Name == "GhostHighlight" then
            highlight:Destroy()
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.GhostStatus, GUIElements.GhostStroke, GUIElements.GhostFrame, false)
    end
    
    ShowNotification("👻 MODO FANTASMA DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function GhostModule.Toggle()
    if GhostModeEnabled then
        GhostModule.Disable()
    else
        GhostModule.Enable()
    end
end

function GhostModule.ApplyGhostEffect()
    Utilities.SafeCall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Material = Enum.Material.ForceField
                part.Transparency = Config.GhostTransparency
            end
        end
        
        -- Adicionar highlight fantasma
        local existingHighlight = Character:FindFirstChild("GhostHighlight")
        if not existingHighlight then
            local highlight = Instance.new("Highlight")
            highlight.Name = "GhostHighlight"
            highlight.FillColor = Config.EffectColors[Config.CurrentColorIndex]
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Config.EffectColors[Config.CurrentColorIndex]
            highlight.OutlineTransparency = 0.3
            highlight.Parent = Character
        end
    end)
end

function GhostModule.UpdatePulse(dt)
    if not GhostModeEnabled then return end
    if not Utilities.IsAlive() then return end
    
    GhostPulseTime = GhostPulseTime + dt * Config.GhostPulseSpeed
    local pulseValue = (math.sin(GhostPulseTime) + 1) / 2
    local transparency = Utilities.Lerp(Config.GhostTransparencyMin, Config.GhostTransparencyMax, pulseValue)
    
    Utilities.SafeCall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = transparency
            end
        end
        
        -- Atualizar highlight
        local highlight = Character:FindFirstChild("GhostHighlight")
        if highlight then
            highlight.FillTransparency = 0.5 + pulseValue * 0.3
            highlight.OutlineTransparency = 0.1 + pulseValue * 0.4
            
            local currentColor = Config.EffectColors[Config.CurrentColorIndex]
            highlight.FillColor = currentColor
            highlight.OutlineColor = currentColor
        end
    end)
end

-- ============================================================
-- MÓDULO DE VOO (FLY)
-- ============================================================
local FlyModule = {}

function FlyModule.Enable()
    if FlyEnabled then return end
    FlyEnabled = true
    
    Utilities.SafeCall(function()
        -- Criar BodyVelocity
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.P = 9000
        FlyBodyVelocity.Parent = HumanoidRootPart
        
        -- Criar BodyGyro
        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyGyro.P = 9000
        FlyBodyGyro.D = 500
        FlyBodyGyro.Parent = HumanoidRootPart
        
        -- Desabilitar gravidade
        Humanoid.PlatformStand = true
    end)
    
    -- Efeito de ativação
    FlyModule.PlayActivationEffect()
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.FlyStatus, GUIElements.FlyStroke, GUIElements.FlyFrame, true)
        GUIElements.ProgressBarBG.Visible = true
    end
    
    ShowNotification("🦅 MODO VOAR ATIVADO", Color3.fromRGB(0, 200, 255), 1.5)
end

function FlyModule.Disable()
    if not FlyEnabled then return end
    FlyEnabled = false
    CurrentFlySpeed = 0
    
    Utilities.SafeCall(function()
        -- Remover BodyVelocity
        if FlyBodyVelocity then
            FlyBodyVelocity:Destroy()
            FlyBodyVelocity = nil
        end
        
        -- Remover BodyGyro
        if FlyBodyGyro then
            FlyBodyGyro:Destroy()
            FlyBodyGyro = nil
        end
        
        -- Restaurar gravidade
        if Humanoid then
            Humanoid.PlatformStand = false
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.FlyStatus, GUIElements.FlyStroke, GUIElements.FlyFrame, false)
        GUIElements.ProgressBarBG.Visible = false
    end
    
    ShowNotification("🦅 MODO VOAR DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function FlyModule.Toggle()
    if FlyEnabled then
        FlyModule.Disable()
    else
        FlyModule.Enable()
    end
end

function FlyModule.Update(dt)
    if not FlyEnabled then return end
    if not Utilities.IsAlive() then return end
    if not FlyBodyVelocity or not FlyBodyGyro then return end
    
    Utilities.SafeCall(function()
        local camera = Camera
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Calcular direção de movimento
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Aceleração/Desaceleração suave
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            CurrentFlySpeed = Utilities.Lerp(CurrentFlySpeed, Config.FlySpeed, dt * Config.FlyAcceleration)
        else
            CurrentFlySpeed = Utilities.Lerp(CurrentFlySpeed, 0, dt * Config.FlyDeceleration)
        end
        
        -- Aplicar velocidade
        FlyBodyVelocity.Velocity = moveDirection * CurrentFlySpeed
        
        -- Rotação suave da câmera
        FlyBodyGyro.CFrame = camera.CFrame
        
        -- Atualizar barra de progresso
        if GUIElements then
            local speedPercent = CurrentFlySpeed / Config.FlySpeedMax
            GUIElements.ProgressFill.Size = UDim2.new(speedPercent, 0, 1, 0)
        end
    end)
end

function FlyModule.PlayActivationEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Criar ondas de energia
        for i = 1, 5 do
            task.spawn(function()
                task.wait(i * 0.1)
                local wave = Instance.new("Part")
                wave.Name = "FlyWave"
                wave.Shape = Enum.PartType.Ball
                wave.Size = Vector3.new(1, 1, 1)
                wave.CFrame = HumanoidRootPart.CFrame
                wave.Anchored = true
                wave.CanCollide = false
                wave.Material = Enum.Material.Neon
                wave.Color = Config.EffectColors[Config.CurrentColorIndex]
                wave.Transparency = 0.3
                wave.Parent = Workspace
                
                local tween = TweenService:Create(
                    wave,
                    TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = Vector3.new(20, 20, 20), Transparency = 1}
                )
                tween:Play()
                tween.Completed:Connect(function()
                    wave:Destroy()
                end)
            end)
        end
    end)
end

-- ============================================================
-- MÓDULO SPEED BOOST
-- ============================================================
local SpeedModule = {}

function SpeedModule.Enable()
    if SpeedBoostEnabled then return end
    SpeedBoostEnabled = true
    
    Utilities.SafeCall(function()
        if Humanoid then
            Humanoid.WalkSpeed = Config.SpeedBoostAmount
        end
    end)
    
    -- Efeito de velocidade
    SpeedModule.PlayEffect()
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.SpeedStatus, GUIElements.SpeedStroke, GUIElements.SpeedFrame, true)
    end
    
    ShowNotification("⚡ SPEED BOOST ATIVADO (" .. Config.SpeedBoostAmount .. ")", Color3.fromRGB(255, 200, 0), 1.5)
end

function SpeedModule.Disable()
    if not SpeedBoostEnabled then return end
    SpeedBoostEnabled = false
    
    Utilities.SafeCall(function()
        if Humanoid then
            Humanoid.WalkSpeed = Config.NormalSpeed
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.SpeedStatus, GUIElements.SpeedStroke, GUIElements.SpeedFrame, false)
    end
    
    ShowNotification("⚡ SPEED BOOST DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function SpeedModule.Toggle()
    if SpeedBoostEnabled then
        SpeedModule.Disable()
    else
        SpeedModule.Enable()
    end
end

function SpeedModule.PlayEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Linhas de velocidade
        for i = 1, 8 do
            task.spawn(function()
                local line = Instance.new("Part")
                line.Name = "SpeedLine"
                line.Size = Vector3.new(0.1, 0.1, math.random(5, 15))
                line.CFrame = HumanoidRootPart.CFrame * CFrame.new(
                    math.random(-3, 3),
                    math.random(-3, 3),
                    -math.random(2, 8)
                )
                line.Anchored = true
                line.CanCollide = false
                line.Material = Enum.Material.Neon
                line.Color = Color3.fromRGB(255, 200, 0)
                line.Transparency = 0.3
                line.Parent = Workspace
                
                local tween = TweenService:Create(
                    line,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        CFrame = line.CFrame * CFrame.new(0, 0, -20),
                        Transparency = 1,
                        Size = Vector3.new(0.05, 0.05, 0.5)
                    }
                )
                tween:Play()
                tween.Completed:Connect(function()
                    line:Destroy()
                end)
            end)
        end
    end)
end

-- ============================================================
-- MÓDULO DE TRAIL
-- ============================================================
local TrailModule = {}

function TrailModule.Enable()
    if TrailEnabled then return end
    TrailEnabled = true
    
    Utilities.SafeCall(function()
        -- Criar attachments
        local attachment0 = Instance.new("Attachment")
        attachment0.Name = "TrailAttachment0"
        attachment0.Position = Vector3.new(0, 1.5, 0)
        attachment0.Parent = HumanoidRootPart
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Name = "TrailAttachment1"
        attachment1.Position = Vector3.new(0, -1.5, 0)
        attachment1.Parent = HumanoidRootPart
        
        -- Criar trail
        TrailObject = Instance.new("Trail")
        TrailObject.Name = "NoclipTrail"
        TrailObject.Attachment0 = attachment0
        TrailObject.Attachment1 = attachment1
        TrailObject.Lifetime = Config.TrailLifetime
        TrailObject.MinLength = 0.1
        TrailObject.MaxLength = 0
        TrailObject.FaceCamera = true
        TrailObject.LightInfluence = 0
        TrailObject.LightEmission = 1
        
        TrailObject.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.TrailColor1),
            ColorSequenceKeypoint.new(0.5, Config.TrailColor2),
            ColorSequenceKeypoint.new(1, Config.TrailColor1),
        })
        
        TrailObject.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        
        TrailObject.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0),
        })
        
        TrailObject.Parent = HumanoidRootPart
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.TrailStatus, GUIElements.TrailStroke, GUIElements.TrailFrame, true)
    end
    
    ShowNotification("✨ TRAIL ATIVADO", Color3.fromRGB(0, 170, 255), 1.5)
end

function TrailModule.Disable()
    if not TrailEnabled then return end
    TrailEnabled = false
    
    Utilities.SafeCall(function()
        if TrailObject then
            TrailObject:Destroy()
            TrailObject = nil
        end
        
        -- Remover attachments
        if HumanoidRootPart then
            local a0 = HumanoidRootPart:FindFirstChild("TrailAttachment0")
            local a1 = HumanoidRootPart:FindFirstChild("TrailAttachment1")
            if a0 then a0:Destroy() end
            if a1 then a1:Destroy() end
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.TrailStatus, GUIElements.TrailStroke, GUIElements.TrailFrame, false)
    end
    
    ShowNotification("✨ TRAIL DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function TrailModule.Toggle()
    if TrailEnabled then
        TrailModule.Disable()
    else
        TrailModule.Enable()
    end
end

function TrailModule.UpdateColor()
    if not TrailEnabled or not TrailObject then return end
    
    Utilities.SafeCall(function()
        local color = Config.EffectColors[Config.CurrentColorIndex]
        local color2 = Config.EffectColors[(Config.CurrentColorIndex % #Config.EffectColors) + 1]
        
        TrailObject.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(0.5, color2),
            ColorSequenceKeypoint.new(1, color),
        })
    end)
end

-- ============================================================
-- MÓDULO DE PARTÍCULAS
-- ============================================================
local ParticleModule = {}

function ParticleModule.Enable()
    if ParticlesEnabled then return end
    ParticlesEnabled = true
    
    Utilities.SafeCall(function()
        ParticleEmitter = Instance.new("ParticleEmitter")
        ParticleEmitter.Name = "NoclipParticles"
        ParticleEmitter.Rate = Config.ParticleRate
        ParticleEmitter.Lifetime = NumberRange.new(0.5, Config.ParticleLifetime)
        ParticleEmitter.Speed = NumberRange.new(1, Config.ParticleSpeed)
        ParticleEmitter.SpreadAngle = Vector2.new(180, 180)
        ParticleEmitter.RotSpeed = NumberRange.new(-100, 100)
        ParticleEmitter.Rotation = NumberRange.new(0, 360)
        ParticleEmitter.LightEmission = 1
        ParticleEmitter.LightInfluence = 0
        
        local color = Config.EffectColors[Config.CurrentColorIndex]
        ParticleEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        })
        
        ParticleEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 0),
        })
        
        ParticleEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        
        ParticleEmitter.Texture = "rbxassetid://6490035152"
        ParticleEmitter.Parent = HumanoidRootPart
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.ParticleStatus, GUIElements.ParticleStroke, GUIElements.ParticleFrame, true)
    end
    
    ShowNotification("🌟 PARTÍCULAS ATIVADAS", Color3.fromRGB(255, 255, 0), 1.5)
end

function ParticleModule.Disable()
    if not ParticlesEnabled then return end
    ParticlesEnabled = false
    
    Utilities.SafeCall(function()
        if ParticleEmitter then
            ParticleEmitter:Destroy()
            ParticleEmitter = nil
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.ParticleStatus, GUIElements.ParticleStroke, GUIElements.ParticleFrame, false)
    end
    
    ShowNotification("🌟 PARTÍCULAS DESATIVADAS", Color3.fromRGB(255, 60, 60), 1.5)
end

function ParticleModule.Toggle()
    if ParticlesEnabled then
        ParticleModule.Disable()
    else
        ParticleModule.Enable()
    end
end

function ParticleModule.UpdateColor()
    if not ParticlesEnabled or not ParticleEmitter then return end
    
    Utilities.SafeCall(function()
        local color = Config.EffectColors[Config.CurrentColorIndex]
        ParticleEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        })
    end)
end

-- ============================================================
-- MÓDULO DE SOM
-- ============================================================
local SoundModule = {}

function SoundModule.Enable()
    if SoundEnabled then return end
    SoundEnabled = true
    
    Utilities.SafeCall(function()
        GhostSound = Utilities.CreateSound(
            HumanoidRootPart,
            Config.SoundId,
            Config.SoundVolume,
            true
        )
        GhostSound.Name = "GhostSound"
        GhostSound:Play()
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.SoundStatus, GUIElements.SoundStroke, GUIElements.SoundFrame, true)
    end
    
    ShowNotification("🔊 SOM FANTASMA ATIVADO", Color3.fromRGB(100, 200, 255), 1.5)
end

function SoundModule.Disable()
    if not SoundEnabled then return end
    SoundEnabled = false
    
    Utilities.SafeCall(function()
        if GhostSound then
            GhostSound:Stop()
            GhostSound:Destroy()
            GhostSound = nil
        end
    end)
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.SoundStatus, GUIElements.SoundStroke, GUIElements.SoundFrame, false)
    end
    
    ShowNotification("🔊 SOM FANTASMA DESATIVADO", Color3.fromRGB(255, 60, 60), 1.5)
end

function SoundModule.Toggle()
    if SoundEnabled then
        SoundModule.Disable()
    else
        SoundModule.Enable()
    end
end

-- ============================================================
-- MÓDULO DE TELEPORT
-- ============================================================
local TeleportModule = {}

function TeleportModule.Execute()
    Utilities.SafeCall(function()
        if not Utilities.IsAlive() then return end
        
        local target = Mouse.Hit
        if target then
            -- Efeito de saída
            TeleportModule.PlayExitEffect()
            
            -- Teleportar
            task.wait(0.1)
            HumanoidRootPart.CFrame = target + Vector3.new(0, 5, 0)
            
            -- Efeito de chegada
            task.wait(0.1)
            TeleportModule.PlayArrivalEffect()
            
            ShowNotification("🎯 TELEPORTADO!", Color3.fromRGB(0, 255, 170), 1)
        end
    end)
end

function TeleportModule.PlayExitEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Implosão
        for i = 1, 6 do
            task.spawn(function()
                local part = Instance.new("Part")
                part.Size = Vector3.new(8, 8, 8)
                part.Shape = Enum.PartType.Ball
                part.CFrame = HumanoidRootPart.CFrame * CFrame.new(
                    math.random(-8, 8),
                    math.random(-8, 8),
                    math.random(-8, 8)
                )
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.Color = Config.EffectColors[Config.CurrentColorIndex]
                part.Transparency = 0.5
                part.Parent = Workspace
                
                local tween = TweenService:Create(
                    part,
                    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {CFrame = HumanoidRootPart.CFrame, Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}
                )
                tween:Play()
                tween.Completed:Connect(function()
                    part:Destroy()
                end)
            end)
        end
    end)
end

function TeleportModule.PlayArrivalEffect()
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Explosão de chegada
        local sphere = Instance.new("Part")
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(1, 1, 1)
        sphere.CFrame = HumanoidRootPart.CFrame
        sphere.Anchored = true
        sphere.CanCollide = false
        sphere.Material = Enum.Material.Neon
        sphere.Color = Config.EffectColors[Config.CurrentColorIndex]
        sphere.Transparency = 0.3
        sphere.Parent = Workspace
        
        local tween = TweenService:Create(
            sphere,
            TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(25, 25, 25), Transparency = 1}
        )
        tween:Play()
        tween.Completed:Connect(function()
            sphere:Destroy()
        end)
        
        -- Partículas de chegada
        for i = 1, 15 do
            task.spawn(function()
                local p = Instance.new("Part")
                p.Size = Vector3.new(0.4, 0.4, 0.4)
                p.Shape = Enum.PartType.Ball
                p.CFrame = HumanoidRootPart.CFrame
                p.Anchored = true
                p.CanCollide = false
                p.Material = Enum.Material.Neon
                p.Color = Config.EffectColors[math.random(1, #Config.EffectColors)]
                p.Transparency = 0
                p.Parent = Workspace
                
                local targetCF = HumanoidRootPart.CFrame * CFrame.new(
                    math.random(-12, 12),
                    math.random(-12, 12),
                    math.random(-12, 12)
                )
                
                local tw = TweenService:Create(
                    p,
                    TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CFrame = targetCF, Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
                )
                tw:Play()
                tw.Completed:Connect(function()
                    p:Destroy()
                end)
            end)
        end
    end)
end

-- ============================================================
-- MÓDULO DE CORES
-- ============================================================
local ColorModule = {}

function ColorModule.CycleColor()
    Config.CurrentColorIndex = (Config.CurrentColorIndex % #Config.EffectColors) + 1
    local newColor = Config.EffectColors[Config.CurrentColorIndex]
    
    -- Atualizar stroke principal
    if GUIElements then
        TweenService:Create(
            GUIElements.MainStroke,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad),
            {Color = newColor}
        ):Play()
    end
    
    -- Atualizar trail
    TrailModule.UpdateColor()
    
    -- Atualizar partículas
    ParticleModule.UpdateColor()
    
    -- Atualizar ghost highlight
    if GhostModeEnabled then
        Utilities.SafeCall(function()
            local highlight = Character:FindFirstChild("GhostHighlight")
            if highlight then
                highlight.FillColor = newColor
                highlight.OutlineColor = newColor
            end
        end)
    end
    
    -- Efeito de mudança de cor
    ColorModule.PlayChangeEffect(newColor)
    
    local colorNames = {"Azul", "Roxo", "Verde Água", "Laranja", "Rosa", "Amarelo", "Branco", "Verde", "Vermelho", "Azul Escuro"}
    local colorName = colorNames[Config.CurrentColorIndex] or "Custom"
    
    ShowNotification("🎨 COR: " .. colorName, newColor, 1.5)
end

function ColorModule.PlayChangeEffect(color)
    Utilities.SafeCall(function()
        if not HumanoidRootPart then return end
        
        -- Anel de cor
        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Ball
        ring.Size = Vector3.new(3, 3, 3)
        ring.CFrame = HumanoidRootPart.CFrame
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = color
        ring.Transparency = 0.3
        ring.Parent = Workspace
        
        local tween = TweenService:Create(
            ring,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(15, 15, 15), Transparency = 1}
        )
        tween:Play()
        tween.Completed:Connect(function()
            ring:Destroy()
        end)
    end)
end

-- ============================================================
-- SISTEMA DE INPUT (TECLADO)
-- ============================================================
local function SetupInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Noclip Toggle (N)
        if input.KeyCode == Config.NoclipKey then
            NoclipModule.Toggle()
        end
        
        -- Ghost Mode Toggle (F)
        if input.KeyCode == Config.GhostKey then
            GhostModule.Toggle()
        end
        
        -- Fly Toggle (G)
        if input.KeyCode == Config.FlyKey then
            FlyModule.Toggle()
        end
        
        -- Speed Boost Toggle (B)
        if input.KeyCode == Config.SpeedKey then
            SpeedModule.Toggle()
        end
        
        -- GUI Toggle (H)
        if input.KeyCode == Config.GUIToggleKey then
            GUIVisible = not GUIVisible
            if GUIElements then
                local targetPos
                if GUIVisible then
                    targetPos = UDim2.new(0, 15, 0.5, -260)
                    GUIElements.MainFrame.Visible = true
                else
                    targetPos = UDim2.new(0, -350, 0.5, -260)
                end
                
                local tween = TweenService:Create(
                    GUIElements.MainFrame,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, GUIVisible and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                    {Position = targetPos}
                )
                tween:Play()
                
                if not GUIVisible then
                    tween.Completed:Connect(function()
                        if not GUIVisible then
                            -- Manter invisível
                        end
                    end)
                end
                
                ShowNotification(GUIVisible and "📱 GUI VISÍVEL" or "📱 GUI OCULTA (H para mostrar)", Color3.fromRGB(200, 200, 255), 1)
            end
        end
        
        -- Teleport (T)
        if input.KeyCode == Config.TeleportKey then
            TeleportModule.Execute()
        end
        
        -- Trail Toggle (J)
        if input.KeyCode == Config.TrailKey then
            TrailModule.Toggle()
        end
        
        -- Particles Toggle (K)
        if input.KeyCode == Config.ParticlesKey then
            ParticleModule.Toggle()
        end
        
        -- Sound Toggle (L)
        if input.KeyCode == Config.SoundKey then
            SoundModule.Toggle()
        end
        
        -- Color Cycle (M)
        if input.KeyCode == Config.ColorKey then
            ColorModule.CycleColor()
        end
        
        -- Fly Speed Control (Scroll ou + -)
        if FlyEnabled then
            if input.KeyCode == Enum.KeyCode.Plus or input.KeyCode == Enum.KeyCode.KeypadPlus then
                Config.FlySpeed = Utilities.Clamp(Config.FlySpeed + 10, Config.FlySpeedMin, Config.FlySpeedMax)
                ShowNotification("🦅 Fly Speed: " .. Config.FlySpeed, Color3.fromRGB(0, 200, 255), 0.8)
            end
            if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
                Config.FlySpeed = Utilities.Clamp(Config.FlySpeed - 10, Config.FlySpeedMin, Config.FlySpeedMax)
                ShowNotification("🦅 Fly Speed: " .. Config.FlySpeed, Color3.fromRGB(0, 200, 255), 0.8)
            end
        end
        
        -- Speed Boost Control
        if SpeedBoostEnabled then
            if input.KeyCode == Enum.KeyCode.RightBracket then
                Config.SpeedBoostAmount = Utilities.Clamp(Config.SpeedBoostAmount + 10, Config.NormalSpeed, Config.SpeedBoostMax)
                Humanoid.WalkSpeed = Config.SpeedBoostAmount
                ShowNotification("⚡ Speed: " .. Config.SpeedBoostAmount, Color3.fromRGB(255, 200, 0), 0.8)
            end
            if input.KeyCode == Enum.KeyCode.LeftBracket then
                Config.SpeedBoostAmount = Utilities.Clamp(Config.SpeedBoostAmount - 10, Config.NormalSpeed, Config.SpeedBoostMax)
                Humanoid.WalkSpeed = Config.SpeedBoostAmount
                ShowNotification("⚡ Speed: " .. Config.SpeedBoostAmount, Color3.fromRGB(255, 200, 0), 0.8)
            end
        end
    end)
end

-- ============================================================
-- SETUP DOS CLICKS DOS BOTÕES DA GUI
-- ============================================================
local function SetupButtonClicks()
    if not GUIElements then return end
    
    GUIElements.NoclipBtn.MouseButton1Click:Connect(function()
        NoclipModule.Toggle()
    end)
    
    GUIElements.GhostBtn.MouseButton1Click:Connect(function()
        GhostModule.Toggle()
    end)
    
    GUIElements.FlyBtn.MouseButton1Click:Connect(function()
        FlyModule.Toggle()
    end)
    
    GUIElements.SpeedBtn.MouseButton1Click:Connect(function()
        SpeedModule.Toggle()
    end)
    
    GUIElements.TrailBtn.MouseButton1Click:Connect(function()
        TrailModule.Toggle()
    end)
    
    GUIElements.ParticleBtn.MouseButton1Click:Connect(function()
        ParticleModule.Toggle()
    end)
    
    GUIElements.SoundBtn.MouseButton1Click:Connect(function()
        SoundModule.Toggle()
    end)
    
    GUIElements.TeleportBtn.MouseButton1Click:Connect(function()
        TeleportModule.Execute()
    end)
    
    GUIElements.ColorBtn.MouseButton1Click:Connect(function()
        ColorModule.CycleColor()
    end)
    
    -- Efeito hover nos botões
    local allFrames = {
        GUIElements.NoclipFrame, GUIElements.GhostFrame, GUIElements.FlyFrame,
        GUIElements.SpeedFrame, GUIElements.TrailFrame, GUIElements.ParticleFrame,
        GUIElements.SoundFrame, GUIElements.TeleportFrame, GUIElements.ColorFrame,
    }
    
    for _, frame in ipairs(allFrames) do
        local btn = frame:FindFirstChild("ClickButton")
        if btn then
            btn.MouseEnter:Connect(function()
                TweenService:Create(
                    frame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    {BackgroundColor3 = Color3.fromRGB(45, 45, 70)}
                ):Play()
            end)
            
            btn.MouseLeave:Connect(function()
                -- Restaurar cor baseada no estado
                local isEnabled = false
                if frame.Name == "NoclipFrame" then isEnabled = NoclipEnabled
                elseif frame.Name == "GhostFrame" then isEnabled = GhostModeEnabled
                elseif frame.Name == "FlyFrame" then isEnabled = FlyEnabled
                elseif frame.Name == "SpeedFrame" then isEnabled = SpeedBoostEnabled
                elseif frame.Name == "TrailFrame" then isEnabled = TrailEnabled
                elseif frame.Name == "ParticlesFrame" then isEnabled = ParticlesEnabled
                elseif frame.Name == "SoundFrame" then isEnabled = SoundEnabled
                end
                
                local bgColor = isEnabled and Color3.fromRGB(30, 50, 40) or Color3.fromRGB(35, 35, 55)
                TweenService:Create(
                    frame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                    {BackgroundColor3 = bgColor}
                ):Play()
            end)
        end
    end
end

-- ============================================================
-- LOOP PRINCIPAL DE UPDATE
-- ============================================================
local function MainUpdateLoop()
    RunService.RenderStepped:Connect(function(dt)
        -- Verificar se o personagem existe
        if not Utilities.IsAlive() then return end
        
        -- Update do Ghost Mode (pulse)
        GhostModule.UpdatePulse(dt)
        
        -- Update do Fly
        FlyModule.Update(dt)
        
        -- Update da GUI info
        if GUIElements and GUIVisible then
            Utilities.SafeCall(function()
                -- Velocidade
                local velocity = Utilities.RoundToDecimal(Utilities.CalculateVelocity(), 1)
                GUIElements.SpeedLabel.Text = "Vel: " .. velocity
                
                -- Posição
                local pos = HumanoidRootPart.Position
                GUIElements.PosLabel.Text = string.format("Pos: %d, %d, %d", 
                    math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
                
                -- Tempo de sessão
                local sessionTime = tick() - SessionStartTime
                GUIElements.TimeLabel.Text = "Sessão: " .. Utilities.FormatTime(sessionTime)
                
                -- Ativações
                GUIElements.ActivationsLabel.Text = "Ativações: " .. NoclipActivationCount
                
                -- Animação do ícone fantasma
                local ghostIconScale = 1 + math.sin(tick() * 3) * 0.1
                GUIElements.GhostIcon.TextSize = 28 * ghostIconScale
                
                -- Animação do stroke principal (rainbow quando noclip ativo)
                if NoclipEnabled then
                    local rainbowColor = Utilities.GetRainbowColor(0.5)
                    GUIElements.MainStroke.Color = rainbowColor
                end
                
                -- Rotação do gradiente do header
                local headerGrad = GUIElements.HeaderGradient
                if headerGrad then
                    headerGrad.Rotation = (tick() * 30) % 360
                end
            end)
        end
        
        -- Tracking de distância
        if HumanoidRootPart then
            local currentPos = HumanoidRootPart.Position
            local distance = (currentPos - LastPosition).Magnitude
            if distance < 100 then -- Ignorar teleports
                DistanceTraveled = DistanceTraveled + distance
            end
            LastPosition = currentPos
            IsMoving = distance > 0.1
        end
        
        -- Efeito contínuo quando noclip está ativo e movendo
        if NoclipEnabled and IsMoving then
            -- Partículas de passagem de parede sutis
            if math.random(1, 10) == 1 then
                Utilities.SafeCall(function()
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(0.2, 0.2, 0.2)
                    p.Shape = Enum.PartType.Ball
                    p.CFrame = HumanoidRootPart.CFrame * CFrame.new(
                        math.random(-2, 2),
                        math.random(-2, 2),
                        math.random(-2, 2)
                    )
                    p.Anchored = true
                    p.CanCollide = false
                    p.Material = Enum.Material.Neon
                    p.Color = Config.EffectColors[Config.CurrentColorIndex]
                    p.Transparency = 0.5
                    p.Parent = Workspace
                    
                    local tw = TweenService:Create(
                        p,
                        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
                    )
                    tw:Play()
                    tw.Completed:Connect(function()
                        p:Destroy()
                    end)
                end)
            end
        end
    end)
end

-- ============================================================
-- CHARACTER RESET HANDLER
-- ============================================================
local function OnCharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Desabilitar todos os efeitos no respawn
    local wasNoclipEnabled = NoclipEnabled
    local wasGhostEnabled = GhostModeEnabled
    local wasFlyEnabled = FlyEnabled
    local wasSpeedEnabled = SpeedBoostEnabled
    local wasTrailEnabled = TrailEnabled
    local wasParticlesEnabled = ParticlesEnabled
    local wasSoundEnabled = SoundEnabled
    
    -- Reset states
    NoclipEnabled = false
    GhostModeEnabled = false
    FlyEnabled = false
    SpeedBoostEnabled = false
    TrailEnabled = false
    ParticlesEnabled = false
    SoundEnabled = false
    
    -- Limpar conexões antigas
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    -- Limpar objetos antigos
    FlyBodyVelocity = nil
    FlyBodyGyro = nil
    TrailObject = nil
    ParticleEmitter = nil
    GhostSound = nil
    
    -- Esperar um pouco para o personagem carregar completamente
    task.wait(0.5)
    
    -- Reativar se estava ativo
    if wasNoclipEnabled then NoclipModule.Enable() end
    if wasGhostEnabled then GhostModule.Enable() end
    if wasFlyEnabled then FlyModule.Enable() end
    if wasSpeedEnabled then SpeedModule.Enable() end
    if wasTrailEnabled then TrailModule.Enable() end
    if wasParticlesEnabled then ParticleModule.Enable() end
    if wasSoundEnabled then SoundModule.Enable() end
    
    -- Atualizar GUI
    if GUIElements then
        UpdateButtonState(GUIElements.NoclipStatus, GUIElements.NoclipStroke, GUIElements.NoclipFrame, NoclipEnabled)
        UpdateButtonState(GUIElements.GhostStatus, GUIElements.GhostStroke, GUIElements.GhostFrame, GhostModeEnabled)
        UpdateButtonState(GUIElements.FlyStatus, GUIElements.FlyStroke, GUIElements.FlyFrame, FlyEnabled)
        UpdateButtonState(GUIElements.SpeedStatus, GUIElements.SpeedStroke, GUIElements.SpeedFrame, SpeedBoostEnabled)
        UpdateButtonState(GUIElements.TrailStatus, GUIElements.TrailStroke, GUIElements.TrailFrame, TrailEnabled)
        UpdateButtonState(GUIElements.ParticleStatus, GUIElements.ParticleStroke, GUIElements.ParticleFrame, ParticlesEnabled)
        UpdateButtonState(GUIElements.SoundStatus, GUIElements.SoundStroke, GUIElements.SoundFrame, SoundEnabled)
    end
    
    ShowNotification("🔄 Personagem respawnado - Efeitos restaurados", Color3.fromRGB(200, 200, 255), 2)
end

-- ============================================================
-- ANIMAÇÃO DE ENTRADA DA GUI
-- ============================================================
local function PlayGUIIntroAnimation()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        -- Posição inicial (fora da tela)
        GUIElements.MainFrame.Position = UDim2.new(0, -350, 0.5, -260)
        GUIElements.MainFrame.BackgroundTransparency = 1
        
        -- Animar entrada
        task.wait(0.3)
        
        local tweenPos = TweenService:Create(
            GUIElements.MainFrame,
            TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 15, 0.5, -260)}
        )
        
        local tweenAlpha = TweenService:Create(
            GUIElements.MainFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 0}
        )
        
        tweenPos:Play()
        tweenAlpha:Play()
        
        -- Animar botões um por um
        task.wait(0.4)
        
        local scrollFrame = GUIElements.ScrollFrame
        for i, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child.BackgroundTransparency = 1
                task.delay(i * 0.08, function()
                    TweenService:Create(
                        child,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {BackgroundTransparency = 0}
                    ):Play()
                end)
            end
        end
    end)
end

-- ============================================================
-- SISTEMA ANTI-DETECÇÃO (básico)
-- ============================================================
local function SetupAntiDetection()
    -- Esconder o nome da GUI
    Utilities.SafeCall(function()
        if GUIElements and GUIElements.ScreenGui then
            -- Manter a GUI mesmo que scripts tentem remover
            GUIElements.ScreenGui.Name = "PlayerUI_" .. math.random(100000, 999999)
        end
    end)
end

-- ============================================================
-- LIMPEZA AO SAIR / MORRER
-- ============================================================
local function Cleanup()
    Utilities.SafeCall(function()
        -- Desativar tudo
        if NoclipEnabled then NoclipModule.Disable() end
        if GhostModeEnabled then GhostModule.Disable() end
        if FlyEnabled then FlyModule.Disable() end
        if SpeedBoostEnabled then SpeedModule.Disable() end
        if TrailEnabled then TrailModule.Disable() end
        if ParticlesEnabled then ParticleModule.Disable() end
        if SoundEnabled then SoundModule.Disable() end
        
        -- Limpar efeitos
        for _, part in ipairs(EffectParts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        EffectParts = {}
        
        -- Limpar conexões
        for _, conn in ipairs(ConnectionsList) do
            if conn then
                conn:Disconnect()
            end
        end
        ConnectionsList = {}
    end)
end

-- ============================================================
-- ESTATÍSTICAS E DEBUG
-- ============================================================
local DebugModule = {}

function DebugModule.GetStats()
    return {
        NoclipEnabled = NoclipEnabled,
        GhostModeEnabled = GhostModeEnabled,
        FlyEnabled = FlyEnabled,
        SpeedBoostEnabled = SpeedBoostEnabled,
        TrailEnabled = TrailEnabled,
        ParticlesEnabled = ParticlesEnabled,
        SoundEnabled = SoundEnabled,
        NoclipActivationCount = NoclipActivationCount,
        TotalNoclipTime = TotalNoclipTime,
        DistanceTraveled = DistanceTraveled,
        SessionTime = tick() - SessionStartTime,
        CurrentFlySpeed = CurrentFlySpeed,
        CurrentColor = Config.EffectColors[Config.CurrentColorIndex],
        ColorIndex = Config.CurrentColorIndex,
    }
end

function DebugModule.PrintStats()
    local stats = DebugModule.GetStats()
    print("=== NOCLIP SYSTEM STATS ===")
    for key, value in pairs(stats) do
        print(string.format("  %s: %s", key, tostring(value)))
    end
    print("===========================")
end

-- ============================================================
-- SISTEMA DE AUTO-SAVE DE CONFIGURAÇÕES
-- ============================================================
local SaveModule = {}

SaveModule.DefaultConfig = {
    FlySpeed = 80,
    SpeedBoostAmount = 80,
    GhostTransparency = 0.6,
    CurrentColorIndex = 1,
    TrailLifetime = 0.5,
    ParticleRate = 50,
    SoundVolume = 0.3,
}

function SaveModule.SaveConfig()
    -- Em um LocalScript, podemos usar GetPropertyChangedSignal ou outro método
    -- Aqui apenas mantemos em memória
    SaveModule.CurrentConfig = {
        FlySpeed = Config.FlySpeed,
        SpeedBoostAmount = Config.SpeedBoostAmount,
        GhostTransparency = Config.GhostTransparency,
        CurrentColorIndex = Config.CurrentColorIndex,
        TrailLifetime = Config.TrailLifetime,
        ParticleRate = Config.ParticleRate,
        SoundVolume = Config.SoundVolume,
    }
end

function SaveModule.LoadConfig()
    if SaveModule.CurrentConfig then
        for key, value in pairs(SaveModule.CurrentConfig) do
            Config[key] = value
        end
    end
end

-- ============================================================
-- EFEITOS VISUAIS EXTRAS
-- ============================================================
local VisualEffects = {}

function VisualEffects.CreateAfterImage()
    if not Utilities.IsAlive() then return end
    if not NoclipEnabled then return end
    
    Utilities.SafeCall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local clone = Instance.new("Part")
                clone.Size = part.Size
                clone.CFrame = part.CFrame
                clone.Anchored = true
                clone.CanCollide = false
                clone.Material = Enum.Material.Neon
                clone.Color = Config.EffectColors[Config.CurrentColorIndex]
                clone.Transparency = 0.7
                clone.Parent = Workspace
                
                local tween = TweenService:Create(
                    clone,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Transparency = 1, Size = part.Size * 1.2}
                )
                tween:Play()
                tween.Completed:Connect(function()
                    clone:Destroy()
                end)
            end
        end
    end)
end

function VisualEffects.CreateEnergyOrb()
    if not HumanoidRootPart then return end
    
    Utilities.SafeCall(function()
        local orb = Instance.new("Part")
        orb.Shape = Enum.PartType.Ball
        orb.Size = Vector3.new(0.5, 0.5, 0.5)
        orb.CFrame = HumanoidRootPart.CFrame * CFrame.new(
            math.cos(tick() * 3) * 3,
            math.sin(tick() * 2) * 2 + 2,
            math.sin(tick() * 3) * 3
        )
        orb.Anchored = true
        orb.CanCollide = false
        orb.Material = Enum.Material.Neon
        orb.Color = Config.EffectColors[Config.CurrentColorIndex]
        orb.Transparency = 0.3
        orb.Parent = Workspace
        
        local tween = TweenService:Create(
            orb,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1}
        )
        tween:Play()
        tween.Completed:Connect(function()
            orb:Destroy()
        end)
    end)
end

function VisualEffects.PulseGround()
    if not HumanoidRootPart then return end
    if FlyEnabled then return end
    
    Utilities.SafeCall(function()
        local pulse = Instance.new("Part")
        pulse.Shape = Enum.PartType.Cylinder
        pulse.Size = Vector3.new(0.1, 2, 2)
        pulse.CFrame = CFrame.new(HumanoidRootPart.Position.X, HumanoidRootPart.Position.Y - 3, HumanoidRootPart.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
        pulse.Anchored = true
        pulse.CanCollide = false
        pulse.Material = Enum.Material.Neon
        pulse.Color = Config.EffectColors[Config.CurrentColorIndex]
        pulse.Transparency = 0.5
        pulse.Parent = Workspace
        
        local tween = TweenService:Create(
            pulse,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(0.05, 20, 20), Transparency = 1}
        )
        tween:Play()
        tween.Completed:Connect(function()
            pulse:Destroy()
        end)
    end)
end

-- ============================================================
-- LOOP DE EFEITOS VISUAIS CONTÍNUOS
-- ============================================================
local function StartVisualEffectsLoop()
    -- After images quando noclip está ativo
    task.spawn(function()
        while true do
            task.wait(0.3)
            if NoclipEnabled and IsMoving then
                VisualEffects.CreateAfterImage()
            end
        end
    end)
    
    -- Energy orbs quando algum efeito está ativo
    task.spawn(function()
        while true do
            task.wait(0.5)
            if (NoclipEnabled or GhostModeEnabled or FlyEnabled) and Utilities.IsAlive() then
                VisualEffects.CreateEnergyOrb()
            end
        end
    end)
    
    -- Ground pulse quando noclip está ativo
    task.spawn(function()
        while true do
            task.wait(2)
            if NoclipEnabled and not FlyEnabled and Utilities.IsAlive() then
                VisualEffects.PulseGround()
            end
        end
    end)
end

-- ============================================================
-- AJUSTE AUTOMÁTICO DO CANVASSIZE DO SCROLLFRAME
-- ============================================================
local function AdjustScrollCanvas()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local scrollFrame = GUIElements.ScrollFrame
        local listLayout = scrollFrame:FindFirstChild("ListLayout")
        
        if listLayout then
            local contentSize = listLayout.AbsoluteContentSize
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)
        end
    end)
end

-- ============================================================
-- DRAGGABLE GUI (Arrastar a janela)
-- ============================================================
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    dragHandle = dragHandle or frame
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- MINIMAP / INDICADOR DE POSIÇÃO (Extra visual)
-- ============================================================
local MinimapModule = {}

function MinimapModule.CreateMinimap()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local minimapFrame = Instance.new("Frame")
        minimapFrame.Name = "Minimap"
        minimapFrame.Size = UDim2.new(0, 80, 0, 80)
        minimapFrame.Position = UDim2.new(1, -95, 0, 15)
        minimapFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        minimapFrame.BorderSizePixel = 0
        minimapFrame.Parent = GUIElements.ScreenGui
        
        local minimapCorner = Instance.new("UICorner")
        minimapCorner.CornerRadius = UDim.new(1, 0)
        minimapCorner.Parent = minimapFrame
        
        local minimapStroke = Instance.new("UIStroke")
        minimapStroke.Color = Config.EffectColors[Config.CurrentColorIndex]
        minimapStroke.Thickness = 2
        minimapStroke.Transparency = 0.5
        minimapStroke.Parent = minimapFrame
        
        -- Ponto do jogador
        local playerDot = Instance.new("Frame")
        playerDot.Name = "PlayerDot"
        playerDot.Size = UDim2.new(0, 8, 0, 8)
        playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
        playerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        playerDot.BorderSizePixel = 0
        playerDot.ZIndex = 5
        playerDot.Parent = minimapFrame
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = playerDot
        
        -- Direção (seta)
        local directionArrow = Instance.new("Frame")
        directionArrow.Name = "DirectionArrow"
        directionArrow.Size = UDim2.new(0, 2, 0, 12)
        directionArrow.Position = UDim2.new(0.5, -1, 0.5, -16)
        directionArrow.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        directionArrow.BorderSizePixel = 0
        directionArrow.ZIndex = 5
        directionArrow.Parent = minimapFrame
        
        -- Texto de coordenadas
        local coordLabel = Instance.new("TextLabel")
        coordLabel.Name = "CoordLabel"
        coordLabel.Size = UDim2.new(1, 0, 0, 15)
        coordLabel.Position = UDim2.new(0, 0, 1, 5)
        coordLabel.BackgroundTransparency = 1
        coordLabel.Text = "0, 0"
        coordLabel.TextSize = 10
        coordLabel.Font = Enum.Font.Gotham
        coordLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
        coordLabel.Parent = minimapFrame
        
        GUIElements.Minimap = minimapFrame
        GUIElements.MinimapPlayerDot = playerDot
        GUIElements.MinimapCoord = coordLabel
        GUIElements.MinimapArrow = directionArrow
    end)
end

-- ============================================================
-- KEYBIND DISPLAY (Mostra teclas na tela)
-- ============================================================
local function CreateKeybindDisplay()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local keybindFrame = Instance.new("Frame")
        keybindFrame.Name = "KeybindDisplay"
        keybindFrame.Size = UDim2.new(0, 180, 0, 220)
        keybindFrame.Position = UDim2.new(1, -195, 1, -235)
        keybindFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        keybindFrame.BackgroundTransparency = 0.3
        keybindFrame.BorderSizePixel = 0
        keybindFrame.Parent = GUIElements.ScreenGui
        
        local kbCorner = Instance.new("UICorner")
        kbCorner.CornerRadius = UDim.new(0, 8)
        kbCorner.Parent = keybindFrame
        
        local kbTitle = Instance.new("TextLabel")
        kbTitle.Size = UDim2.new(1, 0, 0, 25)
        kbTitle.Position = UDim2.new(0, 0, 0, 5)
        kbTitle.BackgroundTransparency = 1
        kbTitle.Text = "⌨️ ATALHOS"
        kbTitle.TextSize = 13
        kbTitle.Font = Enum.Font.GothamBold
        kbTitle.TextColor3 = Color3.fromRGB(200, 200, 240)
        kbTitle.Parent = keybindFrame
        
        local keybinds = {
            {"N", "Noclip"},
            {"F", "Fantasma"},
            {"G", "Voar"},
            {"B", "Speed"},
            {"J", "Trail"},
            {"K", "Partículas"},
            {"L", "Som"},
            {"T", "Teleport"},
            {"M", "Cor"},
            {"H", "GUI"},
        }
        
        for i, kb in ipairs(keybinds) do
            local line = Instance.new("TextLabel")
            line.Size = UDim2.new(1, -20, 0, 16)
            line.Position = UDim2.new(0, 10, 0, 28 + (i - 1) * 18)
            line.BackgroundTransparency = 1
            line.Text = string.format("[%s] %s", kb[1], kb[2])
            line.TextSize = 11
            line.Font = Enum.Font.Gotham
            line.TextColor3 = Color3.fromRGB(140, 140, 170)
            line.TextXAlignment = Enum.TextXAlignment.Left
            line.Parent = keybindFrame
        end
        
        GUIElements.KeybindDisplay = keybindFrame
    end)
end

-- ============================================================
-- FPS COUNTER
-- ============================================================
local FPSModule = {}

function FPSModule.Create()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local fpsLabel = Instance.new("TextLabel")
        fpsLabel.Name = "FPSLabel"
        fpsLabel.Size = UDim2.new(0, 80, 0, 25)
        fpsLabel.Position = UDim2.new(1, -95, 0, 100)
        fpsLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        fpsLabel.BackgroundTransparency = 0.3
        fpsLabel.BorderSizePixel = 0
        fpsLabel.Text = "FPS: 60"
        fpsLabel.TextSize = 12
        fpsLabel.Font = Enum.Font.GothamBold
        fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        fpsLabel.Parent = GUIElements.ScreenGui
        
        local fpsCorner = Instance.new("UICorner")
        fpsCorner.CornerRadius = UDim.new(0, 6)
        fpsCorner.Parent = fpsLabel
        
        GUIElements.FPSLabel = fpsLabel
        
        -- Loop de FPS
        local frameCount = 0
        local lastTime = tick()
        
        RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local currentTime = tick()
            
            if currentTime - lastTime >= 1 then
                local fps = math.floor(frameCount / (currentTime - lastTime))
                frameCount = 0
                lastTime = currentTime
                
                if GUIElements and GUIElements.FPSLabel then
                    GUIElements.FPSLabel.Text = "FPS: " .. fps
                    
                    if fps >= 50 then
                        GUIElements.FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                    elseif fps >= 30 then
                        GUIElements.FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        GUIElements.FPSLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                    end
                end
            end
        end)
    end)
end

-- ============================================================
-- CROSSHAIR PARA TELEPORT
-- ============================================================
local CrosshairModule = {}

function CrosshairModule.Create()
    if not GUIElements then return end
    
    Utilities.SafeCall(function()
        local crosshair = Instance.new("Frame")
        crosshair.Name = "Crosshair"
        crosshair.Size = UDim2.new(0, 20, 0, 20)
        crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
        crosshair.BackgroundTransparency = 1
        crosshair.Visible = false
        crosshair.ZIndex = 50
        crosshair.Parent = GUIElements.ScreenGui
        
        -- Linhas do crosshair
        local lineH = Instance.new("Frame")
        lineH.Size = UDim2.new(1, 0, 0, 2)
        lineH.Position = UDim2.new(0, 0, 0.5, -1)
        lineH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        lineH.BorderSizePixel = 0
        lineH.ZIndex = 51
        lineH.Parent = crosshair
        
        local lineV = Instance.new("Frame")
        lineV.Size = UDim2.new(0, 2, 1, 0)
        lineV.Position = UDim2.new(0.5, -1, 0, 0)
        lineV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        lineV.BorderSizePixel = 0
        lineV.ZIndex = 51
        lineV.Parent = crosshair
        
        GUIElements.Crosshair = crosshair
    end)
end

-- ============================================================
-- INICIALIZAÇÃO PRINCIPAL
-- ============================================================
local function Initialize()
    print("============================================")
    print("   NOCLIP SYSTEM v2.0 - Inicializando...")
    print("============================================")
    
    -- Criar GUI
    GUIElements = GUI.Create()
    print("[NoclipSystem] GUI criada com sucesso")
    
    -- Setup do input (teclado)
    SetupInput()
    print("[NoclipSystem] Sistema de input configurado")
    
    -- Setup dos clicks dos botões
    SetupButtonClicks()
    print("[NoclipSystem] Botões da GUI configurados")
    
    -- Tornar GUI draggable
    if GUIElements then
        MakeDraggable(GUIElements.MainFrame, GUIElements.Header)
        print("[NoclipSystem] GUI draggable ativada")
    end
    
    -- Criar extras visuais
    MinimapModule.CreateMinimap()
    print("[NoclipSystem] Minimap criado")
    
    CreateKeybindDisplay()
    print("[NoclipSystem] Display de atalhos criado")
    
    FPSModule.Create()
    print("[NoclipSystem] Contador de FPS criado")
    
    CrosshairModule.Create()
    print("[NoclipSystem] Crosshair criado")
    
    -- Ajustar canvas do scroll
    AdjustScrollCanvas()
    
    -- Iniciar loop principal
    MainUpdateLoop()
    print("[NoclipSystem] Loop principal iniciado")
    
    -- Iniciar efeitos visuais
    StartVisualEffectsLoop()
    print("[NoclipSystem] Efeitos visuais iniciados")
    
    -- Setup anti-detecção
    SetupAntiDetection()
    
    -- Animação de entrada
    PlayGUIIntroAnimation()
    print("[NoclipSystem] Animação de intro executada")
    
    -- Handler de respawn
    Player.CharacterAdded:Connect(OnCharacterAdded)
    print("[NoclipSystem] Handler de respawn configurado")
    
    -- Mensagem de boas-vindas
    task.wait(1.5)
    ShowNotification("👻 Noclip System v2.0 Carregado!", Config.EffectColors[1], 3)
    
    print("============================================")
    print("   NOCLIP SYSTEM v2.0 - Pronto!")
    print("   Pressione N para ativar o noclip")
    print("   Pressione H para ocultar/mostrar GUI")
    print("============================================")
end

-- ============================================================
-- EXECUÇÃO
-- ============================================================
Utilities.SafeCall(Initialize)

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
--[[
    RESUMO DE FUNCIONALIDADES:
    
    1.  NOCLIP (N) - Atravessa qualquer parede/objeto sólido
    2.  GHOST MODE (F) - Deixa o personagem transparente e pulsante
    3.  FLY (G) - Permite voar livremente pelo mapa
    4.  SPEED BOOST (B) - Aumenta a velocidade de caminhada
    5.  TRAIL (J) - Adiciona um rastro colorido ao personagem
    6.  PARTÍCULAS (K) - Emite partículas brilhantes
    7.  SOM (L) - Toca som ambiente fantasmagórico
    8.  TELEPORT (T) - Teleporta para onde o mouse aponta
    9.  COR (M) - Cicla entre 10 cores diferentes
    10. GUI TOGGLE (H) - Mostra/esconde a interface
    
    EXTRAS:
    - GUI com design moderno e animações
    - Sistema de notificações
    - Efeitos visuais de ativação/desativação
    - After-images ao se mover com noclip
    - Partículas de energia orbitais
    - Pulso no chão
    - Minimap com posição
    - Contador de FPS
    - Display de atalhos
    - Barra de progresso de velocidade do voo
    - GUI arrastável
    - Persistência após respawn
    - Sistema de estatísticas
    - Cores personalizáveis (10 opções)
    - Efeito rainbow no stroke quando noclip ativo
    - Hover effects nos botões
    - Animação de entrada da GUI
    - Sistema de cleanup automático
    - Anti-detecção básico
    
    TOTAL: 800+ linhas de código funcional!
--]]
