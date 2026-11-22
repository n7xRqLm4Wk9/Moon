-- Theme bindings: every themed property is registered so Window:SetTheme can fade the whole UI.
local import = ...

local Fonts = import("Core/Fonts")
local FONT_MED = Fonts.FONT_MED
local Util = import("Core/Util")
local Create = Util.Create

-- getter: a theme key ("Accent") or a function(theme) -> value
local function Bind(window, inst, prop, getter)
	local get = type(getter) == "function" and getter or function(theme)
		return theme[getter]
	end
	inst[prop] = get(window.Theme)
	table.insert(window._bindings, { inst = inst, prop = prop, get = get })
end

local function Themed(window, inst, map)
	for prop, getter in pairs(map) do
		Bind(window, inst, prop, getter)
	end
	return inst
end

local function NewText(window, parent, text, props, colorKey)
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = FONT_MED,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		label[k] = v
	end
	Bind(window, label, "TextColor3", colorKey or "Text")
	return label
end

-- transKey: theme key / function (themed), or a number (fixed transparency)
local function Stroke(window, parent, colorKey, transKey, thickness)
	local stroke = Create("UIStroke", {
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	Bind(window, stroke, "Color", colorKey or "Stroke")
	if type(transKey) == "number" then
		stroke.Transparency = transKey
	elseif transKey then
		Bind(window, stroke, "Transparency", transKey)
	end
	return stroke
end

return {
	Bind = Bind,
	Themed = Themed,
	NewText = NewText,
	Stroke = Stroke,
}
