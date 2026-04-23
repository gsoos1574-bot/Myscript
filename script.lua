-- Rivals Aimbot | Mobile Fix | Delta X
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════
--         НАСТРОЙКИ
-- ═══════════════════════════════
local FOV_RADIUS = 300        -- Радиус зоны захвата (в пикселях)
local SMOOTHING = 0.2         -- Плавность (0.1 быстро - 0.5 медленно)
local AIM_PART = "Head"       -- Голова
local AimbotEnabled = false

-- ═══════════════════════════════
--         GUI (вместо Drawing)
-- ═══════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RivalsAim"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999

local ok = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ───────────────────────────────
-- КРУГ через ImageLabel (чистый круг)
-- ───────────────────────────────
local CircleFrame = Instance.new("Frame")
CircleFrame.Name = "FOVCircle"
CircleFrame.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
CircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
CircleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
CircleFrame.BackgroundTransparency = 1
CircleFrame.Visible = false
CircleFrame.Parent = ScreenGui

-- Делаем круг через UICorner + рамку
local CircleInner = Instance.new("Frame")
CircleInner.Size = UDim2.new(1, 0, 1, 0)
CircleInner.BackgroundTransparency = 1
CircleInner.BorderSizePixel = 0
CircleInner.Parent = CircleFrame

local UIStrokeCircle = Instance.new("UIStroke")
UIStrokeCircle.Color = Color3.fromRGB(255, 50, 50)
UIStrokeCircle.Thickness = 3
UIStrokeCircle.Parent = CircleInner

local UICornerCircle = Instance.new("UICorner")
UICornerCircle.CornerRadius = UDim.new(1, 0)  -- Делает квадрат кругом
UICornerCircle.Parent = CircleInner

-- ───────────────────────────────
-- ТОЧКА В ЦЕНТРЕ
-- ───────────────────────────────
local DotFrame = Instance.new("Frame")
DotFrame.Size = UDim2.new(0, 8, 0, 8)
DotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
DotFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
DotFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DotFrame.BorderSizePixel = 0
DotFrame.Visible = false
DotFrame.Parent = ScreenGui

local UICornerDot = Instance.new("UICorner")
UICornerDot.CornerRadius = UDim.new(1, 0)
UICornerDot.Parent = DotFrame

-- ───────────────────────────────
-- СТАТУС ТЕКСТ (для дебага)
-- ───────────────────────────────
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 250, 0, 30)
StatusLabel.Position = UDim2.new(0.5, -125, 0, 10)
StatusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StatusLabel.BackgroundTransparency = 0.4
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Text = "СТАТУС: Загрузка..."
StatusLabel.TextScaled = true
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.BorderSizePixel = 0
StatusLabel.Parent = ScreenGui

local UICornerStatus = Instance.new("UICorner")
UICornerStatus.CornerRadius = UDim.new(0, 6)
UICornerStatus.Parent = StatusLabel

-- ───────────────────────────────
-- КНОПКА ON/OFF (большая для телефона)
-- ───────────────────────────────
local BtnFrame = Instance.new("Frame")
BtnFrame.Size = UDim2.new(0, 150, 0, 55)
BtnFrame.Position = UDim2.new(0, 15, 0.5, -27)
BtnFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BtnFrame.BorderSizePixel = 0
BtnFrame.Active = true
BtnFrame.Draggable = true
BtnFrame.Parent = ScreenGui

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 12)
UICornerBtn.Parent = BtnFrame

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(255, 50, 50)
BtnStroke.Thickness = 2
BtnStroke.Parent = BtnFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 1, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Text = "🎯 AIM OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 70, 70)
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = BtnFrame

-- ═══════════════════════════════
--         ЛОГИКА
-- ═══════════════════════════════

local function GetCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

local function GetClosestEnemy()
    local bestTarget = nil
    local bestDist = FOV_RADIUS
    local center = GetCenter()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end

        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local part = char:FindFirstChild(AIM_PART)
            or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

        if dist < bestDist then
            bestDist = dist
            bestTarget = part
        end
    end

    return bestTarget
end

-- Метод наведения камеры
local function LookAtTarget(targetPart)
    if not targetPart or not targetPart.Parent then return end

    local camPos = Camera.CFrame.Position
    local targetPos = targetPart.Position

    -- Вектор от камеры к цели
    local lookVector = (targetPos - camPos).Unit

    -- Строим новый CFrame
    local newCFrame = CFrame.new(camPos, camPos + lookVector)

    -- Плавно применяем
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, SMOOTHING)
end

-- ═══════════════════════════════
--         TOGGLE
-- ═══════════════════════════════
ToggleButton.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled

    if AimbotEnabled then
        -- Включено
        ToggleButton.Text = "🎯 AIM ON"
        ToggleButton.TextColor3 = Color3.fromRGB(50, 255, 90)
        BtnStroke.Color = Color3.fromRGB(50, 255, 90)
        BtnFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
        CircleFrame.Visible = true
        DotFrame.Visible = true
        StatusLabel.Text = "✅ AIM ВКЛЮЧЁН"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 90)
    else
        -- Выключено
        ToggleButton.Text = "🎯 AIM OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 70, 70)
        BtnStroke.Color = Color3.fromRGB(255, 50, 50)
        BtnFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        UIStrokeCircle.Color = Color3.fromRGB(255, 50, 50)
        CircleFrame.Visible = false
        DotFrame.Visible = false
        StatusLabel.Text = "❌ AIM ВЫКЛЮЧЕН"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
    end
end)

-- ═══════════════════════════════
--         ГЛАВНЫЙ ЦИКЛ
-- ═══════════════════════════════
StatusLabel.Text = "✅ Скрипт загружен!"

RunService.RenderStepped:Connect(function()
    if not AimbotEnabled then return end

    local target = GetClosestEnemy()

    if target then
        -- Цель найдена
        UIStrokeCircle.Color = Color3.fromRGB(0, 255, 80)
        StatusLabel.Text = "🔒 LOCKED: " .. (target.Parent and target.Parent.Name or "???")
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 80)

        -- НАВОДИМ КАМЕРУ
        LookAtTarget(target)
    else
        -- Нет цели
        UIStrokeCircle.Color = Color3.fromRGB(255, 50, 50)
        StatusLabel.Text = "🔍 Поиск цели..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

print("[DeltaX] Загружено! Нажми кнопку AIM OFF чтобы включить")
