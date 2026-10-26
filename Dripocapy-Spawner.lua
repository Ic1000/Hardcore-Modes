-- ========================================================
--          CUSTOM ENTITY SPAWNER (VYNIXU NODES FIXED)
-- ========================================================
-- Services
local Players = game:GetService("Players")
local ReSt = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")

-- Variables
local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera
local StaticRushSpeed = 60
local FindPartOnRayWithIgnoreList = workspace.FindPartOnRayWithIgnoreList
local WorldToViewportPoint = Camera.WorldToViewportPoint
local CurrentRooms = workspace:WaitForChild("CurrentRooms")

local SelfModules = {
	DefaultConfig = loadstring(game:HttpGet("https://raw.githubusercontent.com/DripCapybara/Test/main/Doors/Backup/DefaultConfig.lua"))(),
	Functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))(),
}

local ModuleScripts = {
	ModuleEvents = ReSt:FindFirstChild("ModulesClient") and require(ReSt.ModulesClient.Module_Events) or nil,
	MainGame = tryRequire(Plr.PlayerGui.MainUI.Initiator.Main_Game),
}

function tryRequire(path)
	local success, result = pcall(function() return require(path) end)
	return success and result or nil
end

local Spawner = {}

-- Misc Functions
local function onCharacterAdded(char)
	Char, Hum = char, char:WaitForChild("Humanoid")
end

local function getPlayerRoot()
	return Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Head")
end

local function safeLoadAsset(assetId)
	local success, result = pcall(function()
		if type(LoadCustomInstance) == "function" then
			return LoadCustomInstance(assetId)
		else
			local idNum = tostring(assetId):gsub("%D", "")
			return game:GetObjects("rbxassetid://" .. idNum)[1]
		end
	end)
	if success and result then return result end
	warn("Failed to load custom instance: " .. tostring(assetId))
	return nil
end

local function safeLoadAssetImage(assetId)
	local success, result = pcall(function()
		if type(LoadCustomAsset) == "function" then
			return LoadCustomAsset(assetId)
		else
			local idNum = tostring(assetId):gsub("%D", "")
			return "rbxassetid://" .. idNum
		end
	end)
	if success and result then return result end
	return tostring(assetId)
end

-- Hàm kéo Entity di chuyển theo Node cực mượt mà
local function dragEntity(entityTable, entityModel, targetPos, speed)
	if entityTable.Connections.movementNode then
		entityTable.Connections.movementNode:Disconnect()
	end

	local reached = false
	entityTable.Connections.movementNode = RS.RenderStepped:Connect(function(dt)
		if entityModel and entityModel.Parent and not entityModel:GetAttribute("NoAI") then
			local primaryPart = entityModel.PrimaryPart
			if primaryPart then
				local rootPos = primaryPart.Position
				local destination = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
				local diff = destination - rootPos
				local distance = diff.Magnitude

				if distance > 2 then
					local moveStep = math.min(dt * speed, distance)
					local newPos = rootPos + diff.Unit * moveStep
					entityModel:PivotTo(CFrame.new(newPos, destination + Vector3.new(0, diff.Y, 0)))
				else
					reached = true
					if entityTable.Connections.movementNode then
						entityTable.Connections.movementNode:Disconnect()
					end
				end
			else
				if entityTable.Connections.movementNode then entityTable.Connections.movementNode:Disconnect() end
			end
		else
			if entityTable.Connections.movementNode then entityTable.Connections.movementNode:Disconnect() end
		end
	end)

	pcall(function()
		repeat task.wait() until reached or not entityTable.Connections.movementNode or not entityTable.Connections.movementNode.Connected
	end)
end

local function loadSound(soundData)
	local sound = Instance.new("Sound")
	local soundId = tostring(soundData[1])
	local properties = soundData[2]
	for i, v in next, properties do
		if i ~= "SoundId" and i ~= "Parent" then
			sound[i] = v
		end
	end
	if soundId:find("rbxasset://") or soundId:find("http") then
		sound.SoundId = soundId
	else
		local numberId = soundId:gsub("%D", "")
		sound.SoundId = "rbxassetid://" .. numberId
	end
	sound.Parent = workspace
	return sound
end

