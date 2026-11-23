-- Ready-made controls for the ESP: drop them into any tab or section.
local import = ...

local Elements = import("UI/Elements/Base")
local ESP = import("Extras/ESP/ESP")

function Elements:AddESPControls()
	local settings = ESP.Settings

	self:AddToggle({
		Name = "ESP",
		Description = "Master switch for every ESP object",
		Default = ESP.Enabled,
		Flag = "ESP.Enabled",
		Callback = function(value)
			ESP:SetEnabled(value)
		end,
	})
	self:AddToggle({
		Name = "Boxes",
		Default = settings.Box,
		Flag = "ESP.Box",
		Callback = function(value)
			ESP:Configure({ Box = value })
		end,
	})
	self:AddDropdown({
		Name = "Box style",
		Options = { "Corners", "Full" },
		Default = settings.BoxStyle,
		Flag = "ESP.BoxStyle",
		Callback = function(value)
			ESP:Configure({ BoxStyle = value })
		end,
	})
	self:AddToggle({
		Name = "Names",
		Default = settings.Name,
		Flag = "ESP.Name",
		Callback = function(value)
			ESP:Configure({ Name = value })
		end,
	})
	self:AddToggle({
		Name = "Health bars",
		Default = settings.Health,
		Flag = "ESP.Health",
		Callback = function(value)
			ESP:Configure({ Health = value })
		end,
	})
	self:AddToggle({
		Name = "Health numbers",
		Default = settings.HealthText,
		Flag = "ESP.HealthText",
		Callback = function(value)
			ESP:Configure({ HealthText = value })
		end,
	})
	self:AddToggle({
		Name = "Distance",
		Default = settings.Distance,
		Flag = "ESP.Distance",
		Callback = function(value)
			ESP:Configure({ Distance = value })
		end,
	})
	self:AddToggle({
		Name = "Info lines",
		Description = "Extra text you set with object:SetLines",
		Default = settings.Lines,
		Flag = "ESP.Lines",
		Callback = function(value)
			ESP:Configure({ Lines = value })
		end,
	})
	self:AddToggle({
		Name = "Glow outline",
		Description = "Highlights the whole model",
		Default = settings.Highlight,
		Flag = "ESP.Highlight",
		Callback = function(value)
			ESP:Configure({ Highlight = value })
		end,
	})
	self:AddSlider({
		Name = "Max distance",
		Min = 100,
		Max = 3000,
		Increment = 50,
		Default = settings.MaxDistance,
		Flag = "ESP.MaxDistance",
		Callback = function(value)
			ESP:Configure({ MaxDistance = value })
		end,
	})
	self:AddColorPicker({
		Name = "ESP color",
		Default = settings.Color,
		Flag = "ESP.Color",
		Callback = function(color)
			ESP:Configure({ Color = color })
		end,
	})
end

return Elements
