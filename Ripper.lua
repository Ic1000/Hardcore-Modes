-- ========================================================
--         RIPPER BLA SCRIPT (CLEANED & OPTIMIZED)
-- ========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local blaSound -- Biến blaSound theo yêu cầu của fen
local speed = getgenv().FasterTrouble and 225 or 180

-- Hàm tải âm thanh từ GitHub (chuẩn hóa 1 hàm duy nhất)
local function GetGitSound(GithubSnd, SoundName)
	if not isfile(SoundName .. ".mp3") then
		pcall(function()
			writefile(SoundName .. ".mp3", game:HttpGet(GithubSnd))
		end)
	end
	local sound = Instance.new("Sound")
	pcall(function()
		sound.SoundId = (getcustomasset or getsynasset)(SoundName .. ".mp3")
	end)
	return sound
end

-- Khởi tạo blaSound
local gitSoundTemp2 = GetGitSound("https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/XRecorder_Edited_20260810_01.mp3?raw=true", "jjcjfjjc")
blaSound = Instance.new("Sound")
if gitSoundTemp2 then
	blaSound.SoundId = gitSoundTemp2.SoundId
end
blaSound.PlaybackSpeed = 1
blaSound.Looped = false
blaSound.TimePosition = 0
blaSound.Volume = 3.5
blaSound.RollOffMaxDistance = 150
blaSound.Ended:Connect(function()
	blaSound:Destroy()
end)

if getgenv().RipperAchievementEarned == nil then
	getgenv().RipperAchievementEarned = false
end

-- Hàm đổi màu đèn
function light(tim, color0, color1)
	local info = TweenInfo.new(tim, Enum.EasingStyle.Linear)
	for _, l in pairs(Workspace.CurrentRooms:GetDescendants()) do
		if l:IsA("Light") or l:IsA("SurfaceLight") or l:IsA("SpotLight") then
			TweenService:Create(l, info, {Color = color1}):Play()
		elseif l:IsA("MeshPart") and l.Material == Enum.Material.Neon and l.Name ~= "Skybox" then
			TweenService:Create(l, info, {Color = color0}):Play()
		end
	end
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

local LocalPlayer = Players.LocalPlayer

-- Load spawner
local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/iccdjkkkkskskhdgdgegvbfbgncjjdudejdjvi/REBLAHARDCOREDI/refs/heads/main/eipperspawne"))()

-- Tạo Entity
local entity = Spawner:Create({
	Entity = {
		Name = "RipperBla",
		Asset = "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Place_131351567799504_Model_RipperMovingkkd_1791822177.txt",
		HeightOffset = 4
	},
	Lights = {
		Flicker = { Enabled = false, Duration = 1 },
		Shatter = false,
		Repair = false
	},
	Earthquake = { Enabled = false },
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {10, 27, 0.1, 0.4}
	},
	Movement = {
		Speed = speed,
		Delay = 4,
		Reversed = false
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
		Range = 50,
		Amount = 0.001
	},
	Crucifixion = {
		Enabled = true,
		Range = 50,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"Death", "Hints", "Go", "Here"},
		Cause = "Ripper"
	}
})

-- Callbacks
entity:SetCallback("OnSpawned", function()
	print("Entity has spawned")
	
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

entity:SetCallback("OnStartMoving", function()
	print("Entity has started moving")
	
	local entityModel = entity.Model
	local ripe = entityModel and entityModel:FindFirstChild("Ripe")
	
	local urls = {
		{ "https://github.com/cakmay227-svg/random/raw/refs/heads/main/XRecorder_Edited_20260801_01.mp3?raw=true", "jjjciie" },
		{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/Ripper%20bresking%20stuff%202.mp3", "kdjjccj" },
		{ "https://github.com/lynguyen26031993-design/-u/raw/refs/heads/main/RipperBreakingstuff3.mp3", "jckdkxjchjjdj" }
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
			if not hrp or not ripe or not breaking.Parent then
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
	
	loadstring(game:HttpGet("https://raw.githubusercontent.com/iccdjkkkkskskhdgdgegvbfbgncjjdudejdjvi/REBLAHARDCOREDI/refs/heads/main/Flingingstuff"))()
end)

entity:SetCallback("OnDamagePlayer", function(newHealth)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then humanoid.Health = 100 end

	local model = Workspace:WaitForChild("RipperBla")
	local part = model.Ripe
	assert(part, "Model chưa có PrimaryPart!")

	part.Anchored = true
	task.wait(0.7)

	if not LocalPlayer.Character:GetAttribute("Hiding") then
		task.spawn(function()
			local hum = character:WaitForChild("Humanoid", 5)
			local hrp = character:WaitForChild("HumanoidRootPart")
			local camera = Workspace.CurrentCamera
			local entityModel = Workspace:WaitForChild("RipperBla")
			local primaryPart = entityModel:FindFirstChild("Ripe")

			if not (entityModel and hum and hrp and primaryPart and camera) then return end

			local originalWalkSpeed = hum.WalkSpeed
			local originalJumpPower = hum.JumpPower
			hum.WalkSpeed = 0
			hum.JumpPower = 0

			local controlsModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
			controlsModule:Disable()

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
			local lerpSpeed = 4

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
				Jumpscare.Parent = Workspace
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
			TweenService:Create(Alpha, TweenInfo.new(2), {Value = 0}):Play()
			if Static and Static:IsA("Sound") then
				TweenService:Create(Static, TweenInfo.new(2), {Volume = 3}):Play()
			end

			task.wait(2)
			UI.Visible = false
			if Connection then Connection:Disconnect() end
			if Static and Static:IsA("Sound") then
				TweenService:Create(Static, TweenInfo.new(1), {Volume = 0}):Play()
			end

			for i = 0, 11 do
				local Img = UI:FindFirstChild("GrainImage" .. tostring(i))
				if Img then Img.ImageTransparency = 1 end
			end
			Alpha:Destroy()

			task.wait()
			if hum then hum.Health = 0 end

			pcall(function()
				ReplicatedStorage.GameStats["Player_" .. LocalPlayer.Name].Total.DeathCause.Value = "Ripper"
			end)

			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://4988621968"
			sound.Volume = 7
			sound.PlaybackSpeed = 0.6
			sound.Parent = Workspace
			sound:Play()

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
	end
end)

-- Chạy entity
entity:Run(true)
