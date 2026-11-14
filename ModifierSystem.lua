-- ========================================================
--   MODIFIER GUI (AUTO-SIZE + DRAGGABLE + POPUP ADD/UNADD)
-- ========================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Khởi tạo môi trường getgenv an toàn
local env = (getgenv and getgenv()) or _G

-- Xóa GUI cũ nếu chạy lại script
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("HardcoreModifiers")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HardcoreModifiers"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- 1. Nút Open / Close ở góc TRÁI phía trên màn hình
local openCloseBtn = Instance.new("TextButton")
openCloseBtn.Size = UDim2.new(0, 110, 0, 36)
openCloseBtn.AnchorPoint = Vector2.new(0, 0)
openCloseBtn.Position = UDim2.new(0.03, 0, 0.04, 0)
openCloseBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
openCloseBtn.Text = "Close"
openCloseBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
openCloseBtn.TextSize = 14
openCloseBtn.Font = Enum.Font.SourceSansBold
openCloseBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = openCloseBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(80, 80, 80)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = openCloseBtn

-- 2. Khung chính (Danh sách Modifier)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 0) 
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 70, 75)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 48)
title.BackgroundTransparency = 1
title.Text = "HARDCORE MODIFIERS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 1)
divider.Position = UDim2.new(0.05, 0, 0, 48)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- Khung cuộn danh sách
local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(0.92, 0, 0, 0)
listScroll.Position = UDim2.new(0.04, 0, 0, 56)
listScroll.BackgroundTransparency = 1
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150)
listScroll.ScrollingDirection = Enum.ScrollingDirection.Y
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.AutomaticSize = Enum.AutomaticSize.Y
listScroll.Parent = mainFrame

listScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
	local contentHeight = listScroll.AbsoluteCanvasSize.Y
	local targetHeight = math.clamp(contentHeight + 70, 60, 80)
	mainFrame.Size = UDim2.new(0, 340, 0, targetHeight)
end)

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 10)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = listScroll

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.Parent = listScroll

-- Logic ẩn/hiện bảng chính
openCloseBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	openCloseBtn.Text = mainFrame.Visible and "Close" or "Open"
end)

-- Kéo thả bảng chính
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)


-- ========================================================
--   3. BẢNG DETAIL POPUP (HIỆN KHI BẤM VÀO MODIFIER)
-- ========================================================
local detailFrame = Instance.new("Frame")
detailFrame.Size = UDim2.new(0, 360, 0, 220)
detailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
detailFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
detailFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
detailFrame.BorderSizePixel = 0
detailFrame.Visible = false
detailFrame.ZIndex = 5
detailFrame.Parent = screenGui

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 12)
detailCorner.Parent = detailFrame

local detailStroke = Instance.new("UIStroke")
detailStroke.Color = Color3.fromRGB(100, 100, 110)
detailStroke.Thickness = 2
detailStroke.Parent = detailFrame

-- Tiêu đề tên Modifier trong bảng Popup
local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -50, 0, 45)
detailTitle.Position = UDim2.new(0, 15, 0, 5)
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "Tên Modifier"
detailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
detailTitle.TextSize = 18
detailTitle.Font = Enum.Font.SourceSansBold
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.ZIndex = 6
detailTitle.Parent = detailFrame

-- Nút đóng (X) bảng Popup
local closeDetailBtn = Instance.new("TextButton")
closeDetailBtn.Size = UDim2.new(0, 35, 0, 35)
closeDetailBtn.Position = UDim2.new(1, -42, 0, 8)
closeDetailBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
closeDetailBtn.Text = "X"
closeDetailBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeDetailBtn.TextSize = 16
closeDetailBtn.Font = Enum.Font.SourceSansBold
closeDetailBtn.ZIndex = 6
closeDetailBtn.Parent = detailFrame

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 8)
cCorner.Parent = closeDetailBtn

closeDetailBtn.MouseButton1Click:Connect(function()
	detailFrame.Visible = false
end)

-- Trạng thái hiện tại của Modifier đang chọn
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
statusLabel.Position = UDim2.new(0.05, 0, 0, 55)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 6
statusLabel.Parent = detailFrame

