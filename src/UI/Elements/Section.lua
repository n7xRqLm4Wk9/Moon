-- Section header (groups elements inside a tab).
local import = ...

local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT_BOLD = Fonts.FONT_BOLD
local Util = import("Core/Util")
local Create, List = Util.Create, Util.List
local Binding = import("Theme/Binding")
local NewText = Binding.NewText

function Elements:AddSection(name)
	local window = self.Window
	local holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = self.Container,
	})
	List(holder, 6)
	NewText(window, holder, name or "Section", {
		Size = UDim2.new(1, 0, 0, 30),
		Font = FONT_BOLD,
		TextYAlignment = Enum.TextYAlignment.Bottom,
	})
	return setmetatable({
		Container = holder,
		Page = self.Page,
		Theme = self.Theme,
		Window = window,
	}, { __index = Elements })
end

return Elements