-- ========================================================
--  HỆ THỐNG LẤY NODE CHUẨN TỪ VYNIXU (LẤY TỪ FILE INIT)
-- ========================================================
local function GetNodesFromRoom(room: Model, reversed: boolean): { BasePart }
	local nodes = {}
	local roomEntrance = room:FindFirstChild("RoomEntrance")
	if roomEntrance then
		local n = roomEntrance:Clone()
		n.Name = "0"
		n.CFrame -= Vector3.new(0, 3, 0)
		nodes[1] = n
	end

	local nodesFolder = room:FindFirstChild("PathfindNodes")
	if nodesFolder then
		for _, n in next, nodesFolder:GetChildren() do
			nodes[#nodes + 1] = n
		end
	end

	local roomExit = room:FindFirstChild("RoomExit")
	if roomExit then
		local index = #nodes + 1
		local n = roomExit:Clone()
		n.Name = tostring(index)
		n.CFrame -= Vector3.new(0, 3, 0)
		nodes[index] = n
	end

	-- Fallback nếu phòng không có node nào cả
	if #nodes == 0 then
		local fallback = room:FindFirstChildWhichIsA("BasePart", true)
		if fallback then
			nodes[1] = fallback
		end
	end

	table.sort(nodes, function(a: BasePart, b: BasePart)
		local numA = tonumber(a.Name) or 0
		local numB = tonumber(b.Name) or 0
		if reversed then
			return numA > numB
		else
			return numA < numB
		end
	end)

	return nodes
end

local function GetPathfindNodesAmbush(config: any): { BasePart }
	local pathfindNodes = {}
	local rooms = CurrentRooms:GetChildren()
	table.sort(rooms, function(a, b)
		return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
	end)

	if config.Movement.Reversed == false then
		for i = 1, #rooms, 1 do
			local room = rooms[i]
			local roomNodes = GetNodesFromRoom(room, false)
			for _, node in next, roomNodes do
				pathfindNodes[#pathfindNodes + 1] = node
			end
		end
	else
		for i = #rooms, 1, -1 do
			local room = rooms[i]
			local roomNodes = GetNodesFromRoom(room, true)
			for _, node in next, roomNodes do
				pathfindNodes[#pathfindNodes + 1] = node
			end
		end
	end
	return pathfindNodes
end

-- Spawner Functions
Spawner.createEntity = function(config)
	for i, v in next, SelfModules.DefaultConfig do
		if config[i] == nil then
			config[i] = v
		end
	end
	config.Speed = StaticRushSpeed / 100 * config.Speed

	if config.Model == "12262883448" or config.Model == "rbxassetid://12262883448" then
		CG = Plr.PlayerGui
		config.RUNFORYOURDARNLIFE = true
	end

	local entityModel = safeLoadAsset(config.Model)
	if typeof(entityModel) == "Instance" and entityModel.ClassName == "Model" then
		entityModel.PrimaryPart = entityModel.PrimaryPart or entityModel:FindFirstChildWhichIsA("BasePart")
		if entityModel.PrimaryPart then
			entityModel.PrimaryPart.Anchored = true
			if config.CustomName then
				entityModel.Name = config.CustomName
			end
			entityModel:SetAttribute("IsCustomEntity", true)
			entityModel:SetAttribute("NoAI", false)

			local entityTable = {
				Model = entityModel,
				Config = config,
				Debug = {
					OnEntitySpawned = function() end,
					OnEntityDespawned = function() end,
					OnEntityStartMoving = function() end,
					OnEntityFinishedRebound = function() end,
					OnEntityEnteredRoom = function() end,
					OnLookAtEntity = function() end,
					OnDeath = function() end
				},
				Connections = {}
			}
			return entityTable
		end
	end
	warn("Spawner Error: Could not create entity model properly.")
	return nil
end

Spawner.runEntity = function(entityTable)
	if not entityTable or not entityTable.Model then return end

	local nodes = GetPathfindNodesAmbush(entityTable.Config)
	if #nodes == 0 then
		warn("Spawner: No nodes found for entity pathfinding!")
		return
	end

	local thing
	if entityTable.Config.RUNFORYOURDARNLIFE == true then
		local currentRooms = workspace:FindFirstChild("CurrentRooms")
		if currentRooms then
			thing = currentRooms.ChildAdded:Connect(function(c)
				nodes = GetPathfindNodesAmbush(entityTable.Config)
			end)
		end
	end

	-- Spawn Model tại node chuẩn xác
	local entityModel = entityTable.Model:Clone()
	local startNodeIndex = entityTable.Config.BackwardsMovement and #nodes or 1
	local startNodeOffset = entityTable.Config.BackwardsMovement and -20 or 20

	if nodes[startNodeIndex] then
		entityModel:PivotTo(nodes[startNodeIndex].CFrame * CFrame.new(0, 0, startNodeOffset) + Vector3.new(0, 3.5 + entityTable.Config.HeightOffset, 0))
	end
	entityModel.Parent = workspace
	task.spawn(entityTable.Debug.OnEntitySpawned)

	if CG:FindFirstChild("JumpscareGui") or (Plr.PlayerGui.MainUI.Death.HelpfulDialogue.Visible and not Plr.PlayerGui.MainUI.DeathPanelDead.Visible) then
		for _, v in next, entityModel:GetDescendants() do
			if v.ClassName == "Sound" and v.Playing then v:Stop() end
		end
	end

	if entityTable.Config.FlickerLights[1] and ModuleScripts.ModuleEvents then
		local latestRoomVal = ReSt:FindFirstChild("GameData") and ReSt.GameData:FindFirstChild("LatestRoom")
		if latestRoomVal and workspace.CurrentRooms:FindFirstChild(tostring(latestRoomVal.Value)) then
			ModuleScripts.ModuleEvents.flicker(workspace.CurrentRooms[tostring(latestRoomVal.Value)], entityTable.Config.FlickerLights[2])
		end
	end

	task.wait(entityTable.Config.DelayTime)
	local enteredRooms = {}

	-- Vòng lặp kiểm tra Va Chạm / Tầm Nhìn / Giết Người Chơi
	entityTable.Connections.movementTick = RS.Stepped:Connect(function()
		if entityModel.Parent and not entityModel:GetAttribute("NoAI") and entityModel.PrimaryPart then
			local entityPos = entityModel.PrimaryPart.Position
			local rootPart = getPlayerRoot()
			if not rootPart then return end
			local rootPos = rootPart.Position

			local floorRay = FindPartOnRayWithIgnoreList(workspace, Ray.new(entityPos, Vector3.new(0, -10, 0)), {entityModel, Char})
			local playerInSight = FindPartOnRayWithIgnoreList(workspace, Ray.new(entityPos, rootPos - entityPos), {entityModel, Char}) == nil

			if floorRay ~= nil and floorRay.Name == "Floor" then
				local currentRooms = workspace:FindFirstChild("CurrentRooms")
				if currentRooms then
					for _, room in next, currentRooms:GetChildren() do
						if floorRay:IsDescendantOf(room) and not table.find(enteredRooms, room) then
							enteredRooms[#enteredRooms + 1] = room
							task.spawn(entityTable.Debug.OnEntityEnteredRoom, room)
							if entityTable.Config.BreakLights and ModuleScripts.ModuleEvents then
								ModuleScripts.ModuleEvents.shatter(room)
							end
							break
						end
					end
				end
			end

			-- Rung màn hình khi tới gần
			local shakeConfig = entityTable.Config.CamShake
			local shakeMag = (rootPos - entityPos).Magnitude
			if shakeConfig[1] and shakeMag <= shakeConfig[3] then
				local shakeRep = {}
				for i, v in next, shakeConfig[2] do shakeRep[i] = v end
				shakeRep[1] = shakeConfig[2][1] / shakeConfig[3] * (shakeConfig[3] - shakeMag)
				if ModuleScripts.MainGame and ModuleScripts.MainGame.camShaker then
					ModuleScripts.MainGame.camShaker.ShakeOnce(ModuleScripts.MainGame.camShaker, table.unpack(shakeRep))
				end
			end

			-- Xử lý Kill người chơi
			if playerInSight then
				local _, onScreen = WorldToViewportPoint(Camera, entityModel.PrimaryPart.Position)
				if onScreen then task.spawn(entityTable.Debug.OnLookAtEntity) end

				if entityTable.Config.CanKill and not Char:GetAttribute("IsDead") and not Char:GetAttribute("Invincible") and (rootPos - entityPos).Magnitude <= entityTable.Config.KillRange then
					task.spawn(function()
						if Char:GetAttribute("Hiding") and not entityTable.Config.RUNFORYOURDARNLIFE then return end
						Char:SetAttribute("IsDead", true)
						for _, v in next, entityModel:GetDescendants() do
							if v.ClassName == "Sound" and v.Playing then v:Stop() end
						end
						if entityTable.Config.Jumpscare[1] then
							Spawner.runJumpscare(entityTable.Config.Jumpscare[2])
						end
						task.spawn(entityTable.Debug.OnDeath)
						Hum.Health = 0
						local gameStats = ReSt:FindFirstChild("GameStats")
						if gameStats and gameStats:FindFirstChild("Player_".. Plr.Name) then
							gameStats["Player_".. Plr.Name].Total.DeathCause.Value = entityModel.Name
						end
						if #entityTable.Config.CustomDialog > 0 and ReSt:FindFirstChild("RemotesFolder") then
							firesignal(ReSt.RemotesFolder.DeathHint.OnClientEvent, entityTable.Config.CustomDialog, "Blue")
						end
					end)
				end
			end
		end
	end)

	task.spawn(entityTable.Debug.OnEntityStartMoving)

	-- Thực hiện di chuyển THUẦN THEO NODE chuẩn Vynixu
	local cyclesConfig = entityTable.Config.Cycles
	if entityTable.Config.BackwardsMovement then
		local inverseNodes = {}
		for nodeIdx = #nodes, 1, -1 do
			inverseNodes[#inverseNodes + 1] = nodes[nodeIdx]
		end
		nodes = inverseNodes
	end

	local maxCycles = math.max(math.random(cyclesConfig.Min, cyclesConfig.Max), 1)
	for cycle = 1, maxCycles do
		for nodeIdx = 1, #nodes, 1 do
			if nodes[nodeIdx] and nodes[nodeIdx].Parent then
				dragEntity(entityTable, entityModel, nodes[nodeIdx].Position + Vector3.new(0, 3.5 + entityTable.Config.HeightOffset, 0), entityTable.Config.Speed)
			end
		end

		if cyclesConfig.Max > 1 then
			for nodeIdx = #nodes, 1, -1 do
				if nodes[nodeIdx] and nodes[nodeIdx].Parent then
					dragEntity(entityTable, entityModel, nodes[nodeIdx].Position + Vector3.new(0, 3.5 + entityTable.Config.HeightOffset, 0), entityTable.Config.Speed)
				end
			end
		end

		task.spawn(entityTable.Debug.OnEntityFinishedRebound)
		if cycle < maxCycles then
			task.wait(cyclesConfig.WaitTime)
		end
	end

	-- Dọn dẹp sau khi chạy xong
	if not entityModel:GetAttribute("NoAI") then
		for _, v in next, entityTable.Connections do
			if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
		end
		if thing then thing:Disconnect() end
		entityModel:Destroy()
		task.spawn(entityTable.Debug.OnEntityDespawned)
	end
end

Spawner.runJumpscare = function(config)
	local image1 = safeLoadAssetImage(config.Image1)
	local image2 = safeLoadAssetImage(config.Image2)
	local sound1, sound2 = nil, nil
	if config.Sound1 then pcall(function() sound1 = loadSound(config.Sound1) end) end
	if config.Sound2 then pcall(function() sound2 = loadSound(config.Sound2) end) end

	local JumpscareGui = Instance.new("ScreenGui")
	local Background = Instance.new("Frame")
	local Face = Instance.new("ImageLabel")

	JumpscareGui.Name = "JumpscareGui"
	JumpscareGui.IgnoreGuiInset = true
	JumpscareGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	Background.Name = "Background"
	Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Background.BorderSizePixel = 0
	Background.Size = UDim2.new(1, 0, 1, 0)
	Background.ZIndex = 999

	Face.Name = "Face"
	Face.AnchorPoint = Vector2.new(0.5, 0.5)
	Face.BackgroundTransparency = 1
	Face.Position = UDim2.new(0.5, 0, 0.5, 0)
	Face.ResampleMode = Enum.ResamplerMode.Pixelated
	Face.Size = UDim2.new(0, 150, 0, 150)
	Face.Image = image1
	Face.Parent = Background
	Background.Parent = JumpscareGui
	JumpscareGui.Parent = CG

	local teaseConfig = config.Tease
	local absHeight = JumpscareGui.AbsoluteSize.Y
	local minTeaseSize = absHeight / 5
	local maxTeaseSize = absHeight / 2.5

	if teaseConfig and teaseConfig[1] then
		local teaseAmount = math.random(teaseConfig.Min, teaseConfig.Max)
		if sound1 then pcall(function() sound1:Play() end) end
		for _ = teaseConfig.Min, teaseAmount do
			task.wait(math.random(100, 200) / 100)
			local growFactor = (maxTeaseSize - minTeaseSize) / teaseAmount
			Face.Size = UDim2.new(0, Face.AbsoluteSize.X + growFactor, 0, Face.AbsoluteSize.Y + growFactor)
		end
		task.wait(math.random(100, 200) / 100)
	end

	Face.Image = image2
	Face.Size = UDim2.new(0, maxTeaseSize, 0, maxTeaseSize)
	if sound2 then pcall(function() sound2:Play() end) end

	TS:Create(Face, TweenInfo.new(0.75), {Size = UDim2.new(0, absHeight * 3, 0, absHeight * 3), ImageTransparency = 0.5}):Play()
	task.wait(0.75)

	if JumpscareGui then JumpscareGui:Destroy() end
	if sound1 then pcall(function() sound1:Destroy() end) end
	if sound2 then pcall(function() sound2:Destroy() end) end
end

Plr.CharacterAdded:Connect(onCharacterAdded)

return Spawner
