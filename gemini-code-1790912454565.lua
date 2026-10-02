local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local charactersFolder = ReplicatedStorage:WaitForChild("Characters")

-- UI Creation
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "MorphUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame", screenGui)
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

-- Abilities handling
local is2011X = false
local cooldowns = {Charge = false, Hit = false}
local animTracks = {}

local function createAnim(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	return anim
end

remotes.MorphEvent.OnClientEvent:Connect(function(morphName, newChar)
	if morphName == "2011X" then
		is2011X = true
		
		-- Wait for the server to replicate the new Humanoid and Animator
		local hum = newChar:WaitForChild("Humanoid")
		local animator = hum:WaitForChild("Animator")
		local animate = newChar:WaitForChild("Animate", 5)
		
		if animate then
			-- Update default animations inside the Animate script safely
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
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not is2011X then return end
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		char.Humanoid.WalkSpeed = 24
		if animTracks.Sprint and not animTracks.Sprint.IsPlaying then animTracks.Sprint:Play() end
	end
	
	if input.KeyCode == Enum.KeyCode.Q and not cooldowns.Charge then
		cooldowns.Charge = true
		if animTracks.Charge then animTracks.Charge:Play() end
		remotes.ChargeEvent:FireServer(mouse.Hit.Position)
		task.wait(30)
		cooldowns.Charge = false
	end
	
	if (input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1) and not cooldowns.Hit then
		cooldowns.Hit = true
		if animTracks.Hit then animTracks.Hit:Play() end
		remotes.HitEvent:FireServer()
		task.wait(1.5)
		cooldowns.Hit = false
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if not is2011X then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 16
		end
		if animTracks.Sprint and animTracks.Sprint.IsPlaying then
			animTracks.Sprint:Stop()
		end
	end
end)