-- Theme registry: builds full themes from a few colors, registers them, resolves names.
local import = ...

local Moon = import("Core/Moon")
local Colors = import("Theme/Colors")
local WHITE, RGB, AccentKeys = Colors.WHITE, Colors.RGB, Colors.AccentKeys

-- Builds a full theme from a few colors: Background and Accent are required.
local function BuildTheme(spec)
	local light = spec.Light == true
	local bg, accent = spec.Background, spec.Accent
	local text = spec.Text or (light and RGB(20, 20, 19) or RGB(250, 249, 245))
	local theme = {
		Background = bg,
		Tint = spec.Tint or bg:Lerp(accent, light and 0.1 or 0.2),
		BackgroundTransparency = spec.BackgroundTransparency or (light and 0.1 or 0.13),
		Card = light and WHITE or text,
		CardTransparency = light and 0.4 or 0.94,
		Control = light and WHITE or text,
		ControlTransparency = light and 0.3 or 0.9,
		Stroke = text,
		StrokeTransparency = light and 0.88 or 0.9,
		Border = text,
		BorderTransparency = light and 0.78 or 0.8,
		Text = text,
		SubText = spec.SubText or text:Lerp(bg, light and 0.45 or 0.4),
		Danger = RGB(196, 43, 28),
		Good = light and RGB(46, 140, 80) or RGB(120, 200, 140),
		Warn = light and RGB(190, 130, 20) or RGB(232, 184, 92),
		Bad = light and RGB(200, 60, 50) or RGB(226, 100, 88),
	}
	for k, v in pairs(AccentKeys(accent)) do
		theme[k] = v
	end
	if spec.AccentText then
		theme.AccentText = spec.AccentText
	end
	return theme
end

local function Register(name, spec)
	local theme = spec.Card and spec or BuildTheme(spec)
	if not Moon.Themes[name] then
		table.insert(Moon._order, name)
	end
	Moon.Themes[name] = theme
	return theme
end

local ALIAS = { Dark = "Moon", Light = "MoonLight" }

function Moon:AddThemes(names)
	if type(names) == "string" then
		names = { names }
	end
	for _, name in ipairs(names or Moon._extraOrder) do
		local spec = Moon.ExtraThemes[name]
		if spec then
			Register(name, spec)
		else
			warn("[Moon] unknown theme: " .. tostring(name))
		end
	end
	return Moon
end

function Moon:AddTheme(name, spec)
	Register(name, spec)
	return Moon
end

function Moon:GetThemeNames()
	return table.clone(Moon._order)
end

local function ResolveTheme(theme)
	if type(theme) == "table" then
		if not theme.Card then
			return BuildTheme(theme)
		end
		if getmetatable(theme) == nil then
			setmetatable(theme, { __index = Moon.Themes.Moon })
		end
		return theme
	end
	local found = Moon.Themes[ALIAS[theme] or theme]
	if not found then
		warn("[Moon] theme not registered (call Moon:AddThemes() first): " .. tostring(theme))
	end
	return found or Moon.Themes.Moon
end

return {
	BuildTheme = BuildTheme,
	Register = Register,
	ResolveTheme = ResolveTheme,
	ALIAS = ALIAS,
}
