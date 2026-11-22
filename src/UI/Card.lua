-- Windows 11 style settings card used by every element.
local import = ...

local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Create, Corner = Util.Create, Util.Corner
local Binding = import("Theme/Binding")
local Themed, NewText, Stroke = Binding.Themed, Binding.NewText, Binding.Stroke

-- Windows 11 "settings card": title + optional description on the left, control on the right.
-- Returns card, rowHeight, controlCenterY
local function Card(self, opts, leftScale)
	local window = self.Window
	local hasDesc = type(opts.Description) == "string" and opts.Description ~= ""
	local rowH = hasDesc and 62 or 48
	leftScale = leftScale or 0.55

	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, rowH),
		BorderSizePixel = 0,
		Parent = self.Container,
	})
	Themed(window, card, { BackgroundColor3 = "Card", BackgroundTransparency = "CardTransparency" })
	Corner(card, 6)
	Stroke(window, card, "Stroke", "StrokeTransparency")

	if hasDesc then
		NewText(window, card, opts.Name or "", {
			Size = UDim2.new(leftScale, -20, 0, 20),
			Position = UDim2.fromOffset(14, 11),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		NewText(window, card, opts.Description, {
			Size = UDim2.new(leftScale, -20, 0, 18),
			Position = UDim2.fromOffset(14, 31),
			Font = FONT,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, "SubText")
	else
		NewText(window, card, opts.Name or "", {
			Size = UDim2.new(leftScale, -20, 1, 0),
			Position = UDim2.fromOffset(14, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	return card, rowH, rowH / 2
end

return Card
