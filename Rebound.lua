--========================================================--
--         REBOUND ENTITY SCRIPT + FULL CRUCIFIX         --
--========================================================--

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Chống nhiều instance Rebound chạy chồng lên nhau
local env = (getgenv and getgenv()) or _G
if env.HardcoreReboundActive == true then
	return
end

env.HardcoreReboundActive = true
env.HardcoreReboundSessionId = (env.HardcoreReboundSessionId or 0) + 1
local currentSessionId = env.HardcoreReboundSessionId

local lockReleased = false
local function ReleaseReboundLock()
	if lockReleased then
		return
	end
	lockReleased = true
	if env.HardcoreReboundSessionId == currentSessionId then
		env.HardcoreReboundActive = false
	end
end

if env.ReboundAchivement ~= nil then
	env.ReboundAchivement = true
end

local VYNIXU_ROOT = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main"

-- Variables
local maxRebounds = 5
local reboundCount = 0
local isJumpscaring = false
local isBanished = false
local completedFullCycleAndDestroyed = false

local CrucifixSettings = {
	Enabled = true,
	Type = "Guiding", -- "Guiding" hoặc "Curious"
	Range = 60,
	Resist = false, -- Đổi thành true nếu muốn test chế độ kháng thánh giá giống file gốc
}

local CrucifixColors = {
	["guiding"] = Color3.fromRGB(137, 207, 255),
	["curious"] = Color3.fromRGB(255, 227, 137),
}

-- ====== UTILS & AUDIO ======
local function GitAud(soundgit, filename)
	local filePath = filename .. ".mp3"
	pcall(function()
		if not isfile or not isfile(filePath) then
			writefile(filePath, game:HttpGet(soundgit))
		end
	end)
	local customFn = getcustomasset or getsynasset
	if customFn then
		local ok, asset = pcall(customFn, filePath)
		if ok and asset then
			return asset
		end
	end
	return ""
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
		Debris:AddItem(sound, 10)
	end)
end

-- Camera Shake Setup
local cameraShaker = require(ReplicatedStorage:WaitForChild("CameraShaker"))
local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
	if not isBanished then
		Camera.CFrame = Camera.CFrame * cf
	end
end)
camShake:Start()

