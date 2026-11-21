-- ========================================================
--     MULTIMONSTER SCRIPT (LET PLAYING SOUNDS FINISH)
-- ========================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

if not LoadCustomInstance then
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))()
	end)
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentRooms = Workspace:WaitForChild("CurrentRooms")

local debounce = false
local isJumpscaring = false
local isCrucifixed = false
local destroyedsounds = false
local activeBreakingSound = nil
local activeSpawnedModel = nil

local speed
if getgenv().FasterTrouble then
	speed = 400
else
	speed = math.random(267, 350)
end

-- Khai báo biến âm thanh cửa an toàn
local doorSound1 = Instance.new("Sound")
doorSound1.SoundId = "rbxassetid://9126281820"
doorSound1.Volume = 3
doorSound1.Parent = SoundService

local doorSound2 = Instance.new("Sound")
doorSound2.SoundId = "rbxassetid://9126281769"
doorSound2.Volume = 3
doorSound2.Parent = SoundService

-- Biến lưu trữ hướng di chuyển của thực thể (tính theo frame)
local entityLastPosition = nil
local entityMoveDirection = Vector3.new(0, 0, -1)

-- DANH SÁCH ẢNH JUMPSCARE 2D
local ALL_JUMPSCARE_IMAGES = {
	"rbxassetid://114943702871183",
	"rbxassetid://77042919484581",
	"rbxassetid://113785746563976",
	"rbxassetid://106324997569765",
	"rbxassetid://93365716697080",
	"rbxassetid://72735059720396",
}

-- ========================================================
--                  HELPER FUNCTIONS                      --
-- ========================================================
local function GetGitSound(GithubSnd, SoundName)
	local sound = Instance.new("Sound")

	local success = pcall(function()
		if writefile and isfile and not isfile(SoundName .. ".mp3") then
			writefile(SoundName .. ".mp3", game:HttpGet(GithubSnd))
		end
	end)

	local assetFunc = getcustomasset or getsynasset
	if success and assetFunc then
		local assetSuccess, assetResult = pcall(function()
			return assetFunc(SoundName .. ".mp3")
		end)
		if assetSuccess and assetResult then
			sound.SoundId = assetResult
			return sound
		end
	end

	sound.SoundId = GithubSnd
	return sound
end

local function AttachFinishCleanup(soundObj: Sound)
	if not soundObj then return end
	if soundObj.IsPlaying then
		soundObj.Ended:Once(function()
			if soundObj and soundObj.Parent then
				pcall(function()
					soundObj:Destroy()
				end)
			end
		end)
	else
		pcall(function()
			soundObj:Destroy()
		end)
	end
end

local function LetPlayingSoundsFinish(targetModel)
	if activeBreakingSound and activeBreakingSound.Parent then
		pcall(function()
			activeBreakingSound.Looped = false
		end)
		AttachFinishCleanup(activeBreakingSound)
		activeBreakingSound = nil
	end

	for _, s in ipairs({ doorSound1, doorSound2 }) do
		if s and s.Parent then
			pcall(function()
				s.Looped = false
			end)
			if not s.IsPlaying then
				pcall(function()
					s.TimePosition = 0
				end)
			end
		end
	end

	if targetModel then
		for _, desc in ipairs(targetModel:GetDescendants()) do
			if desc:IsA("Sound") and not desc:GetAttribute("VolumeIgnore") then
				pcall(function()
					desc.Looped = false
					if desc.IsPlaying then
						desc.Ended:Once(function()
							if desc and desc.Parent then
								desc:Destroy()
							end
						end)
					else
						desc:Destroy()
					end
				end)
			end
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Sound") and obj.Parent and obj.Parent:IsDescendantOf(CurrentRooms) then
			pcall(function()
				obj.Looped = false
				if obj.IsPlaying then
					obj.Ended:Once(function()
						if obj and obj.Parent then
							obj:Destroy()
						end
					end)
				else
					obj:Destroy()
				end
			end)
		end
	end
end

-- ========================================================
-- ADVANCED DIRECTIONAL PUSHABLE ROOM BREAK               --
-- ========================================================
local TARGET_MASS = 0

