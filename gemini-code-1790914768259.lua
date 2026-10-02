local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CharactersFolder = ReplicatedStorage:WaitForChild("Characters")

local MorphEvent = Remotes:WaitForChild("MorphEvent")
local AbilityEvent = Remotes:WaitForChild("AbilityEvent")
local SprintEvent = Remotes:WaitForChild("SprintEvent")

-- Animation IDs
local ANIMS = {
    Walk = "rbxassetid://112299300414259",
    Sprint = "rbxassetid://124733123370196",
    Idle = "rbxassetid://119542689978384",
    Charge = "rbxassetid://108828185445742",
    Grab = "rbxassetid://85098189190021",
    SurvivorGrabbed = "rbxassetid://132281879455672",
    M1 = "rbxassetid://138947059073077",
    Kill = "rbxassetid://76544545227709"
}

-- Cooldown tracking
local Cooldowns = {}

-- Utility: Play Animation
local function playAnim(character, animId)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = animator:LoadAnimation(anim)
        track:Play()
        return track
    end
end

-- FIXED: Morphing Logic
MorphEvent.OnServerEvent:Connect(function(player, charName)
    local targetChar = CharactersFolder:FindFirstChild(charName)
    if targetChar then
        local clone = targetChar:Clone()
        -- It is best practice to name the morphed character the Player's name
        clone.Name = player.Name 
        
        -- Safely move the morph to the player's current location
        if player.Character then
            clone:PivotTo(player.Character:GetPivot())
            player.Character:Destroy() -- Remove old character
        end
        
        -- Set parent to workspace FIRST, then assign to player
        clone.Parent = workspace
        player.Character = clone
        
        -- Override default animations if 2011X
        if charName == "2011X" then
            -- Wait for the default Animate script to load, then change the IDs
            task.delay(0.5, function()
                local animate = clone:FindFirstChild("Animate")
                if animate then
                    if animate:FindFirstChild("idle") and animate.idle:FindFirstChild("Animation1") then
                        animate.idle.Animation1.AnimationId = ANIMS.Idle
                    end
                    if animate:FindFirstChild("walk") and animate.walk:FindFirstChild("WalkAnim") then
                        animate.walk.WalkAnim.AnimationId = ANIMS.Walk
                    end
                end
            end)
        end
    end
end)

-- Handle Sprint
SprintEvent.OnServerEvent:Connect(function(player, isSprinting)
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = isSprinting and 24 or 16
            if isSprinting then
                playAnim(char, ANIMS.Sprint)
            end
        end
    end
end)

-- Handle Abilities
AbilityEvent.OnServerEvent:Connect(function(player, abilityType, mousePos)
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    if not Cooldowns[player] then Cooldowns[player] = {Charge = 0, Hit = 0} end
    local currentTime = os.clock()

    if abilityType == "Charge" and currentTime > Cooldowns[player].Charge then
        Cooldowns[player].Charge = currentTime + 30
        
        -- 1. Flashes red twice (Highlight)
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.new(1, 0, 0)
        hl.Parent = char
        task.wait(0.5); hl.Enabled = false; task.wait(0.5); hl.Enabled = true; task.wait(0.5); hl.Enabled = false; task.wait(0.5)
        hl:Destroy()
        
        -- 2. Glide towards mouse
        local glideTrack = playAnim(char, ANIMS.Charge)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        local direction = (mousePos - hrp.Position).Unit
        bv.Velocity = direction * 50
        bv.Parent = hrp
        
        local connection
        local chargeActive = true
        
        -- 3. Hit Detection for Survivor
        connection = hrp.Touched:Connect(function(hit)
            local targetHum = hit.Parent:FindFirstChild("Humanoid")
            if targetHum and hit.Parent:FindFirstChild("survivor") and chargeActive then
                chargeActive = false
                bv:Destroy()
                if glideTrack then glideTrack:Stop() end
                
                local survivorChar = hit.Parent
                local survivorHrp = survivorChar:FindFirstChild("HumanoidRootPart")
                
                -- Cinematic positioning
                hrp.Anchored = true
                survivorHrp.Anchored = true
                hrp.CFrame = survivorHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
                
                playAnim(char, ANIMS.Grab)
                playAnim(survivorChar, ANIMS.SurvivorGrabbed)
                
                -- DoT Damage
                for i = 1, 25 do
                    targetHum:TakeDamage(1)
                    task.wait(0.1)
                end
                
                survivorHrp.Anchored = false
                task.wait(5)
                hrp.Anchored = false
                connection:Disconnect()
            end
        end)
        
        -- End charge if no hit after 5s
        task.delay(5, function()
            if chargeActive then
                chargeActive = false
                if bv then bv:Destroy() end
                if glideTrack then glideTrack:Stop() end
                if connection then connection:Disconnect() end
            end
        end)
        
    elseif abilityType == "Hit" and currentTime > Cooldowns[player].Hit then
        Cooldowns[player].Hit = currentTime + 1.5
        playAnim(char, ANIMS.M1)
        
        -- Hitbox generation
        local hitbox = Instance.new("Part")
        hitbox.Size = Vector3.new(4, 5, 4)
        hitbox.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = true
        hitbox.Parent = workspace
        
        local connection
        connection = hitbox.Touched:Connect(function(hit)
            local targetHum = hit.Parent:FindFirstChild("Humanoid")
            if targetHum and hit.Parent:FindFirstChild("survivor") then
                connection:Disconnect()
                
                -- Check lethal
                if targetHum.Health <= 40 then
                    targetHum.Health = 0.01 -- Prevent immediate death for cinematic
                    local survivorChar = hit.Parent
                    local survivorHrp = survivorChar:FindFirstChild("HumanoidRootPart")
                    
                    survivorHrp.Anchored = true
                    hrp.Anchored = true
                    survivorHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
                    
                    playAnim(char, ANIMS.Kill)
                    
                    task.wait(2)
                    targetHum.Health = 0 -- Finish them off
                    hrp.Anchored = false
                    survivorHrp.Anchored = false
                else
                    targetHum:TakeDamage(40)
                end
            end
        end)
        
        game.Debris:AddItem(hitbox, 0.3) -- Remove hitbox quickly
    end
end)