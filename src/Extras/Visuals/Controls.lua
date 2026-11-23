-- Ready-made controls for the visuals: drop them into any tab or section.
local import = ...

local Elements = import("UI/Elements/Base")
local Visuals = import("Extras/Visuals/Visuals")

function Elements:AddVisualsControls()
	local options = Visuals:List()
	table.insert(options, 1, "Off")

	self:AddDropdown({
		Name = "Preset",
		Description = "Looks that blend in smoothly",
		Options = options,
		Default = "Off",
		Flag = "Visuals.Preset",
		Callback = function(name)
			if name == "Off" then
				Visuals:Reset()
			else
				Visuals:Apply(name)
			end
		end,
	})
	self:AddSlider({
		Name = "Bloom",
		Min = 0,
		Max = 3,
		Increment = 0.05,
		Default = 0,
		Flag = "Visuals.Bloom",
		Callback = function(value)
			Visuals:Set("Bloom", { Intensity = value, Size = 28, Threshold = 1.1 }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Contrast",
		Min = -0.5,
		Max = 0.5,
		Increment = 0.01,
		Default = 0,
		Flag = "Visuals.Contrast",
		Callback = function(value)
			Visuals:Set("ColorCorrection", { Contrast = value }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Saturation",
		Min = -1,
		Max = 1,
		Increment = 0.05,
		Default = 0,
		Flag = "Visuals.Saturation",
		Callback = function(value)
			Visuals:Set("ColorCorrection", { Saturation = value }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Brightness",
		Min = -0.3,
		Max = 0.3,
		Increment = 0.01,
		Default = 0,
		Flag = "Visuals.Brightness",
		Callback = function(value)
			Visuals:Set("ColorCorrection", { Brightness = value }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Sun rays",
		Min = 0,
		Max = 1,
		Increment = 0.02,
		Default = 0,
		Flag = "Visuals.SunRays",
		Callback = function(value)
			Visuals:Set("SunRays", { Intensity = value, Spread = 0.8 }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Depth of field",
		Min = 0,
		Max = 1,
		Increment = 0.02,
		Default = 0,
		Flag = "Visuals.DepthOfField",
		Callback = function(value)
			Visuals:Set("DepthOfField", { FarIntensity = value, FocusDistance = 40, InFocusRadius = 35 }, 0.15)
		end,
	})
	self:AddSlider({
		Name = "Time of day",
		Min = 0,
		Max = 24,
		Increment = 0.1,
		Default = game:GetService("Lighting").ClockTime,
		Flag = "Visuals.Time",
		Callback = function(value)
			Visuals:Set("Lighting", { ClockTime = value }, 0.15)
		end,
	})
	local camera = workspace.CurrentCamera
	self:AddSlider({
		Name = "Field of view",
		Min = 40,
		Max = 120,
		Default = camera and math.floor(camera.FieldOfView + 0.5) or 70,
		Flag = "Visuals.FOV",
		Callback = function(value)
			Visuals:Set("Camera", { FieldOfView = value }, 0.15)
		end,
	})
	self:AddColorPicker({
		Name = "Color tint",
		Default = Color3.new(1, 1, 1),
		Flag = "Visuals.Tint",
		Callback = function(color)
			Visuals:Set("ColorCorrection", { TintColor = color }, 0.2)
		end,
	})
	self:AddButton({
		Name = "Reset visuals",
		Description = "Puts the game's lighting back as it was",
		ButtonText = "Reset",
		Callback = function()
			Visuals:Reset()
		end,
	})
end

return Elements
