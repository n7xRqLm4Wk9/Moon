-- Dropdown. The option list opens as a floating popup instead of inside the scrolling page:
--   PC:     anchored under the box (flips above when there is no room); closes when you scroll or move the window
--   Mobile: a centered sheet with a dim backdrop and big touch rows (no nested scrolling)
local import = ...

local Card = import("UI/Card")
local Elements = import("UI/Elements/Base")
local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Colors = import("Theme/Colors")
local BLACK = Colors.BLACK
local Fonts = import("Core/Fonts")
local FONT, FONT_MED, FONT_BOLD = Fonts.FONT, Fonts.FONT_MED, Fonts.FONT_BOLD
local Util = import("Core/Util")
local Create, Tween, Corner, List, Pad, Safe, SetFlag, IsPress = Util.Create, Util.Tween, Util.Corner, Util.List, Util.Pad, Util.Safe, Util.SetFlag, Util.IsPress
local Binding = import("Theme/Binding")
local Themed, NewText, Stroke = Binding.Themed, Binding.NewText, Binding.Stroke

function Elements:AddDropdown(opts)
	opts = opts or {}
	local window, theme = self.Window, self.Theme
	local options = opts.Options or {}
	local selected = opts.Default
	local popup = nil
	local obj = {}

	local card, _, cy = Card(self, opts, 0.42)
	obj.Instance = card

	local combo = Create("TextButton", {
		Size = UDim2.new(0.4, 0, 0, 32),
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
	-- never get squeezed too small on narrow screens
	Create("UISizeConstraint", { MinSize = Vector2.new(104, 32), MaxSize = Vector2.new(240, 32), Parent = combo })
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

	local function render()
		valueLabel.Text = selected ~= nil and tostring(selected) or "None"
	end

	local function closePopup()
		local current = popup
		if not current then
			return
		end
		popup = nil
		if window._closePopup == closePopup then
			window._closePopup = nil
		end
		for _, connection in ipairs(current.conns) do
			connection:Disconnect()
		end
		Tween(arrow, { Rotation = 90 }, 0.15)
		Tween(current.frame, { GroupTransparency = 1 }, 0.12)
		Tween(current.scale, { Scale = 0.96 }, 0.12)
		Tween(current.backdrop, { BackgroundTransparency = 1 }, 0.12)
		task.delay(0.14, function()
			current.root:Destroy()
		end)
	end

	local function openPopup()
		if window._closePopup then
			window._closePopup()
		end

		local gui = window.Gui
		local sheet = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local view = gui.AbsoluteSize
		local rowSize = sheet and 44 or 34
		local headerH = sheet and 46 or 0
		local listH = #options * (rowSize + 2) + 8
		local width, height, x, y

		if sheet then
			-- phones: centered sheet, up to 82% of the screen height
			width = math.min(320, view.X - 32)
			height = math.min(headerH + listH, math.floor(view.Y * 0.82))
			x = (view.X - width) / 2
			y = (view.Y - height) / 2
		else
			-- PC: under the box, or above it when there is more room there
			local origin = combo.AbsolutePosition - gui.AbsolutePosition
			local box = combo.AbsoluteSize
			width = math.max(box.X, 170)
			local below = view.Y - (origin.Y + box.Y) - 14
			local above = origin.Y - 14
			height = math.min(listH, 260)
			if height > below and above > below then
				height = math.min(height, math.max(above, rowSize + 8))
				y = origin.Y - height - 6
			else
				height = math.min(height, math.max(below, rowSize + 8))
				y = origin.Y + box.Y + 6
			end
			x = math.clamp(origin.X + box.X - width, 8, math.max(8, view.X - width - 8))
		end
		y = math.clamp(y, 6, math.max(6, view.Y - height - 6))

		local root = Create("Frame", {
			Name = "MoonDropdown",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 100,
			Parent = gui,
		})
		local backdrop = Create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = BLACK,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			ZIndex = 100,
			Parent = root,
		})
		if sheet then
			Tween(backdrop, { BackgroundTransparency = 0.5 }, 0.18)
		end
		local frame = Create("CanvasGroup", {
			Size = UDim2.fromOffset(width, height),
			Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = theme.Background,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			ZIndex = 101,
			Parent = root,
		})
		Corner(frame, 10)
		Create("UIStroke", {
			Color = theme.Border,
			Transparency = theme.BorderTransparency,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = frame,
		})
		local scale = Create("UIScale", { Scale = 0.96, Parent = frame })
		Tween(frame, { GroupTransparency = 0 }, 0.16)
		Tween(scale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)

		if sheet then
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, headerH),
				Text = opts.Name or "Select",
				TextColor3 = theme.Text,
				Font = FONT_BOLD,
				TextSize = 15,
				Parent = frame,
			})
			Create("Frame", {
				Size = UDim2.new(1, -24, 0, 1),
				Position = UDim2.new(0, 12, 0, headerH - 1),
				BackgroundColor3 = theme.Text,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				Parent = frame,
			})
		end

		local list = Create("ScrollingFrame", {
			Position = UDim2.fromOffset(0, headerH),
			Size = UDim2.new(1, 0, 1, -headerH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = frame,
		})
		List(list, 2)
		Pad(list, 6, 4, 6, 4)

		local selectedIndex = 1
		for index, opt in ipairs(options) do
			local isSelected = opt == selected
			local rest = isSelected and 0.92 or 1
			if isSelected then
				selectedIndex = index
			end
			local button = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, rowSize),
				BackgroundColor3 = theme.Text,
				BackgroundTransparency = rest,
				AutoButtonColor = false,
				Text = "",
				BorderSizePixel = 0,
				Parent = list,
			})
			Corner(button, 6)
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -28, 1, 0),
				Position = UDim2.fromOffset(16, 0),
				Text = tostring(opt),
				TextColor3 = isSelected and theme.Accent or theme.Text,
				Font = FONT_MED,
				TextSize = sheet and 15 or 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = button,
			})
			if isSelected then
				local pill = Create("Frame", {
					Size = UDim2.fromOffset(3, 16),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 4, 0.5, 0),
					BackgroundColor3 = theme.Accent,
					BorderSizePixel = 0,
					Parent = button,
				})
				Corner(pill, "pill")
			end
			-- hover only for mouse users; press feedback for everyone (no highlight stuck on touch)
			if not sheet then
				button.MouseEnter:Connect(function()
					Tween(button, { BackgroundTransparency = 0.9 }, 0.08)
				end)
				button.MouseLeave:Connect(function()
					Tween(button, { BackgroundTransparency = rest }, 0.08)
				end)
			end
			button.InputBegan:Connect(function(input)
				if IsPress(input) then
					Tween(button, { BackgroundTransparency = 0.84 }, 0.05)
				end
			end)
			button.InputEnded:Connect(function(input)
				if IsPress(input) then
					Tween(button, { BackgroundTransparency = rest }, 0.1)
				end
			end)
			button.MouseButton1Click:Connect(function()
				obj:Set(opt)
				closePopup()
			end)
		end

		task.delay(0.03, function()
			if list.Parent then
				local rowTop = (selectedIndex - 1) * (rowSize + 2)
				list.CanvasPosition = Vector2.new(0, math.max(0, rowTop - (height - headerH) / 2 + rowSize / 2))
			end
		end)

		local conns = {}
		backdrop.MouseButton1Click:Connect(closePopup)
		if not sheet then
			-- an anchored popup would drift away from its box, so close it instead
			if self.Page then
				table.insert(conns, self.Page:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup))
			end
			table.insert(conns, window.Main:GetPropertyChangedSignal("Position"):Connect(closePopup))
			table.insert(conns, window.Main:GetPropertyChangedSignal("Size"):Connect(closePopup))
		end

		popup = { root = root, frame = frame, scale = scale, backdrop = backdrop, conns = conns }
		window._closePopup = closePopup
		Tween(arrow, { Rotation = -90 }, 0.15)
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
		closePopup()
		options = newOptions or {}
		if not keepSelection or not table.find(options, selected) then
			selected = nil
			SetFlag(opts, nil)
		end
		render()
	end

	combo.MouseButton1Click:Connect(function()
		if popup then
			closePopup()
		else
			openPopup()
		end
	end)

	render()
	SetFlag(opts, selected)
	return obj
end

return Elements
