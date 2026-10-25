-- ========================================================
--          FROSTBITE ENTITY SCRIPT (WITH PROXIMITY SHAKE)
-- ========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Tạo/Kiểm tra biến toàn cục lưu trạng thái thành tựu
if _G.FrostbiteAchievementGotten == nil then
	_G.FrostbiteAchievementGotten = false
end

-- Đợi phòng tiếp theo được kích hoạt an toàn
local gameData = ReplicatedStorage:WaitForChild("GameData", 10)
local latestRoom = gameData and gameData:WaitForChild("LatestRoom", 10)
if latestRoom then
	latestRoom.Changed:Wait()
end

local plr = Players.LocalPlayer

local function GetRoom()
	local currentRooms = workspace:WaitForChild("CurrentRooms", 10)
	local latestRoomValue = latestRoom and latestRoom.Value
	if currentRooms and latestRoomValue then
		return currentRooms:FindFirstChild(tostring(latestRoomValue))
	end
	return nil
end

local currentRoom = GetRoom()
if not currentRoom then
	warn("Không tìm thấy phòng hiện tại!")
	return
end

-- Tải Frostbite entity từ Asset ID chuẩn xác
local success, objects = pcall(function()
	return game:GetObjects("rbxassetid://12272255258")
end)

if not success or not objects or #objects == 0 then
	warn("Không thể tải Asset Frostbite! Lỗi Asset ID hoặc bị Executor chặn.")
	return
end

local s = objects[1]
s.Name = "Frostbite"
s.Parent = workspace

local entity = s:FindFirstChildWhichIsA("BasePart") or s:FindFirstChild("Part") or s
if not entity then
	warn("Không tìm thấy BasePart trong Entity!")
	s:Destroy()
	return
end

local roomEntrance = currentRoom:WaitForChild("RoomEntrance", 5)
if roomEntrance then
	if entity:IsA("BasePart") then
		entity.CFrame = roomEntrance.CFrame * CFrame.new(0, -5, -15)
	elseif entity:IsA("Model") then
		entity:PivotTo(roomEntrance.CFrame * CFrame.new(0, -5, -15))
	end
end

if entity:FindFirstChild("Part") then
	entity.Part.CFrame = entity.CFrame
end

-- Đảm bảo có PrimaryPart cho thực thể để tính khoảng cách rung camera
if not s.PrimaryPart then
	s.PrimaryPart = entity
end

-- Dừng và cài đặt âm thanh cũ an toàn nếu có
pcall(function()
	if entity:FindFirstChild("Ambience") then entity.Ambience:Stop() end
	if entity:FindFirstChild("AmbienceFar") then entity.AmbienceFar:Stop() end
end)

-- Tạo PointLight sáng dần đúng chuẩn ban đầu
local pointLight = Instance.new("PointLight")
pointLight.Color = Color3.fromRGB(255, 255, 255)
pointLight.Range = 60
pointLight.Brightness = 0
pointLight.Parent = entity

TweenService:Create(pointLight, TweenInfo.new(3), {Brightness = 3}):Play()

-- Âm thanh xuất hiện ban đầu
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://137044859218769"
sound.Looped = false
sound.Volume = 1.75
sound.Parent = entity
sound:Play()

-- Tạo hiệu ứng đóng băng màn hình
local frost = Instance.new("ColorCorrectionEffect")
frost.Name = "Frostbite_Effect"
frost.Parent = Lighting
TweenService:Create(frost, TweenInfo.new(10), {
	TintColor = Color3.fromRGB(0, 0, 255),
	Saturation = -0.5,
	Contrast = 0.2
}):Play()

-- Ẩn các attachment lúc đầu
local attachment = entity:FindFirstChild("Attachment") or s:FindFirstChild("Attachment", true)
if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = false end
	end
end

-- HIỆU ỨNG RUNG LẮC KHI LẠI GẦN (Chạy ngầm liên tục dựa theo file bingu)
local hitbox = 80 -- Phạm vi nhận diện để rung màn hình
local shakeConnection
shakeConnection = RunService.Heartbeat:Connect(function()
	local chr = plr.Character
	if chr and chr:FindFirstChild("HumanoidRootPart") and s and s.PrimaryPart then
		local distance = (s.PrimaryPart.Position - chr.HumanoidRootPart.Position).Magnitude
		if distance <= hitbox then
			pcall(function()
				local CameraShaker = require(ReplicatedStorage.CameraShaker)
				local camera = workspace.CurrentCamera
				local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
					camera.CFrame = camera.CFrame * shakeCf
				end)
				camShake:Start()
				camShake:ShakeOnce(9, 8, 0.1, 2, 1, 6)
			end)
		end
	end
end)

-- ĐỢI 8 GIÂY HOÀN TẤT QUÁ TRÌNH CHUẨN BỊ XUẤT HIỆN
task.wait(8)

-- SAU KHI ĐÃ ĐỢI 8 GIÂY -> THỰC THỂ XUẤT HIỆN HOÀN TOÀN:
-- Bật lại attachment
if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = true end
	end
end

-- Bật toàn bộ ParticleEmitter với tốc độ hạt bắn ra liên tục
pcall(function()
	local frostbiteModel = s:FindFirstChild("Frostbite") or s
	if frostbiteModel then
		local frostyNew = frostbiteModel:FindFirstChild("FrostyNew") or frostbiteModel
		if frostyNew then
			local frostPart = frostyNew:FindFirstChild("part") or frostyNew
			for _, particle in ipairs(frostPart:GetDescendants()) do
				if particle:IsA("ParticleEmitter") then
					particle.Enabled = true
					particle.Rate = 500 -- Tăng tốc độ bắn hạt liên tục
				end
			end
		end
	end
end)

