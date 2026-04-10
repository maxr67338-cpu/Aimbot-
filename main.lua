local player = game.Players.LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local aimbotEnabled = true
local espEnabled = true

-- SETTINGS
local maxDistance = 300
local maxFOV = 200 -- kleiner = stärkerer Fokus auf Mitte

-- GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0,120,0,40)
openButton.Position = UDim2.new(0,20,0,20)
openButton.Text = "MENU"
openButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
openButton.TextColor3 = Color3.new(1,1,1)
openButton.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,230,0,170)
frame.Position = UDim2.new(0.5,-115,0.5,-85)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "Combat Menu"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(35,35,35)
title.Parent = frame

local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1,-20,0,40)
aimbotButton.Position = UDim2.new(0,10,0,60)
aimbotButton.Text = "Aimbot ON"
aimbotButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
aimbotButton.TextColor3 = Color3.new(1,1,1)
aimbotButton.Parent = frame

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1,-20,0,40)
espButton.Position = UDim2.new(0,10,0,110)
espButton.Text = "ESP ON"
espButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
espButton.TextColor3 = Color3.new(1,1,1)
espButton.Parent = frame

openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

aimbotButton.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotButton.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
end)

espButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espButton.Text = espEnabled and "ESP ON" or "ESP OFF"
end)

-- WALL CHECK
function canSee(target)
	local origin = camera.CFrame.Position
	local direction = (target.Position - origin)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction, params)

	if result then
		return result.Instance:IsDescendantOf(target.Parent)
	end

	return true
end

-- SCREEN CHECK + BEST TARGET
function getBestTarget()

	local bestTarget = nil
	local shortest = math.huge
	
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

	for _,v in pairs(players:GetPlayers()) do
		
		if v ~= player
		and v.Team ~= player.Team
		and v.Character
		and v.Character:FindFirstChild("Head") then
			
			local head = v.Character.Head
			
			-- auf Bildschirm projizieren
			local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
			
			if onScreen then
				
				local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
				local distanceFromCenter = (screenPoint - screenCenter).Magnitude
				
				if distanceFromCenter < maxFOV then
					
					if canSee(head) then
						
						if distanceFromCenter < shortest then
							shortest = distanceFromCenter
							bestTarget = v
						end
						
					end
					
				end
				
			end
			
		end
		
	end
	
	return bestTarget
	
end

-- ESP
function updateESP()
	for _,v in pairs(players:GetPlayers()) do
		
		if v ~= player and v.Character then
			
			local highlight = v.Character:FindFirstChild("EnemyHighlight")
			
			if espEnabled and v.Team ~= player.Team then
				
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "EnemyHighlight"
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

-- LOOP
runService.RenderStepped:Connect(function()

	updateESP()

	if aimbotEnabled then
		
		local target = getBestTarget()
		
		if target and target.Character then
			
			local head = target.Character:FindFirstChild("Head")
			
			if head then
				camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
			end
			
		end
		
	end
	
end)
