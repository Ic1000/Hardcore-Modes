-- ========================================================
--          FROSTBITE ENTITY SCRIPT (FIXED SPAWN HEIGHT)
-- ========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

if _G.FrostbiteAchievementGotten == nil then
	_G.FrostbiteAchievementGotten = false
end

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

local success, objects = pcall(function()
	return game:GetObjects("rbxassetid://12272255258")
end)

if not success or not objects or #objects == 0 then
	warn("Không thể tải Asset Frostbite!")
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

if not s.PrimaryPart then
	s.PrimaryPart = entity
end

-- ========================================================
-- PHẦN SỬA LỖI: ĐỊNH VỊ VỊ TRÍ CHUẨN XÁC TRÊN MẶT SÀN
-- ========================================================

local function SetEntityPositionOnFloor(targetRoom)
	local floorPart = targetRoom:FindFirstChild("Parts") and targetRoom.Parts:FindFirstChild("Floor")
	local baseCFrame = floorPart and floorPart.CFrame or targetRoom:GetPivot()

	-- Chiếu raycast từ trên độ cao 15 studs xuống dưới để tìm mặt sàn chính xác
	local rayOrigin = baseCFrame.Position + Vector3.new(0, 15, 0)
	local rayDirection = Vector3.new(0, -50, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {s, plr.Character}

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	local targetPosition
	if raycastResult then
		-- Đặt chân thực thể cách mặt sàn 2.5 - 3.5 studs (vừa tầm lơ lửng đẹp)
		targetPosition = raycastResult.Position + Vector3.new(0, -2, 0)
	else
		-- Dự phòng nếu raycast không trúng sàn
		targetPosition = baseCFrame.Position + Vector3.new(0, -3, 0)
	end

	local finalCFrame = CFrame.new(targetPosition)

	if s:IsA("Model") then
		s:PivotTo(finalCFrame)
	elseif entity:IsA("BasePart") then
		entity.CFrame = finalCFrame
	end
end

SetEntityPositionOnFloor(currentRoom)

if entity:FindFirstChild("Part") then
	entity.Part.CFrame = entity.CFrame
end

-- ========================================================
-- HIỆU ỨNG PHÒNG XANH & HIỆU ỨNG ÂM THANH
-- ========================================================

local lightTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local blueLightColor = {Color = Color3.new(0, 0, 1)}

for _, descendant in ipairs(workspace.CurrentRooms:GetDescendants()) do
	if descendant:IsA("Light") then
		TweenService:Create(descendant, lightTweenInfo, blueLightColor):Play()
	end
end

pcall(function()
	if entity:FindFirstChild("Ambience") then entity.Ambience:Stop() end
	if entity:FindFirstChild("AmbienceFar") then entity.AmbienceFar:Stop() end
end)

local pointLight = Instance.new("PointLight")
pointLight.Color = Color3.fromRGB(0, 150, 255)
pointLight.Range = 60
pointLight.Brightness = 0
pointLight.Parent = entity

TweenService:Create(pointLight, TweenInfo.new(3), {Brightness = 3}):Play()

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://137044859218769"
sound.Looped = false
sound.Volume = 2
sound.Parent = entity
sound:Play()

local frost = Instance.new("ColorCorrectionEffect")
frost.Name = "Frostbite_Effect"
frost.Parent = Lighting
TweenService:Create(frost, TweenInfo.new(10), {
	TintColor = Color3.fromRGB(0, 0, 255),
	Saturation = -0.5,
	Contrast = 0.2
}):Play()

local attachment = entity:FindFirstChild("Attachment") or s:FindFirstChild("Attachment", true)
if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = false end
	end
end

local hitbox = 80
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

task.wait(8)

if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = true end
	end
end

pcall(function()
	local frostbiteModel = s:FindFirstChild("Frostbite") or s
	if frostbiteModel then
		local frostyNew = frostbiteModel:FindFirstChild("FrostyNew") or frostbiteModel
		if frostyNew then
			local frostPart = frostyNew:FindFirstChild("part") or frostyNew
			for _, particle in ipairs(frostPart:GetDescendants()) do
				if particle:IsA("ParticleEmitter") then
					particle.Enabled = true
					particle.Rate = 500
				end
			end
		end
	end
end)

pcall(function()
	if entity:FindFirstChild("Ambience") then
		entity.Ambience.SoundId = "rbxassetid://1102548016"
		entity.Ambience.Volume = 0.2
		entity.Ambience:Play()
	end
	if entity:FindFirstChild("AmbienceFar") then
		entity.AmbienceFar.Volume = 0.1
		entity.AmbienceFar:Play()
	end
end)

local activeSound = Instance.new("Sound")
activeSound.Name = "Frostbite_ActiveSound"
activeSound.SoundId = "rbxassetid://127072724991408"
activeSound.Volume = 1.5
activeSound.Looped = true
activeSound.Parent = entity
activeSound:Play()

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
					Image = "rbxassetid://0"
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
			des.Volume = 1.5
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
