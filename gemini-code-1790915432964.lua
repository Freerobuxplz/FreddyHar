-- =====================================================================
-- HELICITY-STYLE ORGANIC SPHERE TORNADO (Single Server Script)
-- =====================================================================

local RunService = game:GetService("RunService")

-- === TORNADO CONFIGURATION ===
local TORNADO_HEIGHT = 220         -- Total height of the funnel
local LAYERS = 50                  -- Number of stacked sphere layers
local SPHERES_PER_LAYER = 10       -- Spheres per ring (higher = denser mesh)
local BASE_RADIUS = 6              -- Bottom funnel width
local TOP_RADIUS = 75              -- Top funnel width

local MOVE_SPEED = 14              -- Map roaming speed
local SWAY_SPEED = 2.5             -- Speed of organic column bending
local SWAY_INTENSITY = 18          -- How far the tornado bends in the wind

-- === PHYSICS CONFIGURATION ===
local SUCTION_RADIUS = 95          -- Reach of the vortex pull
local ROTATION_FORCE = 85          -- Tangential spin speed
local PULL_FORCE = 55              -- Inward pull force towards column
local LIFT_FORCE = 70              -- Upward suction force
local THROW_FORCE = 120            -- Outward eject force at the top

local IGNORED_NAMES = {"Baseplate", "Terrain", "BasePlate", "Floor"}

-- === TORNADO CORE SETUP ===
local tornadoFolder = Instance.new("Folder")
tornadoFolder.Name = "HelicityTornado"
tornadoFolder.Parent = workspace

local core = Instance.new("Part")
core.Name = "TornadoCore"
core.Anchored = true
core.CanCollide = false
core.Transparency = 1
core.Position = Vector3.new(0, 3, 0)
core.Parent = tornadoFolder

-- Dust Cloud Emitter at Base
local baseDust = Instance.new("ParticleEmitter")
baseDust.Texture = "rbxassetid://243660364"
baseDust.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 15),
	NumberSequenceKeypoint.new(0.5, 45),
	NumberSequenceKeypoint.new(1, 70)
})
baseDust.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(0.8, 0.7),
	NumberSequenceKeypoint.new(1, 1)
})
baseDust.Color = ColorSequence.new(Color3.fromRGB(35, 32, 28))
baseDust.Rate = 180
baseDust.Lifetime = NumberRange.new(1.5, 2.5)
baseDust.Speed = NumberRange.new(30, 60)
baseDust.SpreadAngle = Vector2.new(180, 180)
baseDust.Parent = core

-- === CONSTRUCT DENSE SPHERE FUNNEL ===
local sphereLayers = {}

for layerIndex = 1, LAYERS do
	local heightAlpha = (layerIndex / LAYERS)
	local yOffset = heightAlpha * TORNADO_HEIGHT
	
	-- Curved funnel profile (Parabolic growth)
	local layerRadius = BASE_RADIUS + (TOP_RADIUS - BASE_RADIUS) * (heightAlpha ^ 1.6)
	
	-- Sphere size scaled to overlap seamlessly
	local sphereDiameter = ((2 * math.pi * layerRadius) / SPHERES_PER_LAYER) * 1.55
	sphereDiameter = math.clamp(sphereDiameter, 8, 32)
	
	-- Dark atmospheric storm gradient (Dark gray base -> Stormy blue-gray top)
	local colorR = math.clamp(28 + (heightAlpha * 25), 0, 255) / 255
	local colorG = math.clamp(28 + (heightAlpha * 28), 0, 255) / 255
	local colorB = math.clamp(32 + (heightAlpha * 35), 0, 255) / 255
	local layerColor = Color3.new(colorR, colorG, colorB)
	
	local layerData = {
		YOffset = yOffset,
		Radius = layerRadius,
		HeightAlpha = heightAlpha,
		Spheres = {}
	}
	
	for i = 1, SPHERES_PER_LAYER do
		local sphere = Instance.new("Part")
		sphere.Shape = Enum.PartType.Ball
		sphere.Material = Enum.Material.SmoothPlastic
		sphere.Size = Vector3.new(sphereDiameter, sphereDiameter, sphereDiameter)
		sphere.Color = layerColor
		sphere.Transparency = 0 -- Opaque solid overlapping spheres
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.CastShadow = false
		sphere.Parent = tornadoFolder
		
		table.insert(layerData.Spheres, {
			Part = sphere,
			BaseAngle = (i / SPHERES_PER_LAYER) * math.pi * 2
		})
	end
	
	table.insert(sphereLayers, layerData)
end

