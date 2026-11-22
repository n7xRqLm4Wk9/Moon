-- Plain text label.
local import = ...

local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Pad = Util.Pad
local Binding = import("Theme/Binding")
local NewText = Binding.NewText

function Elements:AddLabel(text)
	local label = NewText(self.Window, self.Container, text or "", {
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		TextSize = 13,
		TextWrapped = true,
	}, "SubText")
	Pad(label, 4, 2, 4, 2)
	local obj = { Instance = label }
	function obj:Set(newText)
		label.Text = newText
	end
	return obj
end

return Elements
