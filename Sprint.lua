local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

if _G.SprintSystem then
	warn("is executed, nah")
	pcall(function()
		local mainGame = require(player.PlayerGui.MainUI.Initiator.Main_Game)
		mainGame.caption("Is Executed, Returning...", true)
	end)
	return
end
_G.SprintSystem = true

-- Lấy RemotesFolder chuẩn của Doors
local remotesFolder = ReplicatedStorage:FindFirstChild("EntityInfo")
	or ReplicatedStorage:FindFirstChild("Bricks")
	or ReplicatedStorage:FindFirstChild("RemotesFolder")

-- Cấu hình
local cfg = _G.mobile_sprint_config or {}
local CONFIG = {
	usewhileloading = cfg.usewhileloading ~= nil and cfg.usewhileloading or true,
	maxstamina = 150,
	staminadrain = 20,
	staminaregen = 15,
	regendelay = 1.5,
	sprintboost = 4,
	chaseextra = 1,
	overlaydarkness = 0.4,
	soundvolume = 3,
}

local stamina = CONFIG.maxstamina
local isSprinting = false
local isExhausted = false
local lastSprintTime = 0
local sprintHeldPC = false

-- Buff Vitamins
local vitaminBuffEndTime = 0
local VITAMIN_BUFF_DURATION = 10
local VITAMIN_SPEED_BONUS = 3
local VITAMIN_REGEN_MULT = 1.75

local function HasVitaminBuff()
	return os.clock() < vitaminBuffEndTime
end

-- Lấy Main_Game module
local mainGameModule = nil
local function RefreshMainGame()
	pcall(function()
		local mgScript = player:WaitForChild("PlayerGui", 5)
			:WaitForChild("MainUI", 5)
			:WaitForChild("Initiator", 5)
			:WaitForChild("Main_Game", 5)
		if mgScript and mgScript:IsA("ModuleScript") then
			mainGameModule = require(mgScript)
		end
	end)
end
RefreshMainGame()

local function ShowCaption(text)
	pcall(function()
		if not mainGameModule then
			RefreshMainGame()
		end
		if mainGameModule and type(mainGameModule.caption) == "function" then
			mainGameModule.caption(text, true)
		end
	end)
end

local function IsChasing()
	return mainGameModule and mainGameModule.chase == true
end

local function GetActiveBoost()
	local bonus = HasVitaminBuff() and VITAMIN_SPEED_BONUS or 0
	if not isSprinting then
		return bonus
	end
	return CONFIG.sprintboost + (IsChasing() and CONFIG.chaseextra or 0) + bonus
end

-- Tạo Sound Kiệt Sức
local soundExhausted = Instance.new("Sound")
soundExhausted.Name = "ExhaustedSound"
soundExhausted.SoundId = "rbxassetid://8258601891"
soundExhausted.Volume = CONFIG.soundvolume
soundExhausted.Looped = true
soundExhausted.Parent = player:WaitForChild("PlayerGui")

character:SetAttribute("SpeedBoost", 0)

-- Cơ chế Collision & Speed Bypass
local CollisionClone = nil
local bypassRunId = 0

local function SetupCollisionBypass(char)
	bypassRunId = bypassRunId + 1
	local currentRunId = bypassRunId

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
	if not collision then
		collision = root
	end

	if CollisionClone and CollisionClone.Parent then
		CollisionClone:Destroy()
	end

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
		while currentRunId == bypassRunId and char and char.Parent and CollisionClone and CollisionClone.Parent do
			if root and root.Anchored then
				CollisionClone.Massless = true
				repeat
					task.wait()
				until not root.Anchored or currentRunId ~= bypassRunId or not char.Parent
				task.wait(0.15)
			else
				CollisionClone.Massless = not CollisionClone.Massless
			end
			task.wait(0.24)
		end
	end)
end

-- GUI & Logic Sprint
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SprintGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = player:WaitForChild("PlayerGui")

local sprintButton = nil
local staminaBg = nil
local staminaBar = nil

