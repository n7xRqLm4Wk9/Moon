-- Toast notifications.
local import = ...

local CreateLogo = import("UI/Logo")
local Window = import("Window/Window")
local Fonts = import("Core/Fonts")
local FONT, FONT_MED, FONT_BOLD = Fonts.FONT, Fonts.FONT_MED, Fonts.FONT_BOLD
local Util = import("Core/Util")
local Create, Tween, Corner = Util.Create, Util.Tween, Util.Corner

function Window:Notify(info)
	info = info or {}
	local theme = self.Theme
	local wrap = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 88),
		BackgroundTransparency = 1,
		Parent = self._notifyHolder,
	})
	local card = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(1, 40, 0, 0),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0.06,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = wrap,
	})
	Corner(card, 8)
	local cardStroke = Create("UIStroke", {
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card,
	})
	CreateLogo(self, card, 12, self._logo, { Position = UDim2.fromOffset(12, 10) })
	local function text(str, props, color)
		local label = Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = str,
			TextColor3 = color,
			Font = FONT_MED,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		for k, v in pairs(props) do
			label[k] = v
		end
		return label
	end
	text(self.Title, {
		Size = UDim2.new(1, -40, 0, 14),
		Position = UDim2.fromOffset(32, 10),
		Font = FONT,
		TextSize = 11,
	}, theme.SubText)
	text(info.Title or "Notification", {
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(12, 28),
		Font = FONT_BOLD,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, theme.Text)
	text(info.Content or "", {
		Size = UDim2.new(1, -24, 0, 32),
		Position = UDim2.fromOffset(12, 48),
		Font = FONT,
		TextSize = 13,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, theme.SubText)
	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.32, Enum.EasingStyle.Back)
	Tween(cardStroke, { Transparency = 0.8 }, 1.2)

	local gone = false
	local function dismiss()
		if gone then
			return
		end
		gone = true
		Tween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.25)
		task.wait(0.3)
		wrap:Destroy()
	end
	card.MouseButton1Click:Connect(function()
		task.spawn(dismiss)
	end)
	task.delay(info.Duration or 4, dismiss)
end

return Window
