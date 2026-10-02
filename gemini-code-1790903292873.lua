-- gemini-code-1790902414827.lua
-- ==========================================
-- TORNADO EF SCALE & WIND SPEEDS
-- ==========================================
local EF_DATA = {
	[1] = {Name = "EF1", WindSpeed = 30, Height = 400, BaseRad = 15, TopRad = 120, Curve = 4.0, Snake = 65, Speed = 10, Debris = 100, Cloud = 600},
	[2] = {Name = "EF2", WindSpeed = 90, Height = 450, BaseRad = 35, TopRad = 180, Curve = 3.0, Snake = 45, Speed = 12,  Debris = 150, Cloud = 700},
	[3] = {Name = "EF3", WindSpeed = 126, Height = 450, BaseRad = 75, TopRad = 250, Curve = 2.2, Snake = 30, Speed = 15,  Debris = 250, Cloud = 850},
	[4] = {Name = "EF4", WindSpeed = 150, Height = 500, BaseRad = 160, TopRad = 350, Curve = 1.5, Snake = 15, Speed = 18, Debris = 400, Cloud = 1100},
	[5] = {Name = "EF5", WindSpeed = 170, Height = 500, BaseRad = 250, TopRad = 500, Curve = 1.1, Snake = 5, Speed = 22, Debris = 600, Cloud = 1400}
}

-- Timings
local FORMATION_TIME = 8
local FUNNEL_DROP_TIME = 6
local TORNADO_LIFETIME = 45 
local DISSIPATE_TIME = 5

local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActiveDeployedProbes = {} -- Tracks probes placed on the ground

-- ==========================================
-- PLAYER SETUP (LEADERSTATS & PROBES)
-- ==========================================
local function giveProbeTool(player)
	local probesFolder = ReplicatedStorage:FindFirstChild("Probes")
	if probesFolder then
		local probeTemplate = probesFolder:FindFirstChild("Probe")
		if probeTemplate and not player.Backpack:FindFirstChild("Probe") and not (player.Character and player.Character:FindFirstChild("Probe")) then
			local newProbe = probeTemplate:Clone()
			newProbe.Parent = player.Backpack
			
			-- Handle Deploying the Probe
			newProbe.Activated:Connect(function()
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local hrp = char.HumanoidRootPart
					
					-- Create physical dropped probe
					local droppedProbe = Instance.new("Part")
					droppedProbe.Name = "DeployedProbe"
					droppedProbe.Size = Vector3.new(2, 2, 2)
					droppedProbe.Position = hrp.Position + (hrp.CFrame.LookVector * 5) - Vector3.new(0, 2, 0)
					droppedProbe.Anchored = true
					droppedProbe.Color = Color3.fromRGB(200, 100, 0)
					droppedProbe.Parent = workspace
					
					-- Proximity Prompt to pick back up
					local prompt = Instance.new("ProximityPrompt")
					prompt.ActionText = "Pick Up"
					prompt.ObjectText = "Probe"
					prompt.KeyboardKeyCode = Enum.KeyCode.E
					prompt.Parent = droppedProbe
					
					prompt.Triggered:Connect(function(plr)
						if plr == player then
							ActiveDeployedProbes[droppedProbe] = nil
							droppedProbe:Destroy()
							giveProbeTool(player)
						end
					end)
					
					-- Billboard GUI for Windspeed
					local bg = Instance.new("BillboardGui")
					bg.Size = UDim2.new(0, 200, 0, 50)
					bg.StudsOffset = Vector3.new(0, 3, 0)
					bg.AlwaysOnTop = true
					bg.Parent = droppedProbe
					
					local txt = Instance.new("TextLabel")
					txt.Size = UDim2.new(1, 0, 1, 0)
					txt.BackgroundTransparency = 1
					txt.TextColor3 = Color3.new(1, 1, 1)
					txt.TextStrokeTransparency = 0
					txt.TextScaled = true
					txt.Text = "Waiting for storm..."
					txt.Parent = bg
					
					-- Register and remove tool from inventory
					ActiveDeployedProbes[droppedProbe] = {Owner = player, UI = txt, Active = true}
					newProbe:Destroy()
				end
			end)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = ls
	
	player.CharacterAdded:Connect(function()
		giveProbeTool(player)
	end)
end)

