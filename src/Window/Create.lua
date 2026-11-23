-- Moon:CreateWindow builds the window; Moon:Unload removes every window.
local import = ...

local Moon = import("Core/Moon")
local CreateLogo = import("UI/Logo")
local Window = import("Window/Window")
local BuildWatermark = import("Window/Watermark")
local BuildPlayerCard = import("Window/PlayerCard")
local BuildOpenButton = import("Window/OpenButton")
local BuildResizeGrip = import("Window/ResizeGrip")
local Services = import("Core/Services")
local Players, UserInputService, Lighting, RunService, GuiService = Services.Players, Services.UserInputService, Services.Lighting, Services.RunService, Services.GuiService
local Fonts = import("Core/Fonts")
local FONT, FONT_BOLD = Fonts.FONT, Fonts.FONT_BOLD
local Colors = import("Theme/Colors")
local WHITE = Colors.WHITE
local Util = import("Core/Util")
local Create, Tween, Corner, Pad, List, IsPress, IsMove, GetGuiParent = Util.Create, Util.Tween, Util.Corner, Util.Pad, Util.List, Util.IsPress, Util.IsMove, Util.GetGuiParent
local Registry = import("Theme/Registry")
local ResolveTheme, ALIAS = Registry.ResolveTheme, Registry.ALIAS
local Binding = import("Theme/Binding")
local Bind, Themed, NewText, Stroke = Binding.Bind, Binding.Themed, Binding.NewText, Binding.Stroke

