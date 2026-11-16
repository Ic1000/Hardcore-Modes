-- ========================================================
--   FROSTBITE ENTITY SCRIPT (FULL CRUCIFIX & MELD ICE ROOM)
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

-- TẢI HÀM TIỆN ÍCH CHUẨN VYNIXU (ĐẢM BẢO LoadCustomInstance HOẠT ĐỘNG HOÀN HẢO)
pcall(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))()
end)

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

-- Biến cờ kiểm soát trạng thái
s:SetAttribute("FullySpawned", false)
s:SetAttribute("BeingBanished", false)

-- ========================================================
-- ĐỊNH VỊ VỊ TRÍ CHUẨN XÁC TRÊN MẶT SÀN
-- ========================================================

local function SetEntityPositionOnFloor(targetRoom)
	local floorPart = targetRoom:FindFirstChild("Parts") and targetRoom.Parts:FindFirstChild("Floor")
	local baseCFrame = floorPart and floorPart.CFrame or targetRoom:GetPivot()

	local rayOrigin = baseCFrame.Position + Vector3.new(0, 15, 0)
	local rayDirection = Vector3.new(0, -50, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {s, plr.Character}

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	local targetPosition
	if raycastResult then
		targetPosition = raycastResult.Position + Vector3.new(0, -2, 0)
	else
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
-- HIỆU ỨNG PHÒNG XANH & ÁNH SÁNG BAN ĐẦU
-- ========================================================

local lightTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local blueLightColor = {Color = Color3.fromRGB(100, 180, 255)}

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
pointLight.Color = Color3.fromRGB(100, 200, 255)
pointLight.Range = 70
pointLight.Brightness = 0
pointLight.Parent = entity

TweenService:Create(pointLight, TweenInfo.new(3), {Brightness = 2.5}):Play()

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
	TintColor = Color3.fromRGB(180, 220, 255),
	Saturation = -0.2,
	Contrast = 0.1
}):Play()

local attachment = entity:FindFirstChild("Attachment") or s:FindFirstChild("Attachment", true)
if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "smoker", "BlackTrai3l"}) do
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
				local camShakerMod = ReplicatedStorage:FindFirstChild("CameraShaker", true)
				if camShakerMod then
					local CameraShaker = require(camShakerMod)
					local camera = workspace.CurrentCamera
					local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
						camera.CFrame = camera.CFrame * shakeCf
					end)
					camShake:Start()
					camShake:ShakeOnce(9, 8, 0.1, 2, 1, 6)
				end
			end)
		end
	end
end)

-- THỜI GIAN ĐỢI XUẤT HIỆN HOÀN TOÀN (8 GIÂY)
task.wait(8)

s:SetAttribute("FullySpawned", true)

if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "smoker", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = true end
	end
end

-- ========================================================
-- HIỆU ỨNG CHUYỂN ĐỔI PHÒNG THÀNH "MELD ICE" TỪ TỪ
-- ========================================================
task.spawn(function()
	pcall(function()
		local roomToMeld = GetRoom()
		if roomToMeld then
			local meldTweenInfo = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for _, part in ipairs(roomToMeld:GetDescendants()) do
				if part:IsA("BasePart") and not part.Anchored then continue end
				if part:IsA("BasePart") then
					-- Tween từ từ màu sắc các vật thể trong phòng sang tone băng giá (Xanh dương lạnh)
					TweenService:Create(part, meldTweenInfo, {
						Color = part.Color:Lerp(Color3.fromRGB(150, 210, 255), 0.35),
						Material = Enum.Material.Glass -- Tạo hiệu ứng bề mặt bóng lạnh như băng
					}):Play()
				end
			end
		end
	end)
end)

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
	if not character then return end
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

-- ========================================================
-- TẢI ASSET HIỆU ỨNG TRỪ TÀ (REPENTANCE) CHUẨN VYNIXU ĐỂ KHÔNG BỊ LỖI
-- ========================================================

local repentanceAsset = nil
pcall(function()
	if type(LoadCustomInstance) == "function" then
		repentanceAsset = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm")
	else
		repentanceAsset = game:GetObjects("rbxassetid://12543866876")[1]
	end
end)

local active = true -- Biến quản lý gây sát thương

