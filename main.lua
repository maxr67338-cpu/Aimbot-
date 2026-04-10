local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

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

-- WALL CHECK
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

-- TARGET SYSTEM
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

-- ESP SYSTEM (mit Health + Name)
local function updateESP()
	for _,v in pairs(Players:GetPlayers()) do
		
		if v ~= player and v.Character then
			
			local char = v.Character
			local humanoid = char:FindFirstChild("Humanoid")
			local head = char:FindFirstChild("Head")
			
			if not humanoid or not head then continue end
			
			local highlight = char:FindFirstChild("ESP_HIGHLIGHT")
			local billboard = char:FindFirstChild("ESP_UI")
			
			if espEnabled and v.Team ~= player.Team then
				
				-- Highlight
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ESP_HIGHLIGHT"
					highlight.FillColor = Color3.fromRGB(255,0,0)
					highlight.OutlineColor = Color3.new(1,1,1)
					highlight.Parent = char
				end
				
				-- Billboard GUI (Name + Health)
				if not billboard then
					billboard = Instance.new("BillboardGui")
					billboard.Name = "ESP_UI"
					billboard.Size = UDim2.new(0,100,0,40)
					billboard.StudsOffset = Vector3.new(0,2.5,0)
					billboard.AlwaysOnTop = true
					billboard.Parent = head
					
					local text = Instance.new("TextLabel")
					text.Size = UDim2.new(1,0,1,0)
					text.BackgroundTransparency = 1
					text.TextColor3 = Color3.new(1,1,1)
					text.TextStrokeTransparency = 0
					text.Parent = billboard
				end
				
				-- Update Text
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
