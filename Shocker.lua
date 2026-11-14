--// Hungry Entity (FINAL UPDATED VERSION - Fixed Single Achievement per Match)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

--// SETTINGS
local delay = getgenv().FasterTrouble and 1 or 2
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
			-- Fallback dự phòng nếu executor gọi Vynixu Custom Achievement trực tiếp
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

--// LOAD MODEL
local fileName = "shocker_fixed_v3.rbxm"
local rawUrl = "https://raw.githubusercontent.com/junin724/remake/main/shocker.rbxm"

-- Se o arquivo não existe ou está vazio (0 bytes), tenta baixar
if not isfile(fileName) or (isfile(fileName) and #readfile(fileName) == 0) then
	local success, result = pcall(function()
		return game:HttpGet(rawUrl)
	end)
	
	if success and result and #result > 0 then
		writefile(fileName, result)
	else
		warn("Erro ao baixar o modelo do GitHub. Verifique o link ou a conexão.")
		return
	end
end

-- Carrega o modelo do arquivo local
local successLoad, objects = pcall(function()
	return game:GetObjects(getcustomasset(fileName))
end)

if not successLoad or not objects or #objects == 0 then
	warn("Falha ao carregar o modelo do arquivo. Deletando arquivo corrompido...")
	pcall(function() delfile(fileName) end)
	return
end

local entity = objects[1]
entity.Parent = workspace

if not entity.PrimaryPart then
	entity.PrimaryPart = entity:FindFirstChildWhichIsA("BasePart", true)
end

local primary = entity.PrimaryPart

if not primary then
	warn("No PrimaryPart found for Hungry entity.")
	return
end

--// freeze parts
for _, v in pairs(entity:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = true
		v.CanCollide = false
	end
end

--// Make OOGA BOOGAAAA collidable
local ooga = entity:FindFirstChild("OOGA BOOGAAAA", true)

if ooga and ooga:IsA("BasePart") then
	ooga.CanCollide = true
	ooga.Anchored = true
	ooga.Massless = false
end

--// spawn em frente ao jogador
entity:PivotTo(root.CFrame * CFrame.new(0, 0, -8))

--// scream & sound effects
local scream = Instance.new("Sound")
scream.SoundId = "rbxassetid://297569488"
scream.Volume = 3
scream.PlaybackSpeed = 1
scream.Parent = primary

local pitchEffect = Instance.new("PitchShiftSoundEffect")
pitchEffect.Octave = 0.7
pitchEffect.Parent = scream

local distortionEffect = Instance.new("DistortionSoundEffect")
distortionEffect.Level = 0.8
distortionEffect.Parent = scream

local eqEffect = Instance.new("EqualizerSoundEffect")
eqEffect.HighGain = -80
eqEffect.LowGain = 10
eqEffect.MidGain = -1.7
eqEffect.Parent = scream

local state = "alive"

--// LOOK CHECK
local function IsLookingAtEntity()
	if not entity or not entity.Parent then
		return false
	end

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

--// DESPAWN
local function DespawnEntity(giveBadge)
	if state == "dead" then
		return
	end

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

				if parentConn then
					parentConn:Disconnect()
				end

				SafeGiveBadge()
			end
		end)
	end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.new(0, -160, 0)
	bv.Parent = primary

	task.wait(2)

	if entity and entity.Parent then
		entity:Destroy()
	end

	if giveBadge and entity.Parent == nil and not badgeDone then
		badgeDone = true

		if parentConn then
			parentConn:Disconnect()
		end

		SafeGiveBadge()
	end
end

--// ATTACK
local function Attack()
	if state ~= "alive" then
		return
	end

	state = "attacking"

	local tween = TweenService:Create(
		primary,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear),
		{
			CFrame = root.CFrame
		}
	)

	tween:Play()
	tween.Completed:Wait()

	humanoid:TakeDamage(DAMAGE)
	scream:Play()

	--// CAMERA SHAKE
	local original = camera.CFrame
	local duration = 0.8
	local start = tick()

	while true do
		local t = tick() - start
		local alpha = t / duration

		if alpha >= 1 then
			break
		end

		local drop =
			(-6 * math.exp(-t * 6)) +
			(2.5 * math.exp(-t * 10) * math.sin(t * 25))

		local rebound =
			2 * math.exp(-t * 4) * math.sin(t * 12)

		local y = drop + rebound

		camera.CFrame =
			original *
			CFrame.new(0, y, 0)

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
	if state ~= "alive" then
		return
	end

	if IsLookingAtEntity() then
		Attack()
	else
		DespawnEntity(true)
	end
end)
