--// TẢI HÀM TIỆN ÍCH CHUẨN CỦA VYNIXU TRƯỚC TIÊN ĐỂ KHÔNG BỊ LỖI LoadCustomInstance
pcall(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))()
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

--// SETTINGS
local delay
if getgenv().FasterTrouble then 
	delay = 1 
else 
	delay = 2
end

local DAMAGE = 30
local ATTACK_DELAY = delay
local LOOK_THRESHOLD = 0.65

--// Khởi tạo biến cờ toàn cục chống nhận trùng lặp thành tựu trong ván chơi
getgenv().ShockerGotAchievement = getgenv().ShockerGotAchievement or false

--// Hàm xử lý thành tựu chỉ nhận 1 lần duy nhất mỗi ván
local function SafeGiveBadge()
	if getgenv().ShockerGotAchievement then return end
	getgenv().ShockerGotAchievement = true

	pcall(function()
		if type(GiveShockerBadge) == "function" then
			GiveShockerBadge()
		elseif type(getgenv().GiveShockerBadge) == "function" then
			getgenv().GiveShockerBadge()
		else
			local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Achievements/Source.lua"))()
			if achievementGiver then
				achievementGiver({
					Title = "Shocking Experience.",
					Desc = "Look at me...",
					Reason = "Survival Shocker",
					Image = "rbxassetid://17857830685"
				})
			end
		end
	end)
end

--// TẢI ASSET HIỆU ỨNG TRỪ TÀ (REPENTANCE) BẰNG HÀM VYNIXU CHUẨN
local repentanceAsset = nil
pcall(function()
	if type(LoadCustomInstance) == "function" then
		repentanceAsset = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm")
	else
		repentanceAsset = game:GetObjects("rbxassetid://12543866876")[1]
	end
end)

--// LOAD MODEL THỰC THỂ
local fileName = "shocker_fixed_v3.rbxm"
local rawUrl = "https://raw.githubusercontent.com/junin724/remake/main/shocker.rbxm"

