local player = game.Players.LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local aimbotEnabled = true
local espEnabled = true

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

-- Menü öffnen
openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- Aimbot Toggle
aimbotButton.MouseButton1Click:Connect(function()

	aimbotEnabled = not aimbotEnabled
	
	if aimbotEnabled then
		aimbotButton.Text = "Aimbot ON"
	else
		aimbotButton.Text = "Aimbot OFF"
	end
	
end)

-- ESP Toggle
espButton.MouseButton1Click:Connect(function()

	espEnabled = not espEnabled
	
	if espEnabled then
		espButton.Text = "ESP ON"
	else
		espButton.Text = "ESP OFF"
	end
	
end)

-- Sichtprüfung (Wall Check)
function canSeeTarget(targetPart)

	if not player.Character then return false end
	
	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction, params)

	if result then
		if result.Instance:IsDescendantOf(targetPart.Parent) then
			return true
		else
			return false
		end
	end

	return true
end

-- nächsten sichtbaren Gegner finden
function getClosestEnemy()

	local closest = nil
	local shortestDistance = math.huge
	
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local myPos = player.Character.HumanoidRootPart.Position
	
	for _,v in pairs(players:GetPlayers()) do
		
		if v ~= player
		and v.Character
		and v.Character:FindFirstChild("Head")
		and v.Character:FindFirstChild("HumanoidRootPart")
		and v.Character:FindFirstChildOfClass("Humanoid") then
			
			local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
			
			if humanoid.Health > 0 then
				
				local head = v.Character.Head
				
				if canSeeTarget(head) then
					
					local distance = (head.Position - myPos).Magnitude
					
					if distance < shortestDistance then
						shortestDistance = distance
						closest = v
					end
					
				end
				
			end
			
		end
		
	end
	
	return closest
	
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

-- Hauptloop
runService.RenderStepped:Connect(function()

	updateESP()

	if aimbotEnabled then
		
		local target = getClosestEnemy()
		
		if target and target.Character then
			
			local head = target.Character:FindFirstChild("Head")
			
			if head then
				camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
			end
			
		end
		
	end
	
end)