local blacklist = {
	"wardrobe", "rafter", "bed", "rug", "carpet", "sideroom", "key",
	"drawer", "breaker", "table", "desk", "gold", "dresser", "rift",
	"chest", "floor", "wall", "door", "ceiling", "light", "beam",
	"model", "chandelier", "window", "curtain", "gate", "stairs",
	"vent", "lattice", "barrelstack", "smoothie", "rolltop", "dupe",
	"boards", "crucifix", "flashlight", "moonfloat", "lockpick",
	"candle", "skeleton key", "fireplace",
}

local function hasAncestorContaining(object, text)
	local parent = object.Parent
	while parent do
		if parent:IsA("Model") then
			if string.find(string.lower(parent.Name), text, 1, true) then
				return true
			end
		end
		if parent == CurrentRooms then break end
		parent = parent.Parent
	end
	return false
end

local function isBlacklisted(object)
	local name = string.lower(object.Name)
	if object:IsA("BasePart") then
		if string.find(name, "book", 1, true) then return not hasAncestorContaining(object, "book") end
		if string.find(name, "light", 1, true) then return not hasAncestorContaining(object, "book") end
		if string.find(name, "wall", 1, true) then return not hasAncestorContaining(object, "pillar") end
		if string.find(name, "board", 1, true) then return not hasAncestorContaining(object, "wooden") end
	end
	for _, blacklistName in ipairs(blacklist) do
		if string.find(name, blacklistName, 1, true) then return true end
	end
	return false
end

local function isInside(instance, model)
	return instance == model or instance:IsDescendantOf(model)
end

local function hasTargetParent(model, room)
	local parent = model.Parent
	while parent and parent ~= room do
		if parent:IsA("Model") and not isBlacklisted(parent) then return true end
		parent = parent.Parent
	end
	return false
end

local function shakeCollision(collision)
	if isCrucifixed or not collision or collision.Anchored then return end
	local mass = collision.AssemblyMass
	local force = mass * 5
	for _ = 1, 8 do
		if isCrucifixed or not collision.Parent or collision.Anchored then break end
		local look = Vector3.new(entityMoveDirection.X, 0, entityMoveDirection.Z)
		if look.Magnitude > 0 then
			look = look.Unit
			local angle = math.rad(math.random(-60, 60))
			local direction = CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(look)
			direction = Vector3.new(direction.X, 0, direction.Z).Unit
			collision:ApplyImpulse(direction * force)
			collision:ApplyAngularImpulse(Vector3.new(
				math.random(-1, 1),
				math.random(-1, 1),
				math.random(-1, 1)
			) * mass * 15)
		end
		task.wait(0.03)
	end
end

local function setupModel(model, room, targets)
	if isCrucifixed or not model:IsA("Model") or isBlacklisted(model) or hasTargetParent(model, room) then return end

	local existingCollision
	local hasScriptCollision = false
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "Collision" and v:GetAttribute("WindCollision") == true then
			hasScriptCollision = true
			if v:GetAttribute("Picked") ~= true then
				existingCollision = v
				break
			end
		end
	end

	if existingCollision then
		table.insert(targets, existingCollision)
		return
	end
	if hasScriptCollision then return end

	local parts = {}
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "Collision" and not isBlacklisted(v) then
			table.insert(parts, v)
		end
	end

	if #parts == 0 then return end

	local cf, size = model:GetBoundingBox()
	local volume = size.X * size.Y * size.Z
	if volume <= 0 then return end

	local density = math.clamp(TARGET_MASS / volume, 0.0001, 100)

	local collision = Instance.new("Part")
	collision.Name = "Collision"
	collision.Size = size
	collision.CFrame = cf
	collision.Transparency = 1
	collision.CanCollide = true
	collision.CanTouch = true
	collision.CanQuery = true
	collision.CastShadow = false
	collision.Anchored = true
	collision.Massless = false

	collision.CustomPhysicalProperties = PhysicalProperties.new(density, 0.3, 0.5, 1, 1)
	collision:SetAttribute("WindCollision", true)
	collision:SetAttribute("Picked", false)
	collision.Parent = model

	table.insert(targets, collision)

	collision:GetPropertyChangedSignal("Anchored"):Connect(function()
		if not isCrucifixed and not collision.Anchored then
			task.spawn(shakeCollision, collision)
		end
	end)

	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("WeldConstraint") or v:IsA("Weld") or v:IsA("ManualWeld") or v:IsA("Motor6D") or v:IsA("Snap") or v:IsA("Glue") or v:IsA("RigidConstraint") then
			local p0, p1 = v.Part0, v.Part1
			if p0 and p1 then
				if isInside(p0, model) ~= isInside(p1, model) then
					v:Destroy()
				end
			end
		end
	end

	for _, part in ipairs(parts) do
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = collision
		weld.Part1 = part
		weld.Parent = collision
	end
