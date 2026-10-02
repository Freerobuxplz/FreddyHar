-- =====================================================================
-- HELICITY-STYLE PROCEDURAL TORNADO (Single Server Script)
-- =====================================================================

local RunService = game:GetService("RunService")

-- === CONFIGURATION ===
local TORNADO_HEIGHT = 150          -- How tall the tornado is
local TORNADO_MIN_RADIUS = 5        -- Width at the bottom
local TORNADO_MAX_RADIUS = 60       -- Width at the top
local DAMAGE_RADIUS = 75            -- How far it reaches to suck parts in
local MOVE_SPEED = 12               -- How fast the tornado roams the map
local LIFT_FORCE = 60               -- How fast items get pulled up
local ROTATION_FORCE = 65           -- How fast items spin around the center
local PULL_FORCE = 40               -- How strongly items are pulled to the center

local IGNORED_PARTS = {"Baseplate", "Terrain"} -- Parts the tornado cannot destroy

-- === SETUP TORNADO CORE ===
local tornadoFolder = Instance.new("Folder")
tornadoFolder.Name = "TornadoSystem"
tornadoFolder.Parent = workspace

local core = Instance.new("Part")
core.Name = "TornadoCore"
core.Anchored = true
core.CanCollide = false
core.Transparency = 1
core.Position = Vector3.new(0, 2, 0)
core.Parent = tornadoFolder

-- Dust particle effect at the base
local dust = Instance.new("ParticleEmitter")
dust.Texture = "rbxassetid://243660364" -- Default smoke texture
dust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 40)})
dust.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1)})
dust.Color = ColorSequence.new(Color3.fromRGB(45, 42, 38))
dust.Rate = 100
dust.Speed = NumberRange.new(20, 50)
dust.SpreadAngle = Vector2.new(90, 90)
dust.Parent = core

-- === GENERATE PROCEDURAL FUNNEL CLOUD ===
local funnelParts = {}
local NUM_FUNNEL_PARTS = 200

for i = 1, NUM_FUNNEL_PARTS do
	local p = Instance.new("Part")
	p.Size = Vector3.new(math.random(8, 15), math.random(8, 15), math.random(8, 15))
	p.Anchored = true
	p.CanCollide = false
	p.Color = Color3.fromRGB(40, 40, 40)
	p.Material = Enum.Material.Slate
	p.Transparency = math.random(20, 70) / 100
	p.Parent = tornadoFolder

	-- Assign random data for orbit math
	local heightAlpha = (i / NUM_FUNNEL_PARTS)
	local yOffset = heightAlpha * TORNADO_HEIGHT
	
	-- Parabolic curve for funnel shape
	local targetRadius = TORNADO_MIN_RADIUS + (TORNADO_MAX_RADIUS - TORNADO_MIN_RADIUS) * (heightAlpha ^ 2)
	
	table.insert(funnelParts, {
		Part = p,
		Angle = math.random(0, 360),
		Speed = math.random(3, 7) - (heightAlpha * 2), -- spins faster at bottom
		Radius = targetRadius + math.random(-5, 5),
		YOffset = yOffset
	})
end

-- === MOVEMENT & TARGETING ===
local currentTarget = core.Position
local function getNewTarget()
	return Vector3.new(
		core.Position.X + math.random(-150, 150),
		core.Position.Y,
		core.Position.Z + math.random(-150, 150)
	)
end
currentTarget = getNewTarget()

-- === OVERLAP PARAMS FOR DESTRUCTION ===
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = {tornadoFolder} -- Ignore itself

-- === MAIN LOOP ===
RunService.Heartbeat:Connect(function(deltaTime)
	local corePos = core.Position
	
	-- 1. Move the Tornado Core
	local dirToTarget = (currentTarget - corePos)
	local flatDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z)
	
	if flatDir.Magnitude < 5 then
		currentTarget = getNewTarget()
	else
		core.Position = corePos + (flatDir.Unit * MOVE_SPEED * deltaTime)
	end
	
	-- 2. Animate the Funnel Cloud
	for _, data in ipairs(funnelParts) do
		data.Angle = data.Angle + (data.Speed * deltaTime)
		
		local offset = Vector3.new(
			math.cos(data.Angle) * data.Radius,
			data.YOffset,
			math.sin(data.Angle) * data.Radius
		)
		
		-- Look outward to give a chaotic swirling debris feel
		data.Part.CFrame = CFrame.new(core.Position + offset, core.Position + Vector3.new(0, data.YOffset, 0))
	end
	
	-- 3. Destruction & Physics Engine
	local checkPos = corePos + Vector3.new(0, TORNADO_HEIGHT/3, 0) -- Check from lower-mid of tornado
	local partsInRadius = workspace:GetPartBoundsInRadius(checkPos, DAMAGE_RADIUS, overlapParams)
	
	for _, part in ipairs(partsInRadius) do
		-- Skip ignored parts (Baseplate, Terrain)
		if table.find(IGNORED_PARTS, part.Name) or part:IsA("Terrain") then
			continue
		end
		
		if part:IsA("BasePart") then
			-- Rip the building / object apart
			part.Anchored = false
			part:BreakJoints()
			
			-- Calculate Physics
			local partPos = part.Position
			local centerAtHeight = Vector3.new(corePos.X, partPos.Y, corePos.Z)
			
			local toCenter = (centerAtHeight - partPos)
			local dist = toCenter.Magnitude
			
			-- Vector Math to create the vortex
			local pullVector = toCenter.Unit * PULL_FORCE
			local tangentVector = toCenter:Cross(Vector3.new(0, 1, 0)).Unit * ROTATION_FORCE
			local liftVector = Vector3.new(0, LIFT_FORCE - (partPos.Y - corePos.Y)*0.2, 0) -- Less lift the higher it goes
			
			-- Apply velocities dynamically to bypass NetworkOwnership delays and simulate brutal force
			if dist > 1 then
				part.AssemblyLinearVelocity = pullVector + tangentVector + liftVector
				part.AssemblyAngularVelocity = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
			end
		end
	end
end)