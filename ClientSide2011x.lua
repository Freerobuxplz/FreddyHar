local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local charactersFolder = ReplicatedStorage:WaitForChild("Characters")

-- UI Creation
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "MorphUI"
screenGui.ResetOnSpawn = false

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

-- Populate Characters
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
		cam.CFrame = CFrame.new(Vector3.new(0, 3, 5), clone.PrimaryPart.Position)
		viewport.CurrentCamera = cam
	end
	
	btn.MouseButton1Click:Connect(function()
		remotes.MorphEvent:FireServer(charModel.Name)
		mainFrame.Visible = false -- Hide UI after picking
	end)
end

-- 2011X Abilities & Inputs
local is2011X = false
local cooldowns = {Charge = false, Hit = false}
local animTracks = {}

local function loadAnim(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	return player.Character.Humanoid.Animator:LoadAnimation(anim)
end

remotes.MorphEvent.OnClientEvent:Connect(function(morphName)
	if morphName == "2011X" then
		is2011X = true
		local char = player.Character
		-- Replace default animations
		local animate = char:WaitForChild("Animate")
		animate.idle.Animation1.AnimationId = "rbxassetid://119542689978384"
		animate.walk.WalkAnim.AnimationId = "rbxassetid://112299300414259"
		animate.run.RunAnim.AnimationId = "rbxassetid://112299300414259"
		
		animTracks.Sprint = loadAnim(124733123370196)
		animTracks.Charge = loadAnim(108828185445742)
		animTracks.Hit = loadAnim(138947059073077)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not is2011X then return end
	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") then return end
	
	-- Sprint (Shift / LT)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		char.Humanoid.WalkSpeed = 24
		if not animTracks.Sprint.IsPlaying then animTracks.Sprint:Play() end
	end
	
	-- Ability 1: Charge (Key Q)
	if input.KeyCode == Enum.KeyCode.Q and not cooldowns.Charge then
		cooldowns.Charge = true
		animTracks.Charge:Play()
		remotes.ChargeEvent:FireServer(mouse.Hit.Position)
		task.wait(30)
		cooldowns.Charge = false
	end
	
	-- Ability 2: Hit (Key E or M1)
	if (input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1) and not cooldowns.Hit then
		cooldowns.Hit = true
		animTracks.Hit:Play()
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