-- Asset Loader
local function LoadCustomInstance(assetId, parent)
	local model = nil
	local retryCount = 0

	while not model and retryCount < 5 do
		retryCount = retryCount + 1
		local success, result = pcall(function()
			local loadedObjects
			if typeof(assetId) == "string" and assetId:match("^https?://") then
				local fileName = "CustomAsset_" .. tostring(#assetId) .. "_" .. tostring(retryCount) .. ".rbxm"
				writefile(fileName, game:HttpGet(assetId))
				loadedObjects = game:GetObjects((getcustomasset or getsynasset)(fileName))
			else
				loadedObjects = game:GetObjects(assetId)
			end
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

local repentanceTemplate = nil
local function GetRepentanceTemplate()
	if repentanceTemplate and repentanceTemplate.Parent then
		return repentanceTemplate
	end
	repentanceTemplate = LoadCustomInstance(VYNIXU_ROOT .. "/Assets/Repentance.rbxm", ReplicatedStorage)
	if repentanceTemplate then
		repentanceTemplate.Parent = nil
	end
	return repentanceTemplate
end

task.spawn(function()
	pcall(GetRepentanceTemplate)
end)

local speed = env.FasterTrouble and 1.4 or 1.8

local function HasCrucifixEquipped()
	local char = LocalPlayer.Character
	if not char then
		return false, nil
	end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local tagged = false
			pcall(function()
				tagged = item:HasTag("Crucifix") or item:HasTag("Cruxy")
			end)
			if tagged or item.Name:lower():find("crucifix", 1, true) or item.Name:lower():find("cruxy", 1, true) then
				return true, item
			end
		end
	end
	return false, nil
end

local function HasClearCrucifixSight(origin, hrp, char, entityPart, rootModel)
	if not origin or not hrp then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclude = {}
	if char then table.insert(exclude, char) end
	if rootModel then table.insert(exclude, rootModel) end
	if entityPart then table.insert(exclude, entityPart) end
	for _, spot in ipairs(CollectionService:GetTagged("HidingSpot")) do
		table.insert(exclude, spot)
	end
	params.FilterDescendantsInstances = exclude

	local hit = workspace:Raycast(origin, hrp.Position - origin, params)
	return hit == nil
end

local function GetGiveMeColorDescendants(root)
	local list = {}
	local ok = pcall(function()
		list = root:QueryDescendants(".GiveMeColor")
	end)
	if ok and #list > 0 then
		return list
	end
	for _, desc in ipairs(root:GetDescendants()) do
		local hasTag = false
		pcall(function()
			hasTag = desc:HasTag("GiveMeColor")
		end)
		if hasTag or desc.Name == "GiveMeColor" then
			table.insert(list, desc)
		end
	end
	return list
end

local function PivotModelSafely(model, targetCFrame)
	if not model or not model.Parent then return end
	pcall(function()
		if model:IsA("Model") then
			model:PivotTo(targetCFrame)
		elseif model:IsA("BasePart") then
			model.CFrame = targetCFrame
		end
	end)
end

-- ====== THÀNH TỰU KHI REBOUND ĐI HẾT VÒNG VÀ DESTROY ======
local function GiveReboundAchievement()
	if isBanished or not completedFullCycleAndDestroyed then
		return
	end

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	task.spawn(function()
		local success, achievementGiver = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()
		end)

		if success and achievementGiver then
			local payload = {
				Title = "Out Of Many Rebound..",
				Desc = "I will come back..or not..",
				Reason = "Survive and Encounter Rebound..",
				Image = "rbxassetid://13856279697"
			}

			pcall(function()
				if typeof(achievementGiver) == "function" then
					achievementGiver(payload)
				elseif typeof(achievementGiver) == "table" and typeof(achievementGiver.Give) == "function" then
					achievementGiver.Give(payload)
				end
			end)
		end
	end)
end

-- ====== FULL CRUCIFIX / REPENTANCE MECHANIC (GIỐNG BẢN GỐC) ======
local function CrucifixEntity(entityPart, rootModel, stopMoveFn)
	local resist = CrucifixSettings.Resist == true

	if not resist then
		if isBanished then return end
		isBanished = true
		isJumpscaring = true
		completedFullCycleAndDestroyed = false
		if stopMoveFn then
			pcall(stopMoveFn)
		end
	end

	local char = LocalPlayer.Character
	local entityPivot = (entityPart and entityPart:IsA("BasePart") and entityPart.CFrame)
		or (rootModel and rootModel:GetPivot())
		or CFrame.new()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if char then table.insert(exclude, char) end
	if rootModel then table.insert(exclude, rootModel) end
	if entityPart then table.insert(exclude, entityPart) end
	params.FilterDescendantsInstances = exclude

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	if not result then
		result = { Position = entityPivot.Position - Vector3.new(0, 4, 0) }
	end

	pcall(function()
		if rootModel then
			rootModel:SetAttribute("BeingBanished", true)
			rootModel:SetAttribute("Paused", true)
			for _, desc in ipairs(rootModel:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = true
					desc.CanCollide = false
				end
			end
		end
		if entityPart and entityPart:IsA("BasePart") then
			entityPart.Anchored = true
			entityPart.CanCollide = false
		end
	end)

	local mainCamShaker
	local theShake
	pcall(function()
		local mainGame = require(PlayerGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game"))
		mainCamShaker = mainGame.camShaker
		if mainCamShaker then
			theShake = mainCamShaker:StartShake(5, 20, 2, Vector3.zero)
		end
	end)

	local template = GetRepentanceTemplate()
	if not template then
		if not resist and rootModel and rootModel.Parent then
			rootModel:Destroy()
		end
		return
	end

	local Repentance = template:Clone()
	local Crucifix = Repentance:FindFirstChild("Crucifix")
	local Handle = Crucifix and Crucifix:FindFirstChild("Handle")
	local Pentagram = Repentance:FindFirstChild("Pentagram")
	local EntityPart = Repentance:FindFirstChild("Entity")
	local Sound = Handle and Handle:FindFirstChild(resist and "SoundFail" or "Sound")

	local charPivot = (char and char:GetPivot()) or Camera.CFrame

	pcall(function()
		Repentance:PivotTo(CFrame.new(result.Position))
		if Crucifix then
			Crucifix:PivotTo(charPivot)
		end
		if EntityPart and EntityPart:IsA("BasePart") then
			EntityPart.Anchored = true
			EntityPart.CanCollide = false
			EntityPart.CFrame = entityPivot
		end
	end)

	Repentance.Parent = workspace

	if Sound and Sound:IsA("Sound") then
		pcall(function()
			Sound:Play()
		end)
	end

	local ritualStart = os.clock()
	local function waitUntil(t)
		while Repentance.Parent do
			local elapsed = os.clock() - ritualStart
			if elapsed >= t then
				if Sound and Sound:IsA("Sound") and Sound.TimeLength > 0 and Sound.IsPlaying and Sound.TimePosition < t and elapsed < (t + 2) then
					-- Chờ Sound chạy tới mốc t
				else
					break
				end
			end
			RunService.RenderStepped:Wait()
		end
	end

	local function fadeOut()
		if not Pentagram then return end
		for _, v in ipairs(Pentagram:GetChildren()) do
			if v.Name == "BeamFlat" then
				task.delay(v:GetAttribute("Delay") or 0, function()
					if v and v.Parent then
						TweenService:Create(
							v,
							TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
							{ Brightness = 0 }
						):Play()
					end
				end)
			elseif v.Name == "BeamChain" then
				TweenService:Create(
					v,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
					{ Brightness = 0 }
				):Play()
			end
		end
	end

	-- Set pentagram color
	local colorKey = tostring(CrucifixSettings.Type or "Guiding"):lower()
	local Color = CrucifixColors[colorKey] or CrucifixColors.guiding

	for _, v in ipairs(GetGiveMeColorDescendants(Repentance)) do
		if v:IsA("Light") or v:IsA("BasePart") then
			v.Color = Color
		elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color),
				ColorSequenceKeypoint.new(1, Color),
			})
		end
	end

	-- Khóa model thực thể bám theo EntityPart của Repentance (giống file gốc)
	local targetEntityRoot = rootModel or entityPart
	local offsetFromEntityPart = CFrame.identity
	if rootModel and EntityPart and EntityPart:IsA("BasePart") then
		pcall(function()
			offsetFromEntityPart = EntityPart.CFrame:ToObjectSpace(rootModel:GetPivot())
		end)
	end

	local lockActive = true
	task.spawn(function()
		if not resist and EntityPart and targetEntityRoot then
			while lockActive and EntityPart.Parent and Repentance.Parent and targetEntityRoot.Parent do
				local targetCF = EntityPart.CFrame
				if rootModel and EntityPart:IsA("BasePart") then
					targetCF = EntityPart.CFrame * offsetFromEntityPart
				end
				PivotModelSafely(targetEntityRoot, targetCF)
				RunService.RenderStepped:Wait()
			end
		end
	end)

	-- Pentagram animation
	if Pentagram and Pentagram:FindFirstChild("Circle") then
		local circle = Pentagram.Circle
		TweenService:Create(
			circle,
			TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) }
		):Play()
		task.delay(2, function()
			if circle and circle.Parent then
				circle:Destroy()
			end
		end)
	end

	-- Crucifix hover
	if Handle then
		local bodyPos = Handle:FindFirstChild("BodyPosition")
		local bodyAngVel = Handle:FindFirstChild("BodyAngularVelocity")
		if bodyPos then
			bodyPos.Position = (charPivot * CFrame.new(1, 4, -6)).Position
		end
		if bodyAngVel then
			TweenService:Create(
				bodyAngVel,
				TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
				{ AngularVelocity = Vector3.new(0, 40, 0) }
			):Play()
		end

		task.delay(3, function()
			local shards = Handle:FindFirstChild("Shards")
			if shards then
				for _, shard in ipairs(shards:GetChildren()) do
					if shard:IsA("BasePart") then
						pcall(function()
							shard.CollisionGroup = "NoPlayer"
						end)
						shard.CanCollide = true
						local weld = shard:FindFirstChild("Weld")
						if weld then
							weld:Destroy()
						end
						shard.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
		end)
	end

	-- Nâng thực thể lên (+2 studs, Elastic.In, 3s) giống file gốc
	local liftTween
	if not resist and EntityPart and EntityPart:IsA("BasePart") then
		liftTween = TweenService:Create(
			EntityPart,
			TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
			{ CFrame = EntityPart.CFrame + Vector3.new(0, 2, 0) }
		)
		liftTween:Play()
	end

	-- Ritual animation
	task.spawn(function()
		waitUntil(2.625)
		if not Repentance.Parent then return end

		local pentLight = Pentagram
			and Pentagram:FindFirstChild("Base")
			and Pentagram.Base:FindFirstChild("LightAttach")
			and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
		local handleLight = Handle and Handle:FindFirstChild("Light")

		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 5, Range = 40 }
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 11.25, Range = 30 }
			):Play()
		end

		task.wait(1.5)
		if not Repentance.Parent then return end

		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0 }
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0 }
			):Play()
		end

		if not resist then
			if handleLight then
				TweenService:Create(
					handleLight,
					TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
					{ Brightness = 15, Range = 40 }
				):Play()
			end

			if theShake then
				pcall(function()
					theShake:StartFadeOut(3)
				end)
			end
			fadeOut()

			local bodyAngVel = Handle and Handle:FindFirstChild("BodyAngularVelocity")
			if bodyAngVel then
				TweenService:Create(
					bodyAngVel,
					TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					{ AngularVelocity = Vector3.zero }
				):Play()
			end
		end
	end)

	-- Crucifix actions (hạ thực thể -50 studs với Back.In trong 3s giống file gốc)
	if not resist then
		waitUntil(2.5)

		local pullTween
		if EntityPart and EntityPart:IsA("BasePart") and Repentance.Parent then
			pullTween = TweenService:Create(
				EntityPart,
				TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ CFrame = EntityPart.CFrame - Vector3.new(0, 50, 0) }
			)
			pullTween:Play()
		end

		local muteTarget = rootModel or entityPart
		if muteTarget then
			for _, snd in ipairs(muteTarget:GetDescendants()) do
				if snd:IsA("Sound") and not snd:GetAttribute("VolumeIgnore") then
					TweenService:Create(
						snd,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ Volume = 0 }
					):Play()
				end
			end
		end

		if pullTween then
			pullTween.Completed:Wait()
		else
			task.wait(3)
		end

		waitUntil(6.75)
	else
		waitUntil(4)

		local bodyAngVel = Handle and Handle:FindFirstChild("BodyAngularVelocity")
		local pentLight = Pentagram
			and Pentagram:FindFirstChild("Base")
			and Pentagram.Base:FindFirstChild("LightAttach")
			and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
		local handleLight = Handle and Handle:FindFirstChild("Light")

		if bodyAngVel then
			TweenService:Create(
				bodyAngVel,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ AngularVelocity = Vector3.zero }
			):Play()
		end
		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) }
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) }
			):Play()
		end

		if theShake then
			pcall(function()
				theShake:StartFadeOut(3)
			end)
		end

		-- Fade pentagram to red
		task.spawn(function()
			local color = Instance.new("Color3Value")
			color.Value = Color3.fromRGB(137, 207, 255)

			local tween = TweenService:Create(
				color,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Value = Color3.fromRGB(255, 116, 130) }
			)
			tween:Play()

			while tween.PlaybackState == Enum.PlaybackState.Playing do
				for _, d in ipairs(Repentance:GetDescendants()) do
					if d.ClassName == "Beam" then
						d.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, color.Value),
							ColorSequenceKeypoint.new(1, color.Value),
						})
					elseif d.Name == "Glow" then
						d.Color = color.Value
					end
				end
				task.wait()
			end
		end)

		waitUntil(9.625)
	end

	-- Crucifix glow explode
	local glow = Handle and Handle:FindFirstChild("Glow")
	local pentLight = Pentagram
		and Pentagram:FindFirstChild("Base")
		and Pentagram.Base:FindFirstChild("LightAttach")
		and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
	local handleLight = Handle and Handle:FindFirstChild("Light")
	local explodeParticle = Handle and Handle:FindFirstChild("ExplodeParticle")

	if glow and glow:IsA("BasePart") then
		TweenService:Create(
			glow,
			TweenInfo.new(1),
			{ Size = glow.Size * 3, Transparency = 1 }
		):Play()
	end
	if pentLight then
		TweenService:Create(
			pentLight,
			TweenInfo.new(1),
			{ Brightness = 0, Range = 0 }
		):Play()
	end
	if handleLight then
		TweenService:Create(
			handleLight,
			TweenInfo.new(1),
			{ Brightness = 0, Range = 0 }
		):Play()
	end

	if not resist then
		if explodeParticle and explodeParticle:IsA("ParticleEmitter") then
			explodeParticle:Emit(math.random(20, 30))
		end
		if mainCamShaker then
			pcall(function()
				mainCamShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5)
			end)
		end

		lockActive = false
		task.wait(0.1)
		if rootModel and rootModel.Parent then
			rootModel:Destroy()
		elseif entityPart and entityPart.Parent then
			entityPart:Destroy()
		end
	else
		pcall(function()
			if rootModel then
				rootModel:SetAttribute("BeingBanished", false)
				rootModel:SetAttribute("Paused", false)
			end
			if entityPart and entityPart:IsA("BasePart") then
				entityPart.Anchored = false
			end
		end)
		fadeOut()
	end

	Debris:AddItem(Repentance, 5)
	if not resist then
		ReleaseReboundLock()
	end
