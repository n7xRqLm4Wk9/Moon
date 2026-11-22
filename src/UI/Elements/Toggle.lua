-- On/off toggle.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Create, Apply, Corner, Safe, SetFlag = Util.Create, Util.Apply, Util.Corner, Util.Safe, Util.SetFlag
local Binding = import("Theme/Binding")
local Bind, NewText, Stroke = Binding.Bind, Binding.NewText, Binding.Stroke

function Elements:AddToggle(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local state = opts.Default == true
	local card, _, cy = Card(self, opts, 0.55)

	local click = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})
	local status = NewText(window, card, "", {
		Size = UDim2.fromOffset(40, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -64, 0, cy),
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = FONT,
		TextSize = 13,
	}, function(t)
		return state and t.Text or t.SubText
	end)
	local track = Create("Frame", {
		Size = UDim2.fromOffset(40, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		BorderSizePixel = 0,
		Parent = card,
	})
	Bind(window, track, "BackgroundColor3", "Accent")
	Corner(track, "pill")
	local trackStroke = Stroke(window, track, function(t)
		return state and t.Accent or t.SubText
	end, 0, 1)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		Parent = track,
	})
	Bind(window, knob, "BackgroundColor3", function(t)
		return state and t.AccentText or t.SubText
	end)
	Corner(knob, "pill")

	local obj = { Instance = card }

	local function render(instant)
		Apply(track, { BackgroundTransparency = state and 0 or 1 }, instant)
		Apply(trackStroke, { Color = state and theme.Accent or theme.SubText }, instant)
		Apply(knob, {
			Size = state and UDim2.fromOffset(14, 14) or UDim2.fromOffset(12, 12),
			Position = state and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
			BackgroundColor3 = state and theme.AccentText or theme.SubText,
		}, instant)
		Apply(status, { TextColor3 = state and theme.Text or theme.SubText }, instant)
		status.Text = state and "On" or "Off"
	end

	function obj:Set(value, silent)
		state = value and true or false
		render(false)
		SetFlag(opts, state)
		if not silent then
			Safe(opts.Callback, state)
		end
	end
	function obj:Get()
		return state
	end

	click.MouseButton1Click:Connect(function()
		obj:Set(not state)
	end)

	render(true)
	SetFlag(opts, state)
	return obj
end

return Elements
