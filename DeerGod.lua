-- ========================================================
--     DEER GOD - FIXED CHASE + FASTER TROUBLE CHASE BOOST
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
local isDeactivated = false
local isBanishing = false
local crucifixFailed = false
local lookDamageEnabled = true
local damageEnabled = true
local isChasingPlayer = false
local hasEnteredChaseMode = false
local currentTween = nil
local nodeConnection = nil
local chaseStepConnection = nil

local env = (getgenv and getgenv()) or _G
local isFasterTrouble = (env.FasterTrouble == true) or (_G.FasterTrouble == true)
local patrolSpeed = isFasterTrouble and 17 or 14

local baseChaseSpeed = 16
local fasterTroubleChaseMultiplier = 1.5 -- 1.25 = tăng 25% | đổi thành 1.5 nếu muốn tăng 50%
local chaseSpeed = isFasterTrouble and (baseChaseSpeed * fasterTroubleChaseMultiplier) or baseChaseSpeed

-- Tải Module CustomAchievements & Vynixu Spawner V2
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()

-- Tải Repentance asset
local function LoadRepentanceAsset()
	local ok, inst = pcall(function()
		if typeof(LoadCustomInstance) == "function" then
			return LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm")
		end
		return nil
	end)
	if ok and inst then
		return inst
	end

	local okGet, objs = pcall(function()
		return game:GetObjects("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm")
	end)
	if okGet and objs and objs[1] then
		return objs[1]
	end
	return nil
end

local RepentanceTemplate = LoadRepentanceAsset()

local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()

if getgenv().DeerGodAchievement == nil then
	getgenv().DeerGodAchievement = false
end

local function GiveDeerGodAchievement()
	if not getgenv().DeerGodAchievement then
		getgenv().DeerGodAchievement = true
		pcall(function()
			achievementGiver({
				Title = "Last Chance To Look Away",
				Desc = "Why are you running?",
				Reason = "Survive the rare Entity called Deer God",
				Image = "rbxassetid://114825307168774",
			})
		end)
	end
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

local function StopChaseConnection()
	isChasingPlayer = false
	if chaseStepConnection then
		chaseStepConnection:Disconnect()
		chaseStepConnection = nil
	end
end

-- Hàm dọn dẹp an toàn ngắt sạch hiệu ứng khi Destroy
local function CleanupEntity()
	if isDeactivated then return end
	isDeactivated = true
	StopChaseConnection()

	if currentTween then pcall(function() currentTween:Cancel() end) end
	if nodeConnection then nodeConnection:Disconnect(); nodeConnection = nil end

	if deer and deer.Parent then
		pcall(function() deer:Destroy() end)
	end

	local nodeSpawner = Workspace:FindFirstChild("DeerGodNode")
	if nodeSpawner then
		pcall(function() nodeSpawner:Destroy() end)
	end
end

-- Kiểm tra tầm nhìn thẳng tới người chơi (raycast lọc vật cản)
local function CanSeePlayer(maxRange)
	if not ambush or not ambush.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
		return false
	end
	if character:GetAttribute("Hiding") then
		return false
	end

	local origin = ambush.Position
	local delta = HumanoidRootPart.Position - origin
	local dist = delta.Magnitude
	if maxRange and dist > maxRange then
		return false
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {deer, Workspace:FindFirstChild("DeerGodNode")}

	local result = Workspace:Raycast(origin, delta, rayParams)
	return result and result.Instance and result.Instance:IsDescendantOf(character) or false
end

-- Bắt đầu đuổi theo người chơi khi thấy trong tầm mắt
local function StartChasePlayer()
	if isChasingPlayer or isDeactivated or hit or isBanishing or character:GetAttribute("Hiding") then return end
	isChasingPlayer = true
	hasEnteredChaseMode = true

	if currentTween then
		pcall(function() currentTween:Cancel() end)
		currentTween = nil
	end

	chaseStepConnection = RunService.RenderStepped:Connect(function(dt)
		if isDeactivated or hit or not ambush or not ambush.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
			StopChaseConnection()
			return
		end

		-- Khi người chơi chui vào tủ (Hiding = true): ngừng đuổi và nhường lại cho luồng di chuyển qua phòng tiếp tục
		if isBanishing or character:GetAttribute("Hiding") then
			StopChaseConnection()
			return
		end

		local currentPos = ambush.Position
		local targetPos = HumanoidRootPart.Position
		local diff = targetPos - currentPos
		local dist = diff.Magnitude

		if dist > 0.5 then
			local stepDist = math.min(chaseSpeed * math.min(dt, 0.1), dist)
			local nextPos = currentPos + diff.Unit * stepDist
			local lookAtPos = Vector3.new(targetPos.X, nextPos.Y, targetPos.Z)
			if (lookAtPos - nextPos).Magnitude > 0.001 then
				ambush.CFrame = CFrame.lookAt(nextPos, lookAtPos)
			else
				ambush.CFrame = CFrame.new(nextPos)
			end
		end
	end)
