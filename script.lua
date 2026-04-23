-- Rivals Aimbot Script | Delta X | Fixed Version
-- ПКМ зажать = активировать аим когда включено

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════
--         НАСТРОЙКИ
-- ═══════════════════════════════
local Settings = {
    AimbotEnabled = false,
    FOVRadius = 250,           -- БОЛЬШОЙ круг
    AimSmoothing = 0.15,       -- Плавность наведения
    AimPart = "Head",          -- Цель - голова
    TeamCheck = false,         -- Выключено для теста
    WallCheck = false,         -- Выключено для теста
}

-- ═══════════════════════════════
--         DRAWING КРУГ (большой, пустой)
-- ═══════════════════════════════
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 60, 60)
FOVCircle.Radius = Settings.FOVRadius
FOVCircle.Filled = false        -- ПУСТОЙ внутри
FOVCircle.Transparency = 1
FOVCircle.NumSides = 128        -- Очень плавный круг

-- Точка в центре
local CenterDot = Drawing.new("Circle")
CenterDot.Visible = false
CenterDot.Thickness = 1
CenterDot.Color = Color3.fromRGB(255, 255, 255)
CenterDot.Radius = 3
CenterDot.Filled = true
CenterDot.Transparency = 1
CenterDot.NumSides = 32

-- Крестик горизонталь
local LineH = Drawing.new("Line")
LineH.Visible = false
LineH.Color = Color3.fromRGB(255, 255, 255)
LineH.Thickness = 1
LineH.Transparency = 1

-- Крестик вертикаль
local LineV = Drawing.new("Line")
LineV.Visible = false
LineV.Color = Color3.fromRGB(255, 255, 255)
LineV.Thickness = 1
LineV.Transparency = 1

-- Текст дебага (чтоб видеть что происходит)
local DebugText = Drawing.new("Text")
DebugText.Visible = true
DebugText.Size = 18
DebugText.Color = Color3.fromRGB(0, 255, 100)
DebugText.Outline = true
DebugText.OutlineColor = Color3.fromRGB(0, 0, 0)
DebugText.Position = Vector2.new(10, 150)
DebugText.Text = "AIM: OFF"

-- ═══════════════════════════════
--         GUI КНОПКА
-- ═══════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false

local ok = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 130, 0, 45)
Frame.Position = UDim2.new(0, 20, 0.5, -22)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 60, 60)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = "🎯 AIM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Frame

-- ═══════════════════════════════
--         ФУНКЦИИ
-- ═══════════════════════════════

local function GetScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- Главная функция поиска врага
local function GetClosestEnemy()
    local closestTarget = nil
    local closestDist = Settings.FOVRadius  -- только внутри круга
    local screenCenter = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local head = char:FindFirstChild("Head")
        if not head then continue end

        -- Переводим 3D -> 2D экран
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local pos2D = Vector2.new(screenPos.X, screenPos.Y)
        local dist = (pos2D - screenCenter).Magnitude

        -- Только если ВНУТРИ круга
        if dist < closestDist then
            closestDist = dist
            closestTarget = head
        end
    end

    return closestTarget
end

-- Наведение камеры на цель
local function AimAt(targetPart)
    if not targetPart then return end

    -- Получаем позицию головы
    local targetPos = targetPart.Position

    -- Направление от камеры к цели
    local camPos = Camera.CFrame.Position
    local direction = (targetPos - camPos).Unit

    -- Новый CFrame камеры смотрит на цель
    local targetCFrame = CFrame.new(camPos, camPos + direction)

    -- Плавное перемещение
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.AimSmoothing)
end

-- ═══════════════════════════════
--         TOGGLE
-- ═══════════════════════════════
ToggleBtn.MouseButton1Click:Connect(function()
    Settings.AimbotEnabled = not Settings.AimbotEnabled

    if Settings.AimbotEnabled then
        ToggleBtn.Text = "🎯 AIM: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(60, 255, 100)
        UIStroke.Color = Color3.fromRGB(60, 255, 100)
        Frame.BackgroundColor3 = Color3.fromRGB(10, 28, 10)

        FOVCircle.Visible = true
        CenterDot.Visible = true
        LineH.Visible = true
        LineV.Visible = true
        DebugText.Text = "AIM: ON | Зажми ПКМ"
        DebugText.Color = Color3.fromRGB(60, 255, 100)
    else
        ToggleBtn.Text = "🎯 AIM: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        UIStroke.Color = Color3.fromRGB(255, 60, 60)
        Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)

        FOVCircle.Visible = false
        CenterDot.Visible = false
        LineH.Visible = false
        LineV.Visible = false
        DebugText.Text = "AIM: OFF"
        DebugText.Color = Color3.fromRGB(255, 80, 80)
    end
end)

-- ═══════════════════════════════
--         ГЛАВНЫЙ ЦИКЛ
-- ═══════════════════════════════
RunService.RenderStepped:Connect(function()
    local center = GetScreenCenter()

    -- Позиция круга всегда по центру экрана
    FOVCircle.Position = center
    CenterDot.Position = center

    -- Крестик по центру
    local cs = 8
    LineH.From = Vector2.new(center.X - cs, center.Y)
    LineH.To   = Vector2.new(center.X + cs, center.Y)
    LineV.From = Vector2.new(center.X, center.Y - cs)
    LineV.To   = Vector2.new(center.X, center.Y + cs)

    -- Если аим выключен - ничего не делаем
    if not Settings.AimbotEnabled then return end

    -- Зажать ПКМ чтобы аим работал
    local rmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if rmb then
        local target = GetClosestEnemy()

        if target then
            -- Цель найдена - круг зелёный
            FOVCircle.Color = Color3.fromRGB(0, 255, 80)
            FOVCircle.Thickness = 3
            DebugText.Text = "🎯 LOCKED: " .. target.Parent.Name
            DebugText.Color = Color3.fromRGB(0, 255, 80)

            -- Наводим камеру
            AimAt(target)
        else
            -- Нет цели в круге - красный
            FOVCircle.Color = Color3.fromRGB(255, 60, 60)
            FOVCircle.Thickness = 2
            DebugText.Text = "AIM: ON | Нет цели в круге"
            DebugText.Color = Color3.fromRGB(255, 200, 0)
        end
    else
        -- ПКМ не зажат
        FOVCircle.Color = Color3.fromRGB(255, 60, 60)
        FOVCircle.Thickness = 2
        DebugText.Text = "AIM: ON | Зажми ПКМ"
        DebugText.Color = Color3.fromRGB(60, 255, 100)
    end
end)

print("✅ [DeltaX] Rivals Aimbot загружен!")
print("📌 Нажми кнопку чтобы включить")
print("📌 Зажми ПКМ для активации аима")
