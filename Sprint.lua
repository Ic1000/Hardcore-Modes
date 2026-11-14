local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Lấy RemotesFolder chuẩn của Doors
local remotesFolder = ReplicatedStorage:FindFirstChild("EntityInfo") or ReplicatedStorage:FindFirstChild("Bricks") or ReplicatedStorage:FindFirstChild("RemotesFolder")

-- Đọc cấu hình: chỉ giữ lại usewhileloading theo yêu cầu
local cfg = _G.mobile_sprint_config or {}
local CONFIG = {
	usewhileloading = cfg.usewhileloading ~= nil and cfg.usewhileloading or true,
	maxstamina = 150,
	staminadrain = 20,
	staminaregen = 15,
	regendelay = 1.5,
	sprintboost = 5,
	overlaydarkness = 0.4,
	soundvolume = 3,
}

local stamina = CONFIG.maxstamina
local isSprinting = false
local isExhausted = false
local lastSprintTime = 0

-- Tạo Sound Kiệt Sức
local soundExhausted = Instance.new("Sound")
soundExhausted.Name = "ExhaustedSound"
soundExhausted.SoundId = "rbxassetid://8258601891"
soundExhausted.Volume = CONFIG.soundvolume
soundExhausted.Looped = true
soundExhausted.Parent = player:WaitForChild("PlayerGui")

character:SetAttribute("SpeedBoost", 0)

-- Anti-Cheat Collision Bypass & Speed Bypass Hook
local CollisionClone = nil
local function SetupCollisionBypass(char)
	local root = char:WaitForChild("HumanoidRootPart")
	local collision = char:FindFirstChild("CollisionPart")
	
	if not collision then
		for _, part in pairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name:lower():find("collision") then
				collision = part
				break
			end
		end
	end
	if not collision then collision = root end

	CollisionClone = collision:Clone()
	CollisionClone.CanCollide = false
	CollisionClone.Massless = true
	CollisionClone.CanQuery = false
	CollisionClone.Name = "CollisionClone"
	
	if CollisionClone:FindFirstChild("CollisionCrouch") then
		CollisionClone.CollisionCrouch:Destroy()
	end
	CollisionClone.Parent = char

	task.spawn(function()
		while char and char.Parent do
			if root.Anchored then
				CollisionClone.Massless = true
				repeat task.wait() until not root.Anchored
				task.wait(0.15)
			else
				-- Luôn luôn bật Massless cho Speed Bypass
				CollisionClone.Massless = true
			end
			task.wait(0.24)
		end
	end)
end

SetupCollisionBypass(character)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	stamina = CONFIG.maxstamina
	isSprinting = false
	isExhausted = false
	CollisionClone = nil
	
	if soundExhausted.IsPlaying then
		soundExhausted:Stop()
	end
	character:SetAttribute("SpeedBoost", 0)
	SetupCollisionBypass(character)
end)

-- Cơ chế chạy ngầm Speed Bypass tự động 100% không cần bật tắt
task.spawn(function()
	while task.wait() do
		if CollisionClone then
			CollisionClone.Massless = true
		end
	end
end)

