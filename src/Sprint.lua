local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local playerGUI = player.PlayerGui

local stamina = 100
local maxStamina = 100

local speedDifference = 8
local drainRate = 20
local refreshRate = 10
local staminaRefresh = 20

local sprintHeld = false
local sprinting = false
local exhausted = false

local exhaustionDuration = 2
local exhaustionTimer = 0




local function sprint(active)
	if exhausted then return end
	-- ternary operator syntax: ( condition and exprIfTrue or exprIfFalse )
	humanoid.WalkSpeed = active and humanoid.WalkSpeed + speedDifference or humanoid.WalkSpeed - speedDifference 
	sprinting = active
end

local function exhaust()
	sprint(false) -- Disable sprinting
	exhausted = true -- Mark as exhausted
	exhaustionTimer = exhaustionDuration -- Start the exhaustion timer
end

local function onInput(input)
	if input.KeyCode == Enum.KeyCode.LeftShift and input.UserInputType ~= Enum.UserInputType.Gamepad1 then
		sprintHeld = input.UserInputState == Enum.UserInputState.Begin
		sprint(sprintHeld)
	end
end


local function updateStaminaUI() 
	playerGUI.StaminaGUI.StaminaFrame.StaminaBar.Size = UDim2.new(math.clamp(stamina / maxStamina,0,1),0,1,0)
	--playerGUI.StaminaGUI.StaminaFrame.Percentage.Text = tostring(math.floor(stamina)) .. "/" .. tostring(math.floor(maxStamina))
end

userInputService.InputBegan:Connect(onInput)
userInputService.InputEnded:Connect(onInput)

runService.Heartbeat:Connect(function(deltaTime)
	if sprinting then
		stamina = math.max(0, stamina - drainRate * deltaTime)
		updateStaminaUI()
		if stamina == 0 then
			exhaust() -- Trigger exhaustion function
		end
	else
		if exhausted then
			exhaustionTimer = exhaustionTimer - deltaTime
			if exhaustionTimer <= 0 then
				exhausted = false -- Reset exhaustion state
			end
		else
			stamina = math.min(100, stamina + refreshRate * deltaTime)
			updateStaminaUI()
			if stamina >= staminaRefresh and sprintHeld then
				sprint(true) -- Start sprinting again if sprint key is held and stamina is sufficient
			end
		end
	end
end)