end

-- Full ảnh động cơ chế Thánh Giá fail
local function PlayFailedCrucifixAnim()
	if isBanishing or isDeactivated or hit or not ambush or not ambush.Parent then
		return
	end

	isBanishing = true
	lookDamageEnabled = false
	damageEnabled = false
	StopChaseConnection()

	if currentTween then
		pcall(function() currentTween:Cancel() end)
		currentTween = nil
	end

	local entityPivot = deer:GetPivot()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, deer}

	local floorRay = Workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	local baseCFrame = floorRay and CFrame.new(floorRay.Position) or CFrame.new(entityPivot.Position)

	local Repentance = RepentanceTemplate and RepentanceTemplate:Clone()
	if camShake then
		camShake:ShakeOnce(5, 20, 2, 1)
	end

	if Repentance then
		local Crucifix = Repentance:FindFirstChild("Crucifix")
		local Handle = Crucifix and Crucifix:FindFirstChild("Handle")
		local Pentagram = Repentance:FindFirstChild("Pentagram")
		local EntityPart = Repentance:FindFirstChild("Entity")
		local Sound = Handle and Handle:FindFirstChild("SoundFail")

		Repentance:PivotTo(baseCFrame)
		if Crucifix and character:GetPivot() then
			Crucifix:PivotTo(character:GetPivot())
		end
		if EntityPart then
			EntityPart.CFrame = entityPivot
		end
		Repentance.Parent = Workspace

		if Sound and Sound:IsA("Sound") then
			Sound:Play()
		end

		local function waitUntil(t)
			if Sound and Sound:IsA("Sound") and Sound.Parent then
				repeat RunService.RenderStepped:Wait() until Sound.TimePosition >= t or not Sound.Parent
			else
				task.wait(t)
			end
		end

		local function fadeOut()
			if not Pentagram then return end
			for _, v in ipairs(Pentagram:GetChildren()) do
				if v.Name == "BeamFlat" then
					task.delay(v:GetAttribute("Delay") or 0, function()
						TweenService:Create(
							v,
							TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
							{ Brightness = 0 }
						):Play()
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

		local initColor = Color3.fromRGB(137, 207, 255)
		if Repentance.QueryDescendants then
			for _, v in next, Repentance:QueryDescendants(".GiveMeColor") do
				if v:IsA("Light") or v:IsA("BasePart") then
					v.Color = initColor
				elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then
					v.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, initColor),
						ColorSequenceKeypoint.new(1, initColor)
					})
				end
			end
		end

		if Pentagram and Pentagram:FindFirstChild("Circle") then
			TweenService:Create(
				Pentagram.Circle,
				TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
				{ CFrame = Pentagram.Circle.CFrame - Vector3.new(0, 25, 0) }
			):Play()
			task.delay(2, function()
				if Pentagram.Circle and Pentagram.Circle.Parent then
					Pentagram.Circle:Destroy()
				end
			end)
		end

		if Handle and Handle:FindFirstChild("BodyPosition") then
			Handle.BodyPosition.Position = (character:GetPivot() * CFrame.new(1, 4, -6)).Position
		end

		if Handle and Handle:FindFirstChild("BodyAngularVelocity") then
			TweenService:Create(
				Handle.BodyAngularVelocity,
				TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
				{ AngularVelocity = Vector3.new(0, 40, 0) }
			):Play()
		end

		task.delay(3, function()
			if Handle and Handle:FindFirstChild("Shards") then
				for _, shard in next, Handle.Shards:GetChildren() do
					shard.CollisionGroup = "NoPlayer"
					shard.CanCollide = true
					if shard:FindFirstChild("Weld") then
						shard.Weld:Destroy()
					end
					shard.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end)

		waitUntil(4)

		if Handle and Handle:FindFirstChild("BodyAngularVelocity") then
			TweenService:Create(
				Handle.BodyAngularVelocity,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ AngularVelocity = Vector3.zero }
			):Play()
		end

		if Pentagram and Pentagram:FindFirstChild("Base") and Pentagram.Base:FindFirstChild("LightAttach") and Pentagram.Base.LightAttach:FindFirstChild("LightBright") then
			TweenService:Create(
				Pentagram.Base.LightAttach.LightBright,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) }
			):Play()
		end

		if Handle and Handle:FindFirstChild("Light") then
			TweenService:Create(
				Handle.Light,
				TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
				{ Brightness = 0, Range = 0, Color = Color3.fromRGB(255, 116, 130) }
			):Play()
		end

		task.spawn(function()
			local colorVal = Instance.new("Color3Value")
			colorVal.Value = Color3.fromRGB(137, 207, 255)

			local colorTween = TweenService:Create(
				colorVal,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Value = Color3.fromRGB(255, 116, 130) }
			)
			colorTween:Play()

			while colorTween.PlaybackState == Enum.PlaybackState.Playing and Repentance.Parent do
				for _, d in next, Repentance:GetDescendants() do
					if d.ClassName == "Beam" then
						d.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, colorVal.Value),
							ColorSequenceKeypoint.new(1, colorVal.Value)
						})
					elseif d.Name == "Glow" and d:IsA("BasePart") then
						d.Color = colorVal.Value
					end
				end
				task.wait()
			end
			colorVal:Destroy()
		end)

		waitUntil(9.625)

		if Handle and Handle:FindFirstChild("Glow") then
			TweenService:Create(
				Handle.Glow,
				TweenInfo.new(1),
				{ Size = Handle.Glow.Size * 3, Transparency = 1 }
			):Play()
		end

		if Pentagram and Pentagram:FindFirstChild("Base") and Pentagram.Base:FindFirstChild("LightAttach") and Pentagram.Base.LightAttach:FindFirstChild("LightBright") then
			TweenService:Create(
				Pentagram.Base.LightAttach.LightBright,
				TweenInfo.new(1),
				{ Brightness = 0, Range = 0 }
			):Play()
		end

		if Handle and Handle:FindFirstChild("Light") then
			TweenService:Create(
				Handle.Light,
				TweenInfo.new(1),
				{ Brightness = 0, Range = 0 }
			):Play()
		end

		fadeOut()
		task.delay(5, function()
			if Repentance and Repentance.Parent then
				Repentance:Destroy()
			end
		end)
	else
		task.wait(2)
	end

	-- Thánh giá fail xong: bật lại sát thương bình thường
	crucifixFailed = true
	isBanishing = false
	lookDamageEnabled = true
	damageEnabled = true

	-- Trục xuất xong: thấy người chơi trong tầm mắt và không nấp trong tủ thì đuổi tiếp
	if not isDeactivated and not hit and not character:GetAttribute("Hiding") and CanSeePlayer(120) then
		StartChasePlayer()
	end
