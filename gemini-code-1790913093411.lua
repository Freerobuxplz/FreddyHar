local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local charactersFolder = ReplicatedStorage:WaitForChild("Characters")

---------------------------------------------------------
-- 1. MORPH SELECTION UI ("BECOME")
---------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")

local morphGui = Instance.new("ScreenGui", playerGui)
morphGui.Name = "MorphSelectionUI"
morphGui.ResetOnSpawn = false
morphGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame", morphGui)
mainFrame.Size = UDim2.new(0.45, 0, 0.65, 0)
mainFrame.Position = UDim2.new(0.275, 0, 0.175, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0.12, 0)
title.Text = "BECOME"
title.TextColor3 = Color3.fromRGB(220, 20, 20)
title.TextScaled = true
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold

local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Size = UDim2.new(0.92, 0, 0.82, 0)
scrollFrame.Position = UDim2.new(0.04, 0, 0.14, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6

local grid = Instance.new("UIGridLayout", scrollFrame)
grid.CellSize = UDim2.new(0, 130, 0, 160)
grid.CellPadding = UDim2.new(0, 12, 0, 12)

for _, charModel in ipairs(charactersFolder:GetChildren()) do
	local btn = Instance.new("TextButton", scrollFrame)
	btn.Text = ""
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(1, 0, 0.22, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.78, 0)
	nameLabel.Text = charModel.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamMedium
	
	local viewport = Instance.new("ViewportFrame", btn)
	viewport.Size = UDim2.new(1, 0, 0.78, 0)
	viewport.BackgroundTransparency = 1
	
	local clone = charModel:Clone()
	clone.Parent = viewport
	
	local primary = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChildWhichIsA("BasePart")
	if primary then
		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.new(primary.Position + Vector3.new(0, 1.5, 5), primary.Position)
		cam.Parent = viewport
		viewport.CurrentCamera = cam
	end
	
	btn.MouseButton1Click:Connect(function()
		remotes.MorphEvent:FireServer(charModel.Name)
		mainFrame.Visible = false
	end)
end

---------------------------------------------------------
-- 2. ABILITY HUD
---------------------------------------------------------
local abilityGui = Instance.new("ScreenGui", playerGui)
abilityGui.Name = "AbilityHUD"
abilityGui.ResetOnSpawn = false
abilityGui.Enabled = false

local abilityFrame = Instance.new("Frame", abilityGui)
abilityFrame.Size = UDim2.new(0, 310, 0, 85)
abilityFrame.Position = UDim2.new(0.5, -155, 0.86, 0)
abilityFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
abilityFrame.BackgroundTransparency = 0.25
Instance.new("UICorner", abilityFrame).CornerRadius = UDim.new(0, 10)

local listLayout = Instance.new("UIListLayout", abilityFrame)
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 10)

local function createAbilityButton(name, hint)
	local btn = Instance.new("TextButton", abilityFrame)
	btn.Size = UDim2.new(0, 90, 0, 65)
	btn.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
	btn.Text = name .. "\n[" .. hint .. "]"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local chargeBtn = createAbilityButton("CHARGE", "Q")
local hitBtn = createAbilityButton("HIT", "E/M1")
local sprintBtn = createAbilityButton("SPRINT", "SHIFT")

---------------------------------------------------------
-- 3. ANIMATION MANAGEMENT & ACTIONS
---------------------------------------------------------
local is2011X = false
local isSprinting = false
local cooldowns = {Charge = false, Hit = false}
local animTracks = {}

local function loadClientAnim(animator, id, priority)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	local track = animator:LoadAnimation(anim)
	track.Priority = priority or Enum.AnimationPriority.Action3
	return track
end

local function doCharge()
	if cooldowns.Charge or not is2011X then return end
	cooldowns.Charge = true
	
	if animTracks.Charge then animTracks.Charge:Play() end
	remotes.ChargeEvent:FireServer(mouse.Hit.Position)
	
	task.spawn(function()
		for i = 30, 1, -1 do
			chargeBtn.Text = "CHARGE\n(" .. i .. "s)"
			chargeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			task.wait(1)
		end
		chargeBtn.Text = "CHARGE\n[Q]"
		chargeBtn.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
		cooldowns.Charge = false
	end)
end

local function doHit()
	if cooldowns.Hit or not is2011X then return end
	cooldowns.Hit = true
	
	if animTracks.Hit then animTracks.Hit:Play() end
	remotes.HitEvent:FireServer()
	
	task.spawn(function()
		hitBtn.Text = "HIT\n(CD...)"
		hitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		task.wait(1.5)
		hitBtn.Text = "HIT\n[E/M1]"
		hitBtn.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
		cooldowns.Hit = false
	end)
end

local function toggleSprint(forcedState)
	if not is2011X then return end
	local char = player.Character
	if not char or not char:FindFirstChildOfClass("Humanoid") then return end
	
	isSprinting = (forcedState ~= nil) and forcedState or not isSprinting
	
	if isSprinting then
		char.Humanoid.WalkSpeed = 24
		sprintBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 0)
		if animTracks.Sprint and not animTracks.Sprint.IsPlaying then
			animTracks.Sprint:Play()
		end
	else
		char.Humanoid.WalkSpeed = 16
		sprintBtn.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
		if animTracks.Sprint and animTracks.Sprint.IsPlaying then
			animTracks.Sprint:Stop(0.1)
		end
	end
end

chargeBtn.MouseButton1Click:Connect(doCharge)
hitBtn.MouseButton1Click:Connect(doHit)
sprintBtn.MouseButton1Click:Connect(function() toggleSprint() end)

---------------------------------------------------------
-- 4. MORPH CLIENT SETUP
---------------------------------------------------------
remotes.MorphEvent.OnClientEvent:Connect(function(morphName, newChar)
	if morphName == "2011X" then
		is2011X = true
		abilityGui.Enabled = true
		
		local hum = newChar:WaitForChild("Humanoid")
		local animator = hum:WaitForChild("Animator")
		local animate = newChar:WaitForChild("Animate", 5)
		
		-- Safely override standard walking/idle track IDs
		if animate then
			local idleAnim = animate:FindFirstChild("idle")
			if idleAnim and idleAnim:FindFirstChild("Animation1") then
				idleAnim.Animation1.AnimationId = "rbxassetid://119542689978384"
			end
			
			local walkAnim = animate:FindFirstChild("walk")
			if walkAnim and walkAnim:FindFirstChild("WalkAnim") then
				walkAnim.WalkAnim.AnimationId = "rbxassetid://112299300414259"
			end
			
			local runAnim = animate:FindFirstChild("run")
			if runAnim and runAnim:FindFirstChild("RunAnim") then
				runAnim.RunAnim.AnimationId = "rbxassetid://112299300414259"
			end
		end
		
		-- Preload abilities with high priorities to prevent movement glitching
		animTracks.Sprint = loadClientAnim(animator, 124733123370196, Enum.AnimationPriority.Action2)
		animTracks.Charge = loadClientAnim(animator, 108828185445742, Enum.AnimationPriority.Action3)
		animTracks.Hit = loadClientAnim(animator, 138947059073077, Enum.AnimationPriority.Action3)
	else
		is2011X = false
		abilityGui.Enabled = false
	end
end)

-- Inputs for PC & Xbox Controller
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not is2011X then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		toggleSprint(true)
	elseif input.KeyCode == Enum.KeyCode.Q then
		doCharge()
	elseif input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 then
		doHit()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if not is2011X then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		toggleSprint(false)
	end
end)