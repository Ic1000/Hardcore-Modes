-- ========================================================
--   FROSTBITE ENTITY SCRIPT (FULL CRUCIFIX & MELD ICE ROOM)
-- ========================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local speed
if getgenv().FasterTrouble then 
speed = 6 else speed = 8
end

if _G.FrostbiteAchievementGotten == nil then
	_G.FrostbiteAchievementGotten = false
end

local CRUCIFIX_COLOR = Color3.fromRGB(137, 207, 255) -- Đổi sang Color3.fromRGB(255, 227, 137) nếu thích vàng Curious

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
task.wait(speed)

s:SetAttribute("FullySpawned", true)

if attachment then
	for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "smoker", "BlackTrai3l"}) do
		local child = attachment:FindFirstChild(v)
		if child then child.Enabled = true end
	end
end

-- ========================================================
-- HIỆU ỨNG BĂNG TỪ TỪ ĐÓNG LẠI & CHỈ TAN KHI THỰC THỂ BIẾN MẤT
-- ========================================================
local originalStates = {}
local frostColor = Color3.fromRGB(155, 215, 255)
local freezeBuildTime = 4
local freezeTweenInfo = TweenInfo.new(freezeBuildTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local hasMelted = false

local function StartGradualFreeze()
	pcall(function()
		local roomToFreeze = GetRoom()
		if not roomToFreeze then return end

		for _, desc in ipairs(roomToFreeze:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name ~= "Light" and desc.Name ~= "Neon" and desc.Name ~= "Bulb" then
				if not originalStates[desc] then
					originalStates[desc] = {
						Color = desc.Color,
						Material = desc.Material
					}
				end
				desc.Material = Enum.Material.Ice
				TweenService:Create(desc, freezeTweenInfo, {Color = frostColor}):Play()
			end
		end
	end)
end

local function MeltIceRoom()
	if hasMelted then return end
	hasMelted = true

	local meltTime = 4
	local meltTweenInfo = TweenInfo.new(meltTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	for part, original in pairs(originalStates) do
		if part and part.Parent and part:IsA("BasePart") then
			pcall(function()
				local tween = TweenService:Create(part, meltTweenInfo, {Color = original.Color})
				tween:Play()
				tween.Completed:Once(function()
					if part and part.Parent then
						part.Material = original.Material
					end
				end)
			end)
		end
	end
	table.clear(originalStates)
end

task.spawn(StartGradualFreeze)

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

local function GetGiveMeColorList(rootObj)
	local list = {}
	local ok = pcall(function()
		list = rootObj:QueryDescendants(".GiveMeColor")
	end)
	if ok and #list > 0 then
		return list
	end
	for _, d in ipairs(rootObj:GetDescendants()) do
		local tagged = false
		pcall(function()
			tagged = d:HasTag("GiveMeColor")
		end)
		if tagged or d.Name == "GiveMeColor" then
			table.insert(list, d)
		end
	end
	return list
end

local active = true -- Biến quản lý gây sát thương

local function TriggerCrucifixBanish(tool)
	if s:GetAttribute("BeingBanished") then return end
	s:SetAttribute("BeingBanished", true)

	-- NGAY LẬP TỨC NGỪNG GÂY DAMAGE VÀ RUNG
	active = false
	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end

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
		des.Volume = 0.8
		des.Parent = workspace
		des:Play()
		Debris:AddItem(des, 6)
	end)

	if tool then
		pcall(function() tool:Destroy() end)
	end

	local character = plr.Character
	local entityPivot = s:GetPivot()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, s}

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	if not result then
		result = { Position = entityPivot.Position - Vector3.new(0, 4, 0) }
	end

	local camShaker
	local theShake
	pcall(function()
		local mainGameMod = plr.PlayerGui:FindFirstChild("MainUI")
			and plr.PlayerGui.MainUI:FindFirstChild("Initiator")
			and plr.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game")
		if mainGameMod then
			local mainGame = require(mainGameMod)
			camShaker = mainGame and mainGame.camShaker
			if camShaker then
				theShake = camShaker:StartShake(5, 20, 2, Vector3.zero)
			end
		end
	end)

	if not camShaker then
		pcall(function()
			local shakerModule = ReplicatedStorage:FindFirstChild("CameraShaker", true)
			if shakerModule then
				local CameraShaker = require(shakerModule)
				camShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
					local curCam = workspace.CurrentCamera
					if curCam then
						curCam.CFrame = curCam.CFrame * shakeCf
					end
				end)
				camShaker:Start()
				theShake = camShaker:StartShake(5, 20, 2, Vector3.zero)
			end
		end)
	end

	local successRitual = false

	if repentanceAsset and repentanceAsset:IsA("Model") then
		local repentance = repentanceAsset:Clone()
		local crucifix = repentance:FindFirstChild("Crucifix")
		local handle = crucifix and crucifix:FindFirstChild("Handle")
		local pentagram = repentance:FindFirstChild("Pentagram")
		local entityPart = repentance:FindFirstChild("Entity")
		local sound = handle and handle:FindFirstChild("Sound")

		if crucifix and pentagram and entityPart then
			successRitual = true
			local charPivot = (character and character:GetPivot()) or workspace.CurrentCamera.CFrame

			pcall(function()
				repentance:PivotTo(CFrame.new(result.Position))
				crucifix:PivotTo(charPivot)
				if entityPart:IsA("BasePart") then
					entityPart.Anchored = true
					entityPart.CanCollide = false
					entityPart.CFrame = entityPivot
				end
			end)

			repentance.Parent = workspace
			if sound and sound:IsA("Sound") then
				pcall(function() sound:Play() end)
			end

			local startClock = os.clock()
			local function waitUntil(t: number)
				while repentance.Parent do
					local elapsed = os.clock() - startClock
					if sound and sound:IsA("Sound") and sound.TimeLength > 0 and sound.IsPlaying then
						if sound.TimePosition >= t or elapsed >= (t + 2) then
							break
						end
					elseif elapsed >= t then
						break
					end
					RunService.RenderStepped:Wait()
				end
			end

			local function fadeOut()
				for _, v in ipairs(pentagram:GetChildren()) do
					if v.Name == "BeamFlat" then
						task.delay(v:GetAttribute("Delay") or 0, function()
							if v and v.Parent then
								pcall(function()
									TweenService:Create(
										v,
										TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
										{ Brightness = 0 }
									):Play()
								end)
							end
						end)
					elseif v.Name == "BeamChain" then
						pcall(function()
							TweenService:Create(
								v,
								TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
								{ Brightness = 0 }
							):Play()
						end)
					end
				end
			end

			-- Đổi màu theo .GiveMeColor
			for _, v in ipairs(GetGiveMeColorList(repentance)) do
				pcall(function()
					if v:IsA("Light") or v:IsA("BasePart") then
						v.Color = CRUCIFIX_COLOR
					elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
						v.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, CRUCIFIX_COLOR),
							ColorSequenceKeypoint.new(1, CRUCIFIX_COLOR),
						})
					end
				end)
			end

			-- Khóa chặt mô hình Frostbite bám theo EntityPart
			task.spawn(function()
				while entityPart.Parent and repentance.Parent and s and s.Parent do
					pcall(function()
						s:PivotTo(entityPart.CFrame)
					end)
					RunService.RenderStepped:Wait()
				end
				if s and s.Parent then
					s:Destroy()
				end
				MeltIceRoom()
			end)

			-- Vòng phép thụt xuống đất
			local circle = pentagram:FindFirstChild("Circle")
			if circle then
				pcall(function()
					TweenService:Create(
						circle,
						TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
						{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) }
					):Play()
				end)
				task.delay(2, function()
					if circle and circle.Parent then
						circle:Destroy()
					end
				end)
			end

			-- Thánh giá lơ lửng, xoay và tách mảnh Shards
			if handle then
				pcall(function()
					local bp = handle:FindFirstChild("BodyPosition")
					if bp then
						bp.Position = (charPivot * CFrame.new(1, 4, -6)).Position
					end
					local bav = handle:FindFirstChild("BodyAngularVelocity")
					if bav then
						TweenService:Create(
							bav,
							TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
							{ AngularVelocity = Vector3.new(0, 40, 0) }
						):Play()
					end
				end)

				task.delay(3, function()
					local shards = handle:FindFirstChild("Shards")
					if shards then
						for _, shard in ipairs(shards:GetChildren()) do
							if shard:IsA("BasePart") then
								pcall(function()
									shard.CollisionGroup = "NoPlayer"
									shard.CanCollide = true
									local weld = shard:FindFirstChild("Weld")
									if weld then weld:Destroy() end
									shard.AssemblyAngularVelocity = Vector3.zero
								end)
							end
						end
					end
				end)
			end

			-- Nâng thực thể lên
			if entityPart:IsA("BasePart") then
				pcall(function()
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
						{ CFrame = entityPart.CFrame + Vector3.new(0, 2, 0) }
					):Play()
				end)
			end

			-- Nhịp ánh sáng nghi thức
			local pentBright = pentagram:FindFirstChild("Base")
				and pentagram.Base:FindFirstChild("LightAttach")
				and pentagram.Base.LightAttach:FindFirstChild("LightBright")
			local handleLight = handle and handle:FindFirstChild("Light")

			task.spawn(function()
				waitUntil(2.625)
				if not repentance.Parent then return end

				if pentBright then
					pcall(function()
						TweenService:Create(
							pentBright,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
							{ Brightness = 5, Range = 40 }
						):Play()
					end)
				end
				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
							{ Brightness = 11.25, Range = 30 }
						):Play()
					end)
				end

				task.wait(1.5)
				if not repentance.Parent then return end

				if pentBright then
					pcall(function()
						TweenService:Create(
							pentBright,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
							{ Brightness = 0, Range = 0 }
						):Play()
					end)
				end
				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
							{ Brightness = 0, Range = 0 }
						):Play()
					end)
				end

				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
							{ Brightness = 15, Range = 40 }
						):Play()
					end)
				end

				if theShake then
					pcall(function() theShake:StartFadeOut(3) end)
				end
				fadeOut()

				local bav = handle and handle:FindFirstChild("BodyAngularVelocity")
				if bav then
					pcall(function()
						TweenService:Create(
							bav,
							TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
							{ AngularVelocity = Vector3.zero }
						):Play()
					end)
				end
			end)

			-- Kéo thực thể xuống & tắt dần âm thanh
			waitUntil(2.5)
			if entityPart:IsA("BasePart") and repentance.Parent then
				pcall(function()
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ CFrame = entityPart.CFrame - Vector3.new(0, 50, 0) }
					):Play()
				end)
			end

			if s and s.Parent then
				for _, snd in ipairs(s:GetDescendants()) do
					if snd:IsA("Sound") and not snd:GetAttribute("VolumeIgnore") then
						pcall(function()
							TweenService:Create(
								snd,
								TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
								{ Volume = 0 }
							):Play()
						end)
					end
				end
			end

			waitUntil(6.75)

			-- Bùng sáng & nổ hạt kết thúc
			local glow = handle and handle:FindFirstChild("Glow")
			if glow and glow:IsA("BasePart") then
				pcall(function()
					TweenService:Create(
						glow,
						TweenInfo.new(1),
						{ Size = glow.Size * 3, Transparency = 1 }
					):Play()
				end)
			end
			if pentBright then
				pcall(function()
					TweenService:Create(
						pentBright,
						TweenInfo.new(1),
						{ Brightness = 0, Range = 0 }
					):Play()
				end)
			end
			if handleLight then
				pcall(function()
					TweenService:Create(
						handleLight,
						TweenInfo.new(1),
						{ Brightness = 0, Range = 0 }
					):Play()
				end)
			end

			local explodeParticle = handle and handle:FindFirstChild("ExplodeParticle")
			if explodeParticle and explodeParticle:IsA("ParticleEmitter") then
				pcall(function() explodeParticle:Emit(math.random(20, 30)) end)
			end
			if camShaker then
				pcall(function() camShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5) end)
			end

			if s and s.Parent then
				s:Destroy()
			end
			MeltIceRoom()
			Debris:AddItem(repentance, 5)
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
			MeltIceRoom()
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
			des.Volume = 0.8
			des.Parent = workspace
			des:Play()

			Debris:AddItem(des, 6)
		end
	end)

	pcall(function()
		if s and s.Parent then s:Destroy() end
	end)

	-- Chỉ bắt đầu chảy/tan băng khi thực thể biến mất
	task.spawn(MeltIceRoom)

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
