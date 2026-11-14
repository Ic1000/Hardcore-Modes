getgenv().OgHungerNewSpawner = nil 

local success, Spawner = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/eoyoustme/Mayhem-Remake/refs/heads/main/OgHungerNewSpawner"))()
end)

if not success or not Spawner then
	warn("[Spawner Error] Không thể tải OgHungerNewSpawner!")
	return
end

local speed = getgenv().FasterTrouble and 100 or 50

local entity = Spawner:Create({
	Entity = {
		Name = "Cease",
		Asset = "rbxassetid://12262854624",
		HeightOffset = 0
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

---====== CUSTOM SYSTEM & VARIABLES ======---

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

---====== CLEAN CALLBACKS ======---

entity:SetCallback("OnSpawned", function()
	local active = Instance.new("Sound")
	active.Parent = workspace
	active.Name = "spawn"
	active.SoundId = "rbxassetid://166047422"
	active.Volume = 3
	active:Play()

	active.Ended:Connect(function()
		active:Destroy()
	end)

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