end

local function BreakRoom(room)
	if isCrucifixed or not room then return end

	task.spawn(function()
		task.wait(0.02)
		if isCrucifixed then return end

		local assetContainer = room:FindFirstChild("Assets") or room

		local breakSound = Instance.new("Sound")
		local breakSoundsList = {
			"rbxassetid://9125992545",
			"rbxassetid://4004052860",
			"rbxassetid://7142857558",
			"rbxassetid://7142843615",
			"rbxassetid://2612674531",
			"rbxassetid://2174790942",
		}

		breakSound.SoundId = breakSoundsList[math.random(1, #breakSoundsList)]

		if not destroyedsounds then
			destroyedsounds = true
			breakSound.Volume = math.random(28, 38) / 10
		else
			breakSound.Volume = 1
		end

		breakSound.Parent = assetContainer
		breakSound:Play()
		breakSound.Ended:Connect(function()
			breakSound:Destroy()
		end)

		local targets = {}
		for _, v in ipairs(room:GetDescendants()) do
			if isCrucifixed then return end
			if v:IsA("Model") then
				setupModel(v, room, targets)
			end
		end

		if isCrucifixed then return end

		local currentDir = entityMoveDirection
		for _, collision in ipairs(targets) do
			if isCrucifixed then break end
			if collision and collision.Parent and collision:GetAttribute("WindCollision") == true then
				collision.Anchored = false
				collision.AssemblyLinearVelocity = (currentDir * math.random(50, 90)) + Vector3.new(0, math.random(15, 35), 0)
				collision.AssemblyAngularVelocity = Vector3.new(
					math.random(-25, 25),
					math.random(-25, 25),
					math.random(-25, 25)
				)
			end
		end
	end)
end

local function TriggerExtremeShake()
	task.spawn(function()
		pcall(function()
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health <= 0 then return end

			local CameraShakerModule = require(ReplicatedStorage:WaitForChild("CameraShaker", 5))
			local camera = Workspace.CurrentCamera
			if CameraShakerModule and camera then
				local despawnShake = CameraShakerModule.new(Enum.RenderPriority.Camera.Value, function(cf)
					camera.CFrame = camera.CFrame * cf
				end)
				despawnShake:Start()
				despawnShake:ShakeOnce(40, 30, 3, 6)
			end
		end)
	end)
end

-- ========================================================
--            FULL CRUCIFIX EFFECT (REPENTANCE)             --
-- ========================================================
local function PlayFullCrucifixEffect(entityObj)
	local model = entityObj and entityObj.Model or activeSpawnedModel or Workspace:FindFirstChild("multimonster")
	if not model or not model.Parent then return end

	isCrucifixed = true
	model:SetAttribute("BeingBanished", true)
	model:SetAttribute("Paused", true)
	model:SetAttribute("Damage", false)
	LetPlayingSoundsFinish(model)

	pcall(function()
		local char = LocalPlayer.Character
		local tool = char and (char:FindFirstChild("Crucifix") or char:FindFirstChild("Cruxy"))
		if tool and tool:IsA("Tool") then
			tool:Destroy()
		end
	end)

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local entityPivot = model:GetPivot()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, model }

	local result = Workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	local groundPos = result and result.Position or (entityPivot.Position - Vector3.new(0, 4, 0))

	local repentanceAsset
	pcall(function()
		repentanceAsset = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm")
	end)

	local camShaker
	pcall(function()
		local camShakerMod = ReplicatedStorage:FindFirstChild("CameraShaker", true)
		if camShakerMod then
			local CameraShaker = require(camShakerMod)
			camShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
				local curCam = Workspace.CurrentCamera
				if curCam then curCam.CFrame = curCam.CFrame * shakeCf end
			end)
			camShaker:Start()
			camShaker:ShakeOnce(5, 20, 2, Vector3.zero)
		end
	end)

	if not repentanceAsset then
		if model and model.Parent then model:Destroy() end
		return
	end

	local Repentance = repentanceAsset:Clone()
	local Crucifix = Repentance:FindFirstChild("Crucifix")
	local Handle = Crucifix and Crucifix:FindFirstChild("Handle")
	local Pentagram = Repentance:FindFirstChild("Pentagram")
	local EntityPart = Repentance:FindFirstChild("Entity")
	local Sound = Handle and Handle:FindFirstChild("Sound")

	Repentance:PivotTo(CFrame.new(groundPos))
	if Crucifix then
		Crucifix:PivotTo(character:GetPivot())
	end
	if EntityPart then
		EntityPart.CFrame = entityPivot
	end
	Repentance.Parent = Workspace

	if Sound and Sound:IsA("Sound") then
		Sound:Play()
	end

	local function waitUntil(t: number)
		if not Sound or not Sound.IsPlaying then
			task.wait(math.min(t, 2))
			return
		end
		local guard = tick()
		repeat
			RunService.RenderStepped:Wait()
		until not Sound.Parent or not Sound.IsPlaying or Sound.TimePosition >= t or (tick() - guard) > 15
	end

	local function fadeOut()
		if not Pentagram then return end
		for _, v in ipairs(Pentagram:GetChildren()) do
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

	local crucifixColor = Color3.fromRGB(137, 207, 255)
	for _, v in ipairs(Repentance:GetDescendants()) do
		if v:HasTag("GiveMeColor") then
			if v:IsA("Light") or v:IsA("BasePart") then
				v.Color = crucifixColor
			elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
				v.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, crucifixColor),
					ColorSequenceKeypoint.new(1, crucifixColor),
				})
			end
		end
	end

	task.spawn(function()
		while EntityPart and EntityPart.Parent and model and model.Parent do
			model:PivotTo(EntityPart.CFrame)
			RunService.RenderStepped:Wait()
		end
		if model and model.Parent then
			model:Destroy()
		end
	end)

	if Pentagram and Pentagram:FindFirstChild("Circle") then
		local circle = Pentagram.Circle
		TweenService:Create(
			circle,
			TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) }
		):Play()
		task.delay(2, function()
			if circle and circle.Parent then circle:Destroy() end
		end)
	end

	if Handle then
		local bodyPos = Handle:FindFirstChild("BodyPosition")
		if bodyPos then
			bodyPos.Position = (character:GetPivot() * CFrame.new(1, 4, -6)).Position
		end

		local bodyAngVel = Handle:FindFirstChild("BodyAngularVelocity")
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
					pcall(function()
						shard.CollisionGroup = "NoPlayer"
						shard.CanCollide = true
						if shard:FindFirstChild("Weld") then shard.Weld:Destroy() end
						shard.AssemblyAngularVelocity = Vector3.zero
					end)
				end
			end
		end)
	end

	if EntityPart then
		TweenService:Create(
			EntityPart,
			TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
			{ CFrame = EntityPart.CFrame + Vector3.new(0, 2, 0) }
		):Play()
	end

	task.spawn(function()
		waitUntil(2.625)

		local pentLight = Pentagram and Pentagram:FindFirstChild("Base")
			and Pentagram.Base:FindFirstChild("LightAttach")
			and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
		local handleLight = Handle and Handle:FindFirstChild("Light")

		if pentLight then
			TweenService:Create(pentLight, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
				Brightness = 5,
				Range = 40,
			}):Play()
		end
		if handleLight then
			TweenService:Create(handleLight, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
				Brightness = 11.25,
				Range = 30,
			}):Play()
		end

		task.wait(1.5)

		if pentLight then
			TweenService:Create(pentLight, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
				Brightness = 0,
				Range = 0,
			}):Play()
		end
		if handleLight then
			TweenService:Create(handleLight, TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
				Brightness = 0,
				Range = 0,
			}):Play()
		end

		if handleLight then
			TweenService:Create(handleLight, TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
				Brightness = 15,
				Range = 40,
			}):Play()
		end

		if camShaker and camShaker.StartFadeOut then
			pcall(function() camShaker:StartFadeOut(3) end)
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
	end)

	waitUntil(2.5)

	if EntityPart then
		TweenService:Create(
			EntityPart,
			TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ CFrame = EntityPart.CFrame - Vector3.new(0, 50, 0) }
		):Play()
	end

	for _, s in ipairs(model:GetDescendants()) do
		if s:IsA("Sound") and not s:GetAttribute("VolumeIgnore") then
			TweenService:Create(
				s,
				TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ Volume = 0 }
			):Play()
		end
	end

	waitUntil(6.75)

	if Handle and Handle:FindFirstChild("Glow") then
		TweenService:Create(Handle.Glow, TweenInfo.new(1), {
			Size = Handle.Glow.Size * 3,
			Transparency = 1,
		}):Play()
	end

	local pentLight = Pentagram and Pentagram:FindFirstChild("Base")
		and Pentagram.Base:FindFirstChild("LightAttach")
		and Pentagram.Base.LightAttach:FindFirstChild("LightBright")
	local handleLight = Handle and Handle:FindFirstChild("Light")

	if pentLight then
		TweenService:Create(pentLight, TweenInfo.new(1), { Brightness = 0, Range = 0 }):Play()
	end
	if handleLight then
		TweenService:Create(handleLight, TweenInfo.new(1), { Brightness = 0, Range = 0 }):Play()
	end

	if Handle and Handle:FindFirstChild("ExplodeParticle") then
		Handle.ExplodeParticle:Emit(math.random(20, 30))
	end
	if camShaker and camShaker.ShakeOnce then
		pcall(function() camShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5) end)
	end

	task.delay(5, function()
		if Repentance and Repentance.Parent then
			Repentance:Destroy()
		end
	end)
