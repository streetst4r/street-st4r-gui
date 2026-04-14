--[[
	STREET ST4R GUI - ULTIMATE FIX
	Rayfield Library + Corrected Tracers + High-Performance ESP
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==========================================
-- SAFE LOADER
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "STREET ST4R",
   LoadingTitle = "STREET ST4R Hub",
   LoadingSubtitle = "by STREET ST4R",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

-- ==========================================
-- STATE VARIABLES
-- ==========================================
local espEnabled, showNames, showHealth = false, false, false
local espMode = "All" 
local espColor = Color3.fromRGB(255, 255, 255)
local espRainbow = false
local espTransparency = 0.5 -- Lowered for better visibility

local fovEnabled = false
local fovDiameter = 220
local fovColor = Color3.fromRGB(255, 0, 255)
local fovRainbow = false

local tracersEnabled = false
local tracerColor = Color3.fromRGB(255, 255, 255)
local tracerRainbow = false

local tickCounter = 0

-- ==========================================
-- OVERLAY SETUP
-- ==========================================
local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "StreetStarOverlay"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local fovCircle = Instance.new("Frame", screenGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 2

local tracerCanvas = Instance.new("Frame", screenGui)
tracerCanvas.Size = UDim2.fromScale(1, 1)
tracerCanvas.BackgroundTransparency = 1
tracerCanvas.Parent = screenGui

-- ==========================================
-- UTILITIES
-- ==========================================
local function areTeammates(a, b)
    if not a or not b then return false end
    if a == b then return true end
    
    -- Check via Team Object
    if a.Team ~= nil and b.Team ~= nil then 
        return a.Team == b.Team 
    end
    
    -- Check via TeamColor (Backup)
    if a.TeamColor == b.TeamColor and not a.Neutral then 
        return true 
    end
    
    return false
end

local function shouldShowPlayer(plr)
    if plr == localPlayer then return false end
    if espMode == "Team check" then 
        return not areTeammates(localPlayer, plr) 
    end
    return true
end

-- ==========================================
-- UI TABS
-- ==========================================
local MainTab = Window:CreateTab("Visuals", 4483362458)

MainTab:CreateSection("ESP Settings")
MainTab:CreateToggle({
    Name = "Enable ESP Highlights", 
    CurrentValue = false, 
    Callback = function(V) espEnabled = V end
})

MainTab:CreateDropdown({
   Name = "ESP Mode",
   Options = {"All", "Team check"},
   CurrentOption = {"All"},
   Callback = function(Option) espMode = Option[1] end,
})

MainTab:CreateToggle({Name = "Show Names", CurrentValue = false, Callback = function(V) showNames = V end})
MainTab:CreateToggle({Name = "Show Health", CurrentValue = false, Callback = function(V) showHealth = V end})
MainTab:CreateToggle({Name = "Rainbow ESP", CurrentValue = false, Callback = function(V) espRainbow = V end})
MainTab:CreateColorPicker({Name = "Static ESP Color", Color = espColor, Callback = function(V) espColor = V end})
MainTab:CreateSlider({Name = "ESP Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(V) espTransparency = V end})

MainTab:CreateSection("FOV Circle")
MainTab:CreateToggle({Name = "Enable FOV Circle", CurrentValue = false, Callback = function(V) fovEnabled = V fovCircle.Visible = V end})
MainTab:CreateToggle({Name = "Rainbow FOV", CurrentValue = false, Callback = function(V) fovRainbow = V end})
MainTab:CreateSlider({Name = "FOV Size", Range = {10, 800}, Increment = 1, CurrentValue = 220, Callback = function(V) fovDiameter = V end})

MainTab:CreateSection("Tracers")
MainTab:CreateToggle({Name = "Enable Tracers", CurrentValue = false, Callback = function(V) tracersEnabled = V end})
MainTab:CreateToggle({Name = "Rainbow Tracers", CurrentValue = false, Callback = function(V) tracerRainbow = V end})
MainTab:CreateColorPicker({Name = "Static Tracer Color", Color = tracerColor, Callback = function(V) tracerColor = V end})

-- ==========================================
-- MAIN RENDER LOOP
-- ==========================================
local labels = {}
local tracerLines = {}

RunService.RenderStepped:Connect(function(dt)
    tickCounter = (tickCounter + dt * 0.3) % 1
    local rainbowColor = Color3.fromHSV(tickCounter, 0.8, 1)

    local currentEspColor = espRainbow and rainbowColor or espColor
    local currentFovColor = fovRainbow and rainbowColor or fovColor
    local currentTracerColor = tracerRainbow and rainbowColor or tracerColor

    -- FOV Update
    if fovEnabled then
        fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        fovCircle.Size = UDim2.fromOffset(fovDiameter, fovDiameter)
        fovStroke.Color = currentFovColor
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hrp and hum and shouldShowPlayer(player) then
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            
            -- --- ESP HIGHLIGHTS ---
            local h = char:FindFirstChild("STREETSTAR_HIGHLIGHT")
            if espEnabled then
                if not h then 
                    h = Instance.new("Highlight")
                    h.Name = "STREETSTAR_HIGHLIGHT"
                    h.Parent = char
                end
                h.Enabled = true
                h.FillColor = currentEspColor
                h.OutlineColor = Color3.new(1, 1, 1)
                h.FillTransparency = espTransparency
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            elseif h then 
                h.Enabled = false 
            end

            -- --- NAMES / HEALTH ---
            local label = labels[player] or Instance.new("TextLabel", screenGui)
            labels[player] = label
            label.Visible = onScreen and (showNames or showHealth)
            if label.Visible then
                label.Size = UDim2.fromOffset(200, 50)
                label.Position = UDim2.fromOffset(screenPos.X - 100, screenPos.Y - 60)
                label.BackgroundTransparency = 1
                label.TextColor3 = currentEspColor
                label.TextStrokeTransparency = 0.5
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Text = (showNames and player.Name or "") .. (showHealth and (" [" .. math.floor(hum.Health) .. "]") or "")
            end

            -- --- TRACERS (STAY ON PLAYER) ---
            local line = tracerLines[player] or Instance.new("Frame", tracerCanvas)
            tracerLines[player] = line
            
            if tracersEnabled and onScreen then
                line.Visible = true
                local startPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                local endPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (endPos - startPos).Magnitude
                
                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.Size = UDim2.fromOffset(distance, 1.5)
                line.Position = UDim2.fromOffset((startPos.X + endPos.X) / 2, (startPos.Y + endPos.Y) / 2)
                line.Rotation = math.deg(math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X))
                line.BackgroundColor3 = currentTracerColor
                line.BorderSizePixel = 0
            else
                line.Visible = false
            end
        else
            -- Cleanup/Hide if player is localplayer, teammate, or dead
            if char then
                local h = char:FindFirstChild("STREETSTAR_HIGHLIGHT")
                if h then h.Enabled = false end
            end
            if labels[player] then labels[player].Visible = false end
            if tracerLines[player] then tracerLines[player].Visible = false end
        end
    end
end)