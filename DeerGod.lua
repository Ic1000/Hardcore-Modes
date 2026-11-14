-- ========================================================
--     DEER GOD - VYNIXU SPAWNER V2 (CUSTOM ACHIEVEMENTS)
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Check phòng hợp lệ
if Workspace.CurrentRooms:FindFirstChild("50") 
    or Workspace.CurrentRooms:FindFirstChild("100") 
    or ReplicatedStorage.GameData.LatestRoom.Value == 6 then
    repeat task.wait() until not Workspace.CurrentRooms:FindFirstChild("50") 
        and not Workspace.CurrentRooms:FindFirstChild("100")
        and not (ReplicatedStorage.GameData.LatestRoom.Value == 6)
end

local hit = false
local isDeactivated = false -- Biến cờ ngắt toàn bộ hệ thống
local currentTween = nil
local nodeConnection = nil

local speed = getgenv().FasterTrouble and 3.5 or 4

-- Tải Module CustomAchievements
local CustomAchievements = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()

-- Hàm cấp thành tựu chuẩn mới
local function GiveDeerGodAchievement()
    pcall(function()
        local isOwned = CustomAchievements:CheckOwned("DeerGodAchievement")
        
        if not isOwned then
            CustomAchievements:Grant({
                Identifier = "DeerGodAchievement",
                Title = "Last Chance To Look Away",
                Desc = "Why are you running?",
                Reason = "Survive the rare Entity called Deer God",
                Image = "rbxassetid://114825307168774"
            }, {
                CheckOwned = true,
                Remember = false
            })
        end
    end)
end

-- Camera Shake Setup
local CameraShaker = require(ReplicatedStorage.CameraShaker)
local camara = Workspace.CurrentCamera
local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
    camara.CFrame = camara.CFrame * cf
end)
camShake:Start()
camShake:Shake(CameraShaker.Presets.Earthquake)

local function GetGitSound(GithubSnd, SoundName)
    local url = GithubSnd
    if not isfile(SoundName .. ".mp3") then
        pcall(function()
            writefile(SoundName .. ".mp3", game:HttpGet(url))
        end)
    end
    local sound = Instance.new("Sound")
    pcall(function()
        sound.SoundId = (getcustomasset or getsynasset)(SoundName .. ".mp3")
    end)
    return sound
end

-- Load Model Deer God
local deer = game:GetObjects("rbxassetid://86055776714285")[1]
deer.Name = "DeerGodModel"
deer.Parent = Workspace
deer.PrimaryPart = deer:FindFirstChildWhichIsA("BasePart")
deer.PrimaryPart.Anchored = true
deer.PrimaryPart.CanCollide = false
local ambush = deer.PrimaryPart

-- Hàm dọn dẹp an toàn ngắt sạch hiệu ứng khi Destroy
local function CleanupEntity()
    if isDeactivated then return end
    isDeactivated = true
    
    if currentTween then pcall(function() currentTween:Cancel() end) end
    if nodeConnection then nodeConnection:Disconnect() end
    
    if deer and deer.Parent then
        pcall(function() deer:Destroy() end)
    end
    
    local nodeSpawner = Workspace:FindFirstChild("DeerGodNode")
    if nodeSpawner then
        pcall(function() nodeSpawner:Destroy() end)
    end
end

---====== Load Vynixu Spawner V2 ======---
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()

---====== Create Node Entity ======---
local entity = spawner.Create({
	Entity = {
		Name = "DeerGodNode",
		Asset = "rbxassetid://83406552862223",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = true,
			Duration = 69
		},
		Shatter = true,
		Repair = false
	},
	Earthquake = {
		Enabled = false
	},
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {3.5, 20, 0.1, 1}
	},
	Movement = {
		Speed = 0,
		Delay = 0,
		Reversed = false
	},
	Rebounding = {
		Enabled = false
	},
	Damage = {
		Enabled = false,
		Range = 0,
		Amount = 0
	},
	Crucifixion = {
		Enabled = true,
		Range = 40,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"Claim has seen you.", "It will consume anyone on sight.", "Do not look at it directly for too long!"},
		Cause = "DeerGod"
	}
})

entity:SetCallback("OnSpawned", function()
    -- Đồng bộ CFrame của Vynixu Node theo vị trí Deer God
    nodeConnection = RunService.RenderStepped:Connect(function()
        if isDeactivated or hit then return end
        local nodeObj = Workspace:FindFirstChild("DeerGodNode")
        if nodeObj and nodeObj.PrimaryPart and ambush and ambush.Parent then
            nodeObj.PrimaryPart.CFrame = ambush.CFrame
        end
    end)
end)

entity:Run()

-- Âm thanh Chase Sound
local followed = GetGitSound("https://github.com/Tinkgy111/Bang/blob/main/followed.mp3?raw=true", "chase")
followed.Parent = deer
followed.Volume = 1
followed:Play()

