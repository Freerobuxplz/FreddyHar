local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
mainFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
mainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Text = "BECOME"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold

local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Size = UDim2.new(1, 0, 0.9, 0)
scrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
scrollFrame.BackgroundTransparency = 1

local grid = Instance.new("UIGridLayout", scrollFrame)
grid.CellSize = UDim2.new(0, 120, 0, 150)
grid.CellPadding = UDim2.new(0, 10, 0, 10)

-- Populate Morph Options
for _, charModel in ipairs(charactersFolder:GetChildren()) do
	local btn = Instance.new("TextButton", scrollFrame)
	btn.Text = ""
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	
	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.8, 0)
	nameLabel.Text = charModel.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	
	local viewport = Instance.new("ViewportFrame", btn)
	viewport.Size = UDim2.new(1, 0, 0.8, 0)
	viewport.BackgroundTransparency = 1
	
	local clone = charModel:Clone()
	clone.Parent = viewport
	
	if clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.new(Vector3.new(0, 3, 6), clone.PrimaryPart.Position)
		cam.Parent = viewport
		viewport.CurrentCamera = cam
	end
	
	btn.MouseButton1Click:Connect(function()
		remotes.MorphEvent:FireServer(charModel.Name)
		mainFrame.Visible = false
	end)
end

---------------------------------------------------------
-- 2. 2011X ABILITY HUD & ACTIONS
---------------------------------------------------------
local abilityGui = Instance.new("ScreenGui", playerGui)
abilityGui.Name = "AbilityHUD"
abilityGui.ResetOnSpawn = false
abilityGui.Enabled = false

local abilityFrame = Instance.new("Frame", abilityGui)
abilityFrame.Size = UDim2.new(0, 320, 0, 90)
abilityFrame.Position = UDim2.new(0.5, -160, 0.85, 0)
abilityFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
abilityFrame.BackgroundTransparency = 0.3

local listLayout = Instance.new("UIListLayout", abilityFrame)
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 10)

local function createAbilityButton(name, keyHint)
	local btn = Instance.new("TextButton", abilityFrame)
	btn.Size = UDim2.new(0, 90, 0, 70)
	btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	btn.Text = name .. "\n[" .. keyHint .. "]"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = true
	
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)
	
	return btn
end

local chargeBtn = createAbilityButton("CHARGE", "Q")
local hitBtn = createAbilityButton("HIT", "E / M1")
local sprintBtn = createAbilityButton("SPRINT", "SHIFT")

---------------------------------------------------------
-- 3. ABILITY STATE & ANIMATIONS
---------------------------------------------------------
local is2011X = false
local isSprinting = false
local cooldowns = {Charge = false, Hit = false}
local animTracks = {}

local function createAnim(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	return anim
end

-- Ability Logic Functions
local function doCharge()
	if cooldowns.Charge or not is2011X then return end
	cooldowns.Charge = true
	
	if animTracks.Charge then animTracks.Charge:Play() end
	remotes.ChargeEvent:FireServer(mouse.Hit.Position)
	
	-- Cooldown Visualizer (30s)
	task.spawn(function()
		for i = 30, 1, -1 do
			chargeBtn.Text = "CHARGE\n(" .. i .. "s)"
			chargeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			task.wait(1)
		end
		chargeBtn.Text = "CHARGE\n[Q]"
		chargeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		cooldowns.Charge = false
	end)
end

local function doHit()
	if cooldowns.Hit or not is2011X then return end
	cooldowns.Hit = true
	
	if animTracks.Hit then animTracks.Hit:Play() end
	remotes.HitEvent:FireServer()
	
	-- Cooldown Visualizer (1.5s)
	task.spawn(function()
		hitBtn.Text = "HIT\n(CD...)"
		hitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		task.wait(1.5)
		hitBtn.Text = "HIT\n[E / M1]"
		hitBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		cooldowns.Hit = false
	end)
end

local function toggleSprint(forcedState)
	if not is2011X then return end
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") then return end
	
	if forcedState ~= nil then
		isSprinting = forcedState
	else
		isSprinting = not isSprinting
	end
	
	if isSprinting then
		char.Humanoid.WalkSpeed = 24
		sprintBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		if animTracks.Sprint and not animTracks.Sprint.IsPlaying then
			animTracks.Sprint:Play()
		end
	else
		char.Humanoid.WalkSpeed = 16
		sprintBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		if animTracks.Sprint and animTracks.Sprint.IsPlaying then
			animTracks.Sprint:Stop()
		end
	end
end

-- UI Click Connectors
chargeBtn.MouseButton1Click:Connect(doCharge)
hitBtn.MouseButton1Click:Connect(doHit)
sprintBtn.MouseButton1Click:Connect(function()
	toggleSprint()
end)

---------------------------------------------------------
-- 4. MORPH LISTENERS & INPUTS
---------------------------------------------------------
remotes.MorphEvent.OnClientEvent:Connect(function(morphName, newChar)
	if morphName == "2011X" then
		is2011X = true
		abilityGui.Enabled = true -- Show Ability UI
		
		local hum = newChar:WaitForChild("Humanoid")
		local animator = hum:WaitForChild("Animator")
		local animate = newChar:WaitForChild("Animate", 5)
		
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
		
		animTracks.Sprint = animator:LoadAnimation(createAnim(124733123370196))
		animTracks.Charge = animator:LoadAnimation(createAnim(108828185445742))
		animTracks.Hit = animator:LoadAnimation(createAnim(138947059073077))
	else
		is2011X = false
		abilityGui.Enabled = false
	end
end)

-- Keyboard / Controller Binds
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