end

-- ========================================================
--               CHECK ĐIỀU KIỆN XUẤT HIỆN                  --
-- ========================================================
if Workspace:FindFirstChild("SeekMovingNewClone") then
	repeat
		task.wait()
	until not Workspace:FindFirstChild("SeekMovingNewClone")
end

local customScream = Instance.new("Sound")
customScream.Name = "CustomSpawnScream"
customScream.SoundId = "rbxassetid://112497140615036"
customScream.Volume = 10
customScream.Parent = SoundService

ContentProvider:PreloadAsync({ customScream }, function()
	if not isCrucifixed then
		customScream:Play()
	end
end)

local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()

if getgenv().MultimonsterAchievementGiven == nil then
	getgenv().MultimonsterAchievementGiven = false
end

local function GiveMultimonsterAchievement()
	if not getgenv().MultimonsterAchievementGiven then
		getgenv().MultimonsterAchievementGiven = true
		pcall(function()
			achievementGiver({
				Title = "A Nostalgic Frights...",
				Desc = "Might Come Back...",
				Reason = "Survive the rare Entity Designed as Multimonster.",
				Image = "rbxassetid://100946605902758",
			})
		end)
	end
end

-- ========================================================
-- LOAD OGHUNGERNEWSPAWNER & TẠO ENTITY
-- ========================================================
getgenv().OgHungerNewSpawner = nil
local success, Spawner = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/eoyoustme/Mayhem-Remake/refs/heads/main/OgHungerNewSpawner"))()
end)