-- Mechanism: Take Damage when Looking
task.spawn(function()
    while task.wait(1.5) do
        if hit or isDeactivated or not ambush.Parent then break end
        
        local origin = ambush.Position
        local direction = (HumanoidRootPart.Position - origin).Unit
        local ray = Ray.new(origin, direction * 5050)
        local cast = Workspace:Raycast(ray.Origin, ray.Direction)
        
        if cast and cast.Instance.Parent == character then
            local _, onScreen = Workspace.CurrentCamera:WorldToScreenPoint(ambush.Position)
            if onScreen and not character:GetAttribute("Hiding") then
                player.Character.Humanoid:TakeDamage(8)
            end
        end
    end
end)

-- Mechanism: Kill/Jumpscare on Close Hitbox
task.spawn(function()
    while task.wait(0.2) do
        if hit or isDeactivated or not ambush.Parent then break end
        
        local hitbox = 9
        local origin = ambush.Position
        local direction = (HumanoidRootPart.Position - origin).Unit
        local ray = Ray.new(origin, direction * hitbox)
        local result = Workspace:Raycast(ray.Origin, ray.Direction)

        if result and result.Instance.Parent == character and not character:GetAttribute("Hiding") then
            hit = true
            CleanupEntity()
            
            local playergui = player:WaitForChild("PlayerGui")
            local screenGui = Instance.new("ScreenGui")
            screenGui.Parent = playergui
            screenGui.Name = "Screen Gui"
            screenGui.IgnoreGuiInset = true

            local stop = false
            local done = false

            local kill = Instance.new("Sound")
            kill.Parent = Workspace
            kill.PlaybackSpeed = 3
            kill.SoundId = "rbxassetid://5263560896"
            kill.Name = "Dear god death sound chat"
            kill.Volume = 5
            kill.Looped = true

            local flange = Instance.new("FlangeSoundEffect")
            flange.Parent = kill; flange.Depth = 1; flange.Mix = 1; flange.Rate = 0.2
            local trem = Instance.new("TremoloSoundEffect")
            trem.Parent = kill; trem.Depth = 1; trem.Duty = 0.94; trem.Frequency = 20
            local pitch = Instance.new("PitchShiftSoundEffect")
            pitch.Parent = kill; pitch.Octave = 0.5
            local distort = Instance.new("DistortionSoundEffect")
            distort.Parent = kill; distort.Level = 0.98

            kill:Play()

            local Backgroun = Instance.new("ImageLabel")
            Backgroun.Parent = screenGui
            Backgroun.Size = UDim2.new(1, 0, 1, 0)
            Backgroun.ImageTransparency = 1
            Backgroun.BackgroundTransparency = 0
            Backgroun.BackgroundColor3 = Color3.new(0, 0, 0)
            Backgroun.Image = "rbxassetid://105983470581183"

            local face = Instance.new("ImageLabel")
            face.Parent = screenGui
            face.AnchorPoint = Vector2.new(0.5, 0.5)
            face.Position = UDim2.new(0.5, 0, 0.589, 0)
            face.Size = UDim2.new(0, 860, 0, 860)
            face.Image = "rbxassetid://73683518024275"
            face.ImageTransparency = 0
            face.BackgroundTransparency = 1

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    Backgroun.BackgroundTransparency = 0; Backgroun.ImageTransparency = 1
                    task.wait(0.1)
                    Backgroun.BackgroundTransparency = 1; Backgroun.ImageTransparency = 0
                end
            end)

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    Backgroun.Image = "rbxassetid://131073231978514"
                    task.wait(0.0589)
                    Backgroun.Image = "rbxassetid://105841646930424"
                end
            end)

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    face.Rotation = 2; face.Image = "rbxassetid://122859819664215"
                    task.wait(0.0589)
                    face.Rotation = -2; face.Image = "rbxassetid://84489429478798"
                    task.wait(0.0589)
                    face.Rotation = 2; face.Image = "rbxassetid://73683518024275"
                    task.wait(0.0589)
                    face.Rotation = -2
                end
            end)

            local text = Instance.new("ImageLabel")
            text.Parent = screenGui
            text.AnchorPoint = Vector2.new(0.5, 0.5)
            text.Position = UDim2.new(0.5, 0, 0.5, 0)
            text.Size = UDim2.new(0, 300, 0, 300)
            text.Image = "rbxassetid://117106082021449"
            text.ImageTransparency = 0
            text.BackgroundTransparency = 1

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    text.Image = "rbxassetid://89229444931090"
                    task.wait(0.0589)
                    text.Image = "rbxassetid://117106082021449"
                end
            end)

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    text.Position = UDim2.new(Random.new():NextNumber(0, 0.5), 0, Random.new():NextNumber(0, 0.6), 0)
                    task.wait()
                end
            end)

            task.spawn(function()
                while task.wait() do
                    if stop then break end
                    text.ImageTransparency = 0; task.wait()
                    text.ImageTransparency = 1
                end
            end)

            task.wait(1.6)
            stop = true
            kill:Stop()
            
            task.spawn(function()
                while task.wait() do
                    if done then break end
                    face.ImageTransparency = 1
                    text.ImageTransparency = 1
                    Backgroun.ImageTransparency = 1
                    Backgroun.BackgroundTransparency = 1
                end
            end)

            pcall(function() 
                local remoteFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                if remoteFolder and remoteFolder:FindFirstChild("DeathHint") then
                    firesignal(remoteFolder.DeathHint.OnClientEvent, {
                        "Claim has seen you.",
                        "It will consume anyone on sight.",
                        "Do not look at it directly for too long!"
                    }, "Blue")
                end                    
            end)
            
            local statsFolder = game.ReplicatedStorage:WaitForChild("GameStats", 5)

            if statsFolder then
                local playerStats = statsFolder:WaitForChild("Player_" .. player.Name, 5)
                if playerStats then
                    local total = playerStats:WaitForChild("Total", 5)
                    local deathCause = total and total:WaitForChild("DeathCause", 5)
                    
                    if deathCause then
                        deathCause.Value = "DeerGod" -- ĐÃ SỬA TỪ "Cease" THÀNH "DeerGod" CHO CHUẨN XÁC
                        print("[Stats] Success: DeerGod")
                    else
                        warn("[Stats] Error Cause!")
                    end
                end
            else
                warn("[Stats] Error cant find GameStats in ReplicatedStorage!")
            end

            task.wait(0.2)
            player.Character.Humanoid.Health = 0
            task.wait(3)
            done = true
        end
    end