end

-- Theo dõi cầm Thánh Giá + Raycast vật cản để kích hoạt trục xuất fail
task.spawn(function()
	while task.wait(0.1) do
		if isDeactivated or hit or crucifixFailed then break end
		if not isBanishing and ambush and ambush.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
			local equipped = character:FindFirstChildOfClass("Tool")
			if equipped and equipped.Name:lower():find("crucifix") and CanSeePlayer(40) then
				pcall(function() equipped:Destroy() end)
				PlayFailedCrucifixAnim()
				break
			end
		end
	end
end)

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
		Enabled = false,
		Range = 40,
		Resist = true,
		Break = false
	},
	Death = {
		Type = "Guiding",
		Hints = {"Claim has seen you.", "It will consume anyone on sight.", "Do not look at it directly for too long!"},
		Cause = "DeerGod"
	}
})

entity:SetCallback("OnSpawned", function()
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
		if not lookDamageEnabled or isBanishing then continue end

		local origin = ambush.Position
		local direction = (HumanoidRootPart.Position - origin).Unit
		local ray = Ray.new(origin, direction * 5050)
		local cast = Workspace:Raycast(ray.Origin, ray.Direction)

		if cast and cast.Instance and cast.Instance.Parent == character then
			local _, onScreen = Workspace.CurrentCamera:WorldToScreenPoint(ambush.Position)
			if onScreen and not character:GetAttribute("Hiding") then
				local hum = character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(8)
				end
			end
		end
	end
end)

