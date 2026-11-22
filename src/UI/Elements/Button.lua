-- Button.
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Fonts = import("Core/Fonts")
local FONT_MED = Fonts.FONT_MED
local Util = import("Core/Util")
local Create, Tween, Corner, Safe = Util.Create, Util.Tween, Util.Corner, Util.Safe
local Binding = import("Theme/Binding")
local Themed = Binding.Themed

function Elements:AddButton(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local card, _, cy = Card(self, opts, 0.55)

	local btn = Create("TextButton", {
		Size = UDim2.fromOffset(opts.ButtonWidth or 96, 30),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0, cy),
		AutoButtonColor = false,
		Text = opts.ButtonText or "Run",
		Font = FONT_MED,
		TextSize = 13,
		BorderSizePixel = 0,
		Parent = card,
	})
	Themed(window, btn, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
	Corner(btn, 4)
	local press = Create("UIScale", { Parent = btn })

	btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = theme.AccentHover }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = theme.Accent }, 0.12)
		Tween(press, { Scale = 1 }, 0.12)
	end)
	btn.MouseButton1Down:Connect(function()
		Tween(btn, { BackgroundColor3 = theme.AccentPressed }, 0.06)
		Tween(press, { Scale = 0.95 }, 0.06)
	end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, { BackgroundColor3 = theme.AccentHover }, 0.12)
		Tween(press, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
	end)
	btn.MouseButton1Click:Connect(function()
		Safe(opts.Callback)
	end)

	local obj = { Instance = card }
	function obj:SetText(text)
		btn.Text = text
	end
	return obj
end

return Elements