end

-- ====== MOVEMENT & JUMPSCARE LOGIC ======
local function MoveRebound(isFinalRebound)
	if isBanished then
		return false
	end
	isJumpscaring = false

	local s = LoadCustomInstance("rbxassetid://94638439855560", workspace)
	if not s then
		return false
	end

	local val = 60
	local killed = false
	local entity = s:FindFirstChild("Rebound") or s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")

	if not entity then
		s:Destroy()
		return false
	end

	pcall(function()
		local movingSound = Instance.new("Sound")
		movingSound.SoundId = GitAud(
			"https://github.com/Kotyara19k-Doorsspawner/Random-files/raw/main/Y2meta.app%20-%20DOORS%20HARDCORE_REBOUND%20MOVING%20START%20(320%20kbps).mp3",
			"Moving2"
		)
		movingSound.Parent = entity
		movingSound.Volume = 5
		movingSound.Name = "am"
		movingSound:Play()
	end)

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

	local activeTween = nil
	local function StopActiveTween()
		if activeTween then
			pcall(function()
				activeTween:Cancel()
			end)
			activeTween = nil
		end
	end

	local function canSeeTarget(target, size)
		if killed or isJumpscaring or isBanished then
			return false
		end
		local origin = entity.Position
		local hrp = target:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false
		end

		local direction = (hrp.Position - origin).Unit * size
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
		if isBanished or not entity or not entity.Parent then
			if killCheckConnection then
				killCheckConnection:Disconnect()
			end
			return
		end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not char or not hrp then
			return
		end

		local dist = (entity.Position - hrp.Position).Magnitude

		-- Không cho ăn thánh giá khi đang núp, chỉ ăn khi không vướng vật cản & đang cầm thánh giá
		if CrucifixSettings.Enabled
			and not char:GetAttribute("Hiding")
			and dist <= CrucifixSettings.Range
			and not isJumpscaring
			and HasClearCrucifixSight(entity.Position, hrp, char, entity, s)
		then
			local hasTool, tool = HasCrucifixEquipped()
			if hasTool and tool then
				if not CrucifixSettings.Resist then
					killed = true
					isJumpscaring = true
					if killCheckConnection then
						killCheckConnection:Disconnect()
					end
				end
				pcall(function()
					tool:Destroy()
				end)
				task.spawn(function()
					CrucifixEntity(entity, s, StopActiveTween)
				end)
				return
			end
		end

		if not isBanished and not char:GetAttribute("Hiding") then
			if dist <= val then
				camShake:Start()
				camShake:ShakeOnce(17, 6, 0.1, 1)
			end

			if not isJumpscaring and canSeeTarget(char, 50) then
				isJumpscaring = true
				if killCheckConnection then
					killCheckConnection:Disconnect()
				end

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
					while isJumpscaring and not isBanished and ReboundJs.Parent do
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
					TweenService:Create(Static, TweenInfo.new(0.5), { ImageTransparency = 0.8 }):Play()
					TweenService:Create(ReboundImg, TweenInfo.new(0.5), { Size = JSSIZE.Size, Position = JSSIZE.Position }):Play()

					task.wait(0.3)
					if not isBanished then
						local hum = char:FindFirstChildWhichIsA("Humanoid")
						if hum then
							hum.Health = 0
						end

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
					end

					task.wait(0.5)
					TweenService:Create(Static, TweenInfo.new(1), { ImageTransparency = 1 }):Play()
					TweenService:Create(ReboundImg, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
					task.wait(1)
					if ReboundJs and ReboundJs.Parent then
						ReboundJs:Destroy()
					end
				end)
			end
		end
	end)

	local function MoveAlongCFrame(targetCF)
		if isBanished or isJumpscaring or not entity or not entity.Parent then
			return false
		end
		activeTween = TweenService:Create(
			entity,
			TweenInfo.new(speed, Enum.EasingStyle.Sine),
			{ CFrame = targetCF }
		)
		activeTween:Play()
		activeTween.Completed:Wait()
		activeTween = nil
		return not isBanished and not isJumpscaring
	end

	if directionType == "ExitToEntrance" then
		for i = latestRoomVal, 1, -1 do
			if isBanished or isJumpscaring then return false end
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room:FindFirstChild("RoomEntrance") then
					if not MoveAlongCFrame(room.RoomEntrance.CFrame) then
						return false
					end
				end
			end
		end
	else
		for i = 1, latestRoomVal + 1 do
			if isBanished or isJumpscaring then return false end
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room:FindFirstChild("RoomExit") then
					if not MoveAlongCFrame(room.RoomExit.CFrame) then
						return false
					end
				end
			end
		end
	end

	if killCheckConnection then
		killCheckConnection:Disconnect()
	end

	if isBanished or isJumpscaring then
		return false
	end

	if entity and entity:IsA("BasePart") then
		entity.Anchored = false
		entity.CanCollide = false
	end
	Debris:AddItem(s, 2)

	if isFinalRebound then
		completedFullCycleAndDestroyed = true
	end

	return true
end

-- ====== RUN REBOUND SEQUENCE ======
local function RunReboundSequence()
	isBanished = false
	isJumpscaring = false
	completedFullCycleAndDestroyed = false

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
	if not isBanished then
		pcall(MoveRebound, currentMax == 0)
	end

	while currentMax > 0 and not isBanished do
		ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
		if isBanished then
			break
		end
		task.wait(2)
		if isBanished then
			break
		end
		currentMax = currentMax - 1
		pcall(MoveRebound, currentMax == 0)
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
	GiveReboundAchievement()
	ReleaseReboundLock()
end

-- Kích hoạt thực thể Rebound
local okRun, errRun = pcall(RunReboundSequence)
if not okRun then
	ReleaseReboundLock()
	warn("[Rebound] Lỗi thực thi:", errRun)
end
