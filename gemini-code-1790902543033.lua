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

-- ==========================================
-- LIFETIME FUNCTION 
-- ==========================================
local function spawnTornado()
	local RATING = math.random(1, 5)
	local TORNADO = EF_DATA[RATING]
	print("⚠️ WEATHER ALERT: An " .. TORNADO.Name .. " tornado is forming! (Winds: " .. TORNADO.WindSpeed .. " mph) ⚠️")

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
	cloudPart.Color = Color3.fromRGB(50, 52, 57) -- Darkened for more storm contrast
	cloudPart.Position = stormCenter + Vector3.new(0, TORNADO.Height, 0)
	cloudPart.Parent = workspace
	table.insert(activeInstances, cloudPart)

	local cloudMesh = Instance.new("SpecialMesh")
	cloudMesh.MeshType = Enum.MeshType.FileMesh
	cloudMesh.MeshId = "rbxassetid://1095708"
	cloudMesh.Scale = Vector3.new(1, 1, 1)
	cloudMesh.Parent = cloudPart

	-- VFX: Lightning core inside the cloud
	local lightningCore = Instance.new("PointLight")
	lightningCore.Color = Color3.fromRGB(180, 200, 255)
	lightningCore.Range = TORNADO.Cloud * 1.5
	lightningCore.Brightness = 0
	lightningCore.Parent = cloudPart

	-- Tween Cloud Growth & Atmosphere
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
		-- Changed material to Glass for a more turbulent/transparent wind look
		segment.Material = Enum.Material.Glass 
		segment.Color = Color3.fromRGB(55, 57, 62)
		segment.Transparency = 1 
		segment.Parent = workspace
		
		table.insert(funnelParts, {part = segment, alpha = alpha})
		table.insert(activeInstances, segment)
	end

	-- 3. Advanced Debris & Wind VFX
	local debrisAtt = Instance.new("Attachment", workspace.Terrain)
	table.insert(activeInstances, debrisAtt)
	
	-- Base Dust (Updated ID)
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

	-- High-Speed Wind Swirls
	local windSwirl = Instance.new("ParticleEmitter", debrisAtt)
	windSwirl.Texture = "rbxassetid://10493864010" -- Standard Roblox smoke/swirl
	windSwirl.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
	windSwirl.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, TORNADO.BaseRad * 2), NumberSequenceKeypoint.new(1, TORNADO.BaseRad * 5)})
	windSwirl.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 1)})
	windSwirl.Lifetime = NumberRange.new(1.5, 3)
	windSwirl.Speed = NumberRange.new(20, 40)
	windSwirl.Rotation = NumberRange.new(0, 360)
	windSwirl.RotSpeed = NumberRange.new(150, 300) -- Creates a spinning vortex effect at the base
	windSwirl.Rate = 0

	-- Flying Chunky Debris
	local flyingDebris = Instance.new("ParticleEmitter", debrisAtt)
	flyingDebris.Texture = "rbxassetid://3475040683" -- Sharp debris fragments
	flyingDebris.Color = ColorSequence.new(Color3.fromRGB(30, 25, 20))
	flyingDebris.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)})
	flyingDebris.Transparency = NumberSequence.new(0)
	flyingDebris.Lifetime = NumberRange.new(2, 5)
	flyingDebris.Speed = NumberRange.new(100, 200)
	flyingDebris.Acceleration = Vector3.new(0, -60, 0) -- Gravity pulling chunks back down
	flyingDebris.SpreadAngle = Vector2.new(45, 45)
	flyingDebris.EmissionDirection = Enum.NormalId.Top
	flyingDebris.RotSpeed = NumberRange.new(-500, 500) -- Chaotic tumbling
	flyingDebris.Rate = 0

	-- 4. Animate and Run Physics
	local timeElapsed = 0
	local funnelDrop = 0
	local isMoving = false
	local isDissipating = false
	
	local roamDirX = (math.random(-100, 100) / 100)
	local roamDirZ = (math.random(-100, 100) / 100)
	local physTick = 0

	local connection
	connection = RS.Heartbeat:Connect(function(dt)
		timeElapsed += dt
		physTick += dt

		-- Lightning Flashes
		if math.random(1, 100) > 94 then
			lightningCore.Brightness = math.random(15, 40)
		else
			lightningCore.Brightness = math.clamp(lightningCore.Brightness - (dt * 60), 0, 40)
		end

		-- Handle Drop sequence
		if funnelDrop < 1 then
			funnelDrop += dt / FUNNEL_DROP_TIME
		elseif not isMoving and not isDissipating then
			isMoving = true 
			dust.Rate = TORNADO.Debris
			windSwirl.Rate = math.clamp(TORNADO.Debris * 0.5, 50, 200)
			flyingDebris.Rate = math.clamp(TORNADO.Debris * 0.2, 20, 100)
		end

		-- Handle Roaming
		if isMoving and not isDissipating then
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
				if not isDissipating then part.Transparency = 1 end
			else
				if not isDissipating then part.Transparency = 0.25 end -- Slight transparency makes the funnel look more like rushing wind
				local drag = (1 - alpha)
				local leanX = groundDragX * drag
				local leanZ = groundDragZ * drag
				local offsetX = math.sin(timeElapsed * 1.5 + (alpha * 5)) * (TORNADO.Snake * drag)
				local offsetZ = math.cos(timeElapsed * 1.2 + (alpha * 6)) * (TORNADO.Snake * drag)
				
				part.CFrame = CFrame.new(stormCenter + Vector3.new(offsetX + leanX, alpha * TORNADO.Height, offsetZ + leanZ))
			end
		end

		-- ===================================================
		-- DESTRUCTION & PLAYER PHYSICS 
		-- ===================================================
		if isMoving and physTick >= 0.1 and not isDissipating then
			physTick = 0
			local hitRad = TORNADO.BaseRad * 3
			local partsInRadius = workspace:GetPartBoundsInRadius(debrisAtt.WorldPosition, hitRad)
			local processedModels = {}

			for _, p in ipairs(partsInRadius) do
				if p.Name == "Baseplate" or p.Name == "Terrain" or p.Parent == workspace then continue end
				
				local model = p:FindFirstAncestorOfClass("Model")
				if not model or processedModels[model] then continue end
				processedModels[model] = true

				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					if not hum.Sit then 
						hum.Health = 0
						local hrp = model:FindFirstChild("HumanoidRootPart")
						if hrp then
							hrp.Anchored = false
							hrp.AssemblyLinearVelocity = Vector3.new(math.random(-200, 200), math.random(300, 600), math.random(-200, 200))
						end
					end
					continue 
				end

				local wt = model:FindFirstChild("WindThreshold")
				if wt and wt:IsA("ValueBase") and wt.Value < TORNADO.WindSpeed then
					
					for _, mp in ipairs(model:GetDescendants()) do
						if mp:IsA("BasePart") and not mp.Anchored then
							local dir = (debrisAtt.WorldPosition - mp.Position).Unit
							mp.AssemblyLinearVelocity = mp.AssemblyLinearVelocity:Lerp((dir * 80) + Vector3.new(0, 50, 0), 0.5)
						end
					end

					local baseParts = {}
					for _, mp in ipairs(model:GetDescendants()) do
						if mp:IsA("BasePart") then table.insert(baseParts, mp) end
					end

					if #baseParts > 0 then
						local ripAmount = math.clamp(math.floor(TORNADO.WindSpeed / 50), 1, 5) 
						
						for i = 1, ripAmount do
							local ripPart = baseParts[math.random(1, #baseParts)]
							if ripPart then
								ripPart.Anchored = false
								ripPart:BreakJoints() 
								ripPart.AssemblyLinearVelocity = Vector3.new(math.random(-300, 300), math.random(300, 800), math.random(-300, 300))
								ripPart.AssemblyAngularVelocity = Vector3.new(math.random(-50,50), math.random(-50,50), math.random(-50,50))
							end
						end
					end
				end
			end
		end
	end)

	task.wait(TORNADO_LIFETIME)

	-- 5. Dissipate Phase
	isDissipating = true
	dust.Rate = 0
	windSwirl.Rate = 0
	flyingDebris.Rate = 0
	
	local endTween = TweenInfo.new(DISSIPATE_TIME, Enum.EasingStyle.Linear)
	TS:Create(cloudPart, endTween, {Transparency = 1}):Play()
	TS:Create(Lighting, endTween, {Ambient = Color3.fromRGB(120, 120, 120), Brightness = 1, ClockTime = 14}):Play()
	
	for _, data in ipairs(funnelParts) do
		TS:Create(data.part, endTween, {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
	end

	task.wait(DISSIPATE_TIME)
	
	-- 6. Cleanup Memory
	connection:Disconnect()
	for _, inst in ipairs(activeInstances) do
		if inst and inst.Parent then inst:Destroy() end
	end
	
	print("Storm dissipated. Waiting for next system...")
end

task.wait(5) 
while true do
	spawnTornado()
	task.wait(math.random(15, 25)) 
end