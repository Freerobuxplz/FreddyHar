local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- :: TORNADO SETTINGS (EF1 Scale) ::
local TORNADO_RADIUS = 60       -- The damage path width (EF1 tornadoes are relatively narrow)
local WIND_SPEED = 110          -- Simulated EF1 wind speed max (mph-equivalent scale)
local LIFETIME = 60             -- How long the tornado lasts in seconds
local TORNADO_START_POS = Vector3.new(0, 0, -200)

-- Create the invisible tornado core
local tornadoCore = Instance.new("Part")
tornadoCore.Name = "EF1_Tornado"
tornadoCore.Anchored = true
tornadoCore.CanCollide = false
tornadoCore.Transparency = 1
tornadoCore.Position = TORNADO_START_POS
tornadoCore.Parent = workspace

-- Create Visuals (Basic Funnel Particles)
local funnel = Instance.new("ParticleEmitter")
funnel.Texture = "rbxassetid://2842057633" -- Standard smoke texture
funnel.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 5),
	NumberSequenceKeypoint.new(0.5, 30),
	NumberSequenceKeypoint.new(1, 60)
})
funnel.Transparency = NumberSequence.new(0.5, 1)
funnel.Rate = 500
funnel.Speed = NumberRange.new(20, 50)
funnel.Lifetime = NumberRange.new(3, 5)
funnel.Rotation = NumberRange.new(0, 360)
funnel.RotSpeed = NumberRange.new(100, 200)
funnel.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
funnel.EmissionDirection = Enum.NormalId.Top
funnel.Parent = tornadoCore

local function isProtected(part)
	-- Protect Baseplate and Spawns
	if part.Name == "Baseplate" or part:IsA("SpawnLocation") or part.Name == "SpawnLocation" then
		return true
	end
	
	-- Protect Terrain
	if part:IsA("Terrain") then
		return true
	end
	
	-- Protect Players and their accessories
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and part:IsDescendantOf(player.Character) then
			return true
		end
	end
	
	return false
end

local function applyHelicity(part, corePos)
	-- Calculate vector from core to part
	local offset = part.Position - Vector3.new(corePos.X, part.Position.Y, corePos.Z)
	local distance = offset.Magnitude
	
	if distance < 1 then distance = 1 end -- Prevent division by zero
	
	-- Helical Vortex Math (Inward pull, Tangential rotation, Vertical updraft)
	local radialVector = -offset.Unit
	local tangentialVector = Vector3.new(-offset.Z, 0, offset.X).Unit
	local updraftVector = Vector3.new(0, 1, 0)
	
	-- Wind force intensifies closer to the core, typical in Rankine vortex models
	local intensity = 1 - (distance / TORNADO_RADIUS)
	if intensity < 0 then intensity = 0 end
	
	local outwardForce = radialVector * (WIND_SPEED * 0.4 * intensity)
	local spinForce = tangentialVector * (WIND_SPEED * 1.5 * intensity)
	local liftForce = updraftVector * (WIND_SPEED * 0.8 * intensity)
	
	local totalWindVelocity = outwardForce + spinForce + liftForce
	
	-- Apply velocity
	part.AssemblyLinearVelocity = Vector3.new(
		math.clamp(totalWindVelocity.X, -300, 300),
		math.clamp(totalWindVelocity.Y, -50, 200),
		math.clamp(totalWindVelocity.Z, -300, 300)
	)
	
	-- Add chaotic rotation
	part.AssemblyAngularVelocity = Vector3.new(
		math.random(-10, 10),
		math.random(-20, 20),
		math.random(-10, 10)
	)
end

-- Main Tornado Loop
local timeAlive = 0
local connection
connection = RunService.Heartbeat:Connect(function(dt)
	timeAlive += dt
	if timeAlive > LIFETIME then
		connection:Disconnect()
		tornadoCore:Destroy()
		return
	end
	
	-- Move the tornado erratically (Typical EF1 behavior)
	local randomMove = Vector3.new(math.random(-20, 20) * dt, 0, math.random(-20, 20) * dt)
	tornadoCore.CFrame = tornadoCore.CFrame + randomMove
	
	-- Spatial query for destruction
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {tornadoCore}
	
	local hitParts = workspace:GetPartBoundsInRadius(tornadoCore.Position, TORNADO_RADIUS, overlapParams)
	
	for _, part in ipairs(hitParts) do
		if part:IsA("BasePart") and not isProtected(part) then
			-- Strip part from ground
			if part.Anchored then
				part.Anchored = false
			end
			
			part:BreakJoints() -- Break welds and snaps
			
			-- Apply vortex physics
			applyHelicity(part, tornadoCore.Position)
			
			-- Mark for deletion so the server doesn't crash from flying debris
			if not part:GetAttribute("CaughtByTornado") then
				part:SetAttribute("CaughtByTornado", true)
				-- Destroys the part after 3 to 6 seconds of flying in the funnel
				Debris:AddItem(part, math.random(3, 6)) 
			end
		end
	end
end)