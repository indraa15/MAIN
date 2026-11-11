-- OsuTrain Auto Click (klik Circle berurutan berdasarkan nomor)
-- UI simple, mobile friendly, bisa digeser lewat judul

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local vim
pcall(function() vim = game:GetService("VirtualInputManager") end)

-- ========== Pengaturan ==========
local enabled = false
local mode = "Touch"      -- "Touch" (simulasi tap) atau "Signal" (firesignal)
local delay = 0           -- jeda minimal antar klik (detik)
local retryCooldown = 0.25 -- kalau circle yang sama masih ada, coba klik lagi setelah ini
-- ================================

local clicked = {}   -- [instance] = waktu klik terakhir
local lastClick = 0

-- ========== Parent GUI ==========
local function getParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
	if ok then return game:GetService("CoreGui") end
	return playerGui
end

local parentGui = getParent()
local old = parentGui:FindFirstChild("OsuAutoGui")
if old then old:Destroy() end

-- ========== Logic ==========
local function getCircles()
	local root = playerGui:FindFirstChild("OsuTrain")
	return root and root:FindFirstChild("Circles")
end

-- ambil circle dengan nomor TERKECIL (urut)
local function getNext()
	local folder = getCircles()
	if not folder then return nil end
	local best, bestNum
	for _, c in ipairs(folder:GetChildren()) do
		local n = tonumber(c.Name:match("^Circle(%d+)$"))
		if n and c:IsA("GuiObject") and (not bestNum or n < bestNum) then
			best, bestNum = c, n
		end
	end
	return best, bestNum
end

local function tapAt(obj)
	if not vim then return end
	local sg = obj:FindFirstAncestorOfClass("ScreenGui")
	local inset = (sg and sg.IgnoreGuiInset) and Vector2.new(0, 0) or GuiService:GetGuiInset()
	local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
	vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
	vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
end

local function clickObject(obj)
	if mode == "Signal" and firesignal then
		if obj:IsA("GuiButton") then
			for _, ev in ipairs({ "MouseButton1Down", "MouseButton1Click", "MouseButton1Up", "Activated" }) do
				pcall(function() firesignal(obj[ev]) end)
			end
		else
			-- bukan tombol: coba cari tombol di dalamnya, kalau tidak ada pakai tap
			local btn = obj:FindFirstChildWhichIsA("GuiButton", true)
			if btn then
				pcall(function() firesignal(btn.MouseButton1Click) end)
				pcall(function() firesignal(btn.Activated) end)
			else
				tapAt(obj)
			end
		end
	else
		tapAt(obj)
	end
end

-- ========== UI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "OsuAutoGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 158)
frame.Position = UDim2.new(0, 12, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
title.BorderSizePixel = 0
title.Text = "Osu Auto  (geser di sini)"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

local function makeButton(text, pos, size, color)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.AutoButtonColor = true
	b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local RED = Color3.fromRGB(200, 60, 70)
local GREEN = Color3.fromRGB(50, 170, 90)
local GRAY = Color3.fromRGB(70, 70, 90)

local toggleBtn = makeButton("OFF", UDim2.new(0, 10, 0, 38), UDim2.new(1, -20, 0, 40), RED)
local modeBtn = makeButton("Mode: Touch", UDim2.new(0, 10, 0, 84), UDim2.new(1, -20, 0, 30), GRAY)
local minus = makeButton("-", UDim2.new(0, 10, 0, 120), UDim2.new(0, 34, 0, 28), GRAY)
local plus = makeButton("+", UDim2.new(1, -44, 0, 120), UDim2.new(0, 34, 0, 28), GRAY)

local delayLabel = Instance.new("TextLabel")
delayLabel.Position = UDim2.new(0, 48, 0, 120)
delayLabel.Size = UDim2.new(1, -96, 0, 14)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay: 0.00s"
delayLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextSize = 12
delayLabel.Parent = frame

local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 48, 0, 134)
status.Size = UDim2.new(1, -96, 0, 14)
status.BackgroundTransparency = 1
status.Text = "Menunggu..."
status.TextColor3 = Color3.fromRGB(150, 200, 255)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = frame

toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggleBtn.Text = enabled and "ON" or "OFF"
	toggleBtn.BackgroundColor3 = enabled and GREEN or RED
	if not enabled then status.Text = "Berhenti" end
end)

modeBtn.MouseButton1Click:Connect(function()
	mode = (mode == "Touch") and "Signal" or "Touch"
	modeBtn.Text = "Mode: " .. mode
end)

local function refreshDelay()
	delayLabel.Text = string.format("Delay: %.2fs", delay)
end
minus.MouseButton1Click:Connect(function()
	delay = math.max(0, math.floor((delay - 0.05) * 100 + 0.5) / 100)
	refreshDelay()
end)
plus.MouseButton1Click:Connect(function()
	delay = math.min(1, math.floor((delay + 0.05) * 100 + 0.5) / 100)
	refreshDelay()
end)

-- drag (touch & mouse)
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

-- ========== Loop utama ==========
local conn
conn = RunService.Heartbeat:Connect(function()
	if not gui.Parent then
		conn:Disconnect()
		return
	end
	if not enabled then return end

	local circle, num = getNext()
	if not circle then
		status.Text = "Menunggu circle..."
		return
	end

	local now = tick()
	if now - lastClick < delay then return end
	if clicked[circle] and now - clicked[circle] < retryCooldown then return end

	clicked[circle] = now
	lastClick = now
	status.Text = "Klik #" .. num
	clickObject(circle)
end)

-- bersihkan cache circle yang sudah hilang
task.spawn(function()
	while gui.Parent do
		task.wait(2)
		for inst in pairs(clicked) do
			if not inst.Parent then clicked[inst] = nil end
		end
	end
end)
