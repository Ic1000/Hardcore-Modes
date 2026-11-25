-- ========================================================
--   RIPPER BLA SCRIPT (CLIENTOPEN + RED LIGHT 3S RESET)
-- ========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local CurrentRooms = Workspace:WaitForChild("CurrentRooms")
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

local speed 
if getgenv().FasterTrouble then 
	speed = 250 
else 
	speed = 200 
end

local RED_COLOR = Color3.fromRGB(255, 25, 25)

if getgenv().RipperAchievementEarned == nil then
	getgenv().RipperAchievementEarned = false
end

-- Hàm tải âm thanh từ GitHub
local function GetGitSound(GithubSnd, SoundName)
	local filePath = SoundName .. ".mp3"
	if not isfile(filePath) then
		pcall(function()
			writefile(filePath, game:HttpGet(GithubSnd))
		end)
	end
	local sound = Instance.new("Sound")
	pcall(function()
		sound.SoundId = (getcustomasset or getsynasset)(filePath)
	end)
	return sound
end

-- Hàm đổi phòng sang đỏ trong 3 giây rồi tự trả lại màu gốc
local function FlashRoomRed(targetRoom, holdSeconds, fadeSeconds)
	if not targetRoom or not targetRoom.Parent then return end

	local holdTime = holdSeconds or 3
	local fadeTime = fadeSeconds or 0.8
	local toRedInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local toNormalInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local savedLights = {}
	local savedNeons = {}

	for _, obj in ipairs(targetRoom:GetDescendants()) do
		if obj:IsA("Light") then
			savedLights[obj] = obj.Color
			pcall(function()
				TweenService:Create(obj, toRedInfo, { Color = RED_COLOR }):Play()
			end)
		elseif obj:IsA("BasePart") and obj.Material == Enum.Material.Neon and obj.Name ~= "Skybox" then
			savedNeons[obj] = obj.Color
			pcall(function()
				TweenService:Create(obj, toRedInfo, { Color = RED_COLOR }):Play()
			end)
		end
	end

	local origAmbient = nil
	pcall(function()
		origAmbient = targetRoom:GetAttribute("Ambient")
		if origAmbient ~= nil then
			targetRoom:SetAttribute("Ambient", RED_COLOR)
		end
	end)

	task.delay(holdTime, function()
		if not targetRoom or not targetRoom.Parent then return end

		for lightObj, origColor in pairs(savedLights) do
			if lightObj and lightObj.Parent then
				pcall(function()
					TweenService:Create(lightObj, toNormalInfo, { Color = origColor }):Play()
				end)
			end
		end

		for neonPart, origColor in pairs(savedNeons) do
			if neonPart and neonPart.Parent then
				pcall(function()
					TweenService:Create(neonPart, toNormalInfo, { Color = origColor }):Play()
				end)
			end
		end

		if origAmbient ~= nil then
			pcall(function()
				targetRoom:SetAttribute("Ambient", origAmbient)
			end)
		end
	end)
end

-- Hàm mở cửa qua ClientOpen:FireServer()
local function FireClientOpenDoor()
	local latestRoom = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
	if latestRoom and latestRoom:FindFirstChild("Door") and latestRoom.Door:FindFirstChild("ClientOpen") then
		pcall(function()
			latestRoom.Door.ClientOpen:FireServer()
		end)
	end
end

-- ========================================================
-- ACHIEVEMENT (CHỈ LẤY 1 LẦN DÙNG GETGENV)
-- ========================================================
local function GiveAchievement()
	if getgenv().RipperAchievementEarned then
		return
	end
	getgenv().RipperAchievementEarned = true

	task.spawn(function()
		local ok, achievementGiver = pcall(function()
			return loadstring(game:HttpGet(
				"https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"
			))()
		end)

		if not ok or not achievementGiver then
			warn("[RIPPER] Achievement loader failed")
			return
		end

		pcall(function()
			achievementGiver({
				Title = "Torn Apart",
				Desc = "Don't Leave Stand still..",
				Reason = "Encounter and survive Ripper.",
				Image = "rbxassetid://12231244908",
			})
		end)
	end)