if not success or not Spawner then
	warn("[MULTIMONSTER] Không tải được OgHungerNewSpawner")
	return
end

local entity = Spawner:Create({
	Entity = {
		Name = "multimonster",
		Asset = "rbxassetid://74103016339839",
		HeightOffset = 0,
	},
	Lights = {
		Flicker = {
			Enabled = false,
			Duration = 1,
		},
		Shatter = false,
		Repair = false,
	},
	Earthquake = {
		Enabled = false,
	},
	Spawned = {
		ChangeColorWhenSpawn = false,
		Rainbow = false,
		Color = Color3.fromRGB(0, 85, 255),
	},
	CameraShake = {
		Enabled = true,
		Range = 150,
		Values = { 18, 25, 0.05, 0.1 },
	},
	Movement = {
		Speed = speed,
		SpeedFast = 470,
		MoveFastNotEnter = false,
		IsMoveWhenWHere = false,
		Delay = math.random(1, 1.5),
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
		ChasePlayerWhenSee = false,
		SpeedWhenChase = 35,
		GlitchMove = false,
		GlitchMoveSoundId = "rbxassetid://0",
		Fakeout = {
			Enabled = false,
			RandomFakeout = false,
			EndSound = "rbxassetid://0",
			EndDelay = 2,
			SpeedMultiplier = 1,
		},
	},
	Jumpscare = {
		Enabled = false,
		Image1 = "rbxassetid://11253398403",
		Image2 = "rbxassetid://12293509957",
		Sound1 = "rbxassetid://0",
		Sound2 = "rbxassetid://109582246349306",
		Tease = {
			[1] = true,
			Min = 1,
			Max = 1,
		},
		Flashing = {
			[1] = true,
			[2] = Color3.fromRGB(255, 255, 255),
		},
		Shake = true,
	},
	Rebounding = {
		Enabled = true,
		Type = "Ambush",
		Min = 2,
		Max = math.random(5, 6),
		Delay = math.random(1, 2),
	},
	Damage = {
		Enabled = true,
		KillOnMove = false,
		Range = 60,
		Amount = 125,
		Cooldown = 1,
		IgnoreHiding = false,
		JumpscareRipper = {
			Enabled = false,
			TargetPartName = "Ripe",
			AttachmentName = "ripe",
			ParticleName = "ParticleEmitter",
			ParticleTexture = "rbxassetid://12737595583",
			SoundUrl = "https://github.com/eoyoustme/back/raw/main/Kill_with_static.mp3",
			SlamSoundId = "rbxassetid://0",
			EndSoundId = "rbxassetid://4988621968",
			Images = {
				"rbxassetid://8482795900",
				"rbxassetid://236542974",
				"rbxassetid://184251462",
				"rbxassetid://236777652",
			},
			FlashDuration = 1.6,
		},
	},
	Crucifixion = {
		Type = "Guiding",
		Enabled = true,
		Range = 60,
		Resist = false,
		Break = true,
	},
	Death = {
		Type = "Curious",
		Hints = {
			"You fell victim to Multimonster...",
			"It travels at terrifying speeds across multiple rooms...",
			"Listen closely for its loud approach and hide immediately...",
			"Do not let it catch you in its line of sight!...",
		},
		Cause = "Multimonster",
	},
})

