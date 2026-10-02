local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- SETUP RADAR UI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TornadoRadar"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local radarBg = Instance.new("Frame")
radarBg.Size = UDim2.new(0, 150, 0, 150)
radarBg.Position = UDim2.new(1, -170, 0, 20)
radarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
radarBg.BackgroundTransparency = 0.5
radarBg.AnchorPoint = Vector2.new(0, 0)
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = radarBg
radarBg.Parent = screenGui

local playerDot = Instance.new("Frame")
playerDot.Size = UDim2.new(0, 6, 0, 6)
playerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
playerDot.BackgroundColor3 = Color3.new(1, 1, 1)
local dotCorner = Instance.new("UICorner", playerDot)
dotCorner.CornerRadius = UDim.new(1, 0)
playerDot.Parent = radarBg

-- ==========================================
-- SETUP "INSIDE TORNADO" EFFECTS
-- ==========================================
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Saturation = 0
colorCorrection.Enabled = false
colorCorrection.Parent = Lighting

local muffleEffect = Instance.new("EqualizerSoundEffect")
muffleEffect.HighGain = 0
muffleEffect.MidGain = 0
muffleEffect.LowGain = 0
muffleEffect.Enabled = false
muffleEffect.Parent = SoundService

local rainEffectGui = Instance.new("ScreenGui")
rainEffectGui.Name = "InsideStormFX"
rainEffectGui.Parent = player:WaitForChild("PlayerGui")
local grayOverlay = Instance.new("Frame")
grayOverlay.Size = UDim2.new(1, 0, 1, 0)
grayOverlay.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
grayOverlay.BackgroundTransparency = 1
grayOverlay.Parent = rainEffectGui

local RADAR_RANGE = 2000
local blips = {}

RunService.RenderStepped:Connect(function()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local activeTornadosFolder = workspace:FindFirstChild("ActiveTornados")
	local trackers = activeTornadosFolder and activeTornadosFolder:GetChildren() or {}

	local isInsideAnyTornado = false

	-- Clean up old radar blips
	for id, blip in pairs(blips) do
		local found = false
		for _, t in ipairs(trackers) do
			if t.Name == id then found = true break end
		end
		if not found then
			blip:Destroy()
			blips[id] = nil
		end
	end

	-- Update Radar & Proximity
	for _, tracker in ipairs(trackers) do
		local rating = tracker:GetAttribute("EF_Rating") or 1
		local baseRad = tracker:GetAttribute("BaseRad") or 50
		local dirX = tracker:GetAttribute("DirX") or 0
		local dirZ = tracker:GetAttribute("DirZ") or 0
		
		-- Distance check for inside effects
		local dist = (hrp.Position - tracker.Position).Magnitude
		if dist < baseRad * 1.5 then
			isInsideAnyTornado = true
		end

		-- Radar Math
		local relPos = tracker.Position - hrp.Position
		local uiX = (relPos.X / RADAR_RANGE) * (radarBg.Size.X.Offset / 2)
		local uiY = (relPos.Z / RADAR_RANGE) * (radarBg.Size.Y.Offset / 2)
		
		-- Clamp to radar circle
		local radarDist = math.sqrt(uiX^2 + uiY^2)
		local maxRad = (radarBg.Size.X.Offset / 2) - 5
		if radarDist > maxRad then
			local angle = math.atan2(uiY, uiX)
			uiX = math.cos(angle) * maxRad
			uiY = math.sin(angle) * maxRad
		end

		if not blips[tracker.Name] then
			local blip = Instance.new("Frame")
			blip.Size = UDim2.new(0, 10, 0, 10)
			blip.BackgroundColor3 = Color3.new(1, 0, 0) -- Red dot
			
			local bCorner = Instance.new("UICorner", blip)
			bCorner.CornerRadius = UDim.new(1,0)
			
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Parent = blip
			
			-- Arrow to show direction
			local arrow = Instance.new("Frame")
			arrow.Size = UDim2.new(0, 2, 0, 8)
			arrow.Position = UDim2.new(0.5, -1, 0, -8)
			arrow.BackgroundColor3 = Color3.new(1,1,1)
			arrow.Parent = blip
			
			blip.Parent = radarBg
			blips[tracker.Name] = blip
		end

		local blip = blips[tracker.Name]
		blip.Position = UDim2.new(0.5, uiX - 5, 0.5, uiY - 5)
		blip.Rotation = math.deg(math.atan2(dirZ, dirX)) + 90
		
		-- Box Outline Danger Color
		local stroke = blip:FindFirstChild("UIStroke")
		if rating == 1 then stroke.Color = Color3.fromRGB(0, 255, 0) -- Green
		elseif rating == 2 then stroke.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		elseif rating == 3 or rating == 4 then stroke.Color = Color3.fromRGB(255, 0, 0) -- Red
		elseif rating == 5 then stroke.Color = Color3.fromRGB(170, 0, 255) end -- Purple
	end

	-- Apply/Remove "Inside Tornado" Effects
	if isInsideAnyTornado then
		colorCorrection.Enabled = true
		colorCorrection.Saturation = -1 -- Screen turns gray
		grayOverlay.BackgroundTransparency = 0.5
		
		muffleEffect.Enabled = true
		muffleEffect.HighGain = -30
		muffleEffect.MidGain = -15
		
		-- Hide Funnel Spheres locally
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.Name == "FunnelSphere" and v:IsA("BasePart") then
				v.LocalTransparencyModifier = 1
			end
		end
	else
		colorCorrection.Enabled = false
		grayOverlay.BackgroundTransparency = 1
		muffleEffect.Enabled = false
		
		-- Unhide Funnel Spheres locally
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.Name == "FunnelSphere" and v:IsA("BasePart") then
				v.LocalTransparencyModifier = 0
			end
		end
	end
end)