-- Bật âm thanh Ambience chính thức
pcall(function()
	if entity:FindFirstChild("Ambience") then
		entity.Ambience.SoundId = "rbxassetid://1102548016"
		entity.Ambience.Volume = 0.8
		entity.Ambience:Play()
	end
	if entity:FindFirstChild("AmbienceFar") then
		entity.AmbienceFar.Volume = 0.6
		entity.AmbienceFar:Play()
	end
end)

-- Âm thanh hoạt động chính thức
local activeSound = Instance.new("Sound")
activeSound.Name = "Frostbite_ActiveSound"
activeSound.SoundId = "rbxassetid://127072724991408"
activeSound.Volume = 1.6
activeSound.Looped = true
activeSound.Parent = entity
activeSound:Play()

-- Kiểm tra bật lửa / nguồn nhiệt bảo vệ tối ưu hóa
local function IsLighterActive(character)
	if not character then return false end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			local name = child.Name:lower()
			if name:find("lighter") or name:find("seek") or name:find("match") or name:find("torch") then
				if child:GetAttribute("IsOn") == true or child:GetAttribute("Lit") == true or child:GetAttribute("Enabled") == true or child:GetAttribute("Active") == true then
					return true
				end
				for _, flame in ipairs(child:GetDescendants()) do
					if (flame:IsA("ParticleEmitter") or flame:IsA("Light")) and flame.Enabled then
						return true
					end
				end
			end
		end
	end
	return false
end

-- Vòng lặp sát thương kết hợp quản lý nhân vật sống/chết/hồi sinh
local active = true
local diedConn

local function setupCharacter(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	if diedConn then diedConn:Disconnect() end
	diedConn = hum.Died:Connect(function()
		active = false
	end)
end

if plr.Character then
	setupCharacter(plr.Character)
end
plr.CharacterAdded:Connect(setupCharacter)

task.spawn(function()
	while active do
		task.wait(1)
		local chr = plr.Character
		if chr then
			local hum = chr:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local isProtected = IsLighterActive(chr)
				if not isProtected then
					hum:TakeDamage(5)

					pcall(function()
						local stats = ReplicatedStorage:FindFirstChild("GameStats")
						local playerStat = stats and stats:FindFirstChild("Player_" .. plr.Name)
						if playerStat and playerStat:FindFirstChild("Total") then
							playerStat.Total.DeathCause.Value = "Frostbite"
						end
					end)
				end
			else
				active = false
			end
		else
			active = false
		end
	end
end)

-- Hàm dọn dẹp hiệu ứng & Trao thành tựu an toàn
local cleanedUp = false
local function Cleanup()
	if cleanedUp then return end
	cleanedUp = true
	active = false

	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end

	if diedConn then diedConn:Disconnect() end

	if not _G.FrostbiteAchievementGotten then
		_G.FrostbiteAchievementGotten = true
		task.spawn(function()
			local success, achievementGiver = pcall(function()
				return loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()
			end)
			if success and achievementGiver then
				achievementGiver({
					Title = "It So Cold....",
					Desc = "A Bite From Ice.",
					Reason = "Encounter Entity Called Frostbite",
					Image = "rbxassetid://109016442861859"
				})
			end
		end)
	end

	pcall(function()
		if attachment then
			for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
				local child = attachment:FindFirstChild(v)
				if child then child.Enabled = false end
			end
		end
	end)

	pcall(function()
		local frostbiteModel = s:FindFirstChild("Frostbite") or s
		if frostbiteModel then
			local frostyNew = frostbiteModel:FindFirstChild("FrostyNew") or frostbiteModel
			if frostyNew then
				local frostPart = frostyNew:FindFirstChild("part") or frostyNew
				for _, particle in ipairs(frostPart:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = false
					end
				end
			end
		end
	end)

	pcall(function()
		if entity and entity.Parent then
			if entity:FindFirstChild("Ambience") then entity.Ambience:Stop() end
			if entity:FindFirstChild("AmbienceFar") then entity.AmbienceFar:Stop() end
			if entity:FindFirstChild("Frostbite_ActiveSound") then entity.Frostbite_ActiveSound:Stop() end

			local des = Instance.new("Sound")
			des.SoundId = "rbxassetid://111715441853991"
			des.Looped = false
			des.Volume = 1.6
			des.Parent = workspace
			des:Play()

			Debris:AddItem(des, 6)
		end
	end)

	pcall(function()
		if s and s.Parent then s:Destroy() end
	end)

	if frost then
		local tweenOut = TweenService:Create(frost, TweenInfo.new(3), {
			TintColor = Color3.fromRGB(255, 255, 255),
			Saturation = 0,
			Contrast = 0
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			if frost then frost:Destroy() end
		end)
	end
end

-- CHỈ KHI THỰC THỂ ĐÃ XUẤT HIỆN HOÀN TOÀN (SAU 8 GIÂY), NẾU NGƯỜI CHƠI MỞ CỬA SANG PHÒNG TIẾP THEO THÌ MỚI BIẾN MẤT
local latestRoomVal = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom", 10)
local roomConnection
if latestRoomVal then
	roomConnection = latestRoomVal.Changed:Connect(function()
		if roomConnection then
			roomConnection:Disconnect()
			roomConnection = nil
		end
		Cleanup()
	end)
end

-- Lắng nghe sự kiện người chơi chết để dọn dẹp
if plr.Character then
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			if roomConnection then 
				roomConnection:Disconnect() 
				roomConnection = nil 
			end
			Cleanup()
		end)
	end
end
