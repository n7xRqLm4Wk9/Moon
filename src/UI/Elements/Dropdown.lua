-- Dropdown.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT, FONT_BOLD = Fonts.FONT, Fonts.FONT_BOLD
local Util = import("Core/Util")
local Create, Tween, Corner, List, Safe, SetFlag = Util.Create, Util.Tween, Util.Corner, Util.List, Util.Safe, Util.SetFlag
local Binding = import("Theme/Binding")
local Bind, Themed, NewText, Stroke = Binding.Bind, Binding.Themed, Binding.NewText, Binding.Stroke

function Elements:AddDropdown(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local options = opts.Options or {}
	local selected = opts.Default
	local open = false
	local buttons = {}
	local obj = {}

	local card, rowH, cy = Card(self, opts, 0.45)
	card.ClipsDescendants = true
	obj.Instance = card

	local combo = Create("TextButton", {
		Size = UDim2.new(0.38, 0, 0, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = card,
	})
	Themed(window, combo, { BackgroundColor3 = "Control", BackgroundTransparency = "ControlTransparency" })
	Corner(combo, 4)
	Stroke(window, combo, "Stroke", "StrokeTransparency")
	local valueLabel = NewText(window, combo, "", {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = FONT,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = NewText(window, combo, ">", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = FONT_BOLD,
		TextSize = 13,
		Rotation = 90,
	}, "SubText")

	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, rowH + 2),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Bind(window, list, "ScrollBarImageColor3", "Accent")
	List(list, 2)

	local function listHeight()
		return math.min(#options * 34, 170)
	end

	local function render()
		valueLabel.Text = selected ~= nil and tostring(selected) or "None"
		for opt, entry in pairs(buttons) do
			entry.pill.Visible = (opt == selected)
		end
	end

	local function toggle(state)
		open = state
		Tween(card, { Size = UDim2.new(1, 0, 0, open and (rowH + 10 + listHeight()) or rowH) }, 0.2)
		Tween(arrow, { Rotation = open and -90 or 90 }, 0.2)
	end

	local function build()
		for _, entry in pairs(buttons) do
			entry.button:Destroy()
		end
		table.clear(buttons)
		for _, opt in ipairs(options) do
			local button = Create("TextButton", {
				Size = UDim2.new(1, -6, 0, 32),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				BorderSizePixel = 0,
				Parent = list,
			})
			Bind(window, button, "BackgroundColor3", "Text")
			Corner(button, 4)
			NewText(window, button, tostring(opt), {
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				Font = FONT,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local pill = Create("Frame", {
				Size = UDim2.fromOffset(3, 14),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				BorderSizePixel = 0,
				Visible = false,
				Parent = button,
			})
			Bind(window, pill, "BackgroundColor3", "Accent")
			Corner(pill, "pill")
			button.MouseEnter:Connect(function()
				Tween(button, { BackgroundTransparency = 0.92 }, 0.1)
			end)
			button.MouseLeave:Connect(function()
				Tween(button, { BackgroundTransparency = 1 }, 0.1)
			end)
			button.MouseButton1Click:Connect(function()
				obj:Set(opt)
				toggle(false)
			end)
			buttons[opt] = { button = button, pill = pill }
		end
		list.Size = UDim2.new(1, -16, 0, listHeight())
		if open then
			card.Size = UDim2.new(1, 0, 0, rowH + 10 + listHeight())
		end
		render()
	end

	function obj:Set(value, silent)
		selected = value
		render()
		SetFlag(opts, selected)
		if not silent then
			Safe(opts.Callback, selected)
		end
	end
	function obj:Get()
		return selected
	end
	function obj:Refresh(newOptions, keepSelection)
		options = newOptions or {}
		if not keepSelection or not table.find(options, selected) then
			selected = nil
			SetFlag(opts, nil)
		end
		build()
	end

	combo.MouseButton1Click:Connect(function()
		toggle(not open)
	end)

	build()
	SetFlag(opts, selected)
	return obj
end

return Elements
