-- Tabs (navigation pane entries + their pages).
local import = ...

local Elements = import("UI/Elements/Base")
local Window = import("Window/Window")
local Fonts = import("Core/Fonts")
local FONT_SERIF = Fonts.FONT_SERIF
local Util = import("Core/Util")
local Create, Tween, Corner, Pad, List = Util.Create, Util.Tween, Util.Corner, Util.Pad, Util.List
local Binding = import("Theme/Binding")
local Bind, NewText = Binding.Bind, Binding.NewText

function Window:AddTab(name)
	local window = self
	local theme = self.Theme

	local tab = setmetatable({
		Theme = theme,
		Window = window,
		_active = false,
	}, { __index = Elements })

	local button = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = self._tabBar,
	})
	Bind(window, button, "BackgroundColor3", "Text")
	Corner(button, 6)
	local pill = Create("Frame", {
		Size = UDim2.fromOffset(3, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BorderSizePixel = 0,
		Parent = button,
	})
	Bind(window, pill, "BackgroundColor3", "Accent")
	Corner(pill, "pill")
	local label = NewText(window, button, name or "Tab", {
		Size = UDim2.new(1, -22, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, function(t)
		return tab._active and t.Text or t.SubText
	end)

	local holder = Create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self._pages,
	})
	local page = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = holder,
	})
	Bind(window, page, "ScrollBarImageColor3", "Accent")
	List(page, 6)
	Pad(page, 8, 4, 16, 16)
	NewText(window, page, name or "Tab", {
		Size = UDim2.new(1, 0, 0, 44),
		Font = FONT_SERIF,
		TextSize = 24,
		LayoutOrder = -1,
	})

	tab.Container = page
	tab.Page = page
	tab._holder = holder
	tab._button = button
	tab._pill = pill
	tab._label = label
	table.insert(self.Tabs, tab)

	function tab:Select()
		for _, other in ipairs(window.Tabs) do
			local active = other == self
			if active and not other._active then
				other._holder.Visible = true
				other._holder.GroupTransparency = 1
				other._holder.Position = UDim2.fromOffset(0, 14)
				Tween(other._holder, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.24)
			elseif not active then
				other._holder.Visible = false
			end
			other._active = active
			Tween(other._pill, { Size = UDim2.fromOffset(3, active and 16 or 0) }, 0.2, Enum.EasingStyle.Back)
			Tween(other._button, { BackgroundTransparency = active and 0.91 or 1 }, 0.15)
			Tween(other._label, { TextColor3 = active and theme.Text or theme.SubText }, 0.15)
		end
	end

	button.MouseEnter:Connect(function()
		if not tab._active then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.1)
		end
	end)
	button.MouseLeave:Connect(function()
		if not tab._active then
			Tween(button, { BackgroundTransparency = 1 }, 0.1)
		end
	end)
	button.MouseButton1Click:Connect(function()
		tab:Select()
	end)

	if #self.Tabs == 1 then
		tab:Select()
	end
	return tab
end

return Window
