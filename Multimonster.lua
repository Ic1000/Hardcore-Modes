-- ========================================================
--                  SERVICES & KHAI BÁO TOÀN CỤC            --
-- ========================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local debounce = false
local isJumpscaring = false
local totalRoomsBroken = 0
local multimonsterIsMoving = false

-- Biến lưu trữ hướng di chuyển của thực thể (tính theo frame)
local entityLastPosition = nil
local entityMoveDirection = Vector3.new(0, 0, -1) -- Hướng mặc định

-- DANH SÁCH ẢNH JUMPSCARE 2D
local ALL_JUMPSCARE_IMAGES = {
	"rbxassetid://114943702871183",
	"rbxassetid://77042919484581",
	"rbxassetid://113785746563976",
	"rbxassetid://106324997569765",
	"rbxassetid://93365716697080",
	"rbxassetid://72735059720396"
}

--========================================================--
--                  HELPER FUNCTIONS                      --
--========================================================--
local function GetGitSound(GithubSnd, SoundName)
	pcall(function()
		if not isfile or not isfile(SoundName .. ".mp3") then
			writefile(SoundName .. ".mp3", game:HttpGet(GithubSnd))
		end
	end)
	
	local sound = Instance.new("Sound")
	local assetFunc = getcustomasset or getsynasset
	local success = false
	if assetFunc then
		pcall(function()
			sound.SoundId = assetFunc(SoundName .. ".mp3")
			success = true
		end)
	end
	if not success then
		sound.SoundId = GithubSnd
	end
	return sound
end

local doorSound1 = Instance.new("Sound")
doorSound1.SoundId = "rbxassetid://9126281820"
doorSound1.Volume = 3
doorSound1.Parent = SoundService

local doorSound2 = Instance.new("Sound")
doorSound2.SoundId = "rbxassetid://9126281769"
doorSound2.Volume = 3
doorSound2.Parent = SoundService

-- Tải CustomAchievements theo đúng chuẩn hàm của Vynixu
local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()

-- Dùng biến Global (getgenv) để khóa vĩnh viễn, chống nhận trùng lặp trong cả ván chơi
if getgenv().MultimonsterAchievementGiven == nil then
	getgenv().MultimonsterAchievementGiven = false
end

local function GiveMultimonsterAchievement()
	if not getgenv().MultimonsterAchievementGiven then
		getgenv().MultimonsterAchievementGiven = true -- Đánh dấu đã nhận vĩnh viễn cho màn này
		pcall(function()
			achievementGiver({
				Title = "Speed Demon",
				Desc = "Outrun the unstoppable force.",
				Reason = "Survive the rare Entity called Multimonster",
				Image = "rbxassetid://132714224363069"
			})
		end)
	end
end

--========================================================--
-- ADVANCED DIRECTIONAL PUSHABLE ROOM BREAK               --
--========================================================--
local CurrentRooms = Workspace:WaitForChild("CurrentRooms")
local breakSounds = {
	"rbxassetid://9125992545",
	"rbxassetid://4004052860",
	"rbxassetid://7142857558",
	"rbxassetid://7142843615",
	"rbxassetid://2612674531",
	"rbxassetid://2174790942"
}

