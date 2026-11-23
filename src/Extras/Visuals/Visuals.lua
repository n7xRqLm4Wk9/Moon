-- Visuals: lighting and post-processing presets that make any game look better.
-- Everything blends smoothly, and Visuals:Reset() puts the game back exactly as it was.
--
--   Moon.Visuals:Apply("Cinematic")
--   Moon.Visuals:Set("Bloom", { Intensity = 1.2 })
--   Moon.Visuals:Reset()
local import = ...

local Moon = import("Core/Moon")
local Services = import("Core/Services")
local Lighting, TweenService = Services.Lighting, Services.TweenService
local Colors = import("Theme/Colors")
local WHITE, RGB = Colors.WHITE, Colors.RGB

local Visuals = {
	Presets = {},
	Current = nil,
	_order = {},
	_ours = {},
}
Moon.Visuals = Visuals

local CLASSES = {
	Bloom = "BloomEffect",
	ColorCorrection = "ColorCorrectionEffect",
	SunRays = "SunRaysEffect",
	DepthOfField = "DepthOfFieldEffect",
	Atmosphere = "Atmosphere",
}

-- values that make a freshly created effect do nothing
local NEUTRAL = {
	Bloom = { Intensity = 0, Size = 24, Threshold = 2 },
	ColorCorrection = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE },
	SunRays = { Intensity = 0, Spread = 1 },
	DepthOfField = { FarIntensity = 0, NearIntensity = 0, FocusDistance = 50, InFocusRadius = 40 },
	Atmosphere = { Density = 0, Offset = 0, Glare = 0, Haze = 0 },
}

local LIGHTING_KEYS = {
	"Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "ExposureCompensation",
	"FogColor", "FogStart", "FogEnd", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
}
local ATMOSPHERE_KEYS = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" }

-- what the game looked like before we touched anything
local snap
local function snapshot()
	if snap then
		return snap
	end
	snap = { Lighting = {} }
	for _, key in ipairs(LIGHTING_KEYS) do
		local ok, value = pcall(function()
			return Lighting[key]
		end)
		if ok then
			snap.Lighting[key] = value
		end
	end
	local camera = workspace.CurrentCamera
	if camera then
		snap.FieldOfView = camera.FieldOfView
	end
	return snap
end

-- numbers and colors blend; anything else (booleans, enums) is set right away
local function tweenProps(instance, props, duration)
	local goals = {}
	for key, value in pairs(props) do
		local kind = typeof(value)
		if kind == "number" or kind == "Color3" then
			goals[key] = value
		else
			pcall(function()
				instance[key] = value
			end)
		end
	end
	if next(goals) == nil then
		return
	end
	local ok = false
	if duration and duration > 0 then
		ok = pcall(function()
			TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals):Play()
		end)
	end
	if not ok then
		for key, value in pairs(goals) do
			pcall(function()
				instance[key] = value
			end)
		end
	end
end

local function ensure(effect)
	local existing = Visuals._ours[effect]
	if existing and existing.Parent then
		return existing
	end
	local class = CLASSES[effect]
	if not class then
		return nil
	end
	if effect == "Atmosphere" then
		-- a game can only use one atmosphere: borrow its own and give it back on reset
		local found = Lighting:FindFirstChildOfClass("Atmosphere")
		if found then
			snapshot()
			if not snap.Atmosphere then
				snap.Atmosphere = {}
				for _, key in ipairs(ATMOSPHERE_KEYS) do
					snap.Atmosphere[key] = found[key]
				end
				snap.AtmosphereInstance = found
			end
			Visuals._ours[effect] = found
			return found
		end
	end
	local instance = Instance.new(class)
	instance.Name = "Moon" .. effect
	for key, value in pairs(NEUTRAL[effect]) do
		instance[key] = value
	end
	instance.Parent = Lighting
	Visuals._ours[effect] = instance
	return instance
end

local function remove(effect, duration)
	local instance = Visuals._ours[effect]
	if not instance then
		return
	end
	Visuals._ours[effect] = nil
	if snap and snap.AtmosphereInstance == instance then
		tweenProps(instance, snap.Atmosphere, duration)
		snap.Atmosphere, snap.AtmosphereInstance = nil, nil
		return
	end
	tweenProps(instance, NEUTRAL[effect], duration)
	task.delay(duration + 0.05, function()
		instance:Destroy()
	end)
end

