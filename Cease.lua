getgenv().OgHungerNewSpawner = nil

local success, Spawner = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/eoyoustme/Mayhem-Remake/refs/heads/main/OgHungerNewSpawner"))()
end)

if not success or not Spawner then
	warn("[Spawner Error] Không thể tải OgHungerNewSpawner!")
	return
end

local speed
if getgenv().FasterTrouble then
	speed = 100
else
	speed = 50
end

local entity = Spawner:Create({
	Entity = {
		Name = "Cease",
		Asset = "https://github.com/reboundplayz/Doors-Fixed-Modes/raw/refs/heads/main/ceasebro.rbxm",
		HeightOffset = -1.5
	},
	Lights = {
		Flicker = {
			Enabled = false,
			Duration = 1
		},
		Shatter = false,
		Repair = false
	},
	Earthquake = {
		Enabled = false
	},
	Spawned = {
		ChangeColorWhenSpawn = false,
		Rainbow = false,
		Color = Color3.fromRGB(0, 85, 255)
	},
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {1.5, 40, 0.1, 0.1}
	},
	Movement = {
		Speed = speed,
		SpeedFast = 100,
		MoveFastNotEnter = false,
		IsMoveWhenWHere = false,
		Delay = 2,
		Reversed = false,
		EndWhenEnterLatestRoom = false,
		EndDelay = 0,

		ReboundMoving = false,
		TweenSecond = 1.5,

		ReboundMoveStyle = false,
		ReboundStyleTimes = 5,
		ReboundStyleSound = "rbxassetid://9114221327",
		ReboundStyleVolume = 5,
		ReboundStyleDelay = 2,
		IsMoveBackWardAndMore = false,

		FasterAndFaster = false,
		ChasePlayerWhenSee = false, -- Bật cơ chế check/rượt đuổi có sẵn của Spawner
		SpeedWhenChase = 35,

		GlitchMove = false,
		GlitchMoveSoundId = "rbxassetid://0",

		Fakeout = {
			Enabled = false,
			RandomFakeout = false,
			EndSound = "rbxassetid://0",
			EndDelay = 2,
			SpeedMultiplier = 1
		}
	},
	Jumpscare = {
		Enabled = false
	},
	Rebounding = {
		Enabled = false,
		Type = "Ambush",
		Min = 1,
		Max = 1,
		Delay = 2
	},
	Damage = {
		Enabled = true,        -- Bật hệ thống sát thương của Spawner
		KillOnMove = true,     -- Bật cơ chế di chuyển mới bị giết của Spawner
		Range = 40,
		Amount = 125,
		Cooldown = 1,
		IgnoreHiding = false
	},
	Crucifixion = {
		Type = "Guiding",
		Enabled = true,
		Range = 40,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"You just died to Cease...", "It sees through movement and can see anyone through a wardrobe.", "Maybe don't hide?", "I hope to see you here again."},
		Cause = "Cease"
	}
})

if not entity then
	warn("[Spawner Error] Không thể tạo entity Cease!")
	return
end

---====== CUSTOM SYSTEM & VARIABLES ======---

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local lavenderColor = Color3.new(0.454902, 0.529412, 1)
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setupModelCollisionListener(model)
	if not model then return end
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
		end
	end
end

local function changeLightColors()
	local currentRoom = workspace:FindFirstChild("CurrentRooms")
	if currentRoom then
		for _, room in ipairs(currentRoom:GetChildren()) do
			for _, desc in ipairs(room:GetDescendants()) do
				if desc:IsA("Light") then
					TweenService:Create(desc, tweenInfo, {Color = lavenderColor}):Play()
				elseif desc:IsA("BasePart") and (desc.Name == "Light" or desc.Name == "Neon" or desc.Name == "Bulb") then
					TweenService:Create(desc, tweenInfo, {Color = lavenderColor}):Play()
				end
			end
		end
	end
end

local repentanceTemplate = nil
local function GetRepentanceTemplate()
	if repentanceTemplate and repentanceTemplate.Parent then
		return repentanceTemplate
	end
	pcall(function()
		if type(LoadCustomInstance) == "function" then
			repentanceTemplate = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm") --[span_2](start_span)[span_2](end_span)
		else
			repentanceTemplate = game:GetObjects("rbxassetid://12543866876")[1]
		end
	end)
	if repentanceTemplate then
		repentanceTemplate.Parent = nil
	end
	return repentanceTemplate