local blacklist = {
	"wardrobe", "rafter", "bed", "rug", "carpet", "sideroom", "key", 
	"drawer", "breaker", "table", "desk", "gold", "dresser", "rift", 
	"chest", "floor", "wall", "door", "ceiling", "light", "beam", 
	"model", "chandelier", "window", "curtain", "gate", "stairs", 
	"vent", "lattice", "barrelstack", "smoothie", "rolltop", "dupe", 
	"boards", "crucifix", "flashlight", "moonfloat", "lockpick", 
	"candle", "skeleton key", "fireplace"
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

local function shakeCollision(collision, customDir)
	if not collision or collision.Anchored then return end
	
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = breakSounds[math.random(1, #breakSounds)]
		sound.Volume = math.random(14, 26) / 10
		sound.PlaybackSpeed = math.random(80, 120) / 100
		sound.RollOffMaxDistance = 120
		sound.Parent = collision
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)

	local mass = collision.AssemblyMass
	local force = mass * 18 

	local pushDir = customDir or entityMoveDirection
	pushDir = Vector3.new(pushDir.X, math.clamp(pushDir.Y, 0.1, 0.5), pushDir.Z).Unit

	for i = 1, 8 do
		if collision.Parent and not collision.Anchored then
			local randomizedDir = (pushDir + Vector3.new(math.random(-20,20)/100, math.random(0,20)/100, math.random(-20,20)/100)).Unit
			collision:ApplyImpulse(randomizedDir * force)
			collision:ApplyAngularImpulse(Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3)) * mass * 20)
			task.wait(0.025)
		end
	end
end

