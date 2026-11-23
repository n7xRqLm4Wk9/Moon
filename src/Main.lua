-- Entry point: loads every module in dependency order and returns the Moon library table.
local import = ...

local Moon = import("Core/Moon")

import("Theme/Registry")
import("Theme/Presets")
import("Core/Config")
import("UI/Elements/Index")
import("Window/Window")
import("Window/Tab")
import("Window/Notify")
import("Window/Create")

-- Optional extras. Nothing here runs unless you ask for it:
--   Moon:Use("ESP")  /  Moon:Use({ "ESP", "TargetCard", "Visuals" })
local EXTRAS = {
	ESP = "Extras/ESP/Index",
	TargetCard = "Extras/TargetCard",
	Visuals = "Extras/Visuals/Index",
}

function Moon:Use(...)
	local names = { ... }
	if type(names[1]) == "table" then
		names = names[1]
	end
	for _, name in ipairs(names) do
		local path = EXTRAS[name]
		if path then
			import(path)
		else
			warn("[Moon] unknown extra: " .. tostring(name) .. " (available: ESP, TargetCard, Visuals)")
		end
	end
	return Moon
end

return Moon
