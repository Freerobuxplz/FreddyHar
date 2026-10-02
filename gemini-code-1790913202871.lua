local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local characters = ReplicatedStorage:WaitForChild("Characters")

-- Helper: Safely find survivor Character & Humanoid regardless of tag location
local function getSurvivor(part, attackerChar)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model or model == attackerChar then return nil, nil end
	
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil, nil end
	
	-- Checks if a StringValue or Child named "survivor" exists anywhere in the model
	local survivorTag = model:FindFirstChild("survivor", true)
	if survivorTag then
		return model, hum
	end
	return nil, nil
end

-- Helper: Play server animations with maximum priority and stop movement blending
local function playServerAnim(humanoid, id, priority)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	
	-- Stop competing tracks so animations don't blend
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	local track = animator:LoadAnimation(anim)
	track.Priority = priority or Enum.AnimationPriority.Action4
	track:Play()
	return track
end

-- Helper: Face two characters toward each other
local function alignFacing(charA, charB, distance)
	local rootA = charA.PrimaryPart or charA:FindFirstChild("HumanoidRootPart")
	local rootB = charB.PrimaryPart or charB:FindFirstChild("HumanoidRootPart")
	if not rootA or not rootB then return end
	
	local posA = rootA.Position
	local targetPosB = posA + (rootA.CFrame.LookVector * (distance or 3))
	
	rootB.CFrame = CFrame.lookAt(targetPosB, Vector3.new(posA.X, targetPosB.Y, posA.Z))
	rootA.CFrame = CFrame.lookAt(posA, Vector3.new(targetPosB.X, posA.Y, targetPosB.Z))
end

---------------------------------------------------------
-- MORPH HANDLER
---------------------------------------------------------
remotes.MorphEvent.OnServerEvent:Connect(function(player, morphName)
	local model = characters:FindFirstChild(morphName)
	if not model then return end
	
	local oldChar = player.Character
	local newChar = model:Clone()
	newChar.Name = player.Name
	
	if oldChar and oldChar.PrimaryPart then
		newChar:SetPrimaryPartCFrame(oldChar.PrimaryPart.CFrame)
	end
	
	local newHum = newChar:FindFirstChildOfClass("Humanoid")
	if newHum and not newHum:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", newHum)
	end
	
	if oldChar and oldChar:FindFirstChild("Animate") then
		local newAnimate = oldChar.Animate:Clone()
		newAnimate.Parent = newChar
	end
	
	player.Character = newChar
	newChar.Parent = workspace
	if oldChar then oldChar:Destroy() end
	
	remotes.MorphEvent:FireClient(player, morphName, newChar)
end)

---------------------------------------------------------
-- ABILITY 1: CHARGE
---------------------------------------------------------
remotes.ChargeEvent.OnServerEvent:Connect(function(player, targetPosition)
	local char = player.Character
	if not char or char.Name ~= "2011X" then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	
	-- 1. Flash Red Twice
	local originalColors = {}
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then originalColors[part] = part.Color end
	end
	
	for i = 1, 2 do
		for part in pairs(originalColors) do part.Color = Color3.fromRGB(255, 0, 0) end
		task.wait(0.2)
		for part, col in pairs(originalColors) do part.Color = col end
		task.wait(0.2)
	end
	
	task.wait(1.6) -- Finish 2-second windup
	
	-- 2. Glide Physics
	local attachment = Instance.new("Attachment", root)
	local linearVelocity = Instance.new("LinearVelocity", root)
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 100000
	
	local direction = (targetPosition - root.Position).Unit
	linearVelocity.VectorVelocity = direction * 60
	
	playServerAnim(hum, 108828185445742, Enum.AnimationPriority.Action3)
	
	local startTime = os.clock()
	local connection
	local intercepted = false
	
	connection = RunService.Heartbeat:Connect(function()
		if intercepted then return end
		
		if os.clock() - startTime >= 5 then
			linearVelocity:Destroy()
			attachment:Destroy()
			connection:Disconnect()
			return
		end
		
		-- Hitbox Detection
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {char}
		
		local hitParts = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -2), Vector3.new(5, 6, 5), overlapParams)
		
		for _, part in ipairs(hitParts) do
			local targetChar, targetHum = getSurvivor(part, char)
			
			if targetChar and targetHum then
				intercepted = true
				linearVelocity:Destroy()
				attachment:Destroy()
				connection:Disconnect()
				
				-- Freeze both characters
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				targetHum.WalkSpeed = 0
				targetHum.JumpPower = 0
				
				-- Teleport in front & face each other
				alignFacing(char, targetChar, 3.5)
				
				-- Play Grab Animations
				playServerAnim(hum, 85098189190021, Enum.AnimationPriority.Action4)
				local victimTrack = playServerAnim(targetHum, 132281879455672, Enum.AnimationPriority.Action4)
				
				-- 25 Damage Ticks
				for i = 1, 25 do
					if targetHum and targetHum.Health > 0 then
						targetHum.Health = math.max(0, targetHum.Health - 1)
					end
					task.wait(0.08)
				end
				
				-- Unfreeze Survivor
				if victimTrack then victimTrack:Stop() end
				targetHum.WalkSpeed = 16
				targetHum.JumpPower = 50
				
				-- 2011X Remains Frozen for 5 Seconds
				task.wait(5)
				hum.WalkSpeed = 16
				hum.JumpPower = 50
				return
			end
		end
	end)
end)

---------------------------------------------------------
-- ABILITY 2: HIT & KILL EXECUTION
---------------------------------------------------------
remotes.HitEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char or char.Name ~= "2011X" then return end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	
	playServerAnim(hum, 138947059073077, Enum.AnimationPriority.Action3)
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {char}
	
	local hitParts = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -3), Vector3.new(5, 6, 5), overlapParams)
	local processedSurvivors = {}
	
	for _, part in ipairs(hitParts) do
		local targetChar, targetHum = getSurvivor(part, char)
		
		if targetChar and targetHum and not processedSurvivors[targetChar] then
			processedSurvivors[targetChar] = true
			
			-- Execution Condition: Health <= 40
			if targetHum.Health <= 40 then
				local targetRoot = targetChar.PrimaryPart or targetChar:FindFirstChild("HumanoidRootPart")
				
				-- Freeze & Anchor Both
				hum.WalkSpeed = 0
				targetHum.WalkSpeed = 0
				if root then root.Anchored = true end
				if targetRoot then targetRoot.Anchored = true end
				
				-- Align Facing
				alignFacing(char, targetChar, 3)
				
				-- Play Kill Animation
				playServerAnim(hum, 76544545227709, Enum.AnimationPriority.Action4)
				
				task.wait(2)
				
				-- Kill & Unanchor
				if root then root.Anchored = false end
				if targetRoot then targetRoot.Anchored = false end
				hum.WalkSpeed = 16
				
				targetHum.Health = 0 -- Triggers Ragdoll / Death
			else
				-- Standard Hit Damage
				targetHum.Health = math.max(0, targetHum.Health - 40)
			end
		end
	end
end)