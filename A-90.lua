-- ========================================================
--                  STANDALONE A-90 SCRIPT
-- ========================================================
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomImageGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local function createImageLabel(parent, imageId, size, position, color, back)
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Size = size
	imageLabel.Position = position
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://" .. imageId
	imageLabel.ImageTransparency = 1 
	imageLabel.BackgroundColor3 = back or Color3.new(1, 0, 0)
	imageLabel.ImageColor3 = color or Color3.new(1, 1, 1)
	imageLabel.Parent = parent
	return imageLabel
end

local function applyGlitchEffect(imageLabel, duration)
	local startTime = tick()
	while tick() - startTime < duration do
		imageLabel.Rotation = math.random(-4, 4) 
		task.wait(0.01) 
	end
	imageLabel.Rotation = 0
end

local function applyscareEffect(imageLabel, duration)
	local startTime = tick()
	while tick() - startTime < duration do
		imageLabel.Position = UDim2.new(0.5 + math.random(-5, 5) / 100, 0, 0.5 + math.random(-5, 5) / 100, 0)
		imageLabel.Rotation = math.random(-5, 5) 
		task.wait(0.01) 
	end
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.Rotation = 0
end

-- Chỉ kiểm tra Tool đang cầm trên tay (trong Character)
local function IsHoldingCrucifix()
	local char = player.Character
	if not char then
		return false
	end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local hasTag = false
			pcall(function()
				hasTag = item:HasTag("Crucifix") or item:HasTag("Cruxy")
			end)
			local lowerName = item.Name:lower()
			if hasTag or lowerName:find("crucifix", 1, true) or lowerName:find("cruxy", 1, true) then
				return true
			end
		end
	end
	return false
end

local angy = createImageLabel(screenGui, "128097037283645", UDim2.new(0, 400, 0, 400), UDim2.new(0.5, 0, 0.5, 0))
angy.ImageTransparency = 1
angy.ImageColor3 = Color3.new(1, 0, 0)
task.spawn(function()
	applyscareEffect(angy, 2.8) 
end)

local deb = false

spawn(function()
	local mainGame = player:WaitForChild("PlayerGui", 5):WaitForChild("MainUI", 5):WaitForChild("Initiator", 5):WaitForChild("Main_Game", 5)
	local jsp = player:WaitForChild("PlayerGui", 5):WaitForChild("MainUI", 5):WaitForChild("Jumpscare", 5)
	if jsp and jsp:FindFirstChild("Jumpscare_A90") then
		local Fce = jsp.Jumpscare_A90:WaitForChild("Face", 5)
		if Fce then
			deb = false
			Fce.Image = "rbxassetid://104997991514855"
			task.spawn(function()
				applyGlitchEffect(Fce, 100) 
			end)
		end
	end
	pcall(function()
		require(mainGame.RemoteListener.Modules.A90)(require(mainGame))
	end)
end)

spawn(function()
	task.wait(2)
	deb = true
end)

spawn(function()
	while task.wait() do
		local jsp = player:WaitForChild("PlayerGui", 5):WaitForChild("MainUI", 5):WaitForChild("Jumpscare", 5)
		if jsp and jsp:FindFirstChild("Jumpscare_A90") and jsp.Jumpscare_A90:FindFirstChild("FaceAngry") then
			if jsp.Jumpscare_A90.FaceAngry.Visible == true then
				if deb == true then
					if screenGui and screenGui.Parent then
						screenGui:Destroy()
					end
					break
				end
				deb = true
				jsp.Jumpscare_A90.FaceAngry.Visible = false

				-- Đang cầm thánh giá trên tay: gây 0 damage, không mất thánh giá, không ghi DeathCause
				if IsHoldingCrucifix() then
					if screenGui and screenGui.Parent then
						screenGui:Destroy()
					end
					break
				end

				angy.ImageTransparency = 0

				local ReSt = game:GetService("ReplicatedStorage") 
				if ReSt:FindFirstChild("GameStats") and ReSt.GameStats:FindFirstChild("Player_".. player.Name) then
					ReSt.GameStats["Player_".. player.Name].Total.DeathCause.Value = "A-90"
				end
				task.wait(1)
				angy.Size = UDim2.new(0, 500, 0, 500)

				-- Kiểm tra lại lần nữa trước khi trừ máu cho chắc
				local damageAmount = IsHoldingCrucifix() and 0 or 70
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if hum and damageAmount > 0 then
					hum:TakeDamage(damageAmount)
				end

				local TweenService = game:GetService("TweenService")
				local timeInfo = TweenInfo.new(5)
				local bye = TweenService:Create(angy, timeInfo, {ImageTransparency = 1})
				bye:Play()
				
				task.delay(3, function()
					if screenGui then screenGui:Destroy() end
				end)
				break
			end
		end
	end
end)
