local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AbilityEvent = Remotes:WaitForChild("AbilityEvent")
local SprintEvent = Remotes:WaitForChild("SprintEvent")

local Character = script.Parent
if Character.Name ~= "2011X" then script:Destroy() return end -- Only runs if morphed into 2011X

local Mouse = Player:GetMouse()
local sprinting = false

-- Sprint Input (Shift / Mobile / Gamepad)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
        sprinting = not sprinting
        SprintEvent:FireServer(sprinting)
    end
end)

-- Ability Inputs (Assuming Q for Charge, E or Click for Hit)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Q then
        -- Trigger Charge (Pass mouse hit for glide direction)
        AbilityEvent:FireServer("Charge", Mouse.Hit.Position)
    elseif input.KeyCode == Enum.KeyCode.E or input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Trigger Hit
        AbilityEvent:FireServer("Hit")
    end
end)