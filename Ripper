--========================================================--
--      RIPPER SYSTEM + PUSHABLE OBJECTS & FULL SOUNDS   --
--              OgHungerNewSpawner Version               --
--========================================================--

getgenv().Ripper29Loaded = nil

-- TẠO BIẾN TOÀN CỤC KHÓA THÀNH TỰU DÙ SCRIPT CÓ XẢY RA LỖI HOẶC CHẠY LẠI
if getgenv().RipperAchievementEarned == nil then
	getgenv().RipperAchievementEarned = false
end

--========================================================--
-- SERVICES
--========================================================--

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- SETTINGS
--========================================================--

local ripperActive = false
local processedRooms = {}
local ripperIsMoving = false -- Biến cờ kiểm tra xem thực thể đã bắt đầu di chuyển hay chưa
local activeRipperModel = nil -- Biến lưu trữ Model của Ripper để tính khoảng cách

--========================================================--
-- ONE TIME CONTROL
--========================================================--

local hasSpawnedOnce = false
local waitingForFirstNewRoom = true

--========================================================--
-- LOAD SPAWNER
--========================================================--

local success, Spawner = pcall(function()
	return loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/eoyoustme/Mayhem-Remake/refs/heads/main/OgHungerNewSpawner"
	))()
end)

if not success or not Spawner then
	warn("[RIPPER] Cannot load OgHungerNewSpawner")
	return
end

print("[RIPPER] Spawner loaded")

--========================================================--
-- HELPER: GET GIT SOUND (TẢI ÂM THANH TỪ GITHUB)
--========================================================--

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

--========================================================--
-- ROOM RED LIGHTING LOGIC (LÀM ĐỎ CĂN PHÒNG)
--========================================================--

local originalLightColors = {}
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

local function SetRoomRed(enable)
	if enable then
		originalAmbient = Lighting.Ambient
		originalOutdoorAmbient = Lighting.OutdoorAmbient
		
		TweenService:Create(Lighting, TweenInfo.new(1), {
			Ambient = Color3.fromRGB(150, 0, 0),
			OutdoorAmbient = Color3.fromRGB(100, 0, 0)
		}):Play()

		local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
		if CurrentRooms then
			for _, room in ipairs(CurrentRooms:GetChildren()) do
				for _, obj in ipairs(room:GetDescendants()) do
					if obj:IsA("Light") then
						if not originalLightColors[obj] then
							originalLightColors[obj] = obj.Color
						end
						TweenService:Create(obj, TweenInfo.new(1), {
							Color = Color3.fromRGB(255, 0, 0)
						}):Play()
					end
				end
			end
		end
	else
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Ambient = originalAmbient,
			OutdoorAmbient = originalOutdoorAmbient
		}):Play()

		for light, color in pairs(originalLightColors) do
			if light and light.Parent then
				TweenService:Create(light, TweenInfo.new(1.5), {
					Color = color
				}):Play()
			end
		end
		table.clear(originalLightColors)
	end
end

--========================================================--
-- SOUNDS
--========================================================--

local introSound = Instance.new("Sound")
introSound.Name = "RipperIntro"
introSound.SoundId = "rbxassetid://12971875415"
introSound.Volume = 2
introSound.Parent = SoundService

local doorSound1 = Instance.new("Sound")
doorSound1.SoundId = "rbxassetid://9126281820"
doorSound1.Volume = 3
doorSound1.Parent = SoundService

local doorSound2 = Instance.new("Sound")
doorSound2.SoundId = "rbxassetid://9126281769"
doorSound2.Volume = 3
doorSound2.Parent = SoundService

local doorSound3 = Instance.new("Sound")
doorSound3.SoundId = "rbxassetid://126631007956569"
doorSound3.Volume = 3
doorSound3.Parent = SoundService

--========================================================--
-- ADVANCED ROOM OBJECT BREAK & PUSHABLE PHYSICS SYSTEM
--========================================================--

local CurrentRooms = workspace:WaitForChild("CurrentRooms")

