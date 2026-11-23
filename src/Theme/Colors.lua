-- Color math helpers.
local import = ...


local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

local function RGB(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function Luma(color)
	return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

local function ToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function FromHex(text)
	local r, g, b = string.match(text, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
	if not r then
		return nil
	end
	return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

local function AccentKeys(accent)
	return {
		Accent = accent,
		AccentHover = accent:Lerp(WHITE, 0.16),
		AccentPressed = accent:Lerp(BLACK, 0.18),
		AccentText = Luma(accent) > 0.62 and RGB(24, 24, 23) or RGB(255, 255, 255),
	}
end

-- red -> amber -> green for a 0..1 health fraction
local HEALTH_RED, HEALTH_AMBER, HEALTH_GREEN = RGB(226, 100, 88), RGB(232, 184, 92), RGB(120, 200, 140)
local function HealthColor(fraction)
	fraction = math.clamp(fraction, 0, 1)
	if fraction > 0.5 then
		return HEALTH_AMBER:Lerp(HEALTH_GREEN, (fraction - 0.5) * 2)
	end
	return HEALTH_RED:Lerp(HEALTH_AMBER, fraction * 2)
end

return {
	HealthColor = HealthColor,
	WHITE = WHITE,
	BLACK = BLACK,
	RGB = RGB,
	Luma = Luma,
	ToHex = ToHex,
	FromHex = FromHex,
	AccentKeys = AccentKeys,
}
