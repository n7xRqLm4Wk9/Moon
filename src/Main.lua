-- Entry point: loads every module in dependency order and returns the Moon library table.
local import = ...

local Moon = import("Core/Moon")

import("Theme/Registry")
import("Theme/Presets")
import("UI/Elements/Index")
import("Window/Window")
import("Window/Tab")
import("Window/Notify")
import("Window/Create")

return Moon