if not entity then return end

-- ========================================================
--                      CALLBACKS                         --
-- ========================================================
entity:SetCallback("CrucifixionOverwrite", function()
	PlayFullCrucifixEffect(entity)
end)

entity:SetCallback("OnSpawned", function()
	isCrucifixed = false
	entityLastPosition = nil
	activeSpawnedModel = entity.Model or Workspace:WaitForChild("multimonster", 5)

	local part = activeSpawnedModel
	if not part then return end

	local object = part:WaitForChild("RushNew", 5)
	if not object then return end

	local dirConn
	dirConn = RunService.RenderStepped:Connect(function()
		if isCrucifixed or not part or not part.Parent then
			if dirConn then dirConn:Disconnect() end
			return
		end
		local primaryPart = part.PrimaryPart or object
		if primaryPart then
			local currentPos = primaryPart.Position
			if entityLastPosition then
				local diff = currentPos - entityLastPosition
				if diff.Magnitude > 0.01 then
					entityMoveDirection = diff.Unit
				end
			end
			entityLastPosition = currentPos
		end
	end)

	local attachment = object:WaitForChild("Main", 5)
	local e = attachment and attachment:WaitForChild("Face", 5)

	if object:IsA("BasePart") then object.CanCollide = false end
	if not e then return end

	local originalTexture = e.Texture
	task.spawn(function()
		local textures = {
			"rbxassetid://12145534911", "rbxassetid://12145554242",
			"rbxassetid://12145599498", "rbxassetid://12145599275",
			"rbxassetid://12155335619", "rbxassetid://12145598814",
			"rbxassetid://12146135062", "rbxassetid://11378285585",
		}
		while not isCrucifixed and part and part.Parent do
			for _, tex in ipairs(textures) do
				if isCrucifixed or not (part and part.Parent) then break end
				e.Texture = tex
				task.wait(0)
			end
		end
		if e and e.Parent then
			e.Texture = originalTexture
		end
	end)
end)