if UserInputService.TouchEnabled then
	sprintButton = Instance.new("TextButton")
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

	staminaBg = Instance.new("Frame")
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

	staminaBar = Instance.new("Frame")
	staminaBar.Name = "StaminaBar"
	staminaBar.Size = UDim2.new(1, 0, 1, 0)
	staminaBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	staminaBar.ZIndex = 1
	staminaBar.Parent = staminaBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = staminaBar
end

local darkOverlay = Instance.new("Frame")
darkOverlay.Name = "DarkOverlay"
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.Position = UDim2.new(0, 0, 0, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 1
darkOverlay.ZIndex = 100
darkOverlay.Active = false
darkOverlay.Parent = screenGui

local vignetteImage = Instance.new("ImageLabel")
vignetteImage.Name = "VignetteOverlay"
vignetteImage.Size = UDim2.new(1, 0, 1, 0)
vignetteImage.Position = UDim2.new(0, 0, 0, 0)
vignetteImage.BackgroundTransparency = 1
vignetteImage.Image = "rbxassetid://190596490"
vignetteImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
vignetteImage.ImageTransparency = 1
vignetteImage.ZIndex = 99
vignetteImage.Parent = screenGui

local function RefreshSprintButtonVisual()
	if not sprintButton then return end
	if isSprinting then
		sprintButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		sprintButton.BackgroundTransparency = 0.2
	elseif isExhausted then
		sprintButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		sprintButton.BackgroundTransparency = 0.7
	else
		sprintButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		sprintButton.BackgroundTransparency = 0.4
	end
end

local function stopSprinting()
	isSprinting = false
	if character then
		character:SetAttribute("SpeedBoost", GetActiveBoost())
	end
	RefreshSprintButtonVisual()
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
			character:SetAttribute("SpeedBoost", GetActiveBoost())
		end
		RefreshSprintButtonVisual()
	end
end

-- Cơ chế Vitamins: hồi +30 máu, đầy stamina & bật buff tốc độ + hồi stamina
local vitaminsCooldown = false
local vitaminsAddedConn = nil
local vitaminsActConn = nil
local vitaminsAncestryConn = nil

local function ApplyVitaminEffect(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if vitaminsCooldown then return end

	vitaminsCooldown = true
	hum.Health = math.min(hum.Health + 30, hum.MaxHealth)

	stamina = CONFIG.maxstamina
	isExhausted = false
	vitaminBuffEndTime = os.clock() + VITAMIN_BUFF_DURATION

	if soundExhausted.IsPlaying then
		soundExhausted:Stop()
	end
	if staminaBar then
		staminaBar.Size = UDim2.new(1, 0, 1, 0)
	end
	if character then
		character:SetAttribute("SpeedBoost", GetActiveBoost())
	end
	RefreshSprintButtonVisual()
	ShowCaption("Vitamin boost active!")

	task.delay(10, function()
		vitaminsCooldown = false
	end)
end

local VITAMIN_SOUND_IDS = {
	["rbxassetid://11405639640"] = true, -- sound_open
	["rbxassetid://10370341073"] = true, -- sound_flick
	["rbxassetid://9121005783"] = true,  -- sound_close
}

local VITAMIN_OPEN_ANIM_IDS = {
	["rbxassetid://1048256314"] = true,
	["1048256314"] = true,
}

local vitaminsCooldown = false
local vitaminsAddedConn = nil
local vitaminsRemovedConn = nil
local vitaminsActConn = nil
local vitaminAnimConn = nil
local vitaminDetailConns = {}

local function ApplyVitaminEffect(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if vitaminsCooldown then return end

	vitaminsCooldown = true
	hum.Health = math.min(hum.Health + 30, hum.MaxHealth)

	stamina = CONFIG.maxstamina
	isExhausted = false
	vitaminBuffEndTime = os.clock() + VITAMIN_BUFF_DURATION

	if soundExhausted.IsPlaying then
		soundExhausted:Stop()
	end
	if staminaBar then
		staminaBar.Size = UDim2.new(1, 0, 1, 0)
	end
	if character then
		character:SetAttribute("SpeedBoost", GetActiveBoost())
	end
	RefreshSprintButtonVisual()
	ShowCaption("Vitamin boost active!")

	-- Cooldown ngắn 1.5s để tránh 1 lần uống kích hoạt đúp nhiều hook (sound + anim + stack),
	-- nhưng vẫn đủ nhanh để uống liên tiếp nhiều viên
	task.delay(1.5, function()
		vitaminsCooldown = false
	end)
end

local function ClearVitaminHooks()
	if vitaminsActConn then
		vitaminsActConn:Disconnect()
		vitaminsActConn = nil
	end
	if vitaminAnimConn then
		vitaminAnimConn:Disconnect()
		vitaminAnimConn = nil
	end
	for _, conn in ipairs(vitaminDetailConns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(vitaminDetailConns)
end

local function IsVitaminTool(obj)
	return obj and obj:IsA("Tool") and obj.Name:lower():find("vitamin", 1, true) ~= nil
end

local function AttachToVitaminTool(char, tool)
	if not IsVitaminTool(tool) then return end
	ClearVitaminHooks()

	-- 1. Theo dõi giảm số viên qua Attribute của Tool (Durability / Uses / Amount / Count / Stack...)
	local attrCache = {}
	for attrName, attrVal in pairs(tool:GetAttributes()) do
		if type(attrVal) == "number" then
			attrCache[attrName] = attrVal
		end
	end

	table.insert(vitaminDetailConns, tool.AttributeChanged:Connect(function(attrName)
		local newVal = tool:GetAttribute(attrName)
		if type(newVal) == "number" then
			local oldVal = attrCache[attrName]
			attrCache[attrName] = newVal
			if oldVal and newVal < oldVal then
				ApplyVitaminEffect(char)
			end
		end
	end))

	-- 2. Theo dõi giảm số viên qua IntValue / NumberValue / TextLabel bên trong Tool
	local function watchDescendant(desc)
		if desc:IsA("IntValue") or desc:IsA("NumberValue") then
			local lastVal = desc.Value
			table.insert(vitaminDetailConns, desc.Changed:Connect(function(newVal)
				if newVal < lastVal then
					ApplyVitaminEffect(char)
				end
				lastVal = newVal
			end))
		elseif desc:IsA("TextLabel") then
			local lastNum = tonumber(desc.Text:match("%d+"))
			table.insert(vitaminDetailConns, desc:GetPropertyChangedSignal("Text"):Connect(function()
				local newNum = tonumber(desc.Text:match("%d+"))
				if lastNum and newNum and newNum < lastNum then
					ApplyVitaminEffect(char)
				end
				lastNum = newNum
			end))
		elseif desc:IsA("Sound") and VITAMIN_SOUND_IDS[desc.SoundId] then
			table.insert(vitaminDetailConns, desc.Played:Connect(function()
				if tool and tool.Parent == char then
					ApplyVitaminEffect(char)
				end
			end))
		end
	end

	for _, desc in ipairs(tool:GetDescendants()) do
		watchDescendant(desc)
	end
	table.insert(vitaminDetailConns, tool.DescendantAdded:Connect(watchDescendant))

	-- 3. Theo dõi Animation uống thuốc
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		vitaminAnimConn = hum.AnimationPlayed:Connect(function(track)
			if not tool or tool.Parent ~= char then return end
			local anim = track and track.Animation
			local animId = anim and tostring(anim.AnimationId) or ""
			local animName = anim and string.lower(anim.Name) or ""
			if VITAMIN_OPEN_ANIM_IDS[animId] or animName:find("open", 1, true) or animName:find("drink", 1, true) or animName:find("use", 1, true) then
				ApplyVitaminEffect(char)
			end
		end)
	end

	-- 4. Bấm sử dụng trực tiếp
	vitaminsActConn = tool.Activated:Connect(function()
		ApplyVitaminEffect(char)
	end)
end

local function BindVitamins(char)
	if vitaminsAddedConn then vitaminsAddedConn:Disconnect() end
	if vitaminsRemovedConn then vitaminsRemovedConn:Disconnect() end
	ClearVitaminHooks()

	-- Nếu đang cầm sẵn Vitamins trên tay lúc script chạy
	for _, child in ipairs(char:GetChildren()) do
		if IsVitaminTool(child) then
			AttachToVitaminTool(char, child)
		end
	end

	-- Khi rút Vitamins ra cầm
	vitaminsAddedConn = char.ChildAdded:Connect(function(child)
		if IsVitaminTool(child) then
			AttachToVitaminTool(char, child)
		end
	end)

	-- Khi dùng hết viên cuối cùng và lọ Vitamins biến mất
	vitaminsRemovedConn = char.ChildRemoved:Connect(function(child)
		if IsVitaminTool(child) then
			task.defer(function()
				local backpack = player:FindFirstChild("Backpack")
				if not child.Parent and (not backpack or not backpack:FindFirstChild(child.Name)) then
					ApplyVitaminEffect(char)
				end
			end)
		end
	end)
end

SetupCollisionBypass(character)
BindVitamins(character)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	stamina = CONFIG.maxstamina
	isSprinting = false
	isExhausted = false
	sprintHeldPC = false
	vitaminBuffEndTime = 0

	if soundExhausted.IsPlaying then
		soundExhausted:Stop()
	end
	character:SetAttribute("SpeedBoost", 0)
	SetupCollisionBypass(character)
	BindVitamins(character)
end)

if sprintButton then
	sprintButton.Activated:Connect(function()
		if isSprinting then
			stopSprinting()
		else
			startSprinting()
		end
	end)
end

-- PC input: giữ Q để sprint
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		sprintHeldPC = true
		startSprinting()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Q then
		sprintHeldPC = false
		if isSprinting then
			stopSprinting()
		end
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if not humanoid or humanoid.Health <= 0 then
		if isSprinting then
			stopSprinting()
		end
		if soundExhausted.IsPlaying then
			soundExhausted:Stop()
		end
		return
	end

	local isCrouching = (character and character:GetAttribute("Crouching") == true)
	local isHiding = (character and character:GetAttribute("Hiding") == true)

	if isCrouching or isHiding then
		if isSprinting then
			stopSprinting()
		end
		if soundExhausted.IsPlaying then
			soundExhausted:Stop()
		end
	elseif sprintHeldPC and not isSprinting and not isExhausted and stamina > 0 then
		startSprinting()
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
			character:SetAttribute("SpeedBoost", GetActiveBoost())
			stamina = math.clamp(stamina - (CONFIG.staminadrain * deltaTime), 0, CONFIG.maxstamina)
			lastSprintTime = os.clock()

			if stamina <= 0 then
				if not isExhausted then
					isExhausted = true
					ShowCaption("You're exhausted.")
					if not soundExhausted.IsPlaying then
						soundExhausted:Play()
					end
				end
				stopSprinting()
			end
		end
	else
		if character then
			character:SetAttribute("SpeedBoost", GetActiveBoost())
		end

		if os.clock() - lastSprintTime >= CONFIG.regendelay then
			local regenRate = CONFIG.staminaregen * (HasVitaminBuff() and VITAMIN_REGEN_MULT or 1)
			stamina = math.clamp(stamina + (regenRate * deltaTime), 0, CONFIG.maxstamina)

			if stamina > 100 and soundExhausted.IsPlaying then
				soundExhausted:Stop()
			end

			if isExhausted and stamina >= CONFIG.maxstamina then
				isExhausted = false
				RefreshSprintButtonVisual()
			end
		end
	end

	local exhaustionRatio = 1 - (stamina / CONFIG.maxstamina)
	local darknessLevel = 1 - (exhaustionRatio * CONFIG.overlaydarkness)
	darkOverlay.BackgroundTransparency = darknessLevel
	vignetteImage.ImageTransparency = math.clamp(1 - (exhaustionRatio * 0.85), 0, 1)

	if staminaBar then
		local targetSize = UDim2.new(stamina / CONFIG.maxstamina, 0, 1, 0)
		staminaBar:TweenSize(targetSize, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)

		if isExhausted then
			staminaBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		elseif stamina < 25 then
			staminaBar.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		else
			staminaBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		end
	end
end)