-- === ROAMING LOGIC ===
local currentTarget = core.Position
local function pickNewTarget()
	return Vector3.new(
		core.Position.X + math.random(-200, 200),
		core.Position.Y,
		core.Position.Z + math.random(-200, 200)
	)
end
currentTarget = pickNewTarget()

-- === OVERLAP FILTER ===
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = {tornadoFolder}

-- === MAIN UPDATE LOOP ===
local totalTime = 0

RunService.Heartbeat:Connect(function(deltaTime)
	totalTime = totalTime + deltaTime
	local corePos = core.Position
	
	-- 1. Move Tornado Core Across Map
	local dirToTarget = (currentTarget - corePos)
	local flatDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z)
	
	if flatDir.Magnitude < 10 then
		currentTarget = pickNewTarget()
	else
		core.Position = corePos + (flatDir.Unit * MOVE_SPEED * deltaTime)
	end
	
	-- Map of height layer center points for physics tracking
	local layerCenters = {}
	
	-- 2. Animate and Sway Funnel Layers
	for index, layer in ipairs(sphereLayers) do
		-- Organic Multi-Frequency Swaying Equations
		local swayX = math.sin(totalTime * SWAY_SPEED + (layer.HeightAlpha * 3)) * (layer.HeightAlpha * SWAY_INTENSITY)
		local swayZ = math.cos(totalTime * (SWAY_SPEED * 0.8) + (layer.HeightAlpha * 2.5)) * (layer.HeightAlpha * SWAY_INTENSITY)
		
		local layerCenter = core.Position + Vector3.new(swayX, layer.YOffset, swayZ)
		layerCenters[index] = layerCenter
		
		-- Spin layers in opposite directions based on height
		local rotationSpeed = (totalTime * (4 - layer.HeightAlpha * 1.5))
		
		for _, sphereData in ipairs(layer.Spheres) do
			local angle = sphereData.BaseAngle + rotationSpeed
			local offset = Vector3.new(
				math.cos(angle) * layer.Radius,
				0,
				math.sin(angle) * layer.Radius
			)
			
			sphereData.Part.Position = layerCenter + offset
		end
	end
	
	-- 3. Helicity Destruction & Vortex Physics
	local sweepCenter = corePos + Vector3.new(0, TORNADO_HEIGHT * 0.4, 0)
	local partsInVortex = workspace:GetPartBoundsInRadius(sweepCenter, SUCTION_RADIUS, overlapParams)
	
	for _, part in ipairs(partsInVortex) do
		-- Filter out terrain, terrain descendants, and baseplates
		if table.find(IGNORED_NAMES, part.Name) or part:IsA("Terrain") or part:IsDescendantOf(workspace.Terrain) then
			continue
		end
		
		if part:IsA("BasePart") and not part.Locked then
			-- Rip building structures apart
			if part.Anchored then
				part.Anchored = false
			end
			part:BreakJoints()
			
			-- Find closest height layer center for accurate local pull
			local partPos = part.Position
			local heightPercent = math.clamp((partPos.Y - corePos.Y) / TORNADO_HEIGHT, 0, 1)
			local targetLayerIdx = math.clamp(math.floor(heightPercent * LAYERS) + 1, 1, LAYERS)
			local localCenter = layerCenters[targetLayerIdx] or (corePos + Vector3.new(0, partPos.Y - corePos.Y, 0))
			
			-- Vector calculations
			local toCenter = Vector3.new(localCenter.X - partPos.X, 0, localCenter.Z - partPos.Z)
			local distToCenter = toCenter.Magnitude
			local centerDir = distToCenter > 0.001 and toCenter.Unit or Vector3.new(1, 0, 0)
			
			-- Tangential tangent vector (creates tight swirl)
			local tangentDir = centerDir:Cross(Vector3.new(0, 1, 0)).Unit
			
			-- Force components
			local pullComp = centerDir * PULL_FORCE
			local spinComp = tangentDir * ROTATION_FORCE
			local liftComp = Vector3.new(0, LIFT_FORCE, 0)
			
			-- Eject parts dynamically when reaching top of funnel
			if heightPercent > 0.88 then
				local ejectDir = (-centerDir + Vector3.new(0, 0.5, 0)).Unit
				part.AssemblyLinearVelocity = ejectDir * THROW_FORCE
			else
				-- Swirling ascent inside vortex
				part.AssemblyLinearVelocity = pullComp + spinComp + liftComp
				part.AssemblyAngularVelocity = Vector3.new(
					math.random(-15, 15),
					math.random(-20, 20),
					math.random(-15, 15)
				)
			end
		end
	end
end)