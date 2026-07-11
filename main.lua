local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getCharacter()
	return player.Character
end

local aimbotEnabled = false -- Startet auf false, bis Key korrekt ist
local espEnabled = false    -- Startet auf false, bis Key korrekt ist
local keyVerified = false   -- Status für das Key-System
local correctKey = "Maxistcool33" -- Der verlangte Key

local maxFOV = 200

-- MAIN GUI CONTAINER
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "CustomMenuGui"
gui.Parent = player:WaitForChild("PlayerGui")

-----------------------------------------------------------------
-- KEY SYSTEM GUI (Öffnet sich zuerst)
----------------------------------------------------------------
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 300, 0, 150)
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
keyFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
keyFrame.ZIndex = 100000000 -- REPARIERT: Maximaler ZIndex im globalen Raum
keyFrame.Parent = gui

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 10)
keyTitle.Text = "Bitte Key eingeben:"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.BackgroundTransparency = 1
keyTitle.ZIndex = 100000001 -- Liegt direkt über dem keyFrame
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.PlaceholderText = "Hier Key einfügen..."
keyInput.Text = ""
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.ZIndex = 100000001 -- Liegt direkt über dem keyFrame
keyInput.Parent = keyFrame

local keySubmit = Instance.new("TextButton")
keySubmit.Size = UDim2.new(1, -40, 0, 35)
keySubmit.Position = UDim2.new(0, 20, 0, 95)
keySubmit.Text = "Überprüfen"
keySubmit.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
keySubmit.TextColor3 = Color3.new(1, 1, 1)
keySubmit.ZIndex = 100000001 -- Liegt direkt über dem keyFrame
keySubmit.Parent = keyFrame
----------------------------------------------------------------
-- CHEAT MENU GUI (Bleibt unsichtbar bis Key korrekt)
----------------------------------------------------------------
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.Position = UDim2.new(0, 20, 0, 20)
openButton.Text = "MENU"
openButton.ZIndex = 5
openButton.Visible = false -- Unsichtbar am Anfang
openButton.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 160)
frame.Position = UDim2.new(0.5, -110, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Visible = false
frame.ZIndex = 4
frame.Parent = gui

local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(1, -20, 0, 40)
aimbotBtn.Position = UDim2.new(0, 10, 0, 20)
aimbotBtn.Text = "Aimbot OFF"
aimbotBtn.ZIndex = 5
aimbotBtn.Parent = frame

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1, -20, 0, 40)
espBtn.Position = UDim2.new(0, 10, 0, 80)
espBtn.Text = "ESP OFF"
espBtn.ZIndex = 5
espBtn.Parent = frame

----------------------------------------------------------------
-- INTERAKTIONEN & LOGIK
----------------------------------------------------------------

-- Key Überprüfung
keySubmit.Activated:Connect(function()
	if keyInput.Text == correctKey then
		keyVerified = true
		keyFrame:Destroy() -- Löscht das Key-Fenster komplett
		
		-- Schaltet die Funktionen frei
		aimbotEnabled = true
		espEnabled = true
		aimbotBtn.Text = "Aimbot ON"
		espBtn.Text = "ESP ON"
		
		-- Macht den Menü-Button sichtbar
		openButton.Visible = true
	else
		keyInput.Text = ""
		keyInput.PlaceholderText = "Falscher Key! Erneut versuchen."
	end
end)

-- Menü öffnen/schließen
openButton.Activated:Connect(function()
	if keyVerified then
		frame.Visible = not frame.Visible
	end
end)

aimbotBtn.Activated:Connect(function()
	if not keyVerified then return end
	aimbotEnabled = not aimbotEnabled
	aimbotBtn.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
end)

espBtn.Activated:Connect(function()
	if not keyVerified then return end
	espEnabled = not espEnabled
	espBtn.Text = espEnabled and "ESP ON" or "ESP OFF"
end)

-- WALL CHECK
local function canSee(targetPart)
	local char = getCharacter()
	if not char then return false end

	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}

	local result = workspace:Raycast(origin, direction, params)

	if result then
		return result.Instance:IsDescendantOf(targetPart.Parent)
	end

	return true
end

-- TARGET SYSTEM
local function getBestTarget()
	local char = getCharacter()
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

	local screenCenter = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local bestTarget = nil
	local shortest = math.huge

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Team ~= player.Team and v.Character and v.Character:FindFirstChild("Head") then
			local head = v.Character.Head
			local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
			
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if dist < maxFOV and canSee(head) then
					if dist < shortest then
						shortest = dist
						bestTarget = v
					end
				end
			end
		end
	end

	return bestTarget
end

-- ESP SYSTEM
local function updateESP()
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character then
			local char = v.Character
			local humanoid = char:FindFirstChild("Humanoid")
			local head = char:FindFirstChild("Head")
			
			if not humanoid or not head then continue end
			
			local highlight = char:FindFirstChild("ESP_HIGHLIGHT")
			local billboard = char:FindFirstChild("ESP_UI")
			
			if espEnabled and v.Team ~= player.Team and keyVerified then
				-- Highlight
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ESP_HIGHLIGHT"
					highlight.FillColor = Color3.fromRGB(255, 0, 0)
					highlight.OutlineColor = Color3.new(1, 1, 1)
					highlight.Parent = char
				end
				
				-- Billboard GUI
				if not billboard then
					billboard = Instance.new("BillboardGui")
					billboard.Name = "ESP_UI"
					billboard.Size = UDim2.new(0, 100, 0, 40)
					billboard.StudsOffset = Vector3.new(0, 2.5, 0)
					billboard.AlwaysOnTop = true
					billboard.Parent = head
					
					local text = Instance.new("TextLabel")
					text.Size = UDim2.new(1, 0, 1, 0)
					text.BackgroundTransparency = 1
					text.TextColor3 = Color3.new(1, 1, 1)
					text.TextStrokeTransparency = 0
					text.Parent = billboard
				end
				
				local text = billboard:FindFirstChildOfClass("TextLabel")
				if text then
					text.Text = v.Name .. "\nHP: " .. math.floor(humanoid.Health)
				end
			else
				if highlight then highlight:Destroy() end
				if billboard then billboard:Destroy() end
			end
		end
	end
end

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
	-- Führt Aimbot und ESP nur aus, wenn der Key verifiziert wurde
	if not keyVerified then return end

	updateESP()

	if not aimbotEnabled then return end

	local target = getBestTarget()
	if target and target.Character then
		local head = target.Character:FindFirstChild("Head")
		if head then
			camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
		end
	end
end)
