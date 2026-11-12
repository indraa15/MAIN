-- // COMBO HUB: CASES + CSESPEED + FLAG MONITOR + OSU AUTO //
-- Auto Click & CLICK dihapus, diganti Osu Auto (Signal, urut nomor, delay 0)
-- Speed bisa diketik manual

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Parent GUI
local parentGui = PlayerGui
pcall(function()
	if gethui then
		parentGui = gethui()
	else
		parentGui = game:GetService("CoreGui")
	end
end)

-- Hapus Hub lama jika ada
local oldHub = parentGui:FindFirstChild("SimpleComboHub")
if oldHub then
	oldHub:Destroy()
end

-- State
local scriptAktif = true
local osuAktif = false
local autoCollectAktif = false
local isMinimized = false

local targetPosition = Vector3.new(208, 24, 105)
local currentTrack = nil
local isMoving = false
local currentSpeed = 400
local moveConnection = nil
local osuConnection = nil

-- ========== UI helper ==========
local GREEN = Color3.fromRGB(100, 255, 100)
local RED = Color3.fromRGB(255, 100, 100)

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleComboHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -95, 0.5, -130)
mainFrame.Size = UDim2.new(0, 190, 0, 254)
mainFrame.Active = true
mainFrame.Parent = screenGui
addCorner(mainFrame, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Size = UDim2.new(1, -70, 0, 30)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "COMBO HUB"
titleLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local function newButton(parent, text, pos, size, bg, textColor, textSize)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = bg
	b.BorderSizePixel = 0
	b.Position = pos
	b.Size = size
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextColor3 = textColor
	b.TextSize = textSize
	b.AutoButtonColor = false
	b.Parent = parent
	addCorner(b, 6)
	return b
end

local WHITE = Color3.fromRGB(255, 255, 255)

local closeButton = newButton(mainFrame, "X", UDim2.new(1, -28, 0, 5), UDim2.new(0, 22, 0, 22), Color3.fromRGB(200, 50, 50), WHITE, 11)
local minButton = newButton(mainFrame, "-", UDim2.new(1, -54, 0, 5), UDim2.new(0, 22, 0, 22), Color3.fromRGB(50, 80, 120), WHITE, 13)

-- Drag (mouse & touch) lewat judul
local dragging = false
local dragStart = nil
local startPos = nil
titleLabel.Active = true
titleLabel.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = mainFrame.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

-- Konten (untuk minimize)
local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 34)
content.Size = UDim2.new(1, 0, 1, -34)
content.Parent = mainFrame

local BTN_BG = Color3.fromRGB(28, 36, 54)
local ROW_W = UDim2.new(1, -20, 0, 30)

local function setToggle(btn, name, state)
	if state then
		btn.Text = name .. ": ON"
		btn.TextColor3 = GREEN
	else
		btn.Text = name .. ": OFF"
		btn.TextColor3 = RED
	end
end

-- 1) Osu Auto
local osuBtn = newButton(content, "Osu Auto: OFF", UDim2.new(0, 10, 0, 0), ROW_W, BTN_BG, RED, 11)

-- 2) Auto Collect
local collectBtn = newButton(content, "Auto Collect: OFF", UDim2.new(0, 10, 0, 36), ROW_W, BTN_BG, RED, 11)

-- 3) Place Base
local placeBaseBtn = newButton(content, "Place Base", UDim2.new(0, 10, 0, 72), ROW_W, Color3.fromRGB(30, 50, 80), WHITE, 11)

-- 4) Speed (diketik manual)
local speedFrame = Instance.new("Frame")
speedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedFrame.BorderSizePixel = 0
speedFrame.Position = UDim2.new(0, 10, 0, 108)
speedFrame.Size = ROW_W
speedFrame.Parent = content
addCorner(speedFrame, 6)