-- Mobile UI
if UserInputService.TouchEnabled then
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SprintGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999999
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local sprintButton = Instance.new("TextButton")
	sprintButton.Name = "SprintButton"
	sprintButton.Size = UDim2.new(0, 65, 0, 65)
	sprintButton.Position = UDim2.new(1, -206, 1, -103)
	sprintButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	sprintButton.BackgroundTransparency = 0.4
	sprintButton.Text = "Sprint"
	sprintButton.TextColor3 = Color3.fromRGB(224, 224, 224)
	sprintButton.TextSize = 16
	sprintButton.Font = Enum.Font.SourceSansBold
	sprintButton.ZIndex = 1
	sprintButton.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(1, 0)
	btnCorner.Parent = sprintButton

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(255, 255, 255)
	btnStroke.Thickness = 2
	btnStroke.Parent = sprintButton

	local staminaBg = Instance.new("Frame")
	staminaBg.Name = "StaminaBG"
	staminaBg.Size = UDim2.new(0, 220, 0, 14)
	staminaBg.Position = UDim2.new(1, -235, 1, -30)
	staminaBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	staminaBg.BackgroundTransparency = 0.3
	staminaBg.ZIndex = 1
	staminaBg.Parent = screenGui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = staminaBg

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.fromRGB(255, 255, 255)
	bgStroke.Thickness = 1.5
	bgStroke.Transparency = 0.5
	bgStroke.Parent = staminaBg

	local staminaBar = Instance.new("Frame")
	staminaBar.Name = "StaminaBar"
	staminaBar.Size = UDim2.new(1, 0, 1, 0)
	staminaBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	staminaBar.ZIndex = 1
	staminaBar.Parent = staminaBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = staminaBar

	local darkOverlay = Instance.new("Frame")
	darkOverlay.Name = "DarkOverlay"
	darkOverlay.Size = UDim2.new(1, 0, 1, 0)
	darkOverlay.Position = UDim2.new(0, 0, 0, 0)
	darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	darkOverlay.BackgroundTransparency = 1
	darkOverlay.ZIndex = 100
	darkOverlay.Active = false
	darkOverlay.Parent = screenGui

	local function stopSprinting()
		isSprinting = false
		if character then
			character:SetAttribute("SpeedBoost", 0)
		end
		
		if isExhausted then
			sprintButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			sprintButton.BackgroundTransparency = 0.7
		else
			sprintButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			sprintButton.BackgroundTransparency = 0.4
		end
	end

	local function startSprinting()
		if not humanoid or humanoid.Health <= 0 then return end
		if character and (character:GetAttribute("Hiding") == true or character:GetAttribute("Crouching") == true) then return end
		
		local isGameLoaded = game:IsLoaded()
		if not isGameLoaded and not CONFIG.usewhileloading then return end
		if isExhausted or stamina <= 0 then return end

		if (CONFIG.usewhileloading and not isGameLoaded) or (humanoid and humanoid.MoveDirection.Magnitude > 0) then
			isSprinting = true
			if character then
				character:SetAttribute("SpeedBoost", CONFIG.sprintboost)
			end
			sprintButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			sprintButton.BackgroundTransparency = 0.2
		end
	end

	sprintButton.Activated:Connect(function()
		if isSprinting then
			stopSprinting()
		else
			startSprinting()
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		local isCrouching = (character and character:GetAttribute("Crouching") == true)
		
		if not humanoid or humanoid.Health <= 0 or (character and character:GetAttribute("Hiding") == true) or isCrouching then
			if isSprinting then
				stopSprinting()
			end
			if soundExhausted.IsPlaying then
				soundExhausted:Stop()
			end
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		local currentHorizontalSpeed = 0
		if hrp then
			local velocity = hrp.AssemblyLinearVelocity
			currentHorizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		end

		local isGameLoaded = game:IsLoaded()

		if isSprinting then
			if (not humanoid or humanoid.MoveDirection.Magnitude == 0) or ((isGameLoaded or not CONFIG.usewhileloading) and currentHorizontalSpeed < 2) then
				stopSprinting()
			else
				stamina = math.clamp(stamina - (CONFIG.staminadrain * deltaTime), 0, CONFIG.maxstamina)
				lastSprintTime = os.clock()
				
				if stamina <= 0 then
					if not isExhausted then
						isExhausted = true
						if not soundExhausted.IsPlaying then
							soundExhausted:Play()
						end
					end
					stopSprinting()
				end
			end
		else
			if os.clock() - lastSprintTime >= CONFIG.regendelay then
				stamina = math.clamp(stamina + (CONFIG.staminaregen * deltaTime), 0, CONFIG.maxstamina)
				
				if stamina > 100 and soundExhausted.IsPlaying then
					soundExhausted:Stop()
				end

				if isExhausted and stamina >= CONFIG.maxstamina then
					isExhausted = false
					sprintButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					sprintButton.BackgroundTransparency = 0.4
				end
			end
		end

		local darknessLevel = 1 - ((1 - (stamina / CONFIG.maxstamina)) * CONFIG.overlaydarkness)
		darkOverlay.BackgroundTransparency = darknessLevel

		local targetSize = UDim2.new(stamina / CONFIG.maxstamina, 0, 1, 0)
		staminaBar:TweenSize(targetSize, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)

		if isExhausted then
			staminaBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		elseif stamina < 25 then
			staminaBar.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		else
			staminaBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		end
	end)
end