local function TriggerCrucifixBanish(tool)
	if s:GetAttribute("BeingBanished") then return end
	s:SetAttribute("BeingBanished", true)

	-- NGAY LẬP TỨC NGỪNG GÂY DAMAGE
	active = false

	-- Tắt toàn bộ âm thanh hoạt động / ambient của thực thể
	pcall(function()
		if entity:FindFirstChild("Ambience") then entity.Ambience:Stop() end
		if entity:FindFirstChild("AmbienceFar") then entity.AmbienceFar:Stop() end
		if entity:FindFirstChild("Frostbite_ActiveSound") then entity.Frostbite_ActiveSound:Stop() end
		for _, child in ipairs(entity:GetDescendants()) do
			if child:IsA("Sound") then
				child:Stop()
			end
		end
	end)

	-- PHÁT ÂM THANH DESPAWN KHI ĂN THÁNH GIÁ
	pcall(function()
		local des = Instance.new("Sound")
		des.SoundId = "rbxassetid://111715441853991"
		des.Looped = false
		des.Volume = 1.5
		des.Parent = workspace
		des:Play()
		Debris:AddItem(des, 6)
	end)

	if tool then tool:Destroy() end

	local character = plr.Character
	local entityPivot = s:GetPivot()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, s}

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	if not result then
		s:Destroy()
		return
	end

	local successRitual = false

	if repentanceAsset and repentanceAsset:IsA("Model") then
		local repentance = repentanceAsset:Clone()
		local crucifix = repentance:FindFirstChild("Crucifix")
		local handle = crucifix and crucifix:FindFirstChild("Handle")
		local pentagram = repentance:FindFirstChild("Pentagram")
		local entityPart = repentance:FindFirstChild("Entity")

		if crucifix and pentagram and entityPart then
			successRitual = true
			local sound = handle and (handle:FindFirstChild("Sound") or handle:FindFirstChild("SoundFail"))

			repentance:PivotTo(CFrame.new(result.Position))
			crucifix:PivotTo(character:GetPivot())
			entityPart.CFrame = entityPivot
			repentance.Parent = workspace

			if sound then sound:Play() end

			-- Khóa chặt mô hình Frostbite bám theo tâm hoạt ảnh trừ tà
			task.spawn(function()
				while entityPart.Parent and s.Parent do
					s:PivotTo(entityPart.CFrame)
					RunService.RenderStepped:Wait()
				end
				if s and s.Parent then
					s:Destroy()
				end
			end)

			-- Vòng phép thụt xuống đất
			if pentagram:FindFirstChild("Circle") then
				TweenService:Create(
					pentagram.Circle,
					TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
					{ CFrame = pentagram.Circle.CFrame - Vector3.new(0, 25, 0) }
				):Play()
				task.delay(2, function() pentagram.Circle:Destroy() end)
			end

			-- Kéo thực thể bay lên không trung
			TweenService:Create(
				entityPart,
				TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
				{ CFrame = entityPart.CFrame + Vector3.new(0, 2, 0) }
			):Play()

			-- Sau 3 giây kéo sập xuống lòng đất
			task.delay(3, function()
				if entityPart then
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ CFrame = entityPart.CFrame - Vector3.new(0, 50, 0) }
					):Play()
				end
			end)

			-- Tan biến từ từ (Fade out) hiệu ứng repentance
			task.delay(7, function()
				if repentance and repentance.Parent then
					for _, part in pairs(repentance:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("Decal") then
							TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
						elseif part:IsA("Beam") or part:IsA("ParticleEmitter") then
							part.Enabled = false
						end
					end

					task.wait(2)
					repentance:Destroy()
				end

				if s and s.Parent then 
					s:Destroy() 
				end
			end)
		end
	end

	-- DỰ PHÒNG AN TOÀN NẾU ASSET TẢI LỖI
	if not successRitual then
		task.spawn(function()
			local startCF = entityPivot
			local t = 0
			while t < 3 and s and s.Parent do
				t = t + RunService.RenderStepped:Wait()
				s:PivotTo(startCF * CFrame.new(0, t * 1.5, 0) * CFrame.Angles(0, math.rad(t * 300), 0))
			end
			if s and s.Parent then
				s:Destroy()
			end
		end)
	end
end

local function CheckCrucifix()
	if not s:GetAttribute("FullySpawned") or s:GetAttribute("BeingBanished") then return end

	local char = plr.Character
	if not char then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local name = tool.Name:lower()
		if name:find("crucifix") or name:find("cruxy") then
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			local primaryPart = s.PrimaryPart or entity
			if rootPart and primaryPart then
				local dist = (primaryPart.Position - rootPart.Position).Magnitude
				if dist <= 45 then
					TriggerCrucifixBanish(tool)
				end
			end
		end
	end
end

task.spawn(function()
	while s and s.Parent do
		CheckCrucifix()
		task.wait(0.2)
	end
end)

-- ========================================================

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
		if not active then break end
		local chr = plr.Character
		if chr then
			local hum = chr:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local isProtected = IsLighterActive(chr)
				if not isProtected and active then
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
			for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "smoker", "BlackTrai3l"}) do
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
		if entity and entity.Parent and not s:GetAttribute("BeingBanished") then
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
