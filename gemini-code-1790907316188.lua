local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- ==========================================
-- SETUP UI (Radar + Middle-Left Status List)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TornadoRadar"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Top Right Radar
local radarBg = Instance.new("Frame")
radarBg.Size = UDim2.new(0, 150, 0, 150)
radarBg.Position = UDim2.new(1, -170, 0, 20)
radarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
radarBg.BackgroundTransparency = 0.5
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

-- Middle Left Status List Container
local statusList = Instance.new("Frame")
statusList.Name = "TornadoStatusList"
statusList.Size = UDim2.new(0, 220, 0.5, 0)
statusList.Position = UDim2.new(0, 15, 0.5, 0) -- Middle Left
statusList.AnchorPoint = Vector2.new(0, 0.5)
statusList.BackgroundTransparency = 1
statusList.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = statusList

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
local statusLabels = {} -- Track labels in the middle-left list

RunService.RenderStepped:Connect(function()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local activeTornadosFolder = workspace:FindFirstChild("ActiveTornados")
	local trackers = activeTornadosFolder and activeTornadosFolder:GetChildren() or {}
	local isInsideAnyTornado = false

	-- Clean up old radar blips and status labels
	for id, blip in pairs(blips) do
		local found = false
		for _, t in ipairs(trackers) do
			if t.Name == id then found = true break end
		end
		if not found then
			blip:Destroy()
			blips[id] = nil
			if statusLabels[id] then
				statusLabels[id]:Destroy()
				statusLabels[id] = nil
			end
		end
	end

	-- Update Radar & Status UI
	for _, tracker in ipairs(trackers) do
		local id = tracker.Name
		local rating = tracker:GetAttribute("EF_Rating") or 1
		local baseRad = tracker:GetAttribute("BaseRad") or 50
		local tName = tracker:GetAttribute("Name") or "Tornado"
		local tSpeed = tracker:GetAttribute("WindSpeed") or 0
		local dirX = tracker:GetAttribute("DirX") or 0
		local dirZ = tracker:GetAttribute("DirZ") or 0
		
		-- Inside Check
		local dist = (hrp.Position - tracker.Position).Magnitude
		if dist < baseRad * 1.5 then
			isInsideAnyTornado = true
		end

		-- =========================================
		-- MIDDLE LEFT STATUS UI UPDATE
		-- =========================================
		if not statusLabels[id] then
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 30)
			lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			lbl.BackgroundTransparency = 0.4
			lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0
			lbl.Parent = statusList
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = lbl
			
			statusLabels[id] = lbl
		end
		statusLabels[id].Text = "⚠️ " .. tName .. " | " .. tSpeed .. " mph"

		-- =========================================
		-- RADAR DOT UPDATE
		-- =========================================
		local relPos = tracker.Position - hrp.Position
		local uiX = (relPos.X / RADAR_RANGE) * (radarBg.Size.X.Offset / 2)
		local uiY = (relPos.Z / RADAR_RANGE) * (radarBg.Size.Y.Offset / 2)
		
		local radarDist = math.sqrt(uiX^2 + uiY^2)
		local maxRad = (radarBg.Size.X.Offset / 2) - 5
		if radarDist > maxRad then
			local angle = math.atan2(uiY, uiX)
			uiX = math.cos(angle) * maxRad
			uiY = math.sin(angle) * maxRad
		end

		if not blips[id] then
			local blip = Instance.new("Frame")
			blip.Size = UDim2.new(0, 10, 0, 10)
			blip.BackgroundColor3 = Color3.new(1, 0, 0) 
			
			local bCorner = Instance.new("UICorner", blip)
			bCorner.CornerRadius = UDim.new(1,0)
			
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Parent = blip
			
			local arrow = Instance.new("Frame")
			arrow.Size = UDim2.new(0, 2, 0, 8)
			arrow.Position = UDim2.new(0.5, -1, 0, -8)
			arrow.BackgroundColor3 = Color3.new(1,1,1)
			arrow.Parent = blip
			
			blip.Parent = radarBg
			blips[id] = blip
		end

		local blip = blips[id]
		blip.Position = UDim2.new(0.5, uiX - 5, 0.5, uiY - 5)
		blip.Rotation = math.deg(math.atan2(dirZ, dirX)) + 90
		
		-- Danger Colors
		local stroke = blip:FindFirstChild("UIStroke")
		if rating == 1 then stroke.Color = Color3.fromRGB(0, 255, 0)
		elseif rating == 2 then stroke.Color = Color3.fromRGB(255, 255, 0)
		elseif rating == 3 or rating == 4 then stroke.Color = Color3.fromRGB(255, 0, 0)
		elseif rating == 5 then stroke.Color = Color3.fromRGB(170, 0, 255) end 
	end

	-- Apply/Remove "Inside Tornado" Effects
	if isInsideAnyTornado then
		colorCorrection.Enabled = true
		colorCorrection.Saturation = -1
		grayOverlay.BackgroundTransparency = 0.5
		muffleEffect.Enabled = true
		muffleEffect.HighGain = -30
		muffleEffect.MidGain = -15
		
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.Name == "FunnelSphere" and v:IsA("BasePart") then
				v.LocalTransparencyModifier = 1
			end
		end
	else
		colorCorrection.Enabled = false
		grayOverlay.BackgroundTransparency = 1
		muffleEffect.Enabled = false
		
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.Name == "FunnelSphere" and v:IsA("BasePart") then
				v.LocalTransparencyModifier = 0
			end
		end
	end
end)