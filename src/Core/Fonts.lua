-- Fonts (with fallbacks for older clients).
local import = ...


local function FontOr(name, fallback)
	local ok, font = pcall(function()
		return Enum.Font[name]
	end)
	return ok and font or fallback
end

local FONT = FontOr("BuilderSans", Enum.Font.Gotham)

local FONT_MED = FontOr("BuilderSansMedium", Enum.Font.GothamMedium)

local FONT_BOLD = FontOr("BuilderSansBold", Enum.Font.GothamBold)

local FONT_SERIF = FontOr("Merriweather", Enum.Font.GothamBold)

return {
	FONT = FONT,
	FONT_MED = FONT_MED,
	FONT_BOLD = FONT_BOLD,
	FONT_SERIF = FONT_SERIF,
}