end)

-- Map Tracking Logic (Các phòng đằng sau)
local rooms = Workspace.CurrentRooms
local value = ReplicatedStorage.GameData.LatestRoom.Value

local nextroom = rooms:FindFirstChild(value + 1)
local room = rooms:FindFirstChild(value)
local room1 = rooms:FindFirstChild(value - 1)
local room2 = rooms:FindFirstChild(value - 2)
local room3 = rooms:FindFirstChild(value - 3)
local room4 = rooms:FindFirstChild(value - 4)
local room5 = rooms:FindFirstChild(value - 5)

-- Tracking Line of Sight & Following
task.spawn(function()
    while task.wait(0.5) do
        if hit or isDeactivated or not ambush.Parent then break end
        if character:GetAttribute("Hiding") then continue end

        local hitbox = 50
        local origin = ambush.Position
        local direction = (HumanoidRootPart.Position - origin).Unit
        local ray = Ray.new(origin, direction * hitbox)
        local raycast = Workspace:Raycast(ray.Origin, ray.Direction)

        if raycast and raycast.Instance.Parent == character then
            while not hit and not isDeactivated and ambush.Parent do
                if character:GetAttribute("Hiding") then break end
                
                if currentTween then pcall(function() currentTween:Cancel() end) end
                currentTween = TweenService:Create(ambush, TweenInfo.new(speed - 2), {CFrame = HumanoidRootPart.CFrame})
                currentTween:Play()
                task.wait(1)
            end
        end
    end
end)

-- Set CFrame khởi tạo ở phòng đằng sau (room5)
if room5 and room5:FindFirstChild("RoomEntrance") then
    ambush.CFrame = room5.RoomEntrance.CFrame
elseif room and room:FindFirstChild("RoomEntrance") then
    ambush.CFrame = room.RoomEntrance.CFrame * CFrame.new(0, 0, 50)
end

-- Di chuyển Deer God qua các phòng
task.spawn(function()
    local function moveToRoom(targetRoom)
        if hit or isDeactivated or not targetRoom or not targetRoom:FindFirstChild("RoomEntrance") then return end
        
        if currentTween then pcall(function() currentTween:Cancel() end) end
        currentTween = TweenService:Create(ambush, TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = targetRoom.RoomEntrance.CFrame})
        currentTween:Play()
        currentTween.Completed:Wait()
    end

    moveToRoom(room4)
    moveToRoom(room3)
    moveToRoom(room2)
    moveToRoom(room1)
    moveToRoom(room)
    moveToRoom(nextroom)

    if not hit and not isDeactivated and nextroom and nextroom:FindFirstChild("RoomExit") then
        if currentTween then pcall(function() currentTween:Cancel() end) end
        currentTween = TweenService:Create(ambush, TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = nextroom.RoomExit.CFrame})
        currentTween:Play()
        currentTween.Completed:Wait()
    end

    -- Nếu sinh tồn thành công -> Cấp thành tựu chuẩn mới & Cleanup
    if not hit and not isDeactivated then
        GiveDeerGodAchievement()
        CleanupEntity()
    end
end)