-- Danh sách tất cả các âm thanh phá hủy sẽ được chạy hết lượt
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

local function shakeCollision(collision)
	if not collision or collision.Anchored then return end
	
	-- CHẠY HẾT TẤT CẢ ÂM THANH TRONG MẢNG BREAKSOUNDS
	pcall(function()
		for _, soundId in ipairs(breakSounds) do
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Volume = math.random(12, 24) / 10
			sound.PlaybackSpeed = math.random(85, 115) / 100
			sound.RollOffMaxDistance = 100
			sound.Parent = collision
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
	end)

	local mass = collision.AssemblyMass
	local force = mass * 8

	for i = 1, 8 do
		if collision.Parent and not collision.Anchored then
			local look = collision.CFrame.LookVector
			look = Vector3.new(look.X, 0, look.Z)
			if look.Magnitude > 0 then
				look = look.Unit
				local angle = math.rad(math.random(-60, 60))
				local direction = CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(look)
				direction = Vector3.new(direction.X, 0, direction.Z).Unit

				collision:ApplyImpulse(direction * force)
				collision:ApplyAngularImpulse(Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)) * mass * 15)
			end
			task.wait(0.03)
		end
	end
end

local function setupModel(model, room, targets)
	if not model:IsA("Model") or isBlacklisted(model) or hasTargetParent(model, room) then return end

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

	if existingCollision then table.insert(targets, existingCollision) return end
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
	collision:SetAttribute("Picked", false)
	collision.Parent = model

	table.insert(targets, collision)

	collision:GetPropertyChangedSignal("Anchored"):Connect(function()
		if not collision.Anchored then
			pcall(function()
				if collision:CanSetNetworkOwnership() then
					collision:SetNetworkOwner(LocalPlayer)
				end
			end)
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
	if not room or processedRooms[room] then return end
	processedRooms[room] = true

	task.spawn(function()
		task.wait(0.05)
		local assets = room:FindFirstChild("Assets") or room

		local mainBreak = Instance.new("Sound")
		mainBreak.SoundId = "rbxassetid://9114223171"
		mainBreak.Volume = 2.5
		mainBreak.Parent = assets
		mainBreak:Play()
		mainBreak.Ended:Connect(function() mainBreak:Destroy() end)

		-- CHỈ PHÁT ÂM THANH PHÁ ĐỒ THEO CƠ CHẾ KHOẢNG CÁCH (DISTANCE CHECK <= 100 STUD)
		if ripperIsMoving then
			local gitUrls = {
				{ "https://github.com/cakmay227-svg/random/raw/refs/heads/main/XRecorder_Edited_20260801_01.mp3?raw=true", "jjjciie" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Ripper%20bresking%20stuff%202.mp3", "kdjjccj" },
				{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/RipperBreakingstuff3.mp3", "jckdkxjchjjdj" }
			}
			local pick = gitUrls[math.random(1, #gitUrls)]
			local gitSound = GetGitSound(pick[1], pick[2])
			
			if gitSound then
				local breaking = Instance.new("Sound")
				breaking.SoundId = gitSound.SoundId
				breaking.PlaybackSpeed = 1
				breaking.Parent = assets
				breaking.Looped = false
				breaking.RollOffMaxDistance = 1000
				breaking.Volume = 6

				task.spawn(function()
					local ripe = activeRipperModel and (activeRipperModel:FindFirstChild("Ripe") or activeRipperModel.PrimaryPart)
					local conn
					conn = RunService.Heartbeat:Connect(function()
						local character = LocalPlayer.Character
						local hrp = character and character:FindFirstChild("HumanoidRootPart")
						
						if not hrp or not ripe or not breaking.Parent then
							if conn then conn:Disconnect() end
							return
						end

						-- KIỂM TRA KHOẢNG CÁCH DƯỚI 100 STUD MỚI PHÁT ÂM THANH
						local inRange = (ripe.Position - hrp.Position).Magnitude <= 100
						if inRange then
							if not breaking.IsPlaying then
								breaking:Play()
							end
						else
							if breaking.IsPlaying then
								breaking:Stop()
							end
						end
					end)

					breaking.Ended:Connect(function()
						if conn then conn:Disconnect() end
						breaking:Destroy()
					end)
				end)
			end
		end

		local targets = {}
		for _, v in ipairs(room:GetDescendants()) do
			if v:IsA("Model") then
				setupModel(v, room, targets)
			end
		end

		for _, collision in ipairs(targets) do
			if collision and collision.Parent and collision:GetAttribute("WindCollision") == true then
				collision.Anchored = false
			end
		end
	end)
end

--========================================================--
-- ACHIEVEMENT (CHỈ LẤY 1 LẦN DÙNG GETGENV)
--========================================================--

local function GiveAchievement()
	if getgenv().RipperAchievementEarned then
		return
	end

	getgenv().RipperAchievementEarned = true

	task.spawn(function()
		local ok, achievementGiver =
			pcall(function()
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
				Image = "rbxassetid://12231244908"
			})
		end)

		print("[RIPPER] Achievement granted successfully (LOCKED FOR THIS SESSION)")
	end)
end

--========================================================--
-- CREATE RIPPER
--========================================================--

local function SpawnRipper()
	if ripperActive then
		return
	end

	if hasSpawnedOnce then
		return
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	hasSpawnedOnce = true
	ripperActive = true
	ripperIsMoving = false -- Reset trạng thái di chuyển khi spawn

	print("[RIPPER] ONE TIME SPAWN")

	local ok, entity = pcall(function()
		return Spawner:Create({
			Entity = {
				Name = "Ripper Entity",
				Asset = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_131351567799504_Model_RipperMovingkkd_1791822177.txt",
				HeightOffset = 4.5
			},

			Lights = {
				Flicker = {
					Enabled = true,
					Duration = 1
				},
				Shatter = true,
				Repair = false
			},

			Earthquake = {
				Enabled = true
			},

			CameraShake = {
				Enabled = true,
				Range = 100,
				Values = {1.5, 40, 0.1, 1}
			},

			Movement = {
				Speed = 180,
				SpeedFast = 1700,
				MoveFastNotEnter = false,
				Delay = 2,
				Reversed = false,
				EndWhenEnterLatestRoom = false,
				EndDelay = 0,

				ReboundMoving = false,
				TweenSecond = 1.5,

				ReboundMoveStyle = false,
				ReboundStyleTimes = 3,

				ReboundStyleSound = "rbxassetid://130994177179386",
				ReboundStyleVolume = 5
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
					Max = 1
				},
				Flashing = {
					[1] = true,
					[2] = Color3.fromRGB(255, 255, 255)
				},
				Shake = true
			},

			Rebounding = {
				Enabled = false,
				Type = "Ambush",
				Min = 1,
				Max = 1,
				Delay = 2
			},

			Damage = {
				Enabled = true,
				KillOnMove = false,
				Range = 40,
				Amount = 125,
				IgnoreHiding = false,

				JumpscareRipper = {
					Enabled = true,
					TargetPartName = "Ripe",
					AttachmentName = "ripe",
					ParticleName = "ParticleEmitter",
					ParticleTexture = "rbxassetid://12737595583",
					SoundUrl = "https://github.com/eoyoustme/back/raw/main/Kill_with_static.mp3",
					SlamSoundId = "rbxassetid://1837829565",
					EndSoundId = "rbxassetid://4988621968",
					Images = {
						"rbxassetid://8482795900",
						"rbxassetid://236542974",
						"rbxassetid://184251462",
						"rbxassetid://236777652"
					},
					FlashDuration = 1.6
				}
			},

			Crucifixion = {
				Enabled = true,
				Range = 45,
				Resist = false,
				Break = true
			},

			Death = {
				Type = "Guiding",
				Cause = "Ripper"
			}
		})
	end)

	if not ok or not entity then
		warn("[RIPPER] Entity creation failed")
		ripperActive = false
		hasSpawnedOnce = true
		return
	end

	entity:SetCallback("OnSpawned", function()
		print("[RIPPER] Entity spawned")
		activeRipperModel = entity.Model -- Lưu lại reference model để kiểm tra khoảng cách
		SetRoomRed(true)
		introSound:Stop()
		introSound.TimePosition = 0
		introSound:Play()
	end)

	-- KHI THỰC THỂ BẮT ĐẦU DI CHUYỂN -> BẬT CỜ ripperIsMoving THÀNH TRUE
	entity:SetCallback("OnStartMoving", function()
		print("[RIPPER] Moving")
		ripperIsMoving = true
	end)

	entity:SetCallback(
		"OnEnterRoom",
		function(room, firstTime)
			doorSound1:Play()
			doorSound2:Play()
			BreakRoom(room)
		end
	)

	entity:SetCallback("OnLookAt", function(lineOfSight) end)
	entity:SetCallback("OnRebounding", function(startOfRebound) end)
	entity:SetCallback("EndWhenGO", function() end)

	entity:SetCallback(
		"OnDespawning",
		function()
			print("[RIPPER] Despawning")
			SetRoomRed(false)
			doorSound3:Play()

			pcall(function()
				local gameData = ReplicatedStorage:FindFirstChild("GameData")
				local latestRoomVal = gameData and gameData:FindFirstChild("LatestRoom")
				
				if latestRoomVal then
					local currentRooms = workspace:FindFirstChild("CurrentRooms")
					local latestRoom = currentRooms and currentRooms:FindFirstChild(tostring(latestRoomVal.Value))
					
					if latestRoom and latestRoom:FindFirstChild("Door") and latestRoom.Door:FindFirstChild("ClientOpen") then
						latestRoom.Door.ClientOpen:FireServer()
					end
				end
			end)
		end
	)

	entity:SetCallback(
		"OnDespawned",
		function()
			print("[RIPPER] Despawned")
			ripperActive = false
			ripperIsMoving = false
			activeRipperModel = nil

			introSound:Stop()
			doorSound1:Stop()
			doorSound2:Stop()
			doorSound3:Stop()

			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 then
				GiveAchievement()
			end
		end
	)

	entity:SetCallback("OnDamagePlayer", function(newHealth)
		print("[RIPPER] Player damaged:", newHealth)
	end)

	task.spawn(function()
		task.wait(0.1)
		local runOK, runError = pcall(function()
			entity:Run(true)
		end)

		if not runOK then
			warn("[RIPPER] Run failed:", runError)
			ripperActive = false
			ripperIsMoving = false
			activeRipperModel = nil
		end
	end)
end

--========================================================--
-- ROOM NUMBER & DETECTION
--========================================================--

local highestRoom = -1

local function GetRoomNumber(room)
	if not room then return nil end
	local attribute = room:GetAttribute("RoomNumber")
	if typeof(attribute) == "number" then return attribute end
	return tonumber(room.Name)
end

for _, room in ipairs(CurrentRooms:GetChildren()) do
	local number = GetRoomNumber(room)
	if number and number > highestRoom then
		highestRoom = number
	end
end

print("[RIPPER] Current room:", highestRoom)

local function NewRoom(room)
	local roomNumber = GetRoomNumber(room)
	if not roomNumber or roomNumber <= highestRoom then return end

	highestRoom = roomNumber
	print("[RIPPER] New room:", roomNumber)

	if hasSpawnedOnce then return end

	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	print("[RIPPER] FIRST NEW ROOM - SPAWNING")
	task.spawn(function()
		SpawnRipper()
	end)
end

CurrentRooms.ChildAdded:Connect(function(room)
	task.spawn(function()
		task.wait(0.15)
		NewRoom(room)
	end)
end)

task.spawn(function()
	while task.wait(0.5) do
		if hasSpawnedOnce then continue end
		local newest = highestRoom
		local newestRoom = nil

		for _, room in ipairs(CurrentRooms:GetChildren()) do
			local number = GetRoomNumber(room)
			if number and number > newest then
				newest = number
				newestRoom = room
			end
		end

		if newestRoom then
			NewRoom(newestRoom)
		end
	end
end)
