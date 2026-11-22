-- Color picker (saturation/value square, hue bar, hex box, presets).
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Fonts = import("Core/Fonts")
local FONT, FONT_MED = Fonts.FONT, Fonts.FONT_MED
local Colors = import("Theme/Colors")
local WHITE, BLACK, RGB, ToHex, FromHex = Colors.WHITE, Colors.BLACK, Colors.RGB, Colors.ToHex, Colors.FromHex
local Util = import("Core/Util")
local Create, Tween, Corner, Safe, SetFlag, IsPress, IsMove = Util.Create, Util.Tween, Util.Corner, Util.Safe, Util.SetFlag, Util.IsPress, Util.IsMove
local Binding = import("Theme/Binding")
local Themed, NewText, Stroke = Binding.Themed, Binding.NewText, Binding.Stroke

local PRESETS = {
	RGB(217, 119, 87),
	RGB(212, 162, 127),
	RGB(235, 219, 188),
	RGB(110, 170, 255),
	RGB(120, 200, 140),
	RGB(167, 125, 240),
	RGB(232, 121, 160),
}

function Elements:AddColorPicker(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local color = opts.Default or theme.Accent
	local h, s, v = color:ToHSV()
	local open = false
	local panelH = 198
	local obj = {}

	local card, rowH, cy = Card(self, opts, 0.5)
	card.ClipsDescendants = true
	obj.Instance = card

	local rowButton = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})
	local swatch = Create("TextButton", {
		Size = UDim2.fromOffset(48, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = card,
	})
	Corner(swatch, 5)
	Stroke(window, swatch, "Text", 0.75)

	local panel = Create("Frame", {
		Position = UDim2.fromOffset(0, rowH),
		Size = UDim2.new(1, 0, 0, panelH),
		BackgroundTransparency = 1,
		Parent = card,
	})

	-- saturation / value square
	local sv = Create("Frame", {
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -48, 0, 112),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		Parent = panel,
	})
	Corner(sv, 5)
	local whiteLayer = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = sv,
	})
	Corner(whiteLayer, 5)
	Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = whiteLayer })
	local blackLayer = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BorderSizePixel = 0,
		Parent = sv,
	})
	Corner(blackLayer, 5)
	Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = blackLayer })
	local svCursor = Create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sv,
	})
	Corner(svCursor, "pill")
	Create("UIStroke", { Color = WHITE, Thickness = 2, Parent = svCursor })
	local svHit = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = sv,
	})

	-- hue bar
	local hueBar = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(18, 112),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = panel,
	})
	Corner(hueBar, 5)
	local hueKeys = {}
	for i = 0, 6 do
		table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	Create("UIGradient", { Color = ColorSequence.new(hueKeys), Rotation = 90, Parent = hueBar })
	local hueCursor = Create("Frame", {
		Size = UDim2.new(1, 6, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = hueBar,
	})
	Corner(hueCursor, 3)
	Create("UIStroke", { Color = WHITE, Thickness = 2, Parent = hueCursor })
	local hueHit = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = hueBar,
	})

	-- hex + rgb readout
	local hexBox = Create("TextBox", {
		Position = UDim2.fromOffset(10, 128),
		Size = UDim2.fromOffset(92, 28),
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "#RRGGBB",
		Font = FONT_MED,
		TextSize = 13,
		ClearTextOnFocus = false,
		Parent = panel,
	})
	Themed(window, hexBox, {
		BackgroundColor3 = "Control",
		BackgroundTransparency = "ControlTransparency",
		TextColor3 = "Text",
		PlaceholderColor3 = "SubText",
	})
	Corner(hexBox, 4)
	Stroke(window, hexBox, "Stroke", "StrokeTransparency")
	local rgbLabel = NewText(window, panel, "", {
		Position = UDim2.fromOffset(110, 128),
		Size = UDim2.new(1, -120, 0, 28),
		Font = FONT,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "SubText")

	-- presets
	local presets = Create("Frame", {
		Position = UDim2.fromOffset(10, 166),
		Size = UDim2.new(1, -20, 0, 20),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = presets,
	})
	for _, preset in ipairs(opts.Presets or PRESETS) do
		local dot = Create("TextButton", {
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = preset,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = presets,
		})
		Corner(dot, "pill")
		Stroke(window, dot, "Text", 0.8)
		dot.MouseButton1Click:Connect(function()
			obj:Set(preset)
		end)
	end

	local function refresh(silent)
		color = Color3.fromHSV(h, s, v)
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0.5, h)
		swatch.BackgroundColor3 = color
		if not hexBox:IsFocused() then
			hexBox.Text = ToHex(color)
		end
		rgbLabel.Text = string.format(
			"%d, %d, %d",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5)
		)
		SetFlag(opts, color)
		if not silent then
			Safe(opts.Callback, color)
		end
	end

	function obj:Set(newColor, silent)
		if newColor == color then
			return
		end
		h, s, v = newColor:ToHSV()
		refresh(silent)
	end
	function obj:Get()
		return color
	end

	local mode
	local function update(input)
		if mode == "sv" then
			local pos, size = sv.AbsolutePosition, sv.AbsoluteSize
			s = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
			v = 1 - math.clamp((input.Position.Y - pos.Y) / size.Y, 0, 1)
		elseif mode == "hue" then
			local pos, size = hueBar.AbsolutePosition, hueBar.AbsoluteSize
			h = math.clamp((input.Position.Y - pos.Y) / size.Y, 0, 0.999)
		end
		refresh()
	end
	local function begin(which, input)
		if IsPress(input) then
			mode = which
			if self.Page then
				self.Page.ScrollingEnabled = false
			end
			update(input)
		end
	end
	svHit.InputBegan:Connect(function(input)
		begin("sv", input)
	end)
	hueHit.InputBegan:Connect(function(input)
		begin("hue", input)
	end)
	window:_connect(UserInputService.InputChanged, function(input)
		if mode and IsMove(input) then
			update(input)
		end
	end)
	window:_connect(UserInputService.InputEnded, function(input)
		if mode and IsPress(input) then
			mode = nil
			if self.Page then
				self.Page.ScrollingEnabled = true
			end
		end
	end)

	hexBox.FocusLost:Connect(function()
		local parsed = FromHex(hexBox.Text)
		if parsed then
			obj:Set(parsed)
		end
		hexBox.Text = ToHex(color)
	end)

	local function toggle(state)
		open = state
		Tween(card, { Size = UDim2.new(1, 0, 0, open and (rowH + panelH) or rowH) }, 0.24)
	end
	rowButton.MouseButton1Click:Connect(function()
		toggle(not open)
	end)
	swatch.MouseButton1Click:Connect(function()
		toggle(not open)
	end)

	refresh(true)
	return obj
end

return Elements