-- KHUNG CHỨA 2 NÚT (TRÁI: ADD TO GAMEPLAY | PHẢI: UNADD)
local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(0.9, 0, 0, 55)
btnContainer.Position = UDim2.new(0.05, 0, 0, 130)
btnContainer.BackgroundTransparency = 1
btnContainer.ZIndex = 6
btnContainer.Parent = detailFrame

-- 1. Nút Add to Gameplay (Bên Trái)
local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.48, 0, 1, 0)
addBtn.Position = UDim2.new(0, 0, 0, 0)
addBtn.BackgroundColor3 = Color3.fromRGB(40, 135, 55)
addBtn.Text = "ADD TO GAMEPLAY"
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.TextSize = 13
addBtn.Font = Enum.Font.SourceSansBold
addBtn.ZIndex = 6
addBtn.Parent = btnContainer

local addCorner = Instance.new("UICorner")
addCorner.CornerRadius = UDim.new(0, 8)
addCorner.Parent = addBtn

-- 2. Nút Unadd (Bên Phải)
local unaddBtn = Instance.new("TextButton")
unaddBtn.Size = UDim2.new(0.48, 0, 1, 0)
unaddBtn.Position = UDim2.new(0.52, 0, 0, 0)
unaddBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
unaddBtn.Text = "UNADD"
unaddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unaddBtn.TextSize = 13
unaddBtn.Font = Enum.Font.SourceSansBold
unaddBtn.ZIndex = 6
unaddBtn.Parent = btnContainer

local unaddCorner = Instance.new("UICorner")
unaddCorner.CornerRadius = UDim.new(0, 8)
unaddCorner.Parent = unaddBtn

-- Biến lưu key đang được chọn
local selectedKeyName = nil

-- 1. Xử lý khi bấm nút Add to Gameplay
addBtn.MouseButton1Click:Connect(function()
	if selectedKeyName then
		-- Nếu biến đang là true rồi mà người chơi vẫn cố bấm Add tiếp -> Bỏ qua luôn, không làm gì cả (Chống spam)
		if env[selectedKeyName] == true then return end
		
		-- Nếu chưa bật thì mới cho bật
		env[selectedKeyName] = true
		statusLabel.Text = "Status: ACTIVE (ON)"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		print("[Anti-Spam] Đã bật modifier: " .. selectedKeyName)
	end
end)

-- 2. Xử lý khi bấm nút Unadd
unaddBtn.MouseButton1Click:Connect(function()
	if selectedKeyName then
		-- Nếu biến đang là false rồi mà cứ cố bấm Unadd tiếp -> Bỏ qua luôn (Chống spam)
		if env[selectedKeyName] == false then return end
		
		-- Nếu đang bật thì mới cho tắt
		env[selectedKeyName] = false
		statusLabel.Text = "Status: INACTIVE (OFF)"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		
		print("[Anti-Spam] Đã tắt modifier: " .. selectedKeyName)
	end
end)



-- ========================================================
--   4. HÀM TẠO NÚT TRONG DANH SÁCH CHÍNH
-- ========================================================
local function AddModifierButton(displayName, envKeyName)
	env[envKeyName] = env[envKeyName] or false
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.96, 0, 0, 45)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	btn.Text = displayName
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 15
	btn.Font = Enum.Font.SourceSansBold
	btn.Parent = listScroll
	
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = btn
	
	-- Bấm vào thẻ modifier -> Mở bảng Popup chi tiết ở giữa màn hình
	btn.MouseButton1Click:Connect(function()
		selectedKeyName = envKeyName
		detailTitle.Text = displayName
		
		if env[envKeyName] then
			statusLabel.Text = "Status: ACTIVE (ON)"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			statusLabel.Text = "Status: INACTIVE (OFF)"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
		
		detailFrame.Visible = true
	end)
end

-- ====== THÊM CÁC MODIFIER TÙY Ý Ở ĐÂY ======
AddModifierButton("Faster Trouble", "FasterTrouble")
AddModifierButton("Modifier 2", "SecondModifier")