-- effect: "Bloom" | "ColorCorrection" | "SunRays" | "DepthOfField" | "Atmosphere" | "Lighting" | "Camera"
function Visuals:Set(effect, props, duration)
	snapshot()
	duration = duration or 0.4
	if effect == "Lighting" then
		tweenProps(Lighting, props, duration)
	elseif effect == "Camera" then
		local camera = workspace.CurrentCamera
		if camera then
			tweenProps(camera, props, duration)
		end
	else
		local instance = ensure(effect)
		if not instance then
			warn("[Moon.Visuals] unknown effect: " .. tostring(effect))
			return Visuals
		end
		pcall(function()
			instance.Enabled = true
		end)
		tweenProps(instance, props, duration)
	end
	return Visuals
end

function Visuals:Apply(name, duration)
	local preset = Visuals.Presets[name]
	if not preset then
		warn("[Moon.Visuals] unknown preset: " .. tostring(name))
		return Visuals
	end
	snapshot()
	duration = duration or 0.6

	for effect in pairs(CLASSES) do
		if preset[effect] then
			Visuals:Set(effect, preset[effect], duration)
		else
			remove(effect, duration)
		end
	end

	-- lighting: preset values on top of the original game values
	local lighting = {}
	for key, value in pairs(snap.Lighting) do
		lighting[key] = value
	end
	for key, value in pairs(preset.Lighting or {}) do
		lighting[key] = value
	end
	tweenProps(Lighting, lighting, duration)

	local camera = workspace.CurrentCamera
	local fov = (preset.Camera and preset.Camera.FieldOfView) or snap.FieldOfView
	if camera and fov then
		tweenProps(camera, { FieldOfView = fov }, duration)
	end

	Visuals.Current = name
	return Visuals
end

-- removes every effect Moon added and restores the game's own lighting and field of view
function Visuals:Reset(duration)
	duration = duration or 0.6
	for effect in pairs(CLASSES) do
		remove(effect, duration)
	end
	if snap then
		tweenProps(Lighting, snap.Lighting, duration)
		local camera = workspace.CurrentCamera
		if camera and snap.FieldOfView then
			tweenProps(camera, { FieldOfView = snap.FieldOfView }, duration)
		end
	end
	Visuals.Current = nil
	return Visuals
end

function Visuals:AddPreset(name, definition)
	if not Visuals.Presets[name] then
		table.insert(Visuals._order, name)
	end
	Visuals.Presets[name] = definition
	return Visuals
end

function Visuals:List()
	return table.clone(Visuals._order)
end

-- built-in presets ------------------------------------------------------

Visuals:AddPreset("Cinematic", {
	Bloom = { Intensity = 0.6, Size = 28, Threshold = 1.2 },
	ColorCorrection = { Contrast = 0.15, Saturation = -0.08, Brightness = -0.02, TintColor = RGB(255, 244, 232) },
	DepthOfField = { FarIntensity = 0.12, FocusDistance = 40, InFocusRadius = 35, NearIntensity = 0 },
	SunRays = { Intensity = 0.08, Spread = 0.6 },
	Lighting = { ExposureCompensation = 0.1 },
})

Visuals:AddPreset("Vivid", {
	Bloom = { Intensity = 0.4, Size = 24, Threshold = 1.4 },
	ColorCorrection = { Saturation = 0.35, Contrast = 0.12, Brightness = 0.02 },
	SunRays = { Intensity = 0.12, Spread = 0.8 },
})

Visuals:AddPreset("Soft Glow", {
	Bloom = { Intensity = 1.1, Size = 40, Threshold = 0.8 },
	ColorCorrection = { Brightness = 0.03, Saturation = 0.05, TintColor = RGB(255, 240, 250) },
})

Visuals:AddPreset("Moonlight", {
	Bloom = { Intensity = 0.8, Size = 30, Threshold = 1 },
	ColorCorrection = { TintColor = RGB(190, 205, 255), Saturation = -0.1, Contrast = 0.1 },
	Atmosphere = { Density = 0.35, Color = RGB(150, 165, 220), Haze = 1.2, Glare = 0 },
	Lighting = {
		ClockTime = 0,
		Brightness = 1,
		Ambient = RGB(24, 28, 48),
		OutdoorAmbient = RGB(38, 44, 76),
		ExposureCompensation = 0.25,
	},
})

Visuals:AddPreset("Warm Sunset", {
	Bloom = { Intensity = 0.5, Size = 28, Threshold = 1.2 },
	ColorCorrection = { TintColor = RGB(255, 224, 200), Saturation = 0.15, Contrast = 0.08 },
	SunRays = { Intensity = 0.2, Spread = 0.9 },
	Atmosphere = { Density = 0.3, Color = RGB(255, 200, 170), Haze = 1.5, Glare = 0.6 },
	Lighting = { ClockTime = 17.6 },
})

Visuals:AddPreset("Noir", {
	Bloom = { Intensity = 0.3, Size = 24, Threshold = 1.6 },
	ColorCorrection = { Saturation = -1, Contrast = 0.25, Brightness = -0.03 },
})

return Visuals
