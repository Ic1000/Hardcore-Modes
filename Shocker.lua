--// TẢI HÀM TIỆN ÍCH CHUẨN CỦA VYNIXU TRƯỚC TIÊN ĐỂ KHÔNG BỊ LỖI LoadCustomInstance
pcall(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))()
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

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

local CRUCIFIX_COLOR = Color3.fromRGB(137, 207, 255) -- Đổi sang Color3.fromRGB(255, 227, 137) nếu thích vàng Curious[span_1](start_span)[span_1](end_span)

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
		repentanceAsset = LoadCustomInstance("https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Repentance.rbxm") --[span_2](start_span)[span_2](end_span)
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

local function GetGiveMeColorList(rootObj)
	local list = {}
	local ok = pcall(function()
		list = rootObj:QueryDescendants(".GiveMeColor") --[span_3](start_span)[span_3](end_span)
	end)
	if ok and #list > 0 then
		return list
	end
	for _, d in ipairs(rootObj:GetDescendants()) do
		local tagged = false
		pcall(function()
			tagged = d:HasTag("GiveMeColor")
		end)
		if tagged or d.Name == "GiveMeColor" then
			table.insert(list, d)
		end
	end
	return list
end

--// HÀM HOẠT ẢNH TRỪ TÀ LẤY TỪ FILE (CÓ DỰ PHÒNG AN TOÀN)
local function CrucifixEntity(targetEntity, primaryPart, holdingItem)
	local entityPivot = (primaryPart and primaryPart.CFrame) or (targetEntity and targetEntity:GetPivot()) or CFrame.new()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude --[span_4](start_span)[span_4](end_span)
	params.FilterDescendantsInstances = {character, targetEntity} --[span_5](start_span)[span_5](end_span)

	local result = workspace:Raycast(entityPivot.Position, Vector3.new(0, -1000, 0), params) --[span_6](start_span)[span_6](end_span)
	if not result then
		result = { Position = entityPivot.Position - Vector3.new(0, 4, 0) }
	end

	pcall(function()
		targetEntity:SetAttribute("BeingBanished", true) --[span_7](start_span)[span_7](end_span)
	end)

	-- Xóa thánh giá trên tay người chơi sau khi kích hoạt
	if holdingItem then
		pcall(function() holdingItem:Destroy() end)
	end

	pcall(function()
		for _, v in pairs(targetEntity:GetDescendants()) do
			if v:IsA("Sound") and v.IsPlaying then
				v:Stop()
			end
		end
	end)

	-- Phát âm thanh thét ngay khoảnh khắc dùng thánh giá
	pcall(function() scream:Play() end)

	local camShaker
	local theShake
	pcall(function()
		local mainGameMod = playerGui:FindFirstChild("MainUI")
			and playerGui.MainUI:FindFirstChild("Initiator")
			and playerGui.MainUI.Initiator:FindFirstChild("Main_Game")
		if mainGameMod then
			local mainGame = require(mainGameMod)
			camShaker = mainGame and mainGame.camShaker --[span_8](start_span)[span_8](end_span)
			if camShaker then
				theShake = camShaker:StartShake(5, 20, 2, Vector3.zero) --[span_9](start_span)[span_9](end_span)
			end
		end
	end)

	if not camShaker then
		pcall(function()
			local shakerModule = ReplicatedStorage:FindFirstChild("CameraShaker", true)
			if shakerModule then
				local CameraShaker = require(shakerModule)
				camShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
					local curCam = workspace.CurrentCamera
					if curCam then
						curCam.CFrame = curCam.CFrame * shakeCf
					end
				end)
				camShaker:Start()
				theShake = camShaker:StartShake(5, 20, 2, Vector3.zero) --[span_10](start_span)[span_10](end_span)
			end
		end)
	end

	local successRitual = false

	if repentanceAsset and repentanceAsset:IsA("Model") then
		local repentance = repentanceAsset:Clone() --[span_11](start_span)[span_11](end_span)
		local crucifix = repentance:FindFirstChild("Crucifix") --[span_12](start_span)[span_12](end_span)
		local handle = crucifix and crucifix:FindFirstChild("Handle") --[span_13](start_span)[span_13](end_span)
		local pentagram = repentance:FindFirstChild("Pentagram") --[span_14](start_span)[span_14](end_span)
		local entityPart = repentance:FindFirstChild("Entity") --[span_15](start_span)[span_15](end_span)
		local sound = handle and handle:FindFirstChild("Sound") --[span_16](start_span)[span_16](end_span)

		if crucifix and pentagram and entityPart then
			successRitual = true
			local charPivot = (character and character:GetPivot()) or workspace.CurrentCamera.CFrame

			pcall(function()
				repentance:PivotTo(CFrame.new(result.Position)) --[span_17](start_span)[span_17](end_span)
				crucifix:PivotTo(charPivot) --[span_18](start_span)[span_18](end_span)
				if entityPart:IsA("BasePart") then
					entityPart.Anchored = true
					entityPart.CanCollide = false
					entityPart.CFrame = entityPivot --[span_19](start_span)[span_19](end_span)
				end
			end)

			repentance.Parent = workspace --[span_20](start_span)[span_20](end_span)
			if sound and sound:IsA("Sound") then
				pcall(function() sound:Play() end) --[span_21](start_span)[span_21](end_span)
			end

			local startClock = os.clock()
			local function waitUntil(t: number)
				while repentance.Parent do
					local elapsed = os.clock() - startClock
					if sound and sound:IsA("Sound") and sound.TimeLength > 0 and sound.IsPlaying then
						if sound.TimePosition >= t or elapsed >= (t + 2) then
							break
						end
					elseif elapsed >= t then
						break
					end
					RunService.RenderStepped:Wait() --[span_22](start_span)[span_22](end_span)
				end
			end

			local function fadeOut()
				for _, v in ipairs(pentagram:GetChildren()) do --[span_23](start_span)[span_23](end_span)
					if v.Name == "BeamFlat" then --[span_24](start_span)[span_24](end_span)
						task.delay(v:GetAttribute("Delay") or 0, function() --[span_25](start_span)[span_25](end_span)
							if v and v.Parent then
								pcall(function()
									TweenService:Create(
										v,
										TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_26](start_span)[span_26](end_span)
										{ Brightness = 0 } --[span_27](start_span)[span_27](end_span)
									):Play()
								end)
							end
						end)
					elseif v.Name == "BeamChain" then --[span_28](start_span)[span_28](end_span)
						pcall(function()
							TweenService:Create(
								v,
								TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), --[span_29](start_span)[span_29](end_span)
								{ Brightness = 0 } --[span_30](start_span)[span_30](end_span)
							):Play()
						end)
					end
				end
			end

			-- Đổi màu vòng phép & hiệu ứng theo .GiveMeColor[span_31](start_span)[span_31](end_span)
			for _, v in ipairs(GetGiveMeColorList(repentance)) do
				pcall(function()
					if v:IsA("Light") or v:IsA("BasePart") then --[span_32](start_span)[span_32](end_span)
						v.Color = CRUCIFIX_COLOR --[span_33](start_span)[span_33](end_span)
					elseif v:IsA("ParticleEmitter") or v:IsA("Beam") then --[span_34](start_span)[span_34](end_span)
						v.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, CRUCIFIX_COLOR), --[span_35](start_span)[span_35](end_span)
							ColorSequenceKeypoint.new(1, CRUCIFIX_COLOR), --[span_36](start_span)[span_36](end_span)
						})
					end
				end)
			end

			-- Khóa thực thể bám theo EntityPart[span_37](start_span)[span_37](end_span)
			task.spawn(function()
				while entityPart.Parent and repentance.Parent and targetEntity and targetEntity.Parent do
					pcall(function()
						targetEntity:PivotTo(entityPart.CFrame) --[span_38](start_span)[span_38](end_span)
					end)
					RunService.RenderStepped:Wait() --[span_39](start_span)[span_39](end_span)
				end
				if targetEntity and targetEntity.Parent then
					targetEntity:Destroy() --[span_40](start_span)[span_40](end_span)
				end
			end)

			-- Vòng phép thụt xuống đất[span_41](start_span)[span_41](end_span)
			local circle = pentagram:FindFirstChild("Circle")
			if circle then
				pcall(function()
					TweenService:Create(
						circle,
						TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), --[span_42](start_span)[span_42](end_span)
						{ CFrame = circle.CFrame - Vector3.new(0, 25, 0) } --[span_43](start_span)[span_43](end_span)
					):Play()
				end)
				task.delay(2, function()
					if circle and circle.Parent then
						circle:Destroy() --[span_44](start_span)[span_44](end_span)
					end
				end)
			end

			-- Thánh giá lơ lửng, xoay và tách mảnh Shards[span_45](start_span)[span_45](end_span)
			if handle then
				pcall(function()
					local bp = handle:FindFirstChild("BodyPosition")
					if bp then
						bp.Position = (charPivot * CFrame.new(1, 4, -6)).Position --[span_46](start_span)[span_46](end_span)
					end
					local bav = handle:FindFirstChild("BodyAngularVelocity")
					if bav then
						TweenService:Create(
							bav,
							TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), --[span_47](start_span)[span_47](end_span)
							{ AngularVelocity = Vector3.new(0, 40, 0) } --[span_48](start_span)[span_48](end_span)
						):Play()
					end
				end)

				task.delay(3, function()
					local shards = handle:FindFirstChild("Shards")
					if shards then
						for _, shard in ipairs(shards:GetChildren()) do --[span_49](start_span)[span_49](end_span)
							if shard:IsA("BasePart") then
								pcall(function()
									shard.CollisionGroup = "NoPlayer" --[span_50](start_span)[span_50](end_span)
									shard.CanCollide = true --[span_51](start_span)[span_51](end_span)
									local weld = shard:FindFirstChild("Weld")
									if weld then weld:Destroy() end --[span_52](start_span)[span_52](end_span)
									shard.AssemblyAngularVelocity = Vector3.zero --[span_53](start_span)[span_53](end_span)
								end)
							end
						end
					end
				end)
			end

			-- Nâng thực thể lên[span_54](start_span)[span_54](end_span)
			if entityPart:IsA("BasePart") then
				pcall(function()
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Elastic, Enum.EasingDirection.In), --[span_55](start_span)[span_55](end_span)
						{ CFrame = entityPart.CFrame + Vector3.new(0, 2, 0) } --[span_56](start_span)[span_56](end_span)
					):Play()
				end)
			end

			-- Nhịp ánh sáng nghi thức[span_57](start_span)[span_57](end_span)
			local pentBright = pentagram:FindFirstChild("Base")
				and pentagram.Base:FindFirstChild("LightAttach")
				and pentagram.Base.LightAttach:FindFirstChild("LightBright")
			local handleLight = handle and handle:FindFirstChild("Light")

			task.spawn(function()
				waitUntil(2.625) --[span_58](start_span)[span_58](end_span)
				if not repentance.Parent then return end

				if pentBright then
					pcall(function()
						TweenService:Create(
							pentBright,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_59](start_span)[span_59](end_span)
							{ Brightness = 5, Range = 40 } --[span_60](start_span)[span_60](end_span)
						):Play()
					end)
				end
				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_61](start_span)[span_61](end_span)
							{ Brightness = 11.25, Range = 30 } --[span_62](start_span)[span_62](end_span)
						):Play()
					end)
				end

				task.wait(1.5) --[span_63](start_span)[span_63](end_span)
				if not repentance.Parent then return end

				if pentBright then
					pcall(function()
						TweenService:Create(
							pentBright,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_64](start_span)[span_64](end_span)
							{ Brightness = 0, Range = 0 } --[span_65](start_span)[span_65](end_span)
						):Play()
					end)
				end
				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_66](start_span)[span_66](end_span)
							{ Brightness = 0, Range = 0 } --[span_67](start_span)[span_67](end_span)
						):Play()
					end)
				end

				if handleLight then
					pcall(function()
						TweenService:Create(
							handleLight,
							TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), --[span_68](start_span)[span_68](end_span)
							{ Brightness = 15, Range = 40 } --[span_69](start_span)[span_69](end_span)
						):Play()
					end)
				end

				if theShake then
					pcall(function() theShake:StartFadeOut(3) end) --[span_70](start_span)[span_70](end_span)
				end
				fadeOut() --[span_71](start_span)[span_71](end_span)

				local bav = handle and handle:FindFirstChild("BodyAngularVelocity")
				if bav then
					pcall(function()
						TweenService:Create(
							bav,
							TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), --[span_72](start_span)[span_72](end_span)
							{ AngularVelocity = Vector3.zero } --[span_73](start_span)[span_73](end_span)
						):Play()
					end)
				end
			end)

			-- Kéo thực thể xuống & tắt dần âm thanh[span_74](start_span)[span_74](end_span)
			waitUntil(2.5) --[span_75](start_span)[span_75](end_span)
			if entityPart:IsA("BasePart") and repentance.Parent then
				pcall(function()
					TweenService:Create(
						entityPart,
						TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_76](start_span)[span_76](end_span)
						{ CFrame = entityPart.CFrame - Vector3.new(0, 50, 0) } --[span_77](start_span)[span_77](end_span)
					):Play()
				end)
			end

			if targetEntity and targetEntity.Parent then
				for _, s in ipairs(targetEntity:GetDescendants()) do --[span_78](start_span)[span_78](end_span)
					if s:IsA("Sound") and not s:GetAttribute("VolumeIgnore") then --[span_79](start_span)[span_79](end_span)
						pcall(function()
							TweenService:Create(
								s,
								TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.In), --[span_80](start_span)[span_80](end_span)
								{ Volume = 0 } --[span_81](start_span)[span_81](end_span)
							):Play()
						end)
					end
				end
			end

			waitUntil(6.75) --[span_82](start_span)[span_82](end_span)

			-- Bùng sáng & nổ hạt kết thúc[span_83](start_span)[span_83](end_span)
			local glow = handle and handle:FindFirstChild("Glow")
			if glow and glow:IsA("BasePart") then
				pcall(function()
					TweenService:Create(
						glow,
						TweenInfo.new(1), --[span_84](start_span)[span_84](end_span)
						{ Size = glow.Size * 3, Transparency = 1 } --[span_85](start_span)[span_85](end_span)
					):Play()
				end)
			end
			if pentBright then
				pcall(function()
					TweenService:Create(
						pentBright,
						TweenInfo.new(1), --[span_86](start_span)[span_86](end_span)
						{ Brightness = 0, Range = 0 } --[span_87](start_span)[span_87](end_span)
					):Play()
				end)
			end
			if handleLight then
				pcall(function()
					TweenService:Create(
						handleLight,
						TweenInfo.new(1), --[span_88](start_span)[span_88](end_span)
						{ Brightness = 0, Range = 0 } --[span_89](start_span)[span_89](end_span)
					):Play()
				end)
			end

			local explodeParticle = handle and handle:FindFirstChild("ExplodeParticle")
			if explodeParticle and explodeParticle:IsA("ParticleEmitter") then
				pcall(function() explodeParticle:Emit(math.random(20, 30)) end) --[span_90](start_span)[span_90](end_span)
			end
			if camShaker then
				pcall(function() camShaker:ShakeOnce(7.5, 7.5, 0.25, 1.5) end) --[span_91](start_span)[span_91](end_span)
			end

			if targetEntity and targetEntity.Parent then
				targetEntity:Destroy() --[span_92](start_span)[span_92](end_span)
			end
			Debris:AddItem(repentance, 5) --[span_93](start_span)[span_93](end_span)
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