end

task.spawn(function()
	pcall(GetRepentanceTemplate)
end)

local function GetGiveMeColorList(rootObj)
	local list = {}
	local ok = pcall(function()
		list = rootObj:QueryDescendants(".GiveMeColor") --[span_3](start_span)[span_3](end_span)
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

---====== CLEAN CALLBACKS ======---

entity:SetCallback("CrucifixionOverwrite", function()
	local model = entity.Model
	if not model or not model.Parent then return end
	if model:GetAttribute("BeingBanished") then return end --[span_4](start_span)[span_4](end_span)

	model:SetAttribute("BeingBanished", true) --[span_5](start_span)[span_5](end_span)
	model:SetAttribute("Paused", true) --[span_6](start_span)[span_6](end_span)
	model:SetAttribute("Damage", false) --[span_7](start_span)[span_7](end_span)

	local character = LocalPlayer.Character
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local camera = workspace.CurrentCamera

	-- Xóa thánh giá đang cầm trên tay người chơi
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") and (item.Name:lower():find("crucifix", 1, true) or item.Name:lower():find("cruxy", 1, true)) then
				pcall(function() item:Destroy() end)
			end
		end
	end
	
	local entityModel = workspace:FindFirstChild("Cease")
    if entityModel then 
	
	local repentSound = entityModel:FindFirstChild("Repent", true)
        if repentSound and repentSound:IsA("Sound") then
            repentSound:Play()
        end
    end

	local entityPivot = model:GetPivot() --[span_8](start_span)[span_8](end_span)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude --[span_9](start_span)[span_9](end_span)
	params.FilterDescendantsInstances = {character, model} --[span_10](start_span)[span_10](end_span)

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params) --[span_11](start_span)[span_11](end_span)
	if not result then
		result = { Position = entityPivot.Position - Vector3.new(0, 4, 0) }
	end

	local camShaker
	local theShake
	pcall(function()
		local mainGameMod = playerGui
			and playerGui:FindFirstChild("MainUI")
			and playerGui.MainUI:FindFirstChild("Initiator")
			and playerGui.MainUI.Initiator:FindFirstChild("Main_Game")
		if mainGameMod then
			local mainGame = require(mainGameMod)
			camShaker = mainGame and mainGame.camShaker --[span_12](start_span)[span_12](end_span)
			if camShaker then
				theShake = camShaker:StartShake(5, 20, 2, Vector3.zero) --[span_13](start_span)[span_13](end_span)
			end
		end
	end)

	local template = GetRepentanceTemplate()
	if not template then
		if model and model.Parent then
			model:Destroy()
		end
		return
	end

	local Repentance = template:Clone() --[span_14](start_span)[span_14](end_span)
	local Crucifix = Repentance:FindFirstChild("Crucifix") --[span_15](start_span)[span_15](end_span)
	local Handle = Crucifix and Crucifix:FindFirstChild("Handle") --[span_16](start_span)[span_16](end_span)
	local Pentagram = Repentance:FindFirstChild("Pentagram") --[span_17](start_span)[span_17](end_span)
	local EntityPart = Repentance:FindFirstChild("Entity") --[span_18](start_span)[span_18](end_span)
	local Sound = Handle and Handle:FindFirstChild("Sound") --[span_19](start_span)[span_19](end_span)

	local charPivot = (character and character:GetPivot()) or (camera and camera.CFrame) or CFrame.new()

	pcall(function()
		Repentance:PivotTo(CFrame.new(result.Position)) --[span_20](start_span)[span_20](end_span)
		if Crucifix then
			Crucifix:PivotTo(charPivot) --[span_21](start_span)[span_21](end_span)
		end
		if EntityPart and EntityPart:IsA("BasePart") then
			EntityPart.Anchored = true
			EntityPart.CanCollide = false
			EntityPart.CFrame = entityPivot --[span_22](start_span)[span_22](end_span)
		end
	end)

	Repentance.Parent = workspace --[span_23](start_span)[span_23](end_span)
	if Sound and Sound:IsA("Sound") then
		pcall(function() Sound:Play() end) --[span_24](start_span)[span_24](end_span)
	end

	local startClock = os.clock()
	local function waitUntil(t: number)
		while Repentance.Parent do
			local elapsed = os.clock() - startClock
			if Sound and Sound:IsA("Sound") and Sound.TimeLength > 0 and Sound.IsPlaying then
				if Sound.TimePosition >= t or elapsed >= (t + 2) then
					break
				end
			elseif elapsed >= t then
				break
			end
			RunService.RenderStepped:Wait() --[span_25](start_span)[span_25](end_span)
		end
	end

	local function fadeOut()
		if not Pentagram then return end
		for _, v in ipairs(Pentagram:GetChildren()) do --[span_26](start_span)[span_26](end_span)
			if v.Name == "BeamFlat" then --[span_27](start_span)[span_27](end_span)
				task.delay(v:GetAttribute("Delay") or 0, function() --[span_28](start_span)[span_28](end_span)
					if v and v.Parent then
						pcall(function()
							TweenService:Create(
								v,
								TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_29](start_span)[span_29](end_span)
								{ Brightness = 0 } --[span_30](start_span)[span_30](end_span)
							):Play()
						end)
					end
				end)
			elseif v.Name == "BeamChain" then --[span_31](start_span)[span_31](end_span)
				pcall(function()
					TweenService:Create(
						v,
						TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_32](start_span)[span_32](end_span)
						{ Brightness = 0 } --[span_33](start_span)[span_33](end_span)
					):Play()
				end)
			end
		end
	end

	local isCurious = tostring(entity.Config.Crucifixion.Type or "Guiding"):lower() == "curious" --[span_34](start_span)[span_34](end_span)
	local Color = isCurious and Color3.fromRGB(255, 227, 137) or Color3.fromRGB(137, 207, 255) --[span_35](start_span)[span_35](end_span)

	for _, v in ipairs(GetGiveMeColorList(Repentance)) do
		pcall(function()
			if v:IsA("Light") or v:IsA("BasePart") then --[span_36](start_span)[span_36](end_span)
				v.Color = Color --[span_37](start_span)[span_37](end_span)
			elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then --[span_38](start_span)[span_38](end_span)
				v.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color), --[span_39](start_span)[span_39](end_span)
					ColorSequenceKeypoint.new(1, Color), --[span_40](start_span)[span_40](end_span)
				})
			end
		end)
	end

	-- Khóa model Cease bám theo EntityPart của Repentance
	task.spawn(function()
		while EntityPart and EntityPart.Parent and Repentance.Parent and model and model.Parent do
			pcall(function()
				model:PivotTo(EntityPart.CFrame) --[span_41](start_span)[span_41](end_span)
			end)
			RunService.RenderStepped:Wait() --[span_42](start_span)[span_42](end_span)
		end
		if model and model.Parent then
			model:Destroy() --[span_43](start_span)[span_43](end_span)
		end
	end)

	-- Vòng phép thụt xuống đất
	local circle = Pentagram and Pentagram:FindFirstChild("Circle")
	if circle then
		pcall(function()
			TweenService:Create(
				circle,
				TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), --[span_44](start_span)[span_44](end_span)
				{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) } --[span_45](start_span)[span_45](end_span)
			):Play()
		end)
		task.delay(2, function()
			if circle and circle.Parent then
				circle:Destroy() --[span_46](start_span)[span_46](end_span)
			end
		end)
	end

	-- Thánh giá lơ lửng, xoay và tách mảnh Shards
	if Handle then
		pcall(function()
			local bp = Handle:FindFirstChild("BodyPosition")
			if bp then
				bp.Position = (charPivot * CFrame.new(1, 4, -6)).Position --[span_47](start_span)[span_47](end_span)
			end
			local bav = Handle:FindFirstChild("BodyAngularVelocity")
			if bav then
				TweenService:Create(
					bav,
					TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), --[span_48](start_span)[span_48](end_span)
					{ AngularVelocity = Vector3.new(0, 40, 0) } --[span_49](start_span)[span_49](end_span)
				):Play()
			end
		end)

		task.delay(3, function()
			local shards = Handle:FindFirstChild("Shards")
			if shards then
				for _, shard in ipairs(shards:GetChildren()) do --[span_50](start_span)[span_50](end_span)
					if shard:IsA("BasePart") then
						pcall(function()
							shard.CollisionGroup = "NoPlayer" --[span_51](start_span)[span_51](end_span)
							shard.CanCollide = true --[span_52](start_span)[span_52](end_span)
							local weld = shard:FindFirstChild("Weld")
							if weld then weld:Destroy() end --[span_53](start_span)[span_53](end_span)
							shard.AssemblyAngularVelocity = Vector3.zero --[span_54](start_span)[span_54](end_span)
						end)
					end
				end
			end
		end)
	end

	-- Nâng thực thể lên
	if EntityPart and EntityPart:IsA("BasePart") then
		pcall(function()
			TweenService:Create(
				EntityPart,
				TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In), --[span_55](start_span)[span_55](end_span)
				{ CFrame = EntityPart.CFrame + Vector3.new(0, 2, 0) } --[span_56](start_span)[span_56](end_span)
			):Play()
		end)
	end

	local pentBright = Pentagram
		and Pentagram:FindFirstChild("Base")
		and Pentagram.Base:FindFirstChild("LightAttach")
		and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
	local handleLight = Handle and Handle:FindFirstChild("Light")

	task.spawn(function()
		waitUntil(2.625) --[span_57](start_span)[span_57](end_span)
		if not Repentance.Parent then return end

		if pentBright then
			pcall(function()
				TweenService:Create(
					pentBright,
					TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_58](start_span)[span_58](end_span)
					{ Brightness = 5, Range = 40 } --[span_59](start_span)[span_59](end_span)
				):Play()
			end)
		end
		if handleLight then
			pcall(function()
				TweenService:Create(
					handleLight,
					TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_60](start_span)[span_60](end_span)
					{ Brightness = 11.25, Range = 30 } --[span_61](start_span)[span_61](end_span)
				):Play()
			end)
		end

		task.wait(1.5) --[span_62](start_span)[span_62](end_span)
		if not Repentance.Parent then return end

		if pentBright then
			pcall(function()
				TweenService:Create(
					pentBright,
					TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_63](start_span)[span_63](end_span)
					{ Brightness = 0, Range = 0 } --[span_64](start_span)[span_64](end_span)
				):Play()
			end)
		end
		if handleLight then
			pcall(function()
				TweenService:Create(
					handleLight,
					TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_65](start_span)[span_65](end_span)
					{ Brightness = 0, Range = 0 } --[span_66](start_span)[span_66](end_span)
				):Play()
			end)
		end

		if handleLight then
			pcall(function()
				TweenService:Create(
					handleLight,
					TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_67](start_span)[span_67](end_span)
					{ Brightness = 15, Range = 40 } --[span_68](start_span)[span_68](end_span)
				):Play()
			end)
		end

		if theShake then
			pcall(function() theShake:StartFadeOut(3) end) --[span_69](start_span)[span_69](end_span)
		end
		fadeOut() --[span_70](start_span)[span_70](end_span)

		local bav = Handle and Handle:FindFirstChild("BodyAngularVelocity")
		if bav then
			pcall(function()
				TweenService:Create(
					bav,
					TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), --[span_71](start_span)[span_71](end_span)
					{ AngularVelocity = Vector3.zero } --[span_72](start_span)[span_72](end_span)
				):Play()
			end)
		end
	end)

	-- Kéo thực thể xuống & tắt dần âm thanh
	waitUntil(2.5) --[span_73](start_span)[span_73](end_span)
	if EntityPart and EntityPart:IsA("BasePart") and Repentance.Parent then
		pcall(function()
			TweenService:Create(
				EntityPart,
				TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_74](start_span)[span_74](end_span)
				{ CFrame = EntityPart.CFrame - Vector3.new(0, 50, 0) } --[span_75](start_span)[span_75](end_span)
			):Play()
		end)
	end

	if model and model.Parent then
		for _, s in ipairs(model:GetDescendants()) do --[span_76](start_span)[span_76](end_span)
			if s:IsA("Sound") and not s:GetAttribute("VolumeIgnore") then --[span_77](start_span)[span_77](end_span)
				pcall(function()
					TweenService:Create(
						s,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_78](start_span)[span_78](end_span)
						{ Volume = 0 } --[span_79](start_span)[span_79](end_span)
					):Play()
				end)
			end
		end
	end

	waitUntil(6.75) --[span_80](start_span)[span_80](end_span)

	-- Bùng sáng & nổ hạt kết thúc
	local glow = Handle and Handle:FindFirstChild("Glow")
	if glow and glow:IsA("BasePart") then
		pcall(function()
			TweenService:Create(
				glow,
				TweenInfo.new(1), --[span_81](start_span)[span_81](end_span)
				{ Size = glow.Size * 3, Transparency = 1 } --[span_82](start_span)[span_82](end_span)
			):Play()
		end)
	end
	if pentBright then
		pcall(function()
			TweenService:Create(
				pentBright,
				TweenInfo.new(1), --[span_83](start_span)[span_83](end_span)
				{ Brightness = 0, Range = 0 } --[span_84](start_span)[span_84](end_span)
			):Play()
		end)
	end
	if handleLight then
		pcall(function()
			TweenService:Create(
				handleLight,
				TweenInfo.new(1), --[span_85](start_span)[span_85](end_span)
				{ Brightness = 0, Range = 0 } --[span_86](start_span)[span_86](end_span)
			):Play()
		end)
	end

	local explodeParticle = Handle and Handle:FindFirstChild("ExplodeParticle")
	if explodeParticle and explodeParticle:IsA("ParticleEmitter") then
		pcall(function() explodeParticle:Emit(math.random(20, 30)) end) --[span_87](start_span)[span_87](end_span)
	end
	if camShaker then
		pcall(function() camShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5) end) --[span_88](start_span)[span_88](end_span)
	end

	if model and model.Parent then
		model:Destroy() --[span_89](start_span)[span_89](end_span)
	end
	Debris:AddItem(Repentance, 5) --[span_90](start_span)[span_90](end_span)