entity:SetCallback("OnStartMoving", function()
	if isCrucifixed then return end
	print("multimonster has started moving")

	task.spawn(function()
		if isCrucifixed then return end

		local urls = {
			{ "https://github.com/Ic1000/Misc/raw/refs/heads/main/ripbreak2.mp3", "ripbreak2" },
			{ "https://github.com/Ic1000/Misc/raw/refs/heads/main/ripperbreak3.mp3", "ripbreak3" },
			{ "https://github.com/Ic1000/Misc/raw/refs/heads/main/ripbreak1.mp3", "ripbreak1" },
		}
		local pick = urls[math.random(1, #urls)]
		local Github = GetGitSound(pick[1], pick[2])

		local breaking = Instance.new("Sound")
		breaking.SoundId = Github.SoundId
		breaking.PlaybackSpeed = 1
		breaking.Parent = Workspace
		breaking.Looped = true
		breaking.RollOffMaxDistance = 1000000000
		breaking.Volume = 0
		activeBreakingSound = breaking

		pcall(function()
			if not isCrucifixed then
				breaking:Play()
			end
		end)

		local conn
		conn = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")

			local womp = entity.Model or Workspace:FindFirstChild("multimonster")
			local ripe = womp and (womp:FindFirstChild("RushNew") or womp.PrimaryPart)

			if not hrp or not womp or not ripe or not breaking.Parent then
				if breaking and breaking.Parent then
					breaking:Stop()
					breaking:Destroy()
				end
				if activeBreakingSound == breaking then
					activeBreakingSound = nil
				end
				if conn then
					conn:Disconnect()
				end
				return
			end

			if isCrucifixed then
				breaking.Looped = false
				if conn then
					conn:Disconnect()
				end
				AttachFinishCleanup(breaking)
				if activeBreakingSound == breaking then
					activeBreakingSound = nil
				end
				return
			end

			local distance = (ripe.Position - hrp.Position).Magnitude
			if distance <= 100 then
				breaking.Volume = 6
				if not breaking.IsPlaying then
					breaking:Play()
				end
			else
				breaking.Volume = 0
			end
		end)

		breaking.Ended:Connect(function()
			if conn then
				conn:Disconnect()
			end
			if activeBreakingSound == breaking then
				activeBreakingSound = nil
			end
			if breaking and breaking.Parent then
				breaking:Destroy()
			end
		end)
	end)
end)

entity:SetCallback("OnDamagePlayer", function(newHealth)
	if isCrucifixed then return end

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local womp = entity.Model or Workspace:WaitForChild("multimonster", 2)

	if not womp then return end
	local wompwomp = womp:FindFirstChild("RushNew")
	if not wompwomp then return end

	if not character:GetAttribute("Hiding") and not debounce then
		debounce = true
		isJumpscaring = true

		pcall(function()
			for _, v in pairs(womp:GetDescendants()) do
				if v:IsA("Sound") and v.IsPlaying then
					v:Stop()
				end
			end
		end)

		pcall(function()
			if HumanoidRootPart then HumanoidRootPart.Anchored = true end

			local savedTransparencies = {}
			if wompwomp:IsA("BasePart") then
				savedTransparencies[wompwomp] = wompwomp.Transparency
				wompwomp.Transparency = 1
			end

			for _, child in ipairs(wompwomp:GetDescendants()) do
				if child:IsA("BasePart") then
					savedTransparencies[child] = child.Transparency
					if child.Name ~= "Main" then
						child.Transparency = 1
					end
				elseif child:IsA("Decal") then
					savedTransparencies[child] = child.Transparency
					child.Transparency = 0
				end
			end

			if wompwomp:IsA("BasePart") then wompwomp.Anchored = true end

			local renderConnection
			renderConnection = RunService.RenderStepped:Connect(function()
				if isCrucifixed or not isJumpscaring then
					if renderConnection then renderConnection:Disconnect() end
					return
				end
				local Camera = Workspace.CurrentCamera
				if wompwomp:IsA("Model") then
					wompwomp:PivotTo(Camera.CFrame * CFrame.new(0, -0.5, -6))
				elseif wompwomp:IsA("BasePart") then
					wompwomp.CFrame = Camera.CFrame * CFrame.new(0, -0.5, -6)
				end
				if humanoid then
					humanoid.WalkSpeed = 0
				end
			end)

			local scareSound = GetGitSound("https://github.com/thefigureblack/audios/blob/main/asixtyScareOmg.mp3?raw=true", "asixtyScareOmg")
			scareSound.Parent = Workspace
			scareSound.Volume = 7.5
			scareSound:Play()

			task.wait(0.5)

			for part, originalTransparency in pairs(savedTransparencies) do
				if part and part.Parent then
					part.Transparency = originalTransparency
				end
			end

			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "A60_JumpscareGui"
			screenGui.Parent = PlayerGui
			screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			local randomSelectedImage = ALL_JUMPSCARE_IMAGES[math.random(1, #ALL_JUMPSCARE_IMAGES)]
			local jumpscareImg = Instance.new("ImageLabel")
			jumpscareImg.Name = "JumpscareImage"
			jumpscareImg.Parent = screenGui
			jumpscareImg.AnchorPoint = Vector2.new(0.5, 0.5)
			jumpscareImg.Position = UDim2.new(0.5, 0, 0.5, 0)
			jumpscareImg.Size = UDim2.new(0, 0, 0, 0)
			jumpscareImg.BackgroundTransparency = 1
			jumpscareImg.Image = randomSelectedImage
			jumpscareImg.ImageTransparency = 0
			jumpscareImg.ImageColor3 = Color3.fromRGB(255, 0, 0)

			local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
			TweenService:Create(colorCorrection, TweenInfo.new(0.2), {
				Brightness = 0.2,
				Contrast = 0.3,
				Saturation = -0.3,
				TintColor = Color3.fromRGB(255, 0, 4),
			}):Play()

			if HumanoidRootPart then HumanoidRootPart.Anchored = false end

			TweenService:Create(jumpscareImg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.2, 0, 1.4, 0),
				Rotation = math.random(-20, 20),
			}):Play()

			task.wait(0.5)
			isJumpscaring = false

			local fadeTween = TweenService:Create(jumpscareImg, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 })

			local function SafeCleanup()
				pcall(function()
					if screenGui then screenGui:Destroy() end
					if colorCorrection then colorCorrection:Destroy() end
					if scareSound then scareSound:Destroy() end
				end)
			end

			fadeTween:Play()
			fadeTween.Completed:Connect(SafeCleanup)
			task.delay(2.5, SafeCleanup)

			Debris:AddItem(screenGui, 4)
			Debris:AddItem(colorCorrection, 3)
			Debris:AddItem(scareSound, 3)

			task.wait(1)
			debounce = false
		end)
	end
end)

entity:SetCallback("OnEnterRoom", function(room, firstTime)
	if isCrucifixed or not room then return end
	BreakRoom(room)
	if not isCrucifixed then
		doorSound1:Play()
		doorSound2:Play()
	end
end)

entity:SetCallback("OnDespawned", function()
	print("multimonster has despawned")
	LetPlayingSoundsFinish(activeSpawnedModel)

	if isCrucifixed then
		return
	end

	TriggerExtremeShake()
	GiveMultimonsterAchievement()

	local lighting = Lighting:FindFirstChild("MainColorCorrection")
	if not lighting then
		lighting = Instance.new("ColorCorrectionEffect")
		lighting.Name = "MainColorCorrection"
		lighting.Parent = Lighting
	end

	lighting.TintColor = Color3.fromRGB(255, 30, 30)
	lighting.Contrast = 0.5
	lighting.Saturation = 0.5

	task.delay(7, function()
		TweenService:Create(lighting, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TintColor = Color3.fromRGB(255, 255, 255),
			Contrast = 0,
			Saturation = 0,
		}):Play()
	end)
end)

entity:Run(true) 