local function setupModel(model, room, targets)
	if not model:IsA("Model") or isBlacklisted(model) or hasTargetParent(model, room) then return end

	local existingCollision

	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "Collision" and v:GetAttribute("WindCollision") == true then
			existingCollision = v
			break
		end
	end

	if existingCollision then 
		existingCollision.Anchored = false
		local currentPushDir = entityMoveDirection
		existingCollision.AssemblyLinearVelocity = (currentPushDir * math.random(80, 120)) + Vector3.new(0, math.random(20, 50), 0)
		existingCollision.AssemblyAngularVelocity = Vector3.new(
			math.random(-40, 40),
			math.random(-40, 40),
			math.random(-40, 40)
		)
		table.insert(targets, existingCollision) 
		return 
	end

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

	local density = math.clamp(10 / volume, 0.0001, 1)

	local collision = Instance.new("Part")
	collision.Name = "Collision"
	collision.Size = size - Vector3.new(0.4, 0.4, 0.4)
	collision.CFrame = cf + Vector3.new(0, 0.2, 0)
	collision.Transparency = 1
	collision.CanCollide = true
	collision.CanTouch = true
	collision.CanQuery = true
	collision.CastShadow = false
	collision.Anchored = true
	collision.Massless = false
	
	collision.CustomPhysicalProperties = PhysicalProperties.new(density, 0.01, 0.1, 1, 1)
	collision:SetAttribute("WindCollision", true)
	collision.Parent = model

	table.insert(targets, collision)

	collision:GetPropertyChangedSignal("Anchored"):Connect(function()
		if not collision.Anchored then
			pcall(function()
				if collision:CanSetNetworkOwnership() then
					collision:SetNetworkOwner(LocalPlayer)
				end
			end)
			task.spawn(shakeCollision, collision, entityMoveDirection)
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
	if not room then return end
	totalRoomsBroken = totalRoomsBroken + 1
	
	task.spawn(function()
		task.wait(0.02)
		local assetContainer = room:FindFirstChild("Assets") or room

		local breakSound = Instance.new("Sound")
		local breakSoundsList = {
			"rbxassetid://9114223171",
			"rbxassetid://9125992545", 
			"rbxassetid://4004052860",
			"rbxassetid://7142857558", 
			"rbxassetid://7142843615",
			"rbxassetid://2612674531", 
			"rbxassetid://2174790942"
		}

		if totalRoomsBroken == 1 then
			breakSound.SoundId = "rbxassetid://9114223171"
			breakSound.Volume = 4.5
		else
			breakSound.SoundId = breakSoundsList[math.random(1, #breakSoundsList)]
			breakSound.Volume = math.random(28, 38) / 10
		end

		breakSound.Parent = assetContainer
		breakSound:Play()
		breakSound.Ended:Connect(function() breakSound:Destroy() end)

		if multimonsterIsMoving then
			local gitUrls = {
				{ "https://github.com/cakmay227-svg/random/raw/refs/heads/main/XRecorder_Edited_20260801_01.mp3?raw=true", "jjjciie" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Ripper%20bresking%20stuff%202.mp3", "kdjjccj" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/RipperBreakingstuff3.mp3", "jckdkxjchjjdj" }
			}
			local pick = gitUrls[math.random(1, #gitUrls)]
			local gitSound = GetGitSound(pick[1], pick[2])
			if gitSound then
				gitSound.Parent = assetContainer
				gitSound.Volume = 5
				gitSound.PlaybackSpeed = 1
				gitSound.RollOffMaxDistance = 1000
				gitSound:Play()
				gitSound.Ended:Connect(function()
					gitSound:Destroy()
				end)
			end
		end

		local targets = {}
		for _, v in ipairs(room:GetDescendants()) do
			if v:IsA("Model") then
				setupModel(v, room, targets)
			end
		end

		local currentDir = entityMoveDirection
		for _, collision in ipairs(targets) do
			if collision and collision.Parent and collision:GetAttribute("WindCollision") == true then
				collision.Anchored = false
				collision.AssemblyLinearVelocity = (currentDir * math.random(70, 110)) + Vector3.new(0, math.random(25, 55), 0)
				collision.AssemblyAngularVelocity = Vector3.new(
					math.random(-35, 35),
					math.random(-35, 35),
					math.random(-35, 35)
				)
			end
		end
	end)
end

local function TriggerExtremeShake()
	task.spawn(function()
		pcall(function()
			local CameraShakerModule = require(ReplicatedStorage:WaitForChild("CameraShaker", 5))
			local camera = Workspace.CurrentCamera
			if CameraShakerModule and camera then
				local despawnShake = CameraShakerModule.new(Enum.RenderPriority.Camera.Value, function(cf)
					camera.CFrame = camera.CFrame * cf
				end)
				despawnShake:Start()
				despawnShake:ShakeOnce(35, 25, 0.05, 5)
			end
		end)
	end)
end

--========================================================--
--               CHECK ĐIỀU KIỆN XUẤT HIỆN                  --
--========================================================--
if Workspace:FindFirstChild("SeekMovingNewClone") or (Workspace:FindFirstChild("CurrentRooms") and (Workspace.CurrentRooms:FindFirstChild("50") or Workspace.CurrentRooms:FindFirstChild("100"))) then
	repeat task.wait() until not Workspace:FindFirstChild("SeekMovingNewClone") and not (Workspace:FindFirstChild("CurrentRooms") and (Workspace.CurrentRooms:FindFirstChild("50") or Workspace.CurrentRooms:FindFirstChild("100")))
end

---====== Load spawner ======---
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()

---====== Create entity ======---
local entity = spawner.Create({
	Entity = {
		Name = "multimonster",
		Asset = "rbxassetid://74103016339839",
		HeightOffset = 0
	},
	Lights = {
		Flicker = { Enabled = false, Duration = 1 },
		Shatter = false,
		Repair = false
	},
	Earthquake = { Enabled = false },
	CameraShake = {
		Enabled = true,
		Range = 150,
		Values = {18, 25, 0.05, 0.1}
	},
	Movement = {
		Speed = math.random(267, 350),
		Delay = math.random(1, 1.5),
		Reversed = false
	},
	Rebounding = {
		Enabled = true,
		Type = "Ambush",
		Min = 2,
		Max = math.random(5, 6),
		Delay = math.random(1, 2)
	},
	Damage = { Enabled = true, Range = 60, Amount = 125 },
	Crucifixion = {
		Enabled = true,
		Range = 50,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"You fell victim to Multimonster...", "It travels at terrifying speeds across multiple rooms...", "Listen closely for its loud approach and hide immediately...", "Do not let it catch you in its line of sight!..."},
		Cause = "Multimonster"
	}
})

---====== Callbacks ======---
entity:SetCallback("OnSpawned", function()
	print("multimonster has spawned")
	multimonsterIsMoving = false
	entityLastPosition = nil
	
	local part = Workspace:WaitForChild("multimonster", 5)
	if not part then return end

	local object = part:WaitForChild("RushNew", 5)
	if not object then return end
	
	RunService.RenderStepped:Connect(function()
		if part and part.Parent then
			local primaryPart = part.PrimaryPart
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
			"rbxassetid://12146135062", "rbxassetid://11378285585"
		}
		while part and part.Parent do
			if isJumpscaring then
				for _, tex in ipairs(textures) do
					if not isJumpscaring then break end
					e.Texture = tex
					task.wait(0.015)
				end
			else
				if e.Texture ~= originalTexture then
					e.Texture = originalTexture
				end
				task.wait(0.1)
			end
		end
	end)
end)

local runningGitSound = nil
entity:SetCallback("OnStartMoving", function()
	print("multimonster has started moving")
	multimonsterIsMoving = true

	task.spawn(function()
		local womp = Workspace:WaitForChild("multimonster", 5)
		if womp then
			local assetContainer = womp:FindFirstChild("RushNew") or womp
			local gitUrls = {
				{ "https://github.com/cakmay227-svg/random/raw/refs/heads/main/XRecorder_Edited_20260801_01.mp3?raw=true", "jjjciie" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Ripper%20bresking%20stuff%202.mp3", "kdjjccj" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/RipperBreakingstuff3.mp3", "jckdkxjchjjdj" }
			}
			local pick = gitUrls[math.random(1, #gitUrls)]
			runningGitSound = GetGitSound(pick[1], pick[2])
			if runningGitSound then
				runningGitSound.Parent = assetContainer
				runningGitSound.Volume = 5
				runningGitSound.PlaybackSpeed = 1
				runningGitSound.RollOffMaxDistance = 1000
				runningGitSound:Play()
				runningGitSound.Ended:Connect(function()
					runningGitSound:Destroy()
				end)
			end
		end
	end)
end)

entity:SetCallback("OnDamagePlayer", function(newHealth)
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local womp = Workspace:WaitForChild("multimonster", 2)
	
	if not womp then return end
	local wompwomp = womp:FindFirstChild("RushNew")
	if not wompwomp then return end

	if not character:GetAttribute("Hiding") and not debounce then
		debounce = true
		isJumpscaring = true
		
		pcall(function()
			for _, v in pairs(womp:GetDescendants()) do
				if v:IsA("Sound") and v.IsPlaying then
					v:Pause()
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
				if not isJumpscaring then
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
			scareSound.Volume = 5
			scareSound:Play()
			
			task.wait(0.5)
			
			for part, originalTransparency in pairs(savedTransparencies) do
				if part and part.Parent then
					part.Transparency = originalTransparency
				end
			end
			
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "A60_JumpscareGui"
			screenGui.Parent = player:WaitForChild("PlayerGui")
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
				Rotation = math.random(-25, 25)
			}):Play()
			
			task.wait(0.5)
			isJumpscaring = false						

			local function SafeCleanup()
				pcall(function()
					if screenGui then screenGui:Destroy() end
					if colorCorrection then colorCorrection:Destroy() end
					if scareSound then scareSound:Destroy() end
				end)
			end

			local fadeTween = TweenService:Create(jumpscareImg, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 })
			fadeTween:Play()
			
			TweenService:Create(colorCorrection, TweenInfo.new(0.5), {
				Brightness = 0,
				Contrast = 0,
				Saturation = 0,
				TintColor = Color3.fromRGB(255, 255, 255),
			}):Play()
			
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
	if room then
		doorSound1:Play()
		doorSound2:Play()
		BreakRoom(room)			
	end
end)

entity:SetCallback("OnDespawned", function()
	print("multimonster has despawned")
	TriggerExtremeShake()
	multimonsterIsMoving = false

	doorSound1:Stop()
	doorSound2:Stop()
	
	-- Cấp thành tựu sinh tồn thành công (được bảo vệ bằng Global Flag chống nhận trùng)
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
			Saturation = 0
		}):Play()
	end)
end)

entity:Run()