local speedLabel = Instance.new("TextLabel")
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.Size = UDim2.new(0, 50, 1, 0)
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.Text = "Speed:"
speedLabel.TextColor3 = WHITE
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local speedBox = Instance.new("TextBox")
speedBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
speedBox.BorderSizePixel = 0
speedBox.Position = UDim2.new(0, 62, 0, 3)
speedBox.Size = UDim2.new(1, -68, 1, -6)
speedBox.Font = Enum.Font.GothamBold
speedBox.Text = tostring(currentSpeed)
speedBox.PlaceholderText = "ketik angka"
speedBox.TextColor3 = WHITE
speedBox.TextSize = 12
speedBox.ClearTextOnFocus = true
speedBox.Parent = speedFrame
addCorner(speedBox, 5)

speedBox.FocusLost:Connect(function()
	local v = tonumber(speedBox.Text)
	if v and v > 0 then
		currentSpeed = v
	end
	speedBox.Text = tostring(currentSpeed)
end)

-- 5) Request Kick
local kickButton = newButton(content, "Request Kick", UDim2.new(0, 10, 0, 144), ROW_W, Color3.fromRGB(41, 128, 185), WHITE, 11)

-- 6) BACK / STOP
local backButton = newButton(content, "BACK", UDim2.new(0, 10, 0, 180), ROW_W, Color3.fromRGB(39, 174, 96), WHITE, 11)

-- ========== Fungsi tombol ==========
closeButton.MouseButton1Click:Connect(function()
	scriptAktif = false
	if moveConnection then
		moveConnection:Disconnect()
	end
	if osuConnection then
		osuConnection:Disconnect()
	end
	screenGui:Destroy()
end)

minButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		minButton.Text = "+"
		mainFrame.Size = UDim2.new(0, 190, 0, 32)
		content.Visible = false
	else
		minButton.Text = "-"
		mainFrame.Size = UDim2.new(0, 190, 0, 254)
		content.Visible = true
	end
end)

osuBtn.MouseButton1Click:Connect(function()
	osuAktif = not osuAktif
	setToggle(osuBtn, "Osu Auto", osuAktif)
end)

collectBtn.MouseButton1Click:Connect(function()
	autoCollectAktif = not autoCollectAktif
	setToggle(collectBtn, "Auto Collect", autoCollectAktif)
end)

placeBaseBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local args = { "Place" }
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestBasePad"):FireServer(unpack(args))
	end)
end)

kickButton.MouseButton1Click:Connect(function()
	local args = { { tier = "Perfect" } }
	pcall(function()
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestKick"):FireServer(unpack(args))
	end)
end)

-- ========== BACK / STOP (CSESPEED) ==========
local function stopMoving()
	if moveConnection then
		moveConnection:Disconnect()
		moveConnection = nil
	end

	if currentTrack then
		currentTrack:Stop()
		currentTrack = nil
	end

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
		end
	end

	isMoving = false
	backButton.Text = "BACK"
	backButton.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
end

backButton.MouseButton1Click:Connect(function()
	if isMoving then
		stopMoving()
	else
		local rewardArgs = { { kind = "waveCutsceneDone" } }
		pcall(function()
			ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FallRewardEvent"):FireServer(unpack(rewardArgs))
		end)

		isMoving = true
		backButton.Text = "STOP"
		backButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)

		local character = LocalPlayer.Character
		if not character then
			stopMoving()
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

		if rootPart and animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://913376220"
			currentTrack = animator:LoadAnimation(anim)
			currentTrack:Play()

			local oldPlatformStand = humanoid.PlatformStand
			local oldAutoRotate = humanoid.AutoRotate
			humanoid.PlatformStand = true
			humanoid.AutoRotate = false

			moveConnection = RunService.RenderStepped:Connect(function(dt)
				local currentPos = rootPart.Position
				local flatCurrent = Vector3.new(currentPos.X, 0, currentPos.Z)
				local flatTarget = Vector3.new(targetPosition.X, 0, targetPosition.Z)

				local distance = (flatTarget - flatCurrent).Magnitude
				if distance < 3 then
					humanoid.PlatformStand = oldPlatformStand
					humanoid.AutoRotate = oldAutoRotate

					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					raycastParams.FilterDescendantsInstances = { character }
					local rayResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0), raycastParams)
					if rayResult then
						rootPart.CFrame = CFrame.new(rayResult.Position + Vector3.new(0, 4, 0), targetPosition)
					end

					stopMoving()
					return
				end

				local direction = (flatTarget - flatCurrent).Unit
				local step = direction * (currentSpeed * dt)
				local newPos = currentPos + Vector3.new(step.X, 0, step.Z)

				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.FilterDescendantsInstances = { character }

				local rayResult = workspace:Raycast(newPos + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0), raycastParams)
				local finalY = newPos.Y
				if rayResult then
					finalY = rayResult.Position.Y + 4
				end

				rootPart.CFrame = CFrame.new(Vector3.new(newPos.X, finalY, newPos.Z), targetPosition)
			end)
		else
			stopMoving()
		end
	end