-- Mechanism: Kill/Jumpscare on Close Hitbox
task.spawn(function()
	while task.wait(0.2) do
		if hit or isDeactivated or not ambush.Parent then break end
		if not damageEnabled or isBanishing then continue end

		local hitbox = 9
		local origin = ambush.Position
		local direction = (HumanoidRootPart.Position - origin).Unit
		local ray = Ray.new(origin, direction * hitbox)
		local result = Workspace:Raycast(ray.Origin, ray.Direction)

		if result and result.Instance and result.Instance.Parent == character and not character:GetAttribute("Hiding") then
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
						deathCause.Value = "DeerGod"
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

-- Tracking Line of Sight: thấy người chơi và không ở trong tủ thì bật StartChasePlayer
task.spawn(function()
	while task.wait(0.25) do
		if hit or isDeactivated or not ambush.Parent then break end
		if isBanishing or isChasingPlayer or character:GetAttribute("Hiding") then continue end

		if CanSeePlayer(65) then
			StartChasePlayer()
		end
	end
end)

-- Set CFrame khởi tạo ở phòng đằng sau (room5)
if room5 and room5:FindFirstChild("RoomEntrance") then
	ambush.CFrame = room5.RoomEntrance.CFrame
elseif room and room:FindFirstChild("RoomEntrance") then
	ambush.CFrame = room.RoomEntrance.CFrame * CFrame.new(0, 0, 50)
end

-- Di chuyển Deer God qua các phòng theo vận tốc ổn định (không phóng nhanh khi khoảng cách xa)
local function MoveToCFrameAtSpeed(targetCFrame, moveSpeed)
	if not ambush or not ambush.Parent or hit or isDeactivated then return end

	local startPos = ambush.Position
	local goalPos = targetCFrame.Position
	local dist = (goalPos - startPos).Magnitude
	local duration = math.max(dist / math.max(moveSpeed, 1), 0.05)

	if currentTween then pcall(function() currentTween:Cancel() end) end
	currentTween = TweenService:Create(
		ambush,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)
	currentTween:Play()

	while currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing do
		if hit or isDeactivated or isBanishing or (isChasingPlayer and not character:GetAttribute("Hiding")) then
			pcall(function() currentTween:Cancel() end)
			break
		end
		task.wait(0.05)
	end
end

task.spawn(function()
	local function waitIfPaused()
		while (isBanishing or (isChasingPlayer and not character:GetAttribute("Hiding"))) and not hit and not isDeactivated do
			task.wait(0.1)
		end
	end

	local function moveToRoom(targetRoom)
		if hit or isDeactivated or not targetRoom or not targetRoom:FindFirstChild("RoomEntrance") then return end
		while not hit and not isDeactivated do
			waitIfPaused()
			if hit or isDeactivated then return end

			local goalCF = targetRoom.RoomEntrance.CFrame
			if (ambush.Position - goalCF.Position).Magnitude <= 1.5 then
				return
			end

			MoveToCFrameAtSpeed(goalCF, patrolSpeed)
			if not (isBanishing or (isChasingPlayer and not character:GetAttribute("Hiding"))) and (ambush.Position - goalCF.Position).Magnitude <= 2.5 then
				return
			end
		end
	end

	moveToRoom(room4)
	moveToRoom(room3)
	moveToRoom(room2)
	moveToRoom(room1)
	moveToRoom(room)
	moveToRoom(nextroom)

	if not hit and not isDeactivated and nextroom and nextroom:FindFirstChild("RoomExit") then
		while not hit and not isDeactivated do
			waitIfPaused()
			if hit or isDeactivated then break end

			local exitCF = nextroom.RoomExit.CFrame
			if (ambush.Position - exitCF.Position).Magnitude <= 1.5 then
				break
			end

			MoveToCFrameAtSpeed(exitCF, patrolSpeed)
			if not (isBanishing or (isChasingPlayer and not character:GetAttribute("Hiding"))) and (ambush.Position - exitCF.Position).Magnitude <= 2.5 then
				break
			end
		end
	end

	-- Chỉ cấp thành tựu & Destroy khi đi hết đường bình thường mà không hề vào chế độ đuổi/chạm
	if not hit and not isDeactivated and not hasEnteredChaseMode then
		GiveDeerGodAchievement()
		CleanupEntity()
	end
end)
