-- Registers every element that has a Flag so a saved config can set it back later.
local import = ...

local Moon = import("Core/Moon")
local Elements = import("UI/Elements/Base")

local TRACKED = { "AddToggle", "AddSlider", "AddDropdown", "AddTextbox", "AddKeybind", "AddColorPicker" }

for _, method in ipairs(TRACKED) do
	local original = Elements[method]
	Elements[method] = function(self, opts)
		local object = original(self, opts)
		if type(opts) == "table" and opts.Flag then
			Moon._elements[opts.Flag] = object
		end
		return object
	end
end

return Elements
