--========================================================--
--                  REBOUND ENTITY SCRIPT                 --
--========================================================--

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

-- Variables
local maxRebounds = 5
local reboundCount = 0
local isJumpscaring = false

-- ====== UTILS & AUDIO ======
local function GitAud(soundgit, filename)
    local url = soundgit
    local FileName = filename
    pcall(function()
        writefile(FileName .. ".mp3", game:HttpGet(url))
    end)
    return (getcustomasset or getsynasset)(FileName .. ".mp3")
end

local function CustomGitSound(soundlink, vol, filename)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = GitAud(soundlink, filename)
        sound.Parent = workspace
        sound.Name = "reboundspawn"
        sound.Volume = vol or 5
        sound.PlaybackSpeed = 1
        sound:Play()
    end)
end

-- Camera Shake Setup
local cameraShaker = require(ReplicatedStorage:WaitForChild("CameraShaker"))
local camera = workspace.CurrentCamera
local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
    camera.CFrame = camera.CFrame * cf
end)

-- Asset Loader
local function LoadCustomInstance(assetId, parent)
    local model = nil
    local retryCount = 0

    while not model and retryCount < 5 do
        retryCount = retryCount + 1
        local success, result = pcall(function()
            local loadedObjects = game:GetObjects(assetId)
            return loadedObjects and loadedObjects[1]
        end)

        if success and result then
            model = result
            model.Parent = parent or workspace

            task.spawn(function()
                for _, obj in ipairs(model:GetDescendants()) do
                    if obj:IsA("Script") or obj:IsA("LocalScript") then
                        obj:Destroy()
                    end
                end
            end)

            pcall(function()
                model:SetAttribute("LoadedByExecutor", true)
            end)
        else
            task.wait(0.5)
        end
    end

    return model
end

local speed = getgenv().FasterTrouble and 1.4 or 1.8

