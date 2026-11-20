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

local VYNIXU_ROOT = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main" --[span_6](start_span)[span_6](end_span)

-- Variables
local maxRebounds = 5
local reboundCount = 0
local isJumpscaring = false
local isBanished = false

local CrucifixSettings = {
	Enabled = true,
	Type = "Guiding", -- "Guiding" hoặc "Curious" --[span_7](start_span)[span_7](end_span)
	Range = 60,
	Resist = false, -- Đổi thành true nếu muốn test chế độ kháng thánh giá giống file gốc --[span_8](start_span)[span_8](end_span)
}

local CrucifixColors = {
	["guiding"] = Color3.fromRGB(137, 207, 255), --[span_9](start_span)[span_9](end_span)
	["curious"] = Color3.fromRGB(255, 227, 137), --[span_10](start_span)[span_10](end_span)
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
	repentanceTemplate = LoadCustomInstance(VYNIXU_ROOT .. "/Assets/Repentance.rbxm", ReplicatedStorage) --[span_11](start_span)[span_11](end_span)
	if repentanceTemplate then
		repentanceTemplate.Parent = nil
	end
	return repentanceTemplate
end

task.spawn(function()
	pcall(GetRepentanceTemplate)
end)

local speed = getgenv().FasterTrouble and 1.4 or 1.8

local function HasCrucifixEquipped()
	local char = LocalPlayer.Character
	if not char then
		return false, nil
	end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local tagged = false
			pcall(function()
				tagged = item:HasTag("Crucifix")
			end)
			if tagged or item.Name:lower():find("crucifix", 1, true) then
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
		list = root:QueryDescendants(".GiveMeColor") --[span_12](start_span)[span_12](end_span)
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

-- ====== FULL CRUCIFIX / REPENTANCE MECHANIC (GIỐNG BẢN GỐC) ======
local function CrucifixEntity(entityPart, rootModel, stopMoveFn)
	local resist = CrucifixSettings.Resist == true --[span_13](start_span)[span_13](end_span)

	if not resist then
		if isBanished then return end
		isBanished = true
		isJumpscaring = true
		if stopMoveFn then
			pcall(stopMoveFn)
		end
	end

	local char = LocalPlayer.Character
	local entityPivot = (entityPart and entityPart:IsA("BasePart") and entityPart.CFrame)
		or (rootModel and rootModel:GetPivot())
		or CFrame.new()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude --[span_14](start_span)[span_14](end_span)
	local exclude = {}
	if char then table.insert(exclude, char) end
	if rootModel then table.insert(exclude, rootModel) end
	if entityPart then table.insert(exclude, entityPart) end
	params.FilterDescendantsInstances = exclude --[span_15](start_span)[span_15](end_span)

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params) --[span_16](start_span)[span_16](end_span)
	if not result then
		result = { Position = entityPivot.Position - Vector3.new(0, 4, 0) }
	end

	pcall(function()
		if rootModel then
			rootModel:SetAttribute("BeingBanished", true) --[span_17](start_span)[span_17](end_span)
			rootModel:SetAttribute("Paused", true) --[span_18](start_span)[span_18](end_span)
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
		local mainGame = require(PlayerGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game")) --[span_19](start_span)[span_19](end_span)
		mainCamShaker = mainGame.camShaker --[span_20](start_span)[span_20](end_span)
		if mainCamShaker then
			theShake = mainCamShaker:StartShake(5, 20, 2, Vector3.zero) --[span_21](start_span)[span_21](end_span)
		end
	end)

	local template = GetRepentanceTemplate()
	if not template then
		if not resist and rootModel and rootModel.Parent then
			rootModel:Destroy()
		end
		return
	end

	local Repentance = template:Clone() --[span_22](start_span)[span_22](end_span)
	local Crucifix = Repentance:FindFirstChild("Crucifix") --[span_23](start_span)[span_23](end_span)
	local Handle = Crucifix and Crucifix:FindFirstChild("Handle") --[span_24](start_span)[span_24](end_span)
	local Pentagram = Repentance:FindFirstChild("Pentagram") --[span_25](start_span)[span_25](end_span)
	local EntityPart = Repentance:FindFirstChild("Entity") --[span_26](start_span)[span_26](end_span)
	local Sound = Handle and Handle:FindFirstChild(resist and "SoundFail" or "Sound") --[span_27](start_span)[span_27](end_span)

	local charPivot = (char and char:GetPivot()) or Camera.CFrame --[span_28](start_span)[span_28](end_span)

	pcall(function()
		Repentance:PivotTo(CFrame.new(result.Position)) --[span_29](start_span)[span_29](end_span)
		if Crucifix then
			Crucifix:PivotTo(charPivot) --[span_30](start_span)[span_30](end_span)
		end
		if EntityPart and EntityPart:IsA("BasePart") then
			EntityPart.Anchored = true
			EntityPart.CanCollide = false
			EntityPart.CFrame = entityPivot --[span_31](start_span)[span_31](end_span)
		end
	end)

	Repentance.Parent = workspace --[span_32](start_span)[span_32](end_span)

	if Sound and Sound:IsA("Sound") then
		pcall(function()
			Sound:Play() --[span_33](start_span)[span_33](end_span)
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
			RunService.RenderStepped:Wait() --[span_34](start_span)[span_34](end_span)
		end
	end

	local function fadeOut()
		if not Pentagram then return end
		for _, v in ipairs(Pentagram:GetChildren()) do --[span_35](start_span)[span_35](end_span)
			if v.Name == "BeamFlat" then --[span_36](start_span)[span_36](end_span)
				task.delay(v:GetAttribute("Delay") or 0, function() --[span_37](start_span)[span_37](end_span)
					if v and v.Parent then
						TweenService:Create(
							v,
							TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_38](start_span)[span_38](end_span)
							{ Brightness = 0 } --[span_39](start_span)[span_39](end_span)
						):Play()
					end
				end)
			elseif v.Name == "BeamChain" then --[span_40](start_span)[span_40](end_span)
				TweenService:Create(
					v,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_41](start_span)[span_41](end_span)
					{ Brightness = 0 } --[span_42](start_span)[span_42](end_span)
				):Play()
			end
		end
	end

	-- Set pentagram color
	local colorKey = tostring(CrucifixSettings.Type or "Guiding"):lower()
	local Color = CrucifixColors[colorKey] or CrucifixColors.guiding --[span_43](start_span)[span_43](end_span)

	for _, v in ipairs(GetGiveMeColorDescendants(Repentance)) do
		if v:IsA("Light") or v:IsA("BasePart") then --[span_44](start_span)[span_44](end_span)
			v.Color = Color --[span_45](start_span)[span_45](end_span)
		elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then --[span_46](start_span)[span_46](end_span)
			v.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color), --[span_47](start_span)[span_47](end_span)
				ColorSequenceKeypoint.new(1, Color), --[span_48](start_span)[span_48](end_span)
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
				RunService.RenderStepped:Wait() --[span_49](start_span)[span_49](end_span)
			end
		end
	end)

	-- Pentagram animation
	if Pentagram and Pentagram:FindFirstChild("Circle") then --[span_50](start_span)[span_50](end_span)
		local circle = Pentagram.Circle
		TweenService:Create(
			circle,
			TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), --[span_51](start_span)[span_51](end_span)
			{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) } --[span_52](start_span)[span_52](end_span)
		):Play()
		task.delay(2, function()
			if circle and circle.Parent then
				circle:Destroy() --[span_53](start_span)[span_53](end_span)
			end
		end)
	end

	-- Crucifix hover
	if Handle then
		local bodyPos = Handle:FindFirstChild("BodyPosition")
		local bodyAngVel = Handle:FindFirstChild("BodyAngularVelocity")
		if bodyPos then
			bodyPos.Position = (charPivot * CFrame.new(1, 4, -6)).Position --[span_54](start_span)[span_54](end_span)
		end
		if bodyAngVel then
			TweenService:Create(
				bodyAngVel,
				TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), --[span_55](start_span)[span_55](end_span)
				{ AngularVelocity = Vector3.new(0, 40, 0) } --[span_56](start_span)[span_56](end_span)
			):Play()
		end

		task.delay(3, function()
			local shards = Handle:FindFirstChild("Shards")
			if shards then
				for _, shard in ipairs(shards:GetChildren()) do --[span_57](start_span)[span_57](end_span)
					if shard:IsA("BasePart") then
						pcall(function()
							shard.CollisionGroup = "NoPlayer" --[span_58](start_span)[span_58](end_span)
						end)
						shard.CanCollide = true --[span_59](start_span)[span_59](end_span)
						local weld = shard:FindFirstChild("Weld")
						if weld then
							weld:Destroy() --[span_60](start_span)[span_60](end_span)
						end
						shard.AssemblyAngularVelocity = Vector3.zero --[span_61](start_span)[span_61](end_span)
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
			TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In), --[span_62](start_span)[span_62](end_span)
			{ CFrame = EntityPart.CFrame + Vector3.new(0, 2, 0) } --[span_63](start_span)[span_63](end_span)
		)
		liftTween:Play()
	end

	-- Ritual animation
	task.spawn(function()
		waitUntil(2.625) --[span_64](start_span)[span_64](end_span)
		if not Repentance.Parent then return end

		local pentLight = Pentagram
			and Pentagram:FindFirstChild("Base")
			and Pentagram.Base:FindFirstChild("LightAttach")
			and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
		local handleLight = Handle and Handle:FindFirstChild("Light")

		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_65](start_span)[span_65](end_span)
				{ Brightness = 5, Range = 40 } --[span_66](start_span)[span_66](end_span)
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_67](start_span)[span_67](end_span)
				{ Brightness = 11.25, Range = 30 } --[span_68](start_span)[span_68](end_span)
			):Play()
		end

		task.wait(1.5) --[span_69](start_span)[span_69](end_span)
		if not Repentance.Parent then return end

		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_70](start_span)[span_70](end_span)
				{ Brightness = 0, Range = 0 } --[span_71](start_span)[span_71](end_span)
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_72](start_span)[span_72](end_span)
				{ Brightness = 0, Range = 0 } --[span_73](start_span)[span_73](end_span)
			):Play()
		end

		if not resist then
			if handleLight then
				TweenService:Create(
					handleLight,
					TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_74](start_span)[span_74](end_span)
					{ Brightness = 15, Range = 40 } --[span_75](start_span)[span_75](end_span)
				):Play()
			end

			if theShake then
				pcall(function()
					theShake:StartFadeOut(3) --[span_76](start_span)[span_76](end_span)
				end)
			end
			fadeOut() --[span_77](start_span)[span_77](end_span)

			local bodyAngVel = Handle and Handle:FindFirstChild("BodyAngularVelocity")
			if bodyAngVel then
				TweenService:Create(
					bodyAngVel,
					TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), --[span_78](start_span)[span_78](end_span)
					{ AngularVelocity = Vector3.zero } --[span_79](start_span)[span_79](end_span)
				):Play()
			end
		end
	end)

	-- Crucifix actions (hạ thực thể -50 studs với Back.In trong 3s giống file gốc)
	if not resist then
		waitUntil(2.5) --[span_80](start_span)[span_80](end_span)

		local pullTween
		if EntityPart and EntityPart:IsA("BasePart") and Repentance.Parent then
			pullTween = TweenService:Create(
				EntityPart,
				TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_81](start_span)[span_81](end_span)
				{ CFrame = EntityPart.CFrame - Vector3.new(0, 50, 0) } --[span_82](start_span)[span_82](end_span)
			)
			pullTween:Play()
		end

		local muteTarget = rootModel or entityPart
		if muteTarget then
			for _, snd in ipairs(muteTarget:GetDescendants()) do --[span_83](start_span)[span_83](end_span)
				if snd:IsA("Sound") and not snd:GetAttribute("VolumeIgnore") then --[span_84](start_span)[span_84](end_span)
					TweenService:Create(
						snd,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_85](start_span)[span_85](end_span)
						{ Volume = 0 } --[span_86](start_span)[span_86](end_span)
					):Play()
				end
			end
		end

		if pullTween then
			pullTween.Completed:Wait()
		else
			task.wait(3)
		end

		waitUntil(6.75) --[span_87](start_span)[span_87](end_span)
	else
		waitUntil(4) --[span_88](start_span)[span_88](end_span)

		local bodyAngVel = Handle and Handle:FindFirstChild("BodyAngularVelocity")
		local pentLight = Pentagram
			and Pentagram:FindFirstChild("Base")
			and Pentagram.Base:FindFirstChild("LightAttach")
			and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
		local handleLight = Handle and Handle:FindFirstChild("Light")

		if bodyAngVel then
			TweenService:Create(
				bodyAngVel,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), --[span_89](start_span)[span_89](end_span)
				{ AngularVelocity = Vector3.zero } --[span_90](start_span)[span_90](end_span)
			):Play()
		end
		if pentLight then
			TweenService:Create(
				pentLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_91](start_span)[span_91](end_span)
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) } --[span_92](start_span)[span_92](end_span)
			):Play()
		end
		if handleLight then
			TweenService:Create(
				handleLight,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_93](start_span)[span_93](end_span)
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) } --[span_94](start_span)[span_94](end_span)
			):Play()
		end

		if theShake then
			pcall(function()
				theShake:StartFadeOut(3) --[span_95](start_span)[span_95](end_span)
			end)
		end

		-- Fade pentagram to red
		task.spawn(function()
			local color = Instance.new("Color3Value") --[span_96](start_span)[span_96](end_span)
			color.Value = Color3.fromRGB(137, 207, 255) --[span_97](start_span)[span_97](end_span)

			local tween = TweenService:Create(
				color,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine), --[span_98](start_span)[span_98](end_span)
				{ Value = Color3.fromRGB(255, 116, 130) } --[span_99](start_span)[span_99](end_span)
			)
			tween:Play() --[span_100](start_span)[span_100](end_span)

			while tween.PlaybackState == Enum.PlaybackState.Playing do --[span_101](start_span)[span_101](end_span)
				for _, d in ipairs(Repentance:GetDescendants()) do --[span_102](start_span)[span_102](end_span)
					if d.ClassName == "Beam" then --[span_103](start_span)[span_103](end_span)
						d.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, color.Value), --[span_104](start_span)[span_104](end_span)
							ColorSequenceKeypoint.new(1, color.Value), --[span_105](start_span)[span_105](end_span)
						})
					elseif d.Name == "Glow" then --[span_106](start_span)[span_106](end_span)
						d.Color = color.Value --[span_107](start_span)[span_107](end_span)
					end
				end
				task.wait() --[span_108](start_span)[span_108](end_span)
			end
		end)

		waitUntil(9.625) --[span_109](start_span)[span_109](end_span)
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
			TweenInfo.new(1), --[span_110](start_span)[span_110](end_span)
			{ Size = glow.Size * 3, Transparency = 1 } --[span_111](start_span)[span_111](end_span)
		):Play()
	end
	if pentLight then
		TweenService:Create(
			pentLight,
			TweenInfo.new(1), --[span_112](start_span)[span_112](end_span)
			{ Brightness = 0, Range = 0 } --[span_113](start_span)[span_113](end_span)
		):Play()
	end
	if handleLight then
		TweenService:Create(
			handleLight,
			TweenInfo.new(1), --[span_114](start_span)[span_114](end_span)
			{ Brightness = 0, Range = 0 } --[span_115](start_span)[span_115](end_span)
		):Play()
	end

	if not resist then
		if explodeParticle and explodeParticle:IsA("ParticleEmitter") then
			explodeParticle:Emit(math.random(20, 30)) --[span_116](start_span)[span_116](end_span)
		end
		if mainCamShaker then
			pcall(function()
				mainCamShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5) --[span_117](start_span)[span_117](end_span)
			end)
		end

		lockActive = false
		task.wait(0.1)
		if rootModel and rootModel.Parent then
			rootModel:Destroy() --[span_118](start_span)[span_118](end_span)
		elseif entityPart and entityPart.Parent then
			entityPart:Destroy()
		end
	else
		pcall(function()
			if rootModel then
				rootModel:SetAttribute("BeingBanished", false) --[span_119](start_span)[span_119](end_span)
				rootModel:SetAttribute("Paused", false) --[span_120](start_span)[span_120](end_span)
			end
			if entityPart and entityPart:IsA("BasePart") then
				entityPart.Anchored = false
			end
		end)
		fadeOut() --[span_121](start_span)[span_121](end_span)
	end

	Debris:AddItem(Repentance, 5) --[span_122](start_span)[span_122](end_span)
