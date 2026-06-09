local player = GetLocalPlayer()
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local mouse = player:GetMouse()

local flying = false
local baseSpeed = 500
local boostSpeed = 5000
local maxVolume = 4
local fadeInSpeed = 0.1
local fadeOutSpeed = 0.4
local wasBoosting = false
local accel = 0.1
local decel = 0.08
local turnSpeed = 0.2
local burstMultiplier = 0.8
local ZERO = Vector3.new(0,0,0)
local currentVel = ZERO
local currentLook = hrp.CFrame.LookVector

local driver = Instance.new("Part", workspace)
driver.Size = Vector3.new(0.1, 0.1, 0.1)
driver.Transparency = 1
driver.CanCollide = false
driver.CFrame = hrp.CFrame
driver.Anchored = false

local ff = Instance.new("ForceField", driver)

local weld = Instance.new("WeldConstraint", driver)
weld.Part0 = driver
weld.Part1 = hrp

local windSound = Instance.new("Sound", driver)
windSound.SoundId = "rbxassetid://3308152153"
windSound.Volume = 0
windSound.RollOffMaxDistance = 12500
windSound.RollOffMinDistance = 25
windSound.Looped = true

local boostSound = Instance.new("Sound", driver)
boostSound.SoundId = "rbxassetid://138106864622900"
boostSound.Volume = 5
boostSound.Looped = false
boostSound.RollOffMaxDistance = 100000
boostSound.RollOffMinDistance = 300

local attach = Instance.new("Attachment", driver)

local lv = Instance.new("LinearVelocity", driver)
lv.Attachment0 = attach
lv.MaxForce = 9999999
lv.VectorVelocity = ZERO
lv.Enabled = false

local gyro = Instance.new("AlignOrientation", driver)
gyro.Attachment0 = attach
gyro.Mode = 0
gyro.MaxTorque = 999999
gyro.RigidityEnabled = false
gyro.Responsiveness = 35
gyro.CFrame = driver.CFrame
gyro.Enabled = false

local mouseHit, mousePos, driverPos, targetLook, mag, lookMag, moveDir, charLook, dot, verticalShift, finalDir, targetVel, accelNow, isBoosting, currentSpeed

BindingService.BindPress(Enum.KeyCode.F, function()
	flying = not flying

	if flying then
		lv.Enabled = true
		gyro.Enabled = true
		hum.PlatformStand = true
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		windSound:Play()
	else
		flying = false
		wasBoosting = false
		lv.Enabled = false
		gyro.Enabled = false
		lv.VectorVelocity = ZERO
		currentVel = ZERO
		burstMultiplier = 1
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		windSound:Stop()
		windSound.Volume = 0
	end
end)

while true do
	task.wait(1/60)

	if hum.Health <= 0 or not char.Parent or not driver.Parent then
		break
	end

	if not flying then
		wasBoosting = false
		continue
	end

	isBoosting = hum.Jump
	currentSpeed = baseSpeed

	if isBoosting then
		currentSpeed = boostSpeed
		if not wasBoosting and flying then
			burstMultiplier = 2.2
			boostSound:Play()
		end
	end

	wasBoosting = isBoosting
	mouseHit = mouse.Hit

	if mouseHit then
		mousePos = mouseHit.Position
		driverPos = driver.Position
		targetLook = mousePos - driverPos
		mag = targetLook.Magnitude
		
		if mag > 0 then
			targetLook = targetLook / mag
		end

		currentLook = currentLook + (targetLook - currentLook) * turnSpeed
		lookMag = currentLook.Magnitude
		
		if lookMag > 0 then
			currentLook = currentLook / lookMag
		end

		moveDir = hum.MoveDirection

		if moveDir.Magnitude > 0 then
			charLook = hrp.CFrame.LookVector
			dot = (moveDir.X * charLook.X) + (moveDir.Y * charLook.Y) + (moveDir.Z * charLook.Z)
			verticalShift = Vector3.new(0, currentLook.Y * dot, 0)
			finalDir = moveDir + verticalShift
			finalDir = finalDir / finalDir.Magnitude
			targetVel = finalDir * currentSpeed
			accelNow = accel * burstMultiplier
			currentVel = currentVel + (targetVel - currentVel) * accelNow
			lv.VectorVelocity = currentVel

			if windSound.Volume < maxVolume then
				windSound.Volume = math.min(windSound.Volume + fadeInSpeed, maxVolume)
			end
		else
			currentVel = currentVel + (ZERO - currentVel) * decel
			lv.VectorVelocity = currentVel

			if windSound.Volume > 0 then
				windSound.Volume = math.max(windSound.Volume - fadeOutSpeed, 0)
			end
		end

		burstMultiplier = 1 + (burstMultiplier - 1) * 0.12
		gyro.CFrame = CFrame.lookAt(driverPos, driverPos + currentLook)
	end
end

if driver then driver:Destroy() end
hum.PlatformStand = false
hum:ChangeState(Enum.HumanoidStateType.GettingUp)