end

-- Hiện mặt Jumpscare của thực thể khi ăn thánh giá
local function ShowCrucifixFace(entityModel)
	local model = entityModel or Workspace:FindFirstChild("RipperBla")
	if not model then return end

	for _, emitter in ipairs(model:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") and emitter.Name == "Face1" then
			emitter.Texture = "rbxassetid://12737595583"
			emitter.Size = NumberSequence.new(10)
			emitter.Squash = NumberSequence.new(0)
			emitter.TimeScale = 1
			emitter.Enabled = true
			emitter:Emit(20)
			
			local repent = GetGitSound(
		"https://github.com/Ic1000/Misc/raw/refs/heads/main/Ripper%20Repent%20SFX.mp3",
		"Ripper_Repent_SFX"
	)
	
	if repent then
		repent.Volume = 7
		repent.Parent = SoundService
		repent:Play()
		repent.Ended:Connect(function()
			if repent and repent.Parent then
				repent:Destroy()
	       		end
       		end)
        	end
		end
	end
end

-- ========================================================
-- CƠ CHẾ PHÁ & MỞ CỬA (RunBla + ClientOpen + FadeDestroy)
-- ========================================================
local function FadeDestroy(model)
	if not model or not model.Parent then return end
	local info = TweenInfo.new(3, Enum.EasingStyle.Linear)

	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("Sound") then
			pcall(function()
				TweenService:Create(v, info, { PlaybackSpeed = 0 }):Play()
			end)
		elseif v:IsA("ParticleEmitter") then
			v.Enabled = false
			pcall(function()
				TweenService:Create(v, info, { Rate = 0 }):Play()
			end)
		elseif v:IsA("Beam") then
			pcall(function()
				TweenService:Create(v, info, {
					Brightness = 0,
					Transparency = NumberSequence.new(1),
				}):Play()
			end)
		elseif v:IsA("Trail") then
			pcall(function()
				TweenService:Create(v, info, {
					Transparency = NumberSequence.new(1),
				}):Play()
			end)
		elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			pcall(function()
				TweenService:Create(v, info, { Brightness = 0 }):Play()
			end)
		end
	end

	task.delay(3, function()
		if model and model.Parent then
			model:Destroy()
		end
	end)
end

local function TweenPivot(model, target, info)
	if not model or not model.Parent then return end

	local val = Instance.new("CFrameValue")
	val.Value = model:GetPivot()

	local conn = val:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then
			model:PivotTo(val.Value)
		end
	end)

	local tw = TweenService:Create(val, info, { Value = target })
	tw:Play()
	tw.Completed:Wait()

	conn:Disconnect()
	val:Destroy()
end

