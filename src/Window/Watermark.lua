-- FPS + ping watermark card.
local import = ...

local CreateLogo = import("UI/Logo")
local Services = import("Core/Services")
local Players, RunService, Stats = Services.Players, Services.RunService, Services.Stats
local Fonts = import("Core/Fonts")
local FONT, FONT_BOLD = Fonts.FONT, Fonts.FONT_BOLD
local Util = import("Core/Util")
local Create, Tween, Corner, Pad = Util.Create, Util.Tween, Util.Corner, Util.Pad
local Binding = import("Theme/Binding")
local Bind, NewText, Stroke = Binding.Bind, Binding.NewText, Binding.Stroke

local function GetPing()
	local ok, ms = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and type(ms) == "number" then
		return math.floor(ms + 0.5)
	end
	local lp = Players.LocalPlayer
	local ok2, seconds = pcall(function()
		return lp:GetNetworkPing()
	end)
	if ok2 and type(seconds) == "number" then
		return math.floor(seconds * 1000 + 0.5)
	end
	return nil
end

local function StatusColor(theme, level)
	if level == 1 then
		return theme.Good
	elseif level == 2 then
		return theme.Warn
	end
	return theme.Bad
end

local function BuildWatermark(window, overlay, opts)
	local visible = opts.Visible ~= false
	local holder = Create("CanvasGroup", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = visible,
		Parent = overlay,
	})
	Bind(window, holder, "BackgroundColor3", "Background")
	Corner(holder, 8)
	Stroke(window, holder, "Border", "BorderTransparency")
	Pad(holder, 5, 0, 12, 0)
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = holder,
	})

	local chip = Create("Frame", {
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = holder,
	})
	Bind(window, chip, "BackgroundColor3", "Accent")
	Corner(chip, 6)
	CreateLogo(window, chip, 14, window._logo, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	local title = NewText(window, holder, opts.Text or window.Title, {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Font = FONT_BOLD,
		TextSize = 13,
	})

	local function Divider(order)
		local line = Create("Frame", {
			Size = UDim2.fromOffset(1, 16),
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = holder,
		})
		Bind(window, line, "BackgroundColor3", "Text")
	end

	local function Stat(label, order, valueWidth)
		local group = Create("Frame", {
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = holder,
		})
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 5),
			Parent = group,
		})
		NewText(window, group, label, {
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 1,
			Font = FONT,
			TextSize = 11,
		}, "SubText")
		return NewText(window, group, "--", {
			Size = UDim2.new(0, valueWidth, 1, 0),
			LayoutOrder = 2,
			Font = FONT_BOLD,
			TextSize = 13,
		})
	end

	Divider(3)
	local fpsValue = Stat("FPS", 4, 26)
	Divider(5)
	local pingValue = Stat("PING", 6, 46)

	local frames, elapsed = 0, 0
	window:_connect(RunService.RenderStepped, function(dt)
		if not visible then
			frames, elapsed = 0, 0
			return
		end
		frames = frames + 1
		elapsed = elapsed + dt
		if elapsed < 0.5 then
			return
		end
		local theme = window.Theme
		local fps = math.floor(frames / elapsed + 0.5)
		frames, elapsed = 0, 0
		fpsValue.Text = tostring(fps)
		fpsValue.TextColor3 = StatusColor(theme, fps >= 55 and 1 or (fps >= 30 and 2 or 3))
		local ping = GetPing()
		if ping then
			pingValue.Text = ping .. " ms"
			pingValue.TextColor3 = StatusColor(theme, ping <= 80 and 1 or (ping <= 160 and 2 or 3))
		else
			pingValue.Text = "--"
		end
	end)

	local obj = { Instance = holder }
	function obj:SetVisible(value)
		value = value and true or false
		if value == visible then
			return
		end
		visible = value
		if visible then
			holder.Visible = true
			holder.GroupTransparency = 1
			Tween(holder, { GroupTransparency = 0 }, 0.2)
		else
			Tween(holder, { GroupTransparency = 1 }, 0.15)
			task.delay(0.16, function()
				if not visible then
					holder.Visible = false
				end
			end)
		end
	end
	function obj:Toggle()
		obj:SetVisible(not visible)
	end
	function obj:IsVisible()
		return visible
	end
	function obj:SetTitle(text)
		title.Text = text
	end
	return obj
end

return BuildWatermark