end)

entity:SetCallback("OnSpawned", function()
		changeLightColors()

	task.spawn(function()
		local entityModel = workspace:WaitForChild("Cease", 5)
		if entityModel then
			setupModelCollisionListener(entityModel)
		end
	end)
end)

entity:SetCallback("OnStartMoving", function()
	local entityModel = workspace:FindFirstChild("Cease")
	if entityModel then
		setupModelCollisionListener(entityModel)
	end
end)

entity:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
	changeLightColors()

	local entityModel = workspace:FindFirstChild("Cease")
	if entityModel then
		setupModelCollisionListener(entityModel)
	end

	-- ====== CEASE FREEZE EFFECT ======
	task.spawn(function()
		local originalStates = {}
		local disabledInteractions = {}
		local frostColor = Color3.fromRGB(155, 215, 255)
		local meltTime = 10
		local meltTweenInfo = TweenInfo.new(meltTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		for _, desc in ipairs(room:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name ~= "Light" and desc.Name ~= "Neon" and desc.Name ~= "Bulb" then
				originalStates[desc] = {
					Color = desc.Color,
					Material = desc.Material
				}
				desc.Color = frostColor
				desc.Material = Enum.Material.Ice
			elseif desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector") then
				if desc.Enabled == true then
					disabledInteractions[desc] = true
					desc.Enabled = false
				end
			end
		end

		for part, original in pairs(originalStates) do
			if part and part.Parent then
				TweenService:Create(part, meltTweenInfo, {Color = original.Color}):Play()
			end
		end

		task.wait(meltTime)

		for part, original in pairs(originalStates) do
			if part and part.Parent then
				part.Material = original.Material
			end
		end

		for interaction, _ in pairs(disabledInteractions) do
			if interaction and interaction.Parent then
				interaction.Enabled = true
			end
		end
	end)
end)

entity:SetCallback("OnDespawning", function()
	pcall(function()
		local currentRooms = workspace:FindFirstChild("CurrentRooms")
		local latestRoomVal = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom").Value
		if currentRooms then
			local latestRoom = currentRooms:FindFirstChild(tostring(latestRoomVal))
			if latestRoom and latestRoom:FindFirstChild("Door") then
				local clientOpen = latestRoom.Door:FindFirstChild("ClientOpen")
				if clientOpen then
					if clientOpen:IsA("RemoteEvent") then
						clientOpen:FireServer()
					elseif clientOpen:IsA("RemoteFunction") then
						clientOpen:InvokeServer()
					end
				end
			end
		end
	end)
end)

---====== Run Entity ======---

entity:Run(true)
