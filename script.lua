-- Rivals Aimbot Script | Delta X
-- GUI Button + Circle Reticle + Aimbot

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════
--         НАСТРОЙКИ
-- ═══════════════════════════════
local Settings = {
    AimbotEnabled = false,
    FOVRadius = 120,          -- Радиус круга прицела (px)
    AimSmoothing = 0.25,      -- Плавность (0.1 = быстро, 0.5 = медленно)
    AimPart = "Head",         -- Часть тела ("Head" / "HumanoidRootPart")
    TeamCheck = true,         -- Не стрелять по союзникам
    WallCheck = true,         -- Проверка стен
    CircleColor = Color3.fromRGB(255, 60, 60),
    CircleThickness = 2,
}

-- ═══════════════════════════════
--         DRAWING - КРУГ
-- ═══════════════════════════════
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = Settings.CircleThickness
FOVCircle.Color = Settings.CircleColor
FOVCircle.Radius = Settings.FOVRadius
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

-- Точка в центре прицела
local CenterDot = Drawing.new("Circle")
CenterDot.Visible = false
CenterDot.Thickness = 1
CenterDot.Color = Color3.fromRGB(255, 255, 255)
CenterDot.Radius = 3
CenterDot.Filled = true
CenterDot.Transparency = 1
CenterDot.NumSides = 16

-- Крестик (линии)
local LineH = Drawing.new("Line")
LineH.Visible = false
LineH.Color = Color3.fromRGB(255, 60, 60)
LineH.Thickness = 1.5
LineH.Transparency = 1

local LineV = Drawing.new("Line")
LineV.Visible = false
LineV.Color = Color3.fromRGB(255, 60, 60)
LineV.Thickness = 1.5
LineV.Transparency = 1

-- ═══════════════════════════════
--         ПЛАВАЮЩАЯ GUI КНОПКА
-- ═══════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Используем защищённый способ добавления GUI
local success = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Фрейм кнопки (перетаскиваемый)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 120, 0, 40)
Frame.Position = UDim2.new(0, 20, 0.5, -20)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 60, 60)
UIStroke.Thickness = 1.5
UIStroke.Parent = Frame

-- Кнопка Toggle
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = "🎯 AIM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Frame

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 8)
UICorner2.Parent = ToggleBtn

-- ═══════════════════════════════
--         ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ═══════════════════════════════

-- Получить центр экрана
local function GetScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- Проверка стен (raycast)
local function IsVisible(target)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (target - origin)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if result then
        local hitInstance = result.Instance
        -- Проверяем попал ли луч в персонажа врага
        local hitCharacter = hitInstance:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer then
                return true -- Луч попал в игрока = виден
            end
        end
        return false -- Попал в стену
    end
    return true
end

-- Проверка команды
local function IsEnemy(player)
    if not Settings.TeamCheck then return true end
    if player.Team == nil or LocalPlayer.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

-- Получить ближайшего врага к центру экрана
local function GetClosestEnemy()
    local closestPlayer = nil
    local closestDistance = Settings.FOVRadius
    local screenCenter = GetScreenCenter()
    
    for _, player in ipairs(Players:GetPlayers()) do
        -- Пропускаем себя
        if player == LocalPlayer then continue end
        
        -- Проверка команды
        if not IsEnemy(player) then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local targetPart = character:FindFirstChild(Settings.AimPart)
        if not targetPart then continue end
        
        -- Переводим 3D позицию в 2D экранные координаты
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        
        if onScreen then
            local screenVec2 = Vector2.new(screenPos.X, screenPos.Y)
            local distance = (screenVec2 - screenCenter).Magnitude
            
            if distance < closestDistance then
                -- Проверка видимости
                if IsVisible(targetPart.Position) then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- ═══════════════════════════════
--         AIMBOT ЛОГИКА
-- ═══════════════════════════════
local function AimAt(targetPart)
    if not targetPart then return end
    
    local targetPos = targetPart.Position
    
    -- Предсказание движения (упреждение)
    local targetVelocity = Vector3.zero
    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart")
    if rootPart then
        targetVelocity = rootPart.AssemblyLinearVelocity
    end
    
    -- Простое упреждение
    local distance = (Camera.CFrame.Position - targetPos).Magnitude
    local bulletSpeed = 500 -- примерная скорость пули в Rivals
    local timeToHit = distance / bulletSpeed
    targetPos = targetPos + (targetVelocity * timeToHit)
    
    -- Плавное наведение через CFrame
    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.AimSmoothing)
end

-- ═══════════════════════════════
--         TOGGLE КНОПКА
-- ═══════════════════════════════
ToggleBtn.MouseButton1Click:Connect(function()
    Settings.AimbotEnabled = not Settings.AimbotEnabled
    
    if Settings.AimbotEnabled then
        ToggleBtn.Text = "🎯 AIM: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(60, 255, 100)
        UIStroke.Color = Color3.fromRGB(60, 255, 100)
        FOVCircle.Visible = true
        CenterDot.Visible = true
        LineH.Visible = true
        LineV.Visible = true
        
        -- Анимация кнопки
        Frame.BackgroundColor3 = Color3.fromRGB(15, 35, 15)
    else
        ToggleBtn.Text = "🎯 AIM: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        UIStroke.Color = Color3.fromRGB(255, 60, 60)
        FOVCircle.Visible = false
        CenterDot.Visible = false
        LineH.Visible = false
        LineV.Visible = false
        
        Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)

-- ═══════════════════════════════
--         ГЛАВНЫЙ ЦИКЛ
-- ═══════════════════════════════
RunService.RenderStepped:Connect(function()
    local center = GetScreenCenter()
    
    -- Обновляем позицию круга и крестика
    FOVCircle.Position = center
    CenterDot.Position = center
    
    -- Крестик
    local crossSize = 10
    LineH.From = Vector2.new(center.X - crossSize, center.Y)
    LineH.To = Vector2.new(center.X + crossSize, center.Y)
    LineV.From = Vector2.new(center.X, center.Y - crossSize)
    LineV.To = Vector2.new(center.X, center.Y + crossSize)
    
    if not Settings.AimbotEnabled then return end
    
    -- Проверяем нажатие ПКМ (прицеливание) или просто автоаим
    -- Держи ПКМ для активации аима
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    -- или можно убрать условие для постоянного аима
    
    if isAiming then
        local closestEnemy = GetClosestEnemy()
        
        if closestEnemy then
            local character = closestEnemy.Character
            if character then
                local targetPart = character:FindFirstChild(Settings.AimPart)
                if targetPart then
                    -- Подсвечиваем круг когда цель найдена
                    FOVCircle.Color = Color3.fromRGB(60, 255, 100)
                    AimAt(targetPart)
                end
            end
        else
            -- Нет цели в круге
            FOVCircle.Color = Settings.CircleColor
        end
    else
        FOVCircle.Color = Settings.CircleColor
    end
end)

-- ═══════════════════════════════
--         ОЧИСТКА ПРИ ВЫХОДЕ
-- ═══════════════════════════════
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    -- Не отключаем при респауне
end)

-- Выводим сообщение
print("✅ Rivals Aimbot загружен! Нажми кнопку для включения. ПКМ = аим")