function Moon:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Moon"

	local self = setmetatable({
		Title = title,
		Tabs = {},
		Theme = {},
		ThemeName = "Moon",
		Visible = true,
		_logo = opts.Logo,
		_conns = {},
		_bindings = {},
		_accentPickers = {},
		_blurSize = 0,
	}, Window)

	-- live theme: every element reads from this one table
	local initial = ResolveTheme(opts.Theme or "Moon")
	for key in pairs(Moon.Themes.Moon) do
		self.Theme[key] = initial[key]
	end
	if type(opts.Theme) == "string" then
		self.ThemeName = ALIAS[opts.Theme] or opts.Theme
	elseif opts.Theme then
		self.ThemeName = "Custom"
	end
	local theme = self.Theme

	if opts.Blur == nil or opts.Blur == true then
		self._blurSize = 12
	elseif type(opts.Blur) == "number" then
		self._blurSize = math.clamp(opts.Blur, 0, 56)
	end

	local parent = opts.Parent or GetGuiParent()
	local guiName = "Moon_" .. title
	for _, leftover in ipairs({ guiName, guiName .. "_Overlay" }) do
		local old = parent:FindFirstChild(leftover)
		if old then
			old:Destroy()
		end
	end
	local oldBlur = Lighting:FindFirstChild("MoonBlur_" .. title)
	if oldBlur then
		oldBlur:Destroy()
	end

	local gui = Create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = parent,
	})
	self.Gui = gui

	-- second layer for the watermark, toasts and open button. It keeps Roblox's default
	-- inset so it sits below the top bar and inside device safe areas (notches).
	local overlay = Create("ScreenGui", {
		Name = guiName .. "_Overlay",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 101,
		Parent = parent,
	})
	pcall(function()
		overlay.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	end)
	self.Overlay = overlay

	-- fit to small screens unless a size was given
	local size = opts.Size
	if not size then
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		size = UDim2.fromOffset(math.min(680, viewport.X - 24), math.min(440, viewport.Y - 24))
	end
	local navWidth = opts.NavWidth or (size.X.Offset > 0 and size.X.Offset < 560 and 124 or 176)

	-- translucent glass window (a CanvasGroup so the whole thing can fade and clip to rounded corners)
	local main = Create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BorderSizePixel = 0,
		Parent = gui,
	})
	Themed(self, main, { BackgroundColor3 = "Background", BackgroundTransparency = "BackgroundTransparency" })
	local mainCorner = Corner(main, 8)
	Stroke(self, main, "Border", "BorderTransparency")
	self.Main = main
	local scale = Create("UIScale", { Parent = main })
	self._scale = scale
	self._userScale = opts.Scale or 1
	self._normalSize = size

	-- soft colored sheen across the glass (fades from top-left to transparent)
	local sheen = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = main,
	})
	Bind(self, sheen, "BackgroundColor3", "Tint")
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.72),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 35,
		Parent = sheen,
	})

	-- title bar
	local titlebar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = main,
	})
	CreateLogo(self, titlebar, 16, opts.Logo, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})
	NewText(self, titlebar, title, {
		Size = UDim2.new(1, -200, 1, 0),
		Position = UDim2.fromOffset(36, 0),
		Font = FONT,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local dragArea = Create("Frame", {
		Size = UDim2.new(1, -134, 1, 0),
		BackgroundTransparency = 1,
		Parent = titlebar,
	})

	local function CaptionButton(index, kind)
		local btn = Create("TextButton", {
			Size = UDim2.fromOffset(40, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6 - (index - 1) * 42, 0.5, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = titlebar,
		})
		Bind(self, btn, "BackgroundColor3", "Text")
		Corner(btn, 6)
		local glyph = Create("Frame", {
			Size = UDim2.fromOffset(10, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Parent = btn,
		})

		local parts = {}
		if kind == "min" then
			table.insert(parts, Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderSizePixel = 0,
				Parent = glyph,
			}))
		elseif kind == "max" then
			local outline = Stroke(self, glyph, "Text", 0, 1)
			table.insert(parts, outline)
		else
			for _, rotation in ipairs({ 45, -45 }) do
				table.insert(parts, Create("Frame", {
					Size = UDim2.fromOffset(14, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Rotation = rotation,
					BorderSizePixel = 0,
					Parent = glyph,
				}))
			end
		end
		local function paint(color)
			for _, part in ipairs(parts) do
				if part:IsA("UIStroke") then
					part.Color = color
				else
					part.BackgroundColor3 = color
				end
			end
		end
		for _, part in ipairs(parts) do
			if not part:IsA("UIStroke") then
				Bind(self, part, "BackgroundColor3", "Text")
			end
		end

		btn.MouseEnter:Connect(function()
			if kind == "close" then
				btn.BackgroundColor3 = theme.Danger
				Tween(btn, { BackgroundTransparency = 0 }, 0.1)
				paint(WHITE)
			else
				Tween(btn, { BackgroundTransparency = 0.9 }, 0.1)
			end
		end)
		btn.MouseLeave:Connect(function()
			Tween(btn, { BackgroundTransparency = 1 }, 0.1)
			paint(theme.Text)
		end)
		return btn
	end

	local closeBtn = CaptionButton(1, "close")
	local maxBtn = CaptionButton(2, "max")
	local minBtn = CaptionButton(3, "min")

	-- body: navigation pane + content
	local body = Create("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -36),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local nav = Create("Frame", {
		Size = UDim2.new(0, navWidth, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local navHeader = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = nav,
	})
	CreateLogo(self, navHeader, 32, opts.Logo, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
	})
	NewText(self, navHeader, title, {
		Size = UDim2.new(1, -64, 0, 18),
		Position = UDim2.fromOffset(58, 12),
		Font = FONT_BOLD,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	NewText(self, navHeader, opts.Subtitle or ("v" .. Moon.Version), {
		Size = UDim2.new(1, -64, 0, 16),
		Position = UDim2.fromOffset(58, 31),
		Font = FONT,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "SubText")

	local localPlayer = Players.LocalPlayer
	local hasCard = opts.PlayerCard ~= false and localPlayer ~= nil

	local tabBar = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -(64 + (hasCard and 68 or 0))),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = nav,
	})
	List(tabBar, 2)
	Pad(tabBar, 8, 4, 8, 8)
	self._tabBar = tabBar

	-- player card (bottom-left): avatar, name and time spent in this game session
	if hasCard then
		BuildPlayerCard(self, nav, gui, navWidth, localPlayer)
	end

	self._pages = Create("Frame", {
		Position = UDim2.fromOffset(navWidth, 0),
		Size = UDim2.new(1, -navWidth, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	local isTouch = UserInputService.TouchEnabled

	-- toast notifications: bottom-right on PC, top-right (under the watermark) on touch devices
	-- so they never cover the jump button
	local notifyHolder = Create("Frame", {
		AnchorPoint = isTouch and Vector2.new(1, 0) or Vector2.new(1, 1),
		Position = isTouch and UDim2.new(1, -12, 0, 58) or UDim2.new(1, -16, 1, -16),
		Size = isTouch and UDim2.new(0, 300, 1, -70) or UDim2.new(0, 320, 1, -32),
		BackgroundTransparency = 1,
		Parent = overlay,
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = isTouch and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
		Parent = notifyHolder,
	})
	self._notifyHolder = notifyHolder

	-- watermark (FPS + ping), top-right of the safe area
	local watermarkOpts = type(opts.Watermark) == "table" and opts.Watermark or { Visible = opts.Watermark ~= false }
	self.Watermark = BuildWatermark(self, overlay, watermarkOpts)

	-- if this client did not apply the top inset to the overlay, offset by the top bar manually
	task.spawn(function()
		RunService.RenderStepped:Wait()
		local camera = workspace.CurrentCamera
		if not overlay.Parent or not camera or camera.ViewportSize.Y - overlay.AbsoluteSize.Y >= 1 then
			return
		end
		local ok, inset = pcall(function()
			return GuiService:GetGuiInset()
		end)
		local top = ok and inset.Y or 0
		self._topInset = top
		self.Watermark.Instance.Position = UDim2.new(1, -12, 0, 12 + top)
		if isTouch then
			notifyHolder.Position = UDim2.new(1, -12, 0, 58 + top)
		end
	end)

	-- open button (draggable, shown while the window is hidden)
	BuildOpenButton(self, overlay, opts)

	-- resize grip (bottom-right corner)
	self._grip = BuildResizeGrip(self, main)

	-- maximize / restore
	local maximized = false
	local restoreSize, restorePos = size, main.Position
	maxBtn.MouseButton1Click:Connect(function()
		maximized = not maximized
		self._maximized = maximized
		if maximized then
			restoreSize, restorePos = main.Size, main.Position
			mainCorner.CornerRadius = UDim.new(0, 0)
			Tween(main, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5) }, 0.22)
		else
			mainCorner.CornerRadius = UDim.new(0, 8)
			self._normalSize = restoreSize
			Tween(main, { Size = restoreSize, Position = restorePos }, 0.22)
		end
		Tween(scale, { Scale = self:_scaleTarget() }, 0.22)
		if self._grip then
			self._grip.Visible = not maximized
		end
	end)
	minBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	-- dragging by the title bar
	local dragging, dragStart, startPos
	dragArea.InputBegan:Connect(function(input)
		if IsPress(input) and not maximized then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	self:_connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	self:_connect(UserInputService.InputEnded, function(input)
		if IsPress(input) then
			dragging = false
		end
	end)

	-- toggle key
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == toggleKey then
			self:Toggle()
		end
	end)

	-- intro animation
	self:_syncBlur()
	main.GroupTransparency = 1
	local introScale = self:_scaleTarget()
	scale.Scale = 0.95 * introScale
	Tween(main, { GroupTransparency = 0 }, 0.28)
	Tween(scale, { Scale = introScale }, 0.32, Enum.EasingStyle.Back)

	table.insert(Moon.Windows, self)
	return self
end


function Moon:Unload()
	for _, window in ipairs({ table.unpack(Moon.Windows) }) do
		window:Destroy()
	end
	table.clear(Moon.Flags)
	table.clear(Moon._elements)
end

return Moon