-- ====== MOVEMENT & JUMPSCARE LOGIC ======
local function MoveRebound()
    isJumpscaring = false
    
    pcall(function()
        local jumpscareSound = Instance.new("Sound")
        jumpscareSound.SoundId = GitAud("https://github.com/Kotyara19k-Doorsspawner/Random-files/raw/main/Y2meta.app%20-%20DOORS%20HARDCORE_REBOUND%20MOVING%20START%20(320%20kbps).mp3", "Moving2")
        jumpscareSound.Parent = entity
        jumpscareSound.Volume = 5
        jumpscareSound.Name = "am"
        jumpscareSound:Play()
    end)
    
    local s = LoadCustomInstance("rbxassetid://94638439855560", workspace)
    if not s then return end

    local val = 60
    local killed = false
    local entity = s:FindFirstChild("Rebound") or s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
    
    if not entity then
        s:Destroy()
        return
    end

    local gruh = workspace:WaitForChild("CurrentRooms")
    local latestRoomVal = ReplicatedStorage.GameData.LatestRoom.Value

    reboundCount = reboundCount + 1
    local directionType = (reboundCount % 2 == 1) and "ExitToEntrance" or "EntranceToExit"

    if directionType == "ExitToEntrance" then
        local targetRoom = gruh:FindFirstChild(latestRoomVal + 1) or gruh:FindFirstChild(latestRoomVal)
        if targetRoom and targetRoom:FindFirstChild("RoomExit") then
            entity.CFrame = targetRoom.RoomExit.CFrame
        elseif targetRoom and targetRoom:FindFirstChild("RoomEntrance") then
            entity.CFrame = targetRoom.RoomEntrance.CFrame
        end
    else
        local startRoom = gruh:FindFirstChild(1)
        if startRoom and startRoom:FindFirstChild("RoomEntrance") then
            entity.CFrame = startRoom.RoomEntrance.CFrame
        end
    end

    task.wait(0.1)

    local function canSeeTarget(target, size)
        if killed or isJumpscaring then return false end
        local origin = entity.Position
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        local direction = (hrp.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, entity)
        if hit and hit:IsDescendantOf(target) then
            killed = true
            return true
        end
        return false
    end

    task.wait(1)

    local killCheckConnection
    killCheckConnection = RunService.Heartbeat:Connect(function()
        if not entity or not entity.Parent then
            if killCheckConnection then killCheckConnection:Disconnect() end
            return
        end

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and not char:GetAttribute("Hiding") then
            if (entity.Position - char.HumanoidRootPart.Position).Magnitude <= val then
                camShake:Start()
                camShake:ShakeOnce(17, 6, 0.1, 1)
            end

            if canSeeTarget(char, 50) and not isJumpscaring then
                isJumpscaring = true

                local ReboundJs = Instance.new("ScreenGui")
                local Static = Instance.new("ImageLabel")
                local ReboundImg = Instance.new("ImageLabel")
                local JSSIZE = Instance.new("ImageLabel")

                ReboundJs.Name = "ReboundJs"
                ReboundJs.Parent = LocalPlayer:WaitForChild("PlayerGui")

                Static.Name = "Static"
                Static.Parent = ReboundJs
                Static.BackgroundTransparency = 1
                Static.Size = UDim2.new(11, 0, 111, 0)
                Static.Image = "rbxassetid://236543215"
                Static.ImageTransparency = 1

                ReboundImg.Name = "Rebound"
                ReboundImg.Parent = ReboundJs
                ReboundImg.BackgroundTransparency = 1
                ReboundImg.Position = UDim2.new(0.4866, 0, 0.4793, 0)
                ReboundImg.Size = UDim2.new(0.0267, 0, 0.0387, 0)
                ReboundImg.Image = "rbxassetid://136184103476873"

                JSSIZE.Name = "JSSIZE"
                JSSIZE.Parent = ReboundJs
                JSSIZE.BackgroundTransparency = 1
                JSSIZE.Position = UDim2.new(-0.586, 0, -1.251, 0)
                JSSIZE.Size = UDim2.new(2.128, 0, 3.081, 0)
                JSSIZE.Visible = false
                JSSIZE.Image = "rbxassetid://136184103476873"

                local jumpscareSound = Instance.new("Sound")
                jumpscareSound.SoundId = "rbxassetid://109582246349306"
                jumpscareSound.Volume = 10
                jumpscareSound.Parent = ReboundJs
                jumpscareSound:Play()

                task.spawn(function()
                    while isJumpscaring and ReboundJs.Parent do
                        Static.Image = "rbxassetid://236543215"
                        task.wait(0.002)
                        Static.Rotation = 0
                        task.wait(0.002)
                        Static.Rotation = 180
                        task.wait(0.002)
                        Static.Image = "rbxassetid://236777652"
                        task.wait(0.002)
                        Static.Rotation = 0
                        task.wait(0.002)
                        Static.Rotation = 180
                        task.wait(0.002)
                    end
                end)

                task.spawn(function()
                    TweenService:Create(Static, TweenInfo.new(0.5), {ImageTransparency = 0.8}):Play()
                    TweenService:Create(ReboundImg, TweenInfo.new(0.5), {Size = JSSIZE.Size, Position = JSSIZE.Position}):Play()
                    
                    task.wait(0.3)
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                     if hum then hum.Health = 0 end

                    pcall(function()
                        local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
                        if gameStats then
                            local playerStat = gameStats:FindFirstChild("Player_" .. LocalPlayer.Name)
                            if playerStat and playerStat:FindFirstChild("Total") and playerStat.Total:FindFirstChild("DeathCause") then
                                playerStat.Total.DeathCause.Value = "Rebound"
                            end
                        end
                        
                        local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage:FindFirstChild("Bricks")
                        if remotesFolder and remotesFolder:FindFirstChild("DeathHint") then
                            firesignal(remotesFolder.DeathHint.OnClientEvent, {
                                "You died to who you call Rebound...",
                                "He makes his presence known and keeps coming back...",
                                "Hide when this happens!"
                            }, "Blue")
                        end
                    end)

                    task.wait(0.5)
                    TweenService:Create(Static, TweenInfo.new(1), {ImageTransparency = 1}):Play()
                    TweenService:Create(ReboundImg, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
                    task.wait(1)
                    ReboundJs:Destroy()
                end)
            end
        end
    end)

    if directionType == "ExitToEntrance" then
        for i = latestRoomVal, 1, -1 do
            if gruh:FindFirstChild(i) then
                local room = gruh[i]
                if room:FindFirstChild("RoomEntrance") then
                    local a = room.RoomEntrance
                    local tween = TweenService:Create(entity, TweenInfo.new(speed, Enum.EasingStyle.Sine), {CFrame = a.CFrame})
                    tween:Play()
                    tween.Completed:Wait()
                end
            end
        end
    else
        for i = 1, latestRoomVal + 1 do
            if gruh:FindFirstChild(i) then
                local room = gruh[i]
                if room:FindFirstChild("RoomExit") then
                    local a = room.RoomExit
                    local tween = TweenService:Create(entity, TweenInfo.new(speed, Enum.EasingStyle.Sine), {CFrame = a.CFrame})
                    tween:Play()
                    tween.Completed:Wait()
                end
            end
        end
    end

    if killCheckConnection then killCheckConnection:Disconnect() end

    if entity and entity:IsA("BasePart") then
        entity.Anchored = false
        entity.CanCollide = false
    end
    Debris:AddItem(s, 2)
end

-- ====== RUN REBOUND SEQUENCE ======
local function RunReboundSequence()
    -- 1. Âm thanh cảnh báo
    CustomGitSound("https://github.com/Anctarus7105/Custom-Sounds/raw/main/ReboundWarning.mp3", 5, "reboundspawn")
    
    -- 2. Hiệu ứng ánh sáng & rung màn hình
    local Warn = Instance.new("ColorCorrectionEffect", game.Lighting)
    Warn.TintColor = Color3.fromRGB(65, 138, 255)
    Warn.Saturation = -0.7
    Warn.Contrast = 0.2
    
    TweenService:Create(Warn, TweenInfo.new(15), {
        TintColor = Color3.fromRGB(255, 255, 255),
        Saturation = 0,
        Contrast = 0
    }):Play()

    camShake:Start()
    camShake:ShakeOnce(10, 3, 0.1, 6, 2, 0.5)
    
    -- 3. Thời gian chờ người chơi trú ẩn
    task.wait(3)

    reboundCount = 0
    local currentMax = maxRebounds
    
    task.wait(2)

    -- 4. Bắt đầu di chuyển
    pcall(MoveRebound)

    while currentMax > 0 do
        ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
        task.wait(2)
        pcall(MoveRebound)
        currentMax = currentMax - 1
    end

    task.wait(5)

    -- 5. Tween chuyển hiệu ứng màu về bình thường mượt mà
    local fadeOutInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(Warn, fadeOutInfo, {
        TintColor = Color3.fromRGB(255, 255, 255),
        Saturation = 0,
        Contrast = 0,
        Brightness = 0
    })
    
    fadeTween:Play()
    
    fadeTween.Completed:Connect(function()
        if Warn and Warn.Parent then
            Warn:Destroy()
        end
    end)
    
    Debris:AddItem(Warn, 7)
end

-- Kích hoạt thực thể Rebound
RunReboundSequence()
