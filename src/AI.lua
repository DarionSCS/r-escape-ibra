--services
local PathfindingService = game:GetService("PathfindingService")

--vars
local npc = script.Parent
local npcHRP = npc.HumanoidRootPart
npcHRP:SetNetworkOwner(nil)
local maxRange = 100
local damage = 10

--play backgroundMusic
npcHRP.harmonica.Playing = true

--raycast parameters
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {npc} --ignores itself

local lastPos
local status

-- uses rays to detect if any players are in its vision
local function canSeeTarget(target) 
	local pos = npcHRP.Position
	local direction =  (target.HumanoidRootPart.Position - npcHRP.Position).Unit * maxRange --idk wat .unit is
	local ray = workspace:Raycast(pos, direction, rayParams)

	if ray and ray.Instance:IsDescendantOf(target) then --if ray sees a player returns true, else false
		return true
	else
		return false
	end
end

--set the target to nearest player
local function findNearestPlayer()
	local players = game.Players:GetPlayers()
	local nearestPlayer
	local maxDistance = maxRange

	for _, player in ipairs(players) do --loop through all players
		local character = player.Character
		if character and character.HumanoidRootPart then
			local target = character
			local distance = (npcHRP.Position - target.HumanoidRootPart.Position).Magnitude

			if distance <= maxDistance and canSeeTarget(target) then
				nearestPlayer = target
				maxDistance = distance --keeps changing maxDistance until nearest player is found 
			end
		end
	end
	return nearestPlayer -- returns nearest player when done looping
end


-- returns path using pathfindingservice
local function getPath(destination) 
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(npcHRP.Position, destination.Position)

	return path
end

--plays random ibra sound
local function playRandomSound()
	local sounds = script.Parent.soundFX:GetChildren()
	local ranNum = math.random(1, #sounds)
	sounds[ranNum]:Play()
end

--damages the target
local function attack(target)
	local distance = (npcHRP.Position - target.HumanoidRootPart.Position).Magnitude
	local debounce = false

	if distance > 8 then -- if target is further than 5 magnitude, it just continues to walk to target
		npc.Humanoid:MoveTo(target.HumanoidRootPart.Position)
	else
		if debounce == false then
			debounce = true
			target.Humanoid.Health -= damage
			playRandomSound()
			task.wait(0.5)
			debounce = false
		end
	end
end


local function walkTo(destination)
	local path = getPath(destination) --using getPath function from earlier here

	if path.Status == Enum.PathStatus.Success then --checks if path can load
		for _, waypoint in pairs (path:GetWaypoints()) do
			path.Blocked:Connect(function()
				path:Destroy()
			end)
			local target = findNearestPlayer()

			if target and target.Humanoid.Health > 0 then
				lastPos = target.HumanoidRootPart.Position
				attack(target)
				break
			else
				if waypoint.Action == Enum.PathWaypointAction.Jump then --jumps if theres an obstacle
					npc.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
				if lastPos then --walks to the last known position it saw you in
					npc.Humanoid:MoveTo(lastPos)
					npc.Humanoid.MoveToFinished:Wait()
					lastPos = nil
					break
				else
					npc.Humanoid:MoveTo(waypoint.Position)
					npc.Humanoid.MoveToFinished:Wait()
				end
			end
		end
	else
		return
	end
end

local function patrol() --walks around map if no one is in sight
	local waypoints = workspace.chilling:GetChildren()
	local ranNum = math.random(1, #waypoints)
	walkTo(waypoints[ranNum])
end

while task.wait(0.2) do
	patrol()
end