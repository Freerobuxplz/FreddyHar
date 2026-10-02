local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local CharactersFolder = ReplicatedStorage:WaitForChild("Characters")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MorphEvent = Remotes:WaitForChild("MorphEvent")

-- Create the UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BecomeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "BECOME"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.TextScaled = true
Title.Parent = MainFrame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.UIListLayout = Instance.new("UIListLayout")
ScrollingFrame.UIListLayout.Padding = UDim.new(0, 5)
ScrollingFrame.UIListLayout.Parent = ScrollingFrame
ScrollingFrame.Parent = MainFrame

-- Generate Character Buttons
for _, charModel in ipairs(CharactersFolder:GetChildren()) do
    if charModel:IsA("Model") then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 80)
        btn.Text = ""
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.Parent = ScrollingFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.Position = UDim2.new(0.5, 0, 0, 0)
        nameLabel.Text = charModel.Name
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextScaled = true
        nameLabel.BackgroundTransparency = 1
        nameLabel.Parent = btn
        
        local vpf = Instance.new("ViewportFrame")
        vpf.Size = UDim2.new(0.5, 0, 1, 0)
        vpf.BackgroundTransparency = 1
        vpf.Parent = btn
        
        local clone = charModel:Clone()
        clone.Parent = vpf
        
        local cam = Instance.new("Camera")
        cam.CFrame = CFrame.new(clone:GetPivot().Position + Vector3.new(0, 2, -5), clone:GetPivot().Position)
        vpf.CurrentCamera = cam
        
        btn.MouseButton1Click:Connect(function()
            MorphEvent:FireServer(charModel.Name)
            ScreenGui.Enabled = false -- Hide UI after selecting
        end)
    end
end