local function RunBla(entityObj)
	local model = entityObj and entityObj.Model
	if not model or not model.Parent then return end

	local room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
	if not room then return end

	local root = model:FindFirstChild("Ripe")
		or model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)

	local doorModel = room:FindFirstChild("Door")
	if not root or not doorModel then return end

	local chance = 2
	for _, v in ipairs(room:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "KeyHitbox" then
			chance = 1
			break
		end
	end

	-- Nhánh 1: Phòng có chìa khóa -> đập cửa rồi biến mất
	if chance == 1 then
		local snd = GetGitSound(
			"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XRecorder_Edited_20261012_01.mp3?raw=true",
			"hvjdjjjc"
		)
		snd.Name = "Slam"
		snd.Volume = 6
		snd.PlaybackSpeed = 1
		snd.Looped = false
		snd.RollOffMaxDistance = 200
		snd.Parent = root
		snd:Play()

		pcall(function()
			local CameraShaker = require(ReplicatedStorage.CameraShaker)
			local camera = Workspace.CurrentCamera
			local s = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
				camera.CFrame = camera.CFrame * cf
			end)
			s:Start()
			s:ShakeOnce(15, 11.5, 0.1, 2, 15, 0.5)
		end)

		if snd.TimeLength > 0 then
			snd.Ended:Wait()
		else
			task.wait(1.5)
		end

		if entityObj:IsAlive() then
			entityObj:Pause()
		end
		FadeDestroy(model)

		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum and hum.Health > 0 then
			GiveAchievement()
		end
		return
	end

	-- Nhánh 2: Phòng thường -> lấy đà húc tung cửa + ClientOpen:FireServer()
	local snd = GetGitSound(
		"https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XRecorder_Edited_20260810_01.mp3?raw=true",
		"jjcjfjjc"
	)
	snd.Name = "BlaSound"
	snd.Volume = 3.5
	snd.PlaybackSpeed = 1
	snd.Looped = false
	snd.RollOffMaxDistance = 200
	snd.Parent = root
	snd:Play()

	local door
	for _, v in ipairs(doorModel:GetDescendants()) do
		if v:IsA("MeshPart") and v.Name == "Door" then
			door = v
			break
		end
	end
	if not door then return end

	local original = model:GetPivot()
	local target = original + door.CFrame.LookVector * -20
	TweenPivot(model, target, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

	task.wait(1.5)

	local target2 = original + door.CFrame.LookVector * -25
	TweenPivot(model, target2, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

	task.spawn(function()
		if model.Parent then
			TweenPivot(model, original, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
		end
	end)

	task.wait(0.6)
	if not model.Parent then return end

	pcall(function()
		local CameraShaker = require(ReplicatedStorage.CameraShaker)
		local camera = Workspace.CurrentCamera
		local s = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
			camera.CFrame = camera.CFrame * cf
		end)
		s:Start()
		s:ShakeOnce(15, 11.5, 0.1, 2, 15, 0.5)
	end)

	FireClientOpenDoor()

	local doorSound = root:FindFirstChild("DoorOpen1")
	if doorSound and doorSound:IsA("Sound") then
		doorSound.Volume = 5
		doorSound:Play()
	end

	local function HideHidden(obj)
		for _, v in ipairs(obj:GetDescendants()) do
			if v:IsA("BasePart") and v.Name == "Hidden" then
				v.Transparency = 1
			end
		end
		obj.DescendantAdded:Connect(function(v)
			if v:IsA("BasePart") and v.Name == "Hidden" then
				v.Transparency = 1
			end
		end)
	end

	HideHidden(doorModel)

	local clone = doorModel:Clone()
	clone.Name = "DoorClone"
	clone.Parent = doorModel.Parent

	local cloneDoor
	for _, v in ipairs(clone:GetDescendants()) do
		if v:IsA("MeshPart") and v.Name == "Door" then
			cloneDoor = v
			break
		end
	end

	if cloneDoor then
		cloneDoor.CFrame = cloneDoor.CFrame
			* CFrame.Angles(math.rad(-90), 0, 0)
			* CFrame.new(0, 7, -3.7)
	else
		clone:Destroy()
	end

	for _, v in ipairs(doorModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency = 1
		elseif v:IsA("SurfaceGui") and v.Name == "Sign" then
			v:Destroy()
		elseif v:IsA("Sound") then
			v.Volume = 0
		end
	end

	if clone.Parent then
		HideHidden(clone)
	end

	if snd.TimeLength > 0 then
		snd.Ended:Wait()
	else
		task.wait(2)
	end

	if entityObj:IsAlive() then
		entityObj:Pause()
	end
	FadeDestroy(model)

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if hum and hum.Health > 0 then
		GiveAchievement()
	end
end

-- ========================================================
-- LOAD OGHUNGERNEWSPAWNER & TẠO ENTITY
-- ========================================================
getgenv().OgHungerNewSpawner = nil
local success, Spawner = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/Ic1000/Misc/refs/heads/main/Oghungerspawner"))()
end)

if not success or not Spawner then
	warn("[RIPPER] Không tải được OgHungerNewSpawner")
	return
end

local isJumpscaring = false
local blaTriggered = false

local entity = Spawner:Create({
	Entity = {
		Name = "RipperBla",
		Asset = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_131351567799504_Model_RipperMovingkkd_1791822177.txt",
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
		Enabled = true,
	},
	Spawned = {
		ChangeColorWhenSpawn = false,
		Rainbow = false,
		Color = Color3.fromRGB(0, 85, 255),
	},
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = { 10, 27, 0.1, 0.4 },
	},
	Movement = {
		Speed = speed,
		SpeedFast = 470,
		MoveFastNotEnter = false,
		IsMoveWhenWHere = false,
		Delay = 4,
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
		Enabled = false,
		Type = "Ambush",
		Min = 1,
		Max = 1,
		Delay = 2,
	},
	Damage = {
		Enabled = true,
		KillOnMove = false,
		Range = 50,
		Amount = 0.001,
		Cooldown = 1,
		IgnoreHiding = false,
		JumpscareRipper = {
			Enabled = false,
			TargetPartName = "Ripe",
			AttachmentName = "ripe",
			ParticleName = "ParticleEmitter",
			ParticleTexture = "rbxassetid://12737595583",
			SoundUrl = "https://github.com/eoyoustme/back/raw/main/Kill_with_static.mp3",
			SlamSoundId = "https://github.com/Ic1000/Misc/raw/refs/heads/main/RipperJumpscareSlam.mp3",
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
		Range = 51,
		Resist = false,
		Break = true,
	},
	Death = {
		Type = "Guiding",
		Hints = { "Death", "Hints", "Go", "Here" },
		Cause = "Ripper",
	},
})

if not entity then return end

-- ========================================================
-- CALLBACKS
-- ========================================================
entity:SetCallback("OnSpawned", function()
	local currentRoom = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
	FlashRoomRed(currentRoom, 3, 0.8)

	task.spawn(function()
		local sound5 = Instance.new("Sound")
		sound5.PlaybackSpeed = 1
		sound5.Volume = 1.8
		sound5.SoundId = "rbxassetid://101665501585468"
		sound5.Parent = Workspace
		sound5:Play()
		task.wait(7)
		sound5:Destroy()
	end)
end)

entity:SetCallback("OnCrucified", function()
	ShowCrucifixFace(entity.Model)
end)

entity:SetCallback("OnEnterRoom", function(room: Model)
	FlashRoomRed(room, 3, 0.8)
end)

entity:SetCallback("OnStartMoving", function()
	local entityModel = entity.Model
	local ripe = entityModel and (entityModel:FindFirstChild("Ripe") or entityModel.PrimaryPart)

	local urls = {
		{ "https://github.com/cakmay227-svg/random/raw/refs/heads/main/XRecorder_Edited_20260801_01.mp3?raw=true", "jjjciie" },
		{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Ripper%20bresking%20stuff%202.mp3", "kdjjccj" },
		{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/RipperBreakingstuff3.mp3", "jckdkxjchjjdj" },
	}
	local pick = urls[math.random(1, #urls)]
	local Github = GetGitSound(pick[1], pick[2])

	local breaking = Instance.new("Sound")
	if Github then breaking.SoundId = Github.SoundId end
	breaking.PlaybackSpeed = 1
	breaking.Parent = Workspace
	breaking.Looped = false
	breaking.RollOffMaxDistance = 1000000000
	breaking.Volume = 6

	task.spawn(function()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not ripe or not ripe.Parent or not breaking.Parent then
				if conn then conn:Disconnect() end
				return
			end
			if (ripe.Position - hrp.Position).Magnitude <= 100 then
				if not breaking.IsPlaying then breaking:Play() end
			else
				if breaking.IsPlaying then breaking:Stop() end
			end
		end)
		breaking.Ended:Connect(function()
			if conn then conn:Disconnect() end
		end)
	end)

	task.spawn(function()
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/iccdjkkkkskskhdgdgegvbfbgncjjdudejdjvi/REBLAHARDCOREDI/refs/heads/main/Flingingstuff"))()
		end)
	end)

	-- Quét tới cửa phòng mới nhất để chạy phá cửa + ClientOpen:FireServer()
	task.spawn(function()
		while entity:IsAlive() and not blaTriggered and not isJumpscaring do
			local model = entity.Model
			if model and not model:GetAttribute("BeingBanished") and not model:GetAttribute("Paused") then
				local room = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
				local door = room and room:FindFirstChild("Door")
				if door then
					local dist = (model:GetPivot().Position - door:GetPivot().Position).Magnitude
					if dist <= 8 then
						blaTriggered = true
						entity:Pause()
						model:SetAttribute("Damage", false)
						RunBla(entity)
						break
					end
				end
			end
			task.wait(0.05)
		end
	end)
end)

entity:SetCallback("OnDamagePlayer", function()
	if isJumpscaring or blaTriggered then return end
	isJumpscaring = true

	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then humanoid.Health = 100 end

	local model = entity.Model or Workspace:FindFirstChild("RipperBla")
	if not model then return end
	local part = model:FindFirstChild("Ripe") or model.PrimaryPart
	if not part then return end

	entity:Pause()
	part.Anchored = true
	task.wait(0.7)

	if not LocalPlayer.Character:GetAttribute("Hiding") then
		task.spawn(function()
			local hum = character:WaitForChild("Humanoid", 5)
			local hrp = character:WaitForChild("HumanoidRootPart")
			local camera = Workspace.CurrentCamera
			local entityModel = model
			local primaryPart = part

			if not (entityModel and hum and hrp and primaryPart and camera) then return end

			local originalWalkSpeed = hum.WalkSpeed
			local originalJumpPower = hum.JumpPower
			hum.WalkSpeed = 0
			hum.JumpPower = 0

			local controlsModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
			controlsModule:Disable()
			
			local JumpscareSound= GetGitSound("https://github.com/Ic1000/Misc/raw/refs/heads/main/RipperJumpscareSlam.mp3", "Ripper_Slam_SFX")
			if JumpscareSound then
				JumpscareSound.Parent = SoundService 			
				JumpscareSound.Volume = 7
				JumpscareSound.PlaybackSpeed = 1
          JumpscareSound:Play()
			end

			local function SetAllParticlesTimeScale(m, timescale)
				for _, descendant in ipairs(m:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") then
						descendant.TimeScale = timescale
					end
				end
			end

			SetAllParticlesTimeScale(entityModel, 1)

			local ripeAttachment = primaryPart:FindFirstChild("Attachment", true)
			if ripeAttachment then
				local emitter = ripeAttachment:FindFirstChild("Face1")
				if emitter then
					emitter.Texture = "rbxassetid://12737595583"
					emitter.Size = NumberSequence.new(10)
					emitter.Squash = NumberSequence.new(0)
					emitter.Enabled = true
					emitter:Emit(20)
					task.wait(0.1)
					emitter.TimeScale = 0
				end
			end

			camera.CameraType = Enum.CameraType.Scriptable
			local startCFrame = camera.CFrame
			local lerpAlpha = 0
			local lerpSpeed = 10

			local lockConnection
			lockConnection = RunService.RenderStepped:Connect(function(dt)
				if not primaryPart or not primaryPart.Parent then
					if lockConnection then lockConnection:Disconnect() end
					return
				end
				local targetCFrame = CFrame.lookAt(startCFrame.Position, primaryPart.Position)
				lerpAlpha = math.clamp(lerpAlpha + dt * lerpSpeed, 0, 1)
				if lerpAlpha < 1 then
					camera.CFrame = startCFrame:Lerp(targetCFrame, lerpAlpha)
				else
					camera.CFrame = CFrame.lookAt(camera.CFrame.Position, primaryPart.Position)
				end
			end)

			task.wait(0.35)
			SetAllParticlesTimeScale(entityModel, 0)

			local Jumpscare = GetGitSound("https://github.com/eoyoustme/back/raw/main/Kill_with_static.mp3", "Kill")
			if Jumpscare then
				Jumpscare.Parent = SoundService 			
				Jumpscare.Volume = 1
				Jumpscare.PlaybackSpeed = 1
			end

			for _, descendant in ipairs(entityModel:GetDescendants()) do
				if descendant:IsA("Sound") then
					descendant.Playing = false
					descendant.Volume = 0
				end
			end

			if Jumpscare then Jumpscare:Play() end

			local MainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI")
			local Url = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_131351567799504_Frame_Jumpscare_Ripper_1790262146.txt"
			local FileName = "Jumpscare_Ripper.txt"
			if not isfile(FileName) then
				pcall(function()
					writefile(FileName, game:HttpGet(Url))
				end)
			end
			local Obj = game:GetObjects(getcustomasset(FileName))[1]
			if Obj then Obj.Parent = MainUI end

			local UI = MainUI:WaitForChild("Jumpscare_Ripper", true)
			if not UI then return end

			local Static = MainUI:FindFirstChild("Static", true)
			local Alpha = Instance.new("NumberValue")
			Alpha.Value = 1
			local GrainIndex = 0
			local LastGrain = tick()

			local function NoiseImage()
				if tick() - LastGrain >= 1 / 80 then
					LastGrain = tick()
					local Old = UI:FindFirstChild("GrainImage" .. tostring(GrainIndex))
					if Old then Old.ImageTransparency = 1 end
					GrainIndex = math.fmod(GrainIndex + 1, 12)
					local New = UI:FindFirstChild("GrainImage" .. tostring(GrainIndex))
					if New then
						New.ImageTransparency = Alpha.Value
						New.ImageColor3 = Color3.new(1, 1, 1)
					end
				end
			end

			UI.Visible = false
			local Connection = RunService.RenderStepped:Connect(function()
				NoiseImage()
			end)

			task.wait(1)
			UI.Visible = true
			TweenService:Create(Alpha, TweenInfo.new(2), { Value = 0 }):Play()
			if Static and Static:IsA("Sound") then
				TweenService:Create(Static, TweenInfo.new(2), { Volume = 3 }):Play()
			end

			task.wait(2)
			UI.Visible = false
			if Connection then Connection:Disconnect() end
			if Static and Static:IsA("Sound") then
				TweenService:Create(Static, TweenInfo.new(1), { Volume = 0 }):Play()
			end

			for i = 0, 11 do
				local Img = UI:FindFirstChild("GrainImage" .. tostring(i))
				if Img then Img.ImageTransparency = 1 end
			end
			Alpha:Destroy()
			
			local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://4988621968"
		sound.Volume = 7
		sound.PlaybackSpeed = 0.6
		sound.Parent = SoundService
		sound:Play()

			task.wait()
			if hum then hum.Health = 0 end

			pcall(function()
				ReplicatedStorage.GameStats["Player_" .. LocalPlayer.Name].Total.DeathCause.Value = "Ripper"
			end)

			if entityModel and entityModel.Parent then
				entityModel:Destroy()
			end
			if lockConnection then
				lockConnection:Disconnect()
			end
			camera.CameraType = Enum.CameraType.Custom

			if hum and hum.Health > 0 then
				hum.WalkSpeed = originalWalkSpeed
				hum.JumpPower = originalJumpPower
				controlsModule:Enable()
				GiveAchievement()
			end
		end)
	else
		isJumpscaring = false
		part.Anchored = false
		entity:Resume()
	end
end)

entity:SetCallback("OnDespawned", function()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if hum and hum.Health > 0 then
		GiveAchievement()
	end
end)

---====== Run Entity ======---
entity:Run(true)
