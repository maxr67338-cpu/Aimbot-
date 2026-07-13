local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local aimbotEnabled = false -- Startet auf false, bis Key korrekt ist
local espEnabled = false    -- Startet auf false, bis Key korrekt ist
local keyVerified = false   -- Status für das Key-System
local correctKey = "Maxaufdie1"

-- AIMBOT EINSTELLUNGEN
local maxFOV = 250         -- Sichtfeld-Radius für den Aimbot
local aimSmoothing = 0.9   -- 0.15 = Sehr flüssig und weich, 1.0 = Sofortiger Snap

-- MAIN GUI CONTAINER
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "CustomMenuGui"
gui.DisplayOrder = 999999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- KEY SYSTEM GUI (Ganz oben)
----------------------------------------------------------------
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 300, 0, 150)
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
keyFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
keyFrame.ZIndex = 100000000
keyFrame.Parent = gui

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 10)
keyTitle.Text = "Bitte Key eingeben:"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.BackgroundTransparency = 1
keyTitle.ZIndex = 100000001
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 35)
keyInput.Position = UDim2.new(0, 20, 0, 50)
keyInput.PlaceholderText = "Hier Key einfügen..."
keyInput.Text = ""
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.ZIndex = 100000001
keyInput.Parent = keyFrame

local keySubmit = Instance.new("TextButton")
keySubmit.Size = UDim2.new(1, -40, 0, 35)
keySubmit.Position = UDim2.new(0, 20, 0, 95)
keySubmit.Text = "Überprüfen"
keySubmit.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
keySubmit.TextColor3 = Color3.new(1, 1, 1)
keySubmit.ZIndex = 100000001
keySubmit.Parent = keyFrame

----------------------------------------------------------------
-- CHEAT MENU GUI
----------------------------------------------------------------
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.Position = UDim2.new(0, 20, 0, 20)
openButton.Text = "MENU"
openButton.ZIndex = 5
openButton.Visible = false
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
-- KONTROLLEN & AKTIONEN
----------------------------------------------------------------

keySubmit.MouseButton1Click:Connect(function()
	if keyInput.Text == correctKey then
		keyVerified = true
		keyFrame:Destroy()
		
		aimbotEnabled = true
		espEnabled = true
		aimbotBtn.Text = "Aimbot ON"
		espBtn.Text = "ESP ON"
		
		openButton.Visible = true
	else
		keyInput.Text = ""
		keyInput.PlaceholderText = "Falscher Key! Erneut versuchen."
	end
end)

openButton.MouseButton1Click:Connect(function()
	if keyVerified then
		frame.Visible = not frame.Visible
	end
end)

aimbotBtn.MouseButton1Click:Connect(function()
	if not keyVerified then return end
	aimbotEnabled = not aimbotEnabled
	aimbotBtn.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
end)

espBtn.MouseButton1Click:Connect(function()
	if not keyVerified then return end
	espEnabled = not espEnabled
	espBtn.Text = espEnabled and "ESP ON" or "ESP OFF"
end)

-- REPARIERT & MODERNISIERT: Absolut sicherer Wand-Check
local function canSee(targetPart)
	local char = getCharacter()
	if not char then return false end

	local origin = camera.CFrame.Position
	-- Richtungvektor von Kamera zum gegnerischen Kopf
	local direction = (targetPart.Position - origin)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- Ignoriert deinen eigenen Charakter, damit du nicht deine eigene Sicht blockierst
	params.FilterDescendantsInstances = {char, camera} 
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	-- Wenn der Strahl nichts trifft, ist die Sicht frei
	if not result then
		return true
	end

	-- Wenn er etwas trifft, prüfen wir, ob es zum Gegner gehört (z.B. dessen Hut oder Haare)
	if result.Instance:IsDescendantOf(targetPart.Parent) then
		return true
	end

	-- Ein Objekt (Wand, Boden) steht dazwischen
	return false
end

-- TARGET SYSTEM
local function getBestTarget()
	local char = getCharacter()
	if not char then return nil end

	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local bestTarget = nil
	local shortestDistance = math.huge

	for _, v in pairs(Players:GetPlayers()) do
		-- FILTER: Nicht man selbst UND anderes Team (oder andere Teamfarbe bei FFA)
		if v ~= player and (v.Team ~= player.Team or v.TeamColor ~= player.TeamColor) and v.Character then
			local tChar = v.Character
			local head = tChar:FindFirstChild("Head")
			local humanoid = tChar:FindFirstChild("Humanoid")
			
			-- Gegner muss leben und einen Kopf besitzen
			if head and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				
				if onScreen then
					local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					
					-- FOV-Check & Wand-Check nacheinander
					if distToCenter < maxFOV then
						if canSee(head) then
							if distToCenter < shortestDistance then
								shortestDistance = distToCenter
								bestTarget = head
							end
						end
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
			
			if espEnabled and (v.Team ~= player.Team or v.TeamColor ~= player.TeamColor) and keyVerified then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ESP_HIGHLIGHT"
					highlight.FillColor = Color3.fromRGB(255, 0, 0)
					highlight.OutlineColor = Color3.new(1, 1, 1)
					highlight.Parent = char
				end
				
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
	if not keyVerified then return end

	updateESP()

	if not aimbotEnabled then return end

	local targetHead = getBestTarget()
	if targetHead then
		-- Smooth Aim Berechnung zur Kameraposition des Ziels
		local targetCFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, aimSmoothing)
	end
end)
