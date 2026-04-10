local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Warten bis Character geladen ist
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local aimbotEnabled = true
local espEnabled = true

local maxFOV = 200

-- GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0,120,0,40)
openButton.Position = UDim2.new(0,20,0,20)
openButton.Text = "MENU"
openButton.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,220,0,160)
frame.Position = UDim2.new(0.5,-110,0.5,-80)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Visible = false
frame.Parent = gui

local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(1,-20,0,40)
aimbotBtn.Position = UDim2.new(0,10,0,20)
aimbotBtn.Text = "Aimbot ON"
aimbotBtn.Parent = frame

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(1,-20,0,40)
espBtn.Position = UDim2.new(0,10,0,80)
espBtn.Text = "ESP ON"
espBtn.Parent = frame

openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

aimbotBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotBtn.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
end)

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espBtn.Text = espEnabled and "ESP ON" or "ESP OFF"
end)

-- WALL CHECK (FIXED)
local function canSee(targetPart)
	local char = getCharacter()
	if not char then return false end

	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {char}

	local result = workspace:Raycast(origin, direction, params)

	if result then
		return result.Instance:IsDescendantOf(targetPart.Parent)
	end

	return true
end

-- TARGET SYSTEM (SCREEN + TEAM + WALL)
local function getBestTarget()
	local char = getCharacter()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local screenCenter = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local bestTarget = nil
	local shortest = math.huge

	for _,v in pairs(Players:GetPlayers()) do
		
		if v ~= player
		and v.Team ~= player.Team
		and v.Character
		and v.Character:FindFirstChild("Head") then
			
			local head = v.Character.Head
			
			local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
			
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				
				if dist < maxFOV then
					if canSee(head) then
						
						if dist < shortest then
							shortest = dist
							bestTarget = v
						end
						
					end
				end
			end
			
		end
		
	end

	return bestTarget
end

-- ESP (FIXED)
local function updateESP()
	for _,v in pairs(Players:GetPlayers()) do
		
		if v ~= player and v.Character then
			
			local highlight = v.Character:FindFirstChild("ESP_HIGHLIGHT")
			
			if espEnabled and v.Team ~= player.Team then
				
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ESP_HIGHLIGHT"
					highlight.FillColor = Color3.fromRGB(255,0,0)
					highlight.OutlineColor = Color3.new(1,1,1)
					highlight.Parent = v.Character
				end
				
			else
				if highlight then
					highlight:Destroy()
				end
			end
			
		end
		
	end
end

-- MAIN LOOP
RunService.RenderStepped:Connect(function()

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