end

-- ====== MOVEMENT & JUMPSCARE LOGIC ======
local function MoveRebound()
	if isBanished then
		return
	end
	isJumpscaring = false

	local s = LoadCustomInstance("rbxassetid://94638439855560", workspace)
	if not s then
		return
	end

	local val = 60
	local killed = false
	local entity = s:FindFirstChild("Rebound") or s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")

	if not entity then
		s:Destroy()
		return
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
		if isBanished or not entity or not entity.Parent then
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
		return not isBanished
	end

	if directionType == "ExitToEntrance" then
		for i = latestRoomVal, 1, -1 do
			if isBanished then break end
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room:FindFirstChild("RoomEntrance") then
					if not MoveAlongCFrame(room.RoomEntrance.CFrame) then
						break
					end
				end
			end
		end
	else
		for i = 1, latestRoomVal + 1 do
			if isBanished then break end
			if gruh:FindFirstChild(i) then
				local room = gruh[i]
				if room:FindFirstChild("RoomExit") then
					if not MoveAlongCFrame(room.RoomExit.CFrame) then
						break
					end
				end
			end
		end
	end

	if killCheckConnection then
		killCheckConnection:Disconnect()
	end

	if isBanished then
		return
	end

	if entity and entity:IsA("BasePart") then
		entity.Anchored = false
		entity.CanCollide = false
	end
	Debris:AddItem(s, 2)
end

-- ====== RUN REBOUND SEQUENCE ======
local function RunReboundSequence()
	isBanished = false
	isJumpscaring = false

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
		pcall(MoveRebound)
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
