-- Textbox.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Create, Tween, Corner, Pad, Safe, SetFlag = Util.Create, Util.Tween, Util.Corner, Util.Pad, Util.Safe, Util.SetFlag
local Binding = import("Theme/Binding")
local Bind, Themed, Stroke = Binding.Bind, Binding.Themed, Binding.Stroke

function Elements:AddTextbox(opts)
	opts = opts or {}
	local window = self.Window
	local card, _, cy = Card(self, opts, 0.45)

	local box = Create("TextBox", {
		Size = UDim2.new(0.38, 0, 0, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		BorderSizePixel = 0,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		TextSize = 13,
		ClearTextOnFocus = opts.ClearOnFocus == true,
		ClipsDescendants = true,
		Parent = card,
	})
	Themed(window, box, {
		BackgroundColor3 = "Control",
		BackgroundTransparency = "ControlTransparency",
		TextColor3 = "Text",
		PlaceholderColor3 = "SubText",
	})
	Corner(box, 4)
	Stroke(window, box, "Stroke", "StrokeTransparency")
	Pad(box, 8, 0, 8, 0)
	local line = Create("Frame", {
		Size = UDim2.new(0, 0, 0, 2),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		BorderSizePixel = 0,
		Parent = box,
	})
	Bind(window, line, "BackgroundColor3", "Accent")

	box.Focused:Connect(function()
		Tween(line, { Size = UDim2.new(1, 0, 0, 2) }, 0.2)
	end)
	box.FocusLost:Connect(function(enterPressed)
		Tween(line, { Size = UDim2.new(0, 0, 0, 2) }, 0.15)
		SetFlag(opts, box.Text)
		Safe(opts.Callback, box.Text, enterPressed)
	end)

	local obj = { Instance = card }
	function obj:Set(text, silent)
		box.Text = text
		SetFlag(opts, text)
		if not silent then
			Safe(opts.Callback, text, false)
		end
	end
	function obj:Get()
		return box.Text
	end
	SetFlag(opts, box.Text)
	return obj
end

return Elements