-- ==========================================
-- TORNADO LIFETIME FUNCTION 
-- ==========================================
local function spawnTornado()
	local RATING = math.random(1, 5)
	local TORNADO = EF_DATA[RATING]
	
	-- Global Screen UI for Tornado Info
	local tornadoUI = Instance.new("ScreenGui")
	tornadoUI.Name = "TornadoStatus"
	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(1, 0, 0, 50)
	statusText.Position = UDim2.new(0, 0, 0, -50) -- Tweens down
	statusText.BackgroundTransparency = 0.5
	statusText.BackgroundColor3 = Color3.new(0,0,0)
	statusText.TextColor3 = Color3.new(1, 0, 0)
	statusText.TextScaled = true
	statusText.TextStrokeTransparency = 0
	statusText.Parent = tornadoUI
	
	for _, plr in ipairs(Players:GetPlayers()) do
		local cloneUI = tornadoUI:Clone()
		cloneUI.Parent = plr.PlayerGui
		TS:Create(cloneUI.TextLabel, TweenInfo.new(1), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	end

	local spawnLoc = workspace:FindFirstChildWhichIsA("SpawnLocation")
	local groundY = spawnLoc and spawnLoc.Position.Y or 0
	local basePos = spawnLoc and spawnLoc.Position or Vector3.new(0, groundY, 0)

	local randomAngle = math.random() * math.pi * 2
	local randomDist = math.random(200, 500)
	local stormCenter = Vector3.new(basePos.X + (math.cos(randomAngle) * randomDist), groundY, basePos.Z + (math.sin(randomAngle) * randomDist))
	
	local activeInstances = {} 

	-- 1. Create the Cloud
	local cloudPart = Instance.new("Part")
	cloudPart.Name = "SupercellCloud"
	cloudPart.Anchored = true
	cloudPart.CanCollide = false
	cloudPart.Size = Vector3.new(1, 1, 1)
	cloudPart.Transparency = 1 
	cloudPart.Color = Color3.fromRGB(50, 52, 57)
	cloudPart.Position = stormCenter + Vector3.new(0, TORNADO.Height, 0)
	cloudPart.Parent = workspace
	table.insert(activeInstances, cloudPart)

	local cloudMesh = Instance.new("SpecialMesh")
	cloudMesh.MeshType = Enum.MeshType.FileMesh
	cloudMesh.MeshId = "rbxassetid://1095708"
	cloudMesh.Scale = Vector3.new(1, 1, 1)
	cloudMesh.Parent = cloudPart

	local lightningCore = Instance.new("PointLight")
	lightningCore.Color = Color3.fromRGB(180, 200, 255)
	lightningCore.Range = TORNADO.Cloud * 1.5
	lightningCore.Brightness = 0
	lightningCore.Parent = cloudPart

	local growInfo = TweenInfo.new(FORMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TS:Create(cloudMesh, growInfo, {Scale = Vector3.new(TORNADO.Cloud, TORNADO.Cloud * 0.25, TORNADO.Cloud)}):Play()
	TS:Create(cloudPart, growInfo, {Transparency = 0}):Play()
	TS:Create(Lighting, growInfo, {Ambient = Color3.fromRGB(30, 30, 35), Brightness = 0.05, ClockTime = 17.8}):Play()
	
	task.wait(FORMATION_TIME) 

	-- 2. Create Funnel Spheres
	local funnelParts = {}
	local SEGMENT_COUNT = 85

	for i = 1, SEGMENT_COUNT do
		local alpha = (i - 1) / (SEGMENT_COUNT - 1)
		local radius = TORNADO.BaseRad + ((TORNADO.TopRad - TORNADO.BaseRad) * (alpha ^ TORNADO.Curve))
		
		local segment = Instance.new("Part")
		segment.Anchored = true
		segment.CanCollide = false
		segment.Shape = Enum.PartType.Ball 
		segment.Size = Vector3.new(radius * 2, radius * 2, radius * 2) 
		segment.Material = Enum.Material.Glass 
		segment.Color = Color3.fromRGB(55, 57, 62)
		segment.Transparency = 1 
		segment.Parent = workspace
		
		table.insert(funnelParts, {part = segment, alpha = alpha, baseRadius = radius})
		table.insert(activeInstances, segment)
	end

	local debrisAtt = Instance.new("Attachment", workspace.Terrain)
	table.insert(activeInstances, debrisAtt)
	
	local dust = Instance.new("ParticleEmitter", debrisAtt)
	dust.Texture = "rbxassetid://61939574"
	dust.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50))
	dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, TORNADO.BaseRad), NumberSequenceKeypoint.new(1, TORNADO.BaseRad * 3.5)})
	dust.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.4), NumberSequenceKeypoint.new(1, 1)})
	dust.Lifetime = NumberRange.new(2, 4.5)
	dust.Speed = NumberRange.new(60, 120)
	dust.SpreadAngle = Vector2.new(90, 90)
	dust.RotSpeed = NumberRange.new(-100, 100)
	dust.Rate = 0

	-- 3. Animate and Run Physics
	local timeElapsed = 0
	local funnelDrop = 0
	local isMoving = false
	local isDissipating = false
	
	local roamDirX = (math.random(-100, 100) / 100)
	local roamDirZ = (math.random(-100, 100) / 100)
	local physTick = 0
	local upgradeTick = 0
	
	local HitCooldowns = {}

	local connection
	connection = RS.Heartbeat:Connect(function(dt)
		if isDissipating then return end -- Stop logic if dissipating to freeze it

		timeElapsed += dt
		physTick += dt
		upgradeTick += dt

		-- Update Global UI
		for _, plr in ipairs(Players:GetPlayers()) do
			local gui = plr.PlayerGui:FindFirstChild("TornadoStatus")
			if gui and gui:FindFirstChild("TextLabel") then
				gui.TextLabel.Text = "⚠️ " .. TORNADO.Name .. " TORNADO ACTIVE | Windspeed: " .. TORNADO.WindSpeed .. " mph ⚠️"
			end
		end

		-- Mid-Storm Upgrades (Every 8 seconds, chance to shift intensity)
		if upgradeTick > 8 then
			upgradeTick = 0
			if math.random(1, 100) > 70 then
				local newRating = math.random(1, 5)
				TORNADO = EF_DATA[newRating]
				
				-- Tween Cloud to new size
				TS:Create(cloudMesh, TweenInfo.new(4), {Scale = Vector3.new(TORNADO.Cloud, TORNADO.Cloud * 0.25, TORNADO.Cloud)}):Play()
				-- Tween Dust Base Size
				dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, TORNADO.BaseRad), NumberSequenceKeypoint.new(1, TORNADO.BaseRad * 3.5)})
				dust.Rate = TORNADO.Debris
				
				-- Adjust Funnel sphere sizes dynamically
				for _, data in ipairs(funnelParts) do
					local targetRad = TORNADO.BaseRad + ((TORNADO.TopRad - TORNADO.BaseRad) * (data.alpha ^ TORNADO.Curve))
					TS:Create(data.part, TweenInfo.new(3), {Size = Vector3.new(targetRad * 2, targetRad * 2, targetRad * 2)}):Play()
				end
			end
		end

		if math.random(1, 100) > 94 then
			lightningCore.Brightness = math.random(15, 40)
		else
			lightningCore.Brightness = math.clamp(lightningCore.Brightness - (dt * 60), 0, 40)
		end

		if funnelDrop < 1 then
			funnelDrop += dt / FUNNEL_DROP_TIME
		elseif not isMoving then
			isMoving = true 
			dust.Rate = TORNADO.Debris
		end

		if isMoving then
			roamDirX = math.clamp(roamDirX + math.sin(timeElapsed * 0.1) * 0.05, -1, 1)
			roamDirZ = math.clamp(roamDirZ + math.cos(timeElapsed * 0.1) * 0.05, -1, 1)
			stormCenter += Vector3.new(roamDirX, 0, roamDirZ) * (TORNADO.Speed * dt)
		end

		cloudPart.CFrame = CFrame.new(stormCenter + Vector3.new(0, TORNADO.Height, 0)) * CFrame.Angles(0, timeElapsed * 0.1, 0)
		
		local groundDragX = -roamDirX * (TORNADO.Height * 0.15)
		local groundDragZ = -roamDirZ * (TORNADO.Height * 0.15)
		debrisAtt.Position = stormCenter + Vector3.new(groundDragX, groundY, groundDragZ)

		local currentDropHeight = TORNADO.Height - (TORNADO.Height * math.clamp(funnelDrop, 0, 1))

		-- Update Funnel Shapes
		for _, data in ipairs(funnelParts) do
			local part = data.part
			local alpha = data.alpha
			local yPos = stormCenter.Y + (alpha * TORNADO.Height)
			
			if yPos < stormCenter.Y + currentDropHeight then
				part.Transparency = 1
			else
				part.Transparency = 0.25 
				local drag = (1 - alpha)
				local leanX = groundDragX * drag
				local leanZ = groundDragZ * drag
				local offsetX = math.sin(timeElapsed * 1.5 + (alpha * 5)) * (TORNADO.Snake * drag)
				local offsetZ = math.cos(timeElapsed * 1.2 + (alpha * 6)) * (TORNADO.Snake * drag)
				
				part.CFrame = CFrame.new(stormCenter + Vector3.new(offsetX + leanX, alpha * TORNADO.Height, offsetZ + leanZ))
			end
		end

		-- ===================================================
		-- PHYSICS, DAMAGE & PROBE INTERCEPTS
		-- ===================================================
		if isMoving and physTick >= 0.1 then
			physTick = 0
			local hitRad = TORNADO.BaseRad * 3.5
			
			-- 1. Check Deployed Probes
			for probe, pData in pairs(ActiveDeployedProbes) do
				if not pData.Active then continue end
				
				pData.UI.Text = "Windspeed: " .. TORNADO.WindSpeed .. " mph"
				
				if (probe.Position - debrisAtt.WorldPosition).Magnitude <= hitRad then
					pData.Active = false
					pData.UI.Text = "INTERCEPTED!"
					pData.UI.TextColor3 = Color3.new(0, 1, 0)
					
					-- Give Money
					if pData.Owner and pData.Owner:FindFirstChild("leaderstats") then
						pData.Owner.leaderstats.Money.Value += TORNADO.WindSpeed * 2
					end
					
					-- Despawn and return tool
					task.delay(2, function()
						if probe then
							ActiveDeployedProbes[probe] = nil
							probe:Destroy()
							giveProbeTool(pData.Owner)
						end
					end)
				end
			end

			-- 2. Handle Players & Models
			local partsInRadius = workspace:GetPartBoundsInRadius(debrisAtt.WorldPosition, hitRad)
			local processedModels = {}

			for _, p in ipairs(partsInRadius) do
				if p.Name == "Baseplate" or p.Name == "Terrain" or p.Parent == workspace or p.Name == "DeployedProbe" then continue end
				
				local model = p:FindFirstAncestorOfClass("Model")
				if not model or processedModels[model] then continue end
				processedModels[model] = true

				local hum = model:FindFirstChildOfClass("Humanoid")
				
				-- PLAYER DETECTION
				if hum and hum.Health > 0 then
					if not HitCooldowns[hum] or (os.clock() - HitCooldowns[hum] > 3) then -- 3 second cooldown
						HitCooldowns[hum] = os.clock()
						
						if hum.Sit then
							-- Inside a vehicle/model
							hum:TakeDamage(15)
						else
							-- Player alone: Damage and fling out
							hum:TakeDamage(45)
							local hrp = model:FindFirstChild("HumanoidRootPart")
							if hrp then
								hrp.Anchored = false
								hrp.AssemblyLinearVelocity = Vector3.new(math.random(-500, 500), math.random(500, 800), math.random(-500, 500))
							end
						end
					end
					continue 
				end

				-- MODEL THROWING (Instead of tearing apart)
				if not HitCooldowns[model] or (os.clock() - HitCooldowns[model] > 5) then
					HitCooldowns[model] = os.clock()
					local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
					
					if primary then
						for _, mp in ipairs(model:GetDescendants()) do
							if mp:IsA("BasePart") and not mp.Anchored then
								mp.AssemblyLinearVelocity = Vector3.new(math.random(-400, 400), math.random(400, 1000), math.random(-400, 400))
								mp.AssemblyAngularVelocity = Vector3.new(math.random(-50,50), math.random(-50,50), math.random(-50,50))
							end
						end
					end
				end
			end
		end
	end)

	task.wait(TORNADO_LIFETIME)

	-- 4. Dissipate Phase (Freeze and Ascend)
	isDissipating = true
	dust.Rate = 0
	
	-- Remove UI
	for _, plr in ipairs(Players:GetPlayers()) do
		local gui = plr.PlayerGui:FindFirstChild("TornadoStatus")
		if gui then gui:Destroy() end
	end
	
	-- Ascend and Shrink Tweens
	local ascendTween = TweenInfo.new(DISSIPATE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	
	TS:Create(cloudMesh, ascendTween, {Scale = Vector3.new(0, 0, 0)}):Play()
	TS:Create(cloudPart, ascendTween, {CFrame = cloudPart.CFrame * CFrame.new(0, 600, 0), Transparency = 1}):Play()
	TS:Create(Lighting, ascendTween, {Ambient = Color3.fromRGB(120, 120, 120), Brightness = 1, ClockTime = 14}):Play()
	
	for _, data in ipairs(funnelParts) do
		TS:Create(data.part, ascendTween, {CFrame = data.part.CFrame * CFrame.new(0, 800, 0), Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
	end

	task.wait(DISSIPATE_TIME)
	
	-- 5. Cleanup Memory
	connection:Disconnect()
	for _, inst in ipairs(activeInstances) do
		if inst and inst.Parent then inst:Destroy() end
	end
	HitCooldowns = nil
end

task.wait(5) 
while true do
	spawnTornado()
	task.wait(math.random(15, 25)) 
end