end)

-- ========== OSU AUTO (Signal, urut nomor, delay 0) ==========
local seen = {} -- [circle] = { last = waktu klik terakhir, n = jumlah klik }
local retryCooldown = 0.08
local maxRetry = 6

local function getSortedCircles()
	local list = {}
	local root = PlayerGui:FindFirstChild("OsuTrain")
	local folder = root and root:FindFirstChild("Circles")
	if not folder then
		return list
	end
	for _, c in ipairs(folder:GetChildren()) do
		local n = tonumber(string.match(c.Name, "^Circle(%d+)$"))
		if n then
			table.insert(list, { obj = c, num = n })
		end
	end
	table.sort(list, function(a, b)
		return a.num < b.num
	end)
	return list
end

local function fire(signal)
	if firesignal then
		pcall(function()
			firesignal(signal)
		end)
	elseif getconnections then
		pcall(function()
			for _, c in ipairs(getconnections(signal)) do
				c:Fire()
			end
		end)
	end
end

local function clickCircle(obj)
	local target = obj
	if not obj:IsA("GuiButton") then
		local inner = obj:FindFirstChildWhichIsA("GuiButton", true)
		if inner then
			target = inner
		end
	end
	if target:IsA("GuiButton") then
		fire(target.MouseButton1Down)
		fire(target.MouseButton1Click)
		fire(target.MouseButton1Up)
		fire(target.Activated)
	end
end

osuConnection = RunService.Heartbeat:Connect(function()
	if not osuAktif then
		return
	end

	local list = getSortedCircles()
	if #list == 0 then
		return
	end

	local now = tick()
	for _, item in ipairs(list) do
		local c = item.obj
		local info = seen[c]
		if not info then
			info = { last = 0, n = 0 }
			seen[c] = info
		end
		if info.n < maxRetry and now - info.last >= retryCooldown then
			info.last = now
			info.n = info.n + 1
			clickCircle(c)
		end
	end
end)

-- bersihkan cache circle yang sudah hilang
task.spawn(function()
	while scriptAktif do
		task.wait(1)
		for inst, _ in pairs(seen) do
			if not inst.Parent then
				seen[inst] = nil
			end
		end
	end
end)

-- ========== REAL-TIME MONITOR: FORCE TRUE FLAG LOCALPLAYER ==========
task.spawn(function()
	while scriptAktif do
		pcall(function()
			local fCollect = LocalPlayer:FindFirstChild("Flag_AutoCollect")
			local fPlace = LocalPlayer:FindFirstChild("Flag_AutoPlace")

			if fCollect then
				if fCollect:IsA("BoolValue") and not fCollect.Value then
					fCollect.Value = true
				elseif fCollect:IsA("IntValue") and fCollect.Value == 0 then
					fCollect.Value = 1
				end
			end

			if fPlace then
				if fPlace:IsA("BoolValue") and not fPlace.Value then
					fPlace.Value = true
				elseif fPlace:IsA("IntValue") and fPlace.Value == 0 then
					fPlace.Value = 1
				end
			end
		end)
		task.wait(0.1)
	end
end)

-- ========== LOOP AUTO COLLECT CASH ==========
task.spawn(function()
	while scriptAktif do
		if autoCollectAktif then
			pcall(function()
				local args = { "Collect" }
				ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestBasePad"):FireServer(unpack(args))
			end)
			task.wait(1)
		else
			task.wait(0.5)
		end
	end
end)