if not isfile(fileName) or (isfile(fileName) and #readfile(fileName) == 0) then
	local success, result = pcall(function()
		return game:HttpGet(rawUrl)
	end)
	
	if success and result and #result > 0 then
		writefile(fileName, result)
	else
		warn("Erro ao baixar o modelo do GitHub.")
		return
	end
end

local successLoad, objects = pcall(function()
	return game:GetObjects(getcustomasset(fileName))
end)

if not successLoad or not objects or #objects == 0 then
	pcall(function() delfile(fileName) end)
	return
end

local entity = objects[1]
entity.Parent = workspace

if not entity.PrimaryPart then
	entity.PrimaryPart = entity:FindFirstChildWhichIsA("BasePart", true)
end

local primary = entity.PrimaryPart
if not primary then return end

for _, v in pairs(entity:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = true
		v.CanCollide = false
	end
end

local ooga = entity:FindFirstChild("OOGA BOOGAAAA", true)
if ooga and ooga:IsA("BasePart") then
	ooga.CanCollide = true
	ooga.Anchored = true
	ooga.Massless = false
end

entity:PivotTo(root.CFrame * CFrame.new(0, 0, -8))

local scream = Instance.new("Sound")
scream.SoundId = "rbxassetid://297569488"
scream.Volume = 3
scream.PlaybackSpeed = 1
scream.Parent = primary

local state = "alive"

--// HÀM HOẠT ẢNH TRỪ TÀ CHUẨN VYNIXU (ĐÃ FIX LỖI SYNTAX)
local function CrucifixEntity(targetEntity, primaryPart, holdingItem)
	local entityPivot = primaryPart.CFrame

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character, targetEntity}
	
	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params)
	if not result then
		if holdingItem then holdingItem:Destroy() end
		targetEntity:Destroy()
		return
	end

	targetEntity:SetAttribute("BeingBanished", true)

	-- Xóa thánh giá trên tay người chơi sau khi kích hoạt
	if holdingItem then holdingItem:Destroy() end
	
	pcall(function()
		for _, v in pairs(targetEntity:GetDescendants()) do
			if v:IsA("Sound") and v.IsPlaying then
				v:Stop()
			end
		end
	end)
		
	-- Phát âm thanh thét ngay khoảnh khắc dùng thánh giá
	scream:Play()

	local successRitual = false

	if repentanceAsset and repentanceAsset:IsA("Model") then
		local repentance = repentanceAsset:Clone()
		local crucifix = repentance:FindFirstChild("Crucifix")
		local handle = crucifix and crucifix:FindFirstChild("Handle")
		local pentagram = repentance:FindFirstChild("Pentagram")
		local entityPart = repentance:FindFirstChild("Entity")
		
		if crucifix and pentagram and entityPart then
			successRitual = true
			local sound = handle and (handle:FindFirstChild("Sound") or handle:FindFirstChild("SoundFail"))
			
			repentance:PivotTo(CFrame.new(result.Position))
			crucifix:PivotTo(character:GetPivot())
			entityPart.CFrame = entityPivot
			repentance.Parent = workspace
			
			if sound then sound:Play() end

			-- Khóa chặt thực thể bám theo tâm hoạt ảnh trừ tà
			task.spawn(function()
				while entityPart.Parent and targetEntity.Parent do
					targetEntity:PivotTo(entityPart.CFrame)
					RunService.RenderStepped:Wait()
				end
				if targetEntity and targetEntity.Parent then
					targetEntity:Destroy()
				end
			end)

			-- Vòng phép thụt xuống đất
			if pentagram:FindFirstChild("Circle") then
				TweenService:Create(
					pentagram.Circle,
					TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
					{ CFrame = pentagram.Circle.CFrame - Vector3.new(0, 25, 0) }
				):Play()
				task.delay(2, function() pentagram.Circle:Destroy() end)
			end

			-- Kéo thực thể bay lên không trung
			TweenService:Create(
				entityPart,
				TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
				{ CFrame = entityPart.CFrame + Vector3.new(0, 2, 0) }
			):Play()

			-- Sau 3 giây kéo sập xuống lòng đất
			task.delay(3, function()
				if entityPart then
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ CFrame = entityPart.CFrame - Vector3.new(0, 50, 0) }
					):Play()
				end
			end)

			-- Dọn dẹp asset từ từ bằng hiệu ứng mờ dần (Fade out)
			task.delay(9, function()
				if repentance and repentance.Parent then
					for _, part in pairs(repentance:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("Decal") then
							TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
						elseif part:IsA("Beam") or part:IsA("ParticleEmitter") then
							part.Enabled = false
						end
					end
					
					task.wait(2) -- Đợi 2 giây cho hiệu ứng chạy xong rồi mới xóa hẳn
					repentance:Destroy()
				end
				
				if targetEntity and targetEntity.Parent then 
					targetEntity:Destroy() 
				end
			end)
		end
	end

	-- DỰ PHÒNG AN TOÀN NẾU ASSET KHÔNG TẢI ĐƯỢC
	if not successRitual then
		task.spawn(function()
			local startCF = primaryPart.CFrame
			local t = 0
			while t < 3 and targetEntity and targetEntity.Parent do
				t = t + RunService.RenderStepped:Wait()
				targetEntity:PivotTo(startCF * CFrame.new(0, t * 1.5, 0) * CFrame.Angles(0, math.rad(t * 300), 0))
			end
			if targetEntity and targetEntity.Parent then
				targetEntity:Destroy()
			end
		end)
	end
end

local function IsLookingAtEntity()
	if not entity or not entity.Parent then return false end

	local camPos = camera.CFrame.Position
	local lookDir = camera.CFrame.LookVector

	for _, part in ipairs(entity:GetDescendants()) do
		if part:IsA("BasePart") then
			local dir = part.Position - camPos
			local dist = dir.Magnitude
			if dist > 0 then
				dir = dir.Unit
				if lookDir:Dot(dir) > LOOK_THRESHOLD then
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = {character}
					local result = workspace:Raycast(camPos, dir * dist, params)
					if result and result.Instance and result.Instance:IsDescendantOf(entity) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function DespawnEntity(giveBadge)
	if state == "dead" then return end
	state = "dead"

	for _, v in pairs(entity:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
			v.CanCollide = false
		end
	end

	local badgeDone = false
	local parentConn

	if giveBadge then
		parentConn = entity.AncestryChanged:Connect(function(_, parent)
			if parent == nil and not badgeDone then
				badgeDone = true
				if parentConn then parentConn:Disconnect() end
				SafeGiveBadge()
			end
		end)
	end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.new(0, -160, 0)
	bv.Parent = primary

	task.wait(2)
	if entity and entity.Parent then entity:Destroy() end

	if giveBadge and entity.Parent == nil and not badgeDone then
		badgeDone = true
		if parentConn then parentConn:Disconnect() end
		SafeGiveBadge()
	end
end

--// ATTACK & CHECK TRACY/CRUCIFIX
local function Attack()
	if state ~= "alive" then return end

	-- Kiểm tra xem người chơi có đang cầm Crucifix / Cruxy trên tay không
	local holdingItem = character:FindFirstChildOfClass("Tool")
	if holdingItem then
		local itemName = holdingItem.Name:lower()
		if itemName:find("crucifix") or itemName:find("cruxy") then
			state = "banished"
			
			-- Kích hoạt hoạt ảnh trừ tà chuẩn Vynixu
			CrucifixEntity(entity, primary, holdingItem)
			SafeGiveBadge()
			return
		end
	end

	state = "attacking"

	local tween = TweenService:Create(
		primary,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear),
		{ CFrame = root.CFrame }
	)

	tween:Play()
	tween.Completed:Wait()

	humanoid:TakeDamage(DAMAGE)
	scream:Play()

	local original = camera.CFrame
	local duration = 0.8
	local start = tick()

	while true do
		local t = tick() - start
		local alpha = t / duration
		if alpha >= 1 then break end

		local drop = (-6 * math.exp(-t * 6)) + (2.5 * math.exp(-t * 10) * math.sin(t * 25))
		local rebound = 2 * math.exp(-t * 4) * math.sin(t * 12)
		local y = drop + rebound

		camera.CFrame = original * CFrame.new(0, y, 0)
		RunService.RenderStepped:Wait()
	end

	camera.CFrame = original
	DespawnEntity(true)
end

--// LOOK-AWAY DESPAWN
task.spawn(function()
	while state == "alive" and entity and entity.Parent do
		if not IsLookingAtEntity() then
			DespawnEntity(true)
			break
		end
		RunService.RenderStepped:Wait()
	end
end)

--// ATTACK CHECK
task.delay(ATTACK_DELAY, function()
	if state ~= "alive" then return end

	if IsLookingAtEntity() then
		Attack()
	else
		DespawnEntity(true)
	end
end)
