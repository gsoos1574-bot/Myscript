-- ============================================
--        UNIVERSAL FLY SCRIPT
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FLY_SPEED = 60
local flyEnabled = false
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

-- ============================================
-- GUI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Кнопка Frame
local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(0, 130, 0, 55)
buttonFrame.Position = UDim2.new(0.5, -65, 0.85, 0)
buttonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
buttonFrame.BackgroundTransparency = 0.2
buttonFrame.BorderSizePixel = 0
buttonFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = buttonFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 70, 70)
stroke.Thickness = 2.5
stroke.Parent = buttonFrame

-- Кнопка текст
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = "✈  FLY: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 70, 70)
toggleButton.TextSize = 17
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = buttonFrame

-- ============================================
-- ПЕРЕТАСКИВАНИЕ КНОПКИ
-- ============================================

local dragging = false
local dragStart = nil
local startPos = nil

buttonFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = buttonFrame.Position
    end
end)

buttonFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        buttonFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================
-- ПОЛЁТ
-- ============================================

local function enableFly()
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    -- Замораживаем анимацию персонажа
    humanoid.PlatformStand = true

    -- BodyVelocity — двигает персонажа
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.P = 1e4
    bodyVelocity.Parent = rootPart

    -- BodyGyro — поворачивает персонажа за камерой
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 1e4
    bodyGyro.D = 150
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    -- Каждый кадр обновляем полёт
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end

        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end

        local camCF = camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)

        -- ПК управление (WASD + Space + Shift)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        -- Мобильный джойстик (MoveDirection автоматически читает джойстик)
        local mobileDir = hum.MoveDirection
        if mobileDir.Magnitude > 0.1 then
            local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
            local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
            moveDir = moveDir + (flatLook * -mobileDir.Z + flatRight * mobileDir.X)
        end

        -- Применяем скорость
        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * FLY_SPEED
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end

        -- Поворачиваем персонажа за камерой
        bodyGyro.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
    end)
end

local function disableFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

-- ============================================
-- НАЖАТИЕ КНОПКИ
-- ============================================

toggleButton.MouseButton1Click:Connect(function()
    -- Проверяем — не перетаскиваем ли кнопку
    if dragging then return end

    flyEnabled = not flyEnabled

    if flyEnabled then
        toggleButton.Text = "✈  FLY: ON"
        toggleButton.TextColor3 = Color3.fromRGB(80, 255, 120)
        stroke.Color = Color3.fromRGB(80, 255, 120)
        buttonFrame.BackgroundColor3 = Color3.fromRGB(15, 40, 20)
        enableFly()
    else
        toggleButton.Text = "✈  FLY: OFF"
        toggleButton.TextColor3 = Color3.fromRGB(255, 70, 70)
        stroke.Color = Color3.fromRGB(255, 70, 70)
        buttonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        disableFly()
    end
end)

-- ============================================
-- ПЕРЕРОЖДЕНИЕ ПЕРСОНАЖА
-- ============================================

player.CharacterAdded:Connect(function(char)
    if flyEnabled then
        task.wait(1)
        enableFly()
    end
end)
