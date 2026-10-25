local function spawnDreadFull()
    -- Lắng nghe và đợi người chơi sang phòng mới (LatestRoom thay đổi) thì mới bắt đầu triệu hồi Dread
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
    
    -- Đợi sự kiện đổi phòng tiếp theo để thực thể xuất hiện đúng nhịp gameplay
    latestRoom.Changed:Wait()

    -- 1. Tạo hiệu ứng màu sắc không gian u ám khi Dread xuất hiện
    local lighting = game:GetService("Lighting")
    local colorCorrection = lighting:FindFirstChild("Ambience_Dread")
    if not colorCorrection then
        colorCorrection = Instance.new("ColorCorrectionEffect", lighting)
        colorCorrection.Name = "Ambience_Dread"
    end
    
    -- Hàm hỗ trợ tải và phát âm thanh từ GitHub
    local function GetGitSound(GithubSnd, SoundName)
        local url = GithubSnd
        if not isfile(SoundName .. ".mp3") then
            writefile(SoundName .. ".mp3", game:HttpGet(url))
        end
        local sound = Instance.new("Sound")
        sound.SoundId = (getcustomasset or getsynasset)(SoundName .. ".mp3")
        return sound
    end
    
    -- 2. Hàm Raycast kiểm tra xem người chơi có đang nhìn trực diện vào Dread hay không
    local function isLookingAtEntity(entityPart)
        local camera = workspace.CurrentCamera
        local entityPos = entityPart.Position
        local viewportPoint, isOnScreen = camera:WorldToViewportPoint(entityPos)
        
        local isVisible = isOnScreen
        if isOnScreen then
            isVisible = 0 < viewportPoint.Z
        end
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {entityPart.Parent}
        
        local character = game.Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("UpperTorso") then return false end
        
        local rayResult = workspace:Raycast(entityPos, character.UpperTorso.Position - entityPos, raycastParams)
        local hitInstance = rayResult and rayResult.Instance
        local hitParent = hitInstance and hitInstance.Parent
        
        return isVisible and (hitParent == character)
    end

    -- 3. Khởi tạo hiệu ứng rung lắc camera ban đầu
    local successShaker, CameraShaker = pcall(function()
        return require(game.ReplicatedStorage:WaitForChild("CameraShaker"))
    end)
    
    local camera = workspace.CurrentCamera
    local cameraShaker
    if successShaker and CameraShaker then
        cameraShaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
            camera.CFrame = camera.CFrame * shakeCFrame
        end)
        cameraShaker:Start()
        cameraShaker:ShakeOnce(2, 10, 1, 1)
    end
    
    -- 4. Tải Model Dread trực tiếp từ asset ID gốc
    local successModel, modelAsset = pcall(function()
        return game:GetObjects("rbxassetid://12797547314")[1]
    end)
    
    if not successModel or not modelAsset then
        warn("Không thể tải Model Dread!")
        return
    end
    
    modelAsset.Parent = workspace
    local dreadRootPart = modelAsset:FindFirstChild("RushNew")
    if not dreadRootPart then
        dreadRootPart = modelAsset:FindFirstChildWhichIsA("BasePart")
    end
    
    -- Đặt vị trí xuất hiện của Dread tại phòng mới nhất
    local currentRooms = workspace.CurrentRooms
    local latestRoomVal = latestRoom.Value
    local roomFolder = currentRooms:FindFirstChild(tostring(latestRoomVal))
    
    if roomFolder and dreadRootPart then
        local targetNode
        local nodesFolder = roomFolder:FindFirstChild("Nodes")
        if nodesFolder then
            local children = nodesFolder:GetChildren()
            if #children > 0 then
                targetNode = children[math.floor(#children / 2)]
            end
        else
            targetNode = roomFolder:FindFirstChild(roomFolder.Name)
        end
        
        if targetNode then
            dreadRootPart.CFrame = targetNode.CFrame + Vector3.new(0, 6, 0)
        end
    end
    
    -- Bật hiệu ứng chỉnh màu màn hình âm u
    colorCorrection.Enabled = true
    colorCorrection.Brightness = 0
    colorCorrection.Contrast = 0
    colorCorrection.Saturation = 0
    
    local TweenService = game:GetService("TweenService")
    TweenService:Create(colorCorrection, TweenInfo.new(2), {
        Brightness = 0.1, 
        Contrast = 0.2, 
        Saturation = -0.7
    }):Play()
    
    -- 5. Vòng lặp theo dõi: Tích lũy không bị trừ + Đếm số lần nhìn lướt (>= 2 lần là bị tóm)
    task.spawn(function()
        local accumulatedLookTime = 0
        local requiredLookTime = 2.0 -- Tích lũy đủ 2s là bị bắt
        
        local lookCount = 0
        local maxLookCount = 2      -- Nhìn lướt qua quá 2 lần là bị bắt
        local wasLooking = false    -- Biến cờ theo dõi trạng thái nhìn để đếm chính xác từng lần lướt
        
        while modelAsset.Parent and dreadRootPart and dreadRootPart.Parent do
            local currentlyLooking = isLookingAtEntity(dreadRootPart)
            
            -- 1. Xử lý đếm số lần nhìn (Dù lướt qua siêu nhanh cũng đếm đúng 1 lần)
            if currentlyLooking and not wasLooking then
                lookCount = lookCount + 1
            end
            wasLooking = currentlyLooking
            
            -- 2. Xử lý tích lũy thời gian (Chỉ cộng thêm khi nhìn, không bị trừ khi quay đi)
            if currentlyLooking then
                accumulatedLookTime = accumulatedLookTime + 0.1
            end
            
            -- KIỂM TRA ĐIỀU KIỆN: Tích lũy đủ 2.0s HOẶC Nhìn lướt từ 2 lần trở lên
            if accumulatedLookTime >= requiredLookTime or lookCount >= maxLookCount then
                colorCorrection.Enabled = false
                
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                -- ĐÓNG BĂNG TỐC ĐỘ NGAY LẬP TỨC TRÁNH NGƯỜI CHƠI DI CHUYỂN
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = 0
                        humanoid.JumpPower = 0
                    end
                end

                local mainUI = player.PlayerGui:FindFirstChild("MainUI")
                
                -- Lấy Module Main_Game để khóa camera
                local successMain, mainGameUI = pcall(function()
                    return require(mainUI.Initiator.Main_Game)
                end)
                
                if successMain and mainGameUI then
                    mainGameUI.stopcam = true -- Khóa góc nhìn chuột của game gốc
                end
                
                local oldCFrame = camera.CFrame
                camera.CameraType = Enum.CameraType.Scriptable
                
                -- Xoay camera nhắm chuẩn xác trực diện vào vị trí tâm của Dread
                local targetCFrame = CFrame.lookAt(oldCFrame.Position, dreadRootPart.Position)
                local lookTween = TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                    CFrame = targetCFrame
                })
                lookTween:Play()
                task.wait(0.15)
                
                -- Khóa cứng hướng camera nhìn thẳng vào Dread
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, dreadRootPart.Position)
                
                -- Phát âm thanh jumpscare từ GitHub
                local jumpScareSound = GetGitSound("https://github.com/Tinkgy111/Bang/blob/main/lv_0_20250111000930.mp3?raw=true", "dread_jumpscare")
                jumpScareSound.Parent = workspace
                jumpScareSound.Volume = 3
                jumpScareSound:Play()
                
                -- Đóng băng toàn bộ hiệu ứng hạt trong phòng
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.ClassName == "ParticleEmitter" then
                        obj.TimeScale = 0
                    end
                end
                task.wait(2)
                
                -- Hiệu ứng gục ngã / mất ý thức (Tối đen hoàn toàn)
                local mainColorCorrection = game.Lighting:FindFirstChild("MainColorCorrection")
                if mainColorCorrection then
                    mainColorCorrection.Brightness = -1
                    mainColorCorrection.Contrast = -4
                    mainColorCorrection.Saturation = -1
                end
                
                -- Xóa bỏ ánh sáng của Dread
                for _, obj in pairs(modelAsset:GetDescendants()) do
                    if obj.Name == "PointLight" then
                        obj:Destroy()
                    end
                end
                
                if cameraShaker then
                    cameraShaker:ShakeOnce(10, 100, 0.1, 10)
                end
                task.wait(1)
                
                if successMain and mainGameUI then
                    mainGameUI.stopcam = false
                    mainGameUI.freemouse = false
                end
                task.wait(0.4)
                
                -- Chạy script lưu trữ hiệu ứng gục ngã
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/XAtomMaster339871/dkrsoilcfrkjghfhgrthngnrtuyghrtuhngur/main/erfz", true))()
                end)
                
                -- 1. Gán nguyên nhân chết cho người chơi vào GameStats
                pcall(function()
                    ReplicatedStorage.GameStats["Player_" .. player.Name].Total.DeathCause.Value = "Dread"
                end)

                -- 2. Gửi bảng thông báo chết màu xanh dương chuẩn Guiding Light của Dread (Cause = "Dread")
                local remoteFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                if remoteFolder and remoteFolder:FindFirstChild("DeathHint") then
                    firesignal(remoteFolder.DeathHint.OnClientEvent, {
                        "You died to Dread...",
                        "Its presence is summoned when the clock hits 12...",
                        "Do not observe it! You may lose your sanity!"
                    }, "Blue", "Dread")
                end
                
                -- 3. Trừ sạch máu để nhân vật chính thức chết và hiện bảng kết quả
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
                
                break
            end
            
            task.wait(0.05) -- Tăng tần suất quét lên 0.05s để phát hiện góc nhìn siêu nhanh
        end
    end)
    
    -- 6. Tự động dọn dẹp model sau khi đi qua 3 phòng
    task.spawn(function()
        local roomChangedEvent = latestRoom.Changed
        for i = 1, 3 do
            roomChangedEvent:Wait()
        end
        if modelAsset then
            modelAsset:Destroy()
        end
        colorCorrection.Enabled = false
    end)
end

-- Gọi hàm kích hoạt Dread
task.spawn(spawnDreadFull)
