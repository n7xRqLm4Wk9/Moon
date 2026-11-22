-- Slider.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Create, Tween, Corner, Safe, SetFlag, IsPress, IsMove = Util.Create, Util.Tween, Util.Corner, Util.Safe, Util.SetFlag, Util.IsPress, Util.IsMove
local Binding = import("Theme/Binding")
local Bind, NewText = Binding.Bind, Binding.NewText

function Elements:AddSlider(opts)
	opts = opts or {}
	local window = self.Window
	local min, max = opts.Min or 0, opts.Max or 100
	local increment = opts.Increment or 1
	local suffix = opts.Suffix or ""
	local decimals = #(string.match(tostring(increment), "%.(%d+)") or "")
	local fmt = "%." .. decimals .. "f"
	local value = min

	local card, _, cy = Card(self, opts, 0.42)

	local valueLabel = NewText(window, card, "", {
		Size = UDim2.fromOffset(56, 20),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = FONT,
		TextSize = 13,
	}, "SubText")
	local track = Create("Frame", {
		Size = UDim2.new(0.34, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -78, 0, cy),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = card,
	})
	Bind(window, track, "BackgroundColor3", "Text")
	Corner(track, "pill")
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	})
	Bind(window, fill, "BackgroundColor3", "Accent")
	Corner(fill, "pill")
	local thumb = Create("Frame", {
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BorderSizePixel = 0,
		Parent = track,
	})
	Bind(window, thumb, "BackgroundColor3", "Text")
	Corner(thumb, "pill")
	local inner = Create("Frame", {
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BorderSizePixel = 0,
		Parent = thumb,
	})
	Bind(window, inner, "BackgroundColor3", "Accent")
	Corner(inner, "pill")
	local hit = Create("TextButton", {
		Size = UDim2.new(1, 18, 0, 28),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		Parent = track,
	})

	local obj = { Instance = card }

	local function apply(v, silent, force)
		v = math.clamp(v, min, max)
		v = math.floor((v - min) / increment + 0.5) * increment + min
		v = math.clamp(tonumber(string.format(fmt, v)), min, max)
		if v == value and not force then
			return
		end
		value = v
		local alpha = (max == min) and 0 or (v - min) / (max - min)
		Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.08)
		Tween(thumb, { Position = UDim2.fromScale(alpha, 0.5) }, 0.08)
		valueLabel.Text = string.format(fmt, v) .. suffix
		SetFlag(opts, v)
		if not silent then
			Safe(opts.Callback, v)
		end
	end

	function obj:Set(v, silent)
		apply(v, silent, true)
	end
	function obj:Get()
		return value
	end

	local dragging = false
	local function fromInput(input)
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		apply(min + (max - min) * alpha)
	end

	hit.InputBegan:Connect(function(input)
		if IsPress(input) then
			dragging = true
			Tween(thumb, { Size = UDim2.fromOffset(22, 22) }, 0.12, Enum.EasingStyle.Back)
			if self.Page then
				self.Page.ScrollingEnabled = false
			end
			fromInput(input)
		end
	end)
	window:_connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			fromInput(input)
		end
	end)
	window:_connect(UserInputService.InputEnded, function(input)
		if dragging and IsPress(input) then
			dragging = false
			Tween(thumb, { Size = UDim2.fromOffset(18, 18) }, 0.15)
			if self.Page then
				self.Page.ScrollingEnabled = true
			end
		end
	end)

	apply(opts.Default or min, true, true)
	return obj
end

return Elements
