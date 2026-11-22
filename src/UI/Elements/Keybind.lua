-- Keybind.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Fonts = import("Core/Fonts")
local FONT_MED = Fonts.FONT_MED
local Util = import("Core/Util")
local Create, Tween, Corner, Safe, SetFlag = Util.Create, Util.Tween, Util.Corner, Util.Safe, Util.SetFlag
local Binding = import("Theme/Binding")
local Themed, Stroke = Binding.Themed, Binding.Stroke

function Elements:AddKeybind(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local key = opts.Default
	local listening = false
	local card, _, cy = Card(self, opts, 0.55)

	local btn = Create("TextButton", {
		Size = UDim2.fromOffset(100, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT_MED,
		TextSize = 13,
		Text = "",
		Parent = card,
	})
	Themed(window, btn, {
		BackgroundColor3 = "Control",
		BackgroundTransparency = "ControlTransparency",
		TextColor3 = "Text",
	})
	Corner(btn, 4)
	local btnStroke = Stroke(window, btn, function(t)
		return listening and t.Accent or t.Stroke
	end, function(t)
		return listening and 0 or t.StrokeTransparency
	end)

	local function render()
		btn.Text = key and key.Name or "None"
		Tween(btnStroke, { Color = theme.Stroke, Transparency = theme.StrokeTransparency }, 0.15)
	end

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "Press a key..."
		Tween(btnStroke, { Color = theme.Accent, Transparency = 0 }, 0.15)
	end)

	window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode ~= Enum.KeyCode.Escape then
					key = input.KeyCode
					SetFlag(opts, key)
					Safe(opts.OnChanged, key)
				end
				render()
			end
		elseif not gameProcessed and key and input.KeyCode == key then
			Safe(opts.Callback, key)
		end
	end)

	local obj = { Instance = card }
	function obj:Set(newKey)
		key = newKey
		SetFlag(opts, key)
		render()
	end
	function obj:Get()
		return key
	end
	render()
	SetFlag(opts, key)
	return obj
end

return Elements
