local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local characters = ReplicatedStorage:WaitForChild("Characters")

local function playAnimOnServer(humanoid, id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	local animator = humanoid:FindFirstChild("Animator")
	if animator then
		local track = animator:LoadAnimation(anim)
		track:Play()
		return track
	end
end

remotes.MorphEvent.OnServerEvent:Connect(function(player, morphName)
	local model = characters:FindFirstChild(morphName)
	if not model then return end
	
	local oldChar = player.Character
	local newChar = model:Clone()
	newChar.Name = player.Name
	newChar:SetPrimaryPartCFrame(oldChar:GetPrimaryPartCFrame())
	
	-- 1. Ensure Animator exists
	local newHum = newChar:FindFirstChild("Humanoid")
	if newHum and not newHum:FindFirstChild("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = newHum
	end
	
	-- 2. Copy the Animate script from the old character so standard walking works
	local oldAnimate = oldChar:FindFirstChild("Animate")
	if oldAnimate then
		local newAnimate = oldAnimate:Clone()
		newAnimate.Parent = newChar
	end
	
	player.Character = newChar
	newChar.Parent = workspace
	oldChar:Destroy()
	
	-- 3. Pass the new character directly to the client
	remotes.MorphEvent:FireClient(player, morphName, newChar)
end)

-- Ability 1: Charge
remotes.ChargeEvent.OnServerEvent:Connect(function(player, targetPosition)
	local char = player.Character
	if not char or char.Name ~= "2011X" then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	
	for i = 1, 2 do
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.Color = Color3.new(1, 0, 0) end
		end
		task.wait(0.2)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.Color = Color3.new(1, 1, 1) end
		end
		task.wait(0.2)
	end
	
	task.wait(1.6)
	
	local bodyVelocity = Instance.new("LinearVelocity", root)
	local attachment = Instance.new("Attachment", root)
	bodyVelocity.Attachment0 = attachment
	bodyVelocity.MaxForce = math.huge
	
	local direction = (targetPosition - root.Position).Unit
	bodyVelocity.VectorVelocity = direction * 50
	
	local connection
	local startTime = os.clock()
	
	connection = RunService.Heartbeat:Connect(function()
		if os.clock() - startTime >= 5 then
			bodyVelocity:Destroy()
			attachment:Destroy()
			connection:Disconnect()
			return
		end
		
		local hit = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0,0,-2), Vector3.new(4,5,4))
		for _, v in ipairs(hit) do
			local targetChar = v.Parent
			local targetHum = targetChar:FindFirstChild("Humanoid")
			
			if targetHum and targetHum ~= hum and targetHum:FindFirstChild("survivor") then
				bodyVelocity:Destroy()
				attachment:Destroy()
				connection:Disconnect()
				
				hum.WalkSpeed = 0
				targetHum.WalkSpeed = 0
				
				root.CFrame = targetChar.PrimaryPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
				
				playAnimOnServer(hum, 85098189190021)
				playAnimOnServer(targetHum, 132281879455672)
				
				for i = 1, 25 do
					targetHum:TakeDamage(1)
					task.wait(0.1)
				end
				
				targetHum.WalkSpeed = 16
				task.wait(5)
				hum.WalkSpeed = 16
				return
			end
		end
	end)
end)

-- Ability 2: Hitbox
remotes.HitEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char or char.Name ~= "2011X" then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	
	local hitboxCFrame = root.CFrame * CFrame.new(0, 0, -3)
	local hitParts = workspace:GetPartBoundsInBox(hitboxCFrame, Vector3.new(4, 5, 4))
	local alreadyHit = {}
	
	for _, part in ipairs(hitParts) do
		local targetChar = part.Parent
		local targetHum = targetChar:FindFirstChild("Humanoid")
		
		if targetHum and targetHum ~= hum and not alreadyHit[targetHum] and targetHum:FindFirstChild("survivor") then
			alreadyHit[targetHum] = true
			
			if targetHum.Health <= 40 then
				targetHum.Health = 0.1 
				targetChar.PrimaryPart.Anchored = true
				root.Anchored = true
				
				targetChar.PrimaryPart.CFrame = root.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
				
				playAnimOnServer(hum, 76544545227709)
				task.wait(2)
				
				targetHum.Health = 0 
				targetChar.PrimaryPart.Anchored = false
				root.Anchored = false
			else
				targetHum:TakeDamage(40)
			end
		end
	end
end)