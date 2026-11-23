-- Target card: a glass card with a player's face, name, health bar and info chips, with small animations.
-- Moon does not find targets or read health for you: you call SetTarget / SetHealth with your own data.
--
--   local card = Window:CreateTargetCard({ Position = "TopCenter" })
--   card:SetTarget({ Name = "Enemy", Sub = "@enemy123", UserId = 1, Health = 100, MaxHealth = 100, Info = { "Team: Red", "AK-47" } }):Show()
--   card:SetHealth(60)      -- animates, shakes and flashes on damage
--   card:Hide()
local import = ...

local Services = import("Core/Services")
local Players, RunService = Services.Players, Services.RunService
local Fonts = import("Core/Fonts")
local FONT, FONT_MED, FONT_BOLD = Fonts.FONT, Fonts.FONT_MED, Fonts.FONT_BOLD
local Colors = import("Theme/Colors")
local WHITE, RGB, HealthColor = Colors.WHITE, Colors.RGB, Colors.HealthColor
local Util = import("Core/Util")
local Create, Tween, Corner = Util.Create, Util.Tween, Util.Corner
local Binding = import("Theme/Binding")
local Bind, Themed, NewText, Stroke = Binding.Bind, Binding.Themed, Binding.NewText, Binding.Stroke
local Window = import("Window/Window")

local GRAY = RGB(110, 110, 118)
local avatarCache = {}

-- anchor, position, direction the card slides in from
local POSITIONS = {
	TopCenter = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 12), -18 },
	TopLeft = { Vector2.new(0, 0), UDim2.new(0, 12, 0, 12), -18 },
	TopRight = { Vector2.new(1, 0), UDim2.new(1, -12, 0, 58), -18 }, -- below the watermark
	BottomCenter = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -84), 18 },
}

function Window:CreateTargetCard(opts)
	opts = opts or {}
	local window = self
	local theme = self.Theme
	local positionName = POSITIONS[opts.Position] and opts.Position or "TopCenter"
	local baseWidth = opts.Width or 290

	local card = { Visible = false }
	local state = "ok" -- "ok" | "low" | "dead"
	local health, maxHealth = nil, 100
	local subText = ""
	local chipCount = 0
	local avatarToken = 0
	local humanoidConn

	local root = Create("CanvasGroup", {
		Name = "MoonTargetCard",
		Size = UDim2.fromOffset(baseWidth, 86),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		Parent = self.Overlay,
	})
	Bind(window, root, "BackgroundColor3", "Background")
	Corner(root, 12)
	local border = Stroke(window, root, "Border", "BorderTransparency")
	local scale = Create("UIScale", { Parent = root })

	-- soft accent glow on the left edge
	local glow = Create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = root })
	Bind(window, glow, "BackgroundColor3", "Accent")
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.6, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glow,
	})

	-- avatar with a ring that follows the health state
	local avatarHolder = Create("Frame", {
		Size = UDim2.fromOffset(56, 56),
		Position = UDim2.fromOffset(14, 15),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local avatarScale = Create("UIScale", { Parent = avatarHolder })
	local avatar = Create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		Parent = avatarHolder,
	})
	Themed(window, avatar, { BackgroundColor3 = "Control", BackgroundTransparency = "ControlTransparency" })
	Corner(avatar, "pill")
	local ring = Stroke(window, avatar, function(t)
		return state == "ok" and t.Accent or t.Bad
	end, 0.15, 2)

	local nameLabel = NewText(window, root, "Target", {
		Position = UDim2.fromOffset(84, 12),
		Size = UDim2.new(1, -170, 0, 18),
		Font = FONT_BOLD,
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local subLabel = NewText(window, root, "", {
		Position = UDim2.fromOffset(84, 31),
		Size = UDim2.new(1, -98, 0, 16),
		Font = FONT,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "SubText")
	local healthText = NewText(window, root, "", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.fromOffset(80, 18),
		Font = FONT_BOLD,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- health bar: the fill moves fast, the white trail lingers behind it
	local track = Create("Frame", {
		Position = UDim2.fromOffset(84, 54),
		Size = UDim2.new(1, -98, 0, 8),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Parent = root,
	})
	Bind(window, track, "BackgroundColor3", "Text")
	Corner(track, "pill")
	local trail = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(trail, "pill")
	local fill = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = HealthColor(1),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(fill, "pill")

	-- info chips
	local chips = Create("Frame", {
		Position = UDim2.fromOffset(84, 70),
		Size = UDim2.new(1, -98, 0, 20),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = chips,
	})

	-- the number counts up/down smoothly
	local counter = Instance.new("NumberValue")
	counter.Changed:Connect(function(value)
		healthText.Text = string.format("%d / %d", math.floor(value + 0.5), maxHealth)
	end)

	-- layout helpers ----------------------------------------------------

	local function basePosition()
		local pos = POSITIONS[positionName][2]
		if positionName:sub(1, 3) == "Top" then
			pos = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + (window._topInset or 0))
		end
		return pos
	end

	local function offsetPosition(pos)
		return UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + POSITIONS[positionName][3])
	end

	local function resize()
		local width = math.min(baseWidth, math.max(window.Overlay.AbsoluteSize.X - 24, 200))
		Tween(root, { Size = UDim2.fromOffset(width, chipCount > 0 and 98 or 80) }, 0.2)
	end

	local function refreshSub()
		subLabel.Text = state == "dead" and "Eliminated" or subText
	end

	local function flashBorder(color)
		border.Color = color
		border.Transparency = 0
		Tween(border, { Color = theme.Border, Transparency = theme.BorderTransparency }, 0.5)
	end

	local function shake()
		if not card.Visible then
			return
		end
		task.spawn(function()
			local base = basePosition()
			for i = 1, 5 do
				local offset = (i % 2 == 0 and 1 or -1) * (7 - i)
				root.Position = UDim2.new(base.X.Scale, base.X.Offset + offset, base.Y.Scale, base.Y.Offset)
				task.wait(0.035)
			end
			root.Position = base
		end)
	end

	local function setState(newState)
		if newState == state then
			return
		end
		state = newState
		Tween(avatar, { ImageColor3 = state == "dead" and GRAY or WHITE }, 0.25)
		Tween(ring, { Color = state == "ok" and theme.Accent or theme.Bad }, 0.25)
		if state ~= "low" then
			ring.Transparency = 0.15
		end
		refreshSub()
	end

	-- low health: the ring pulses
	window:_connect(RunService.RenderStepped, function()
		if card.Visible and state == "low" then
			ring.Transparency = 0.1 + (math.sin(os.clock() * 6) + 1) * 0.15
		end
	end)

	-- public api --------------------------------------------------------

	function card:Show()
		if card.Visible then
			return card
		end
		card.Visible = true
		root.AnchorPoint = POSITIONS[positionName][1]
		resize()
		local final = basePosition()
		root.Position = offsetPosition(final)
		root.GroupTransparency = 1
		root.Visible = true
		scale.Scale = 0.96
		avatarScale.Scale = 0.6
		Tween(root, { Position = final }, 0.35, Enum.EasingStyle.Back)
		Tween(root, { GroupTransparency = 0 }, 0.2)
		Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		Tween(avatarScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
		return card
	end

	function card:Hide()
		if not card.Visible then
			return card
		end
		card.Visible = false
		Tween(root, { GroupTransparency = 1 }, 0.18)
		Tween(root, { Position = offsetPosition(basePosition()) }, 0.2)
		task.delay(0.22, function()
			if not card.Visible then
				root.Visible = false
			end
		end)
		return card
	end

	function card:Toggle()
		if card.Visible then
			return card:Hide()
		end
		return card:Show()
	end

	function card:IsVisible()
		return card.Visible
	end

	function card:SetName(text)
		nameLabel.Text = tostring(text or "")
		return card
	end

	function card:SetSub(text)
		subText = tostring(text or "")
		refreshSub()
		return card
	end

	-- a UserId (number) loads that player's face; a string is used as an image directly
	function card:SetAvatar(source)
		avatarToken = avatarToken + 1
		local token = avatarToken
		if type(source) == "number" then
			local cached = avatarCache[source]
			if cached then
				avatar.Image = cached
			else
				avatar.Image = ""
				task.spawn(function()
					local ok, content = pcall(function()
						return Players:GetUserThumbnailAsync(source, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
					end)
					if ok and content then
						avatarCache[source] = content
						if token == avatarToken and avatar.Parent then
							avatar.Image = content
						end
					end
				end)
			end
		elseif type(source) == "string" then
			avatar.Image = source
		else
			avatar.Image = ""
		end
		if card.Visible then
			avatarScale.Scale = 0.75
			Tween(avatarScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
		end
		return card
	end

	-- small chips under the bar: card:SetInfo({ "Team: Red", "AK-47", "42m" })
	function card:SetInfo(lines)
		for _, child in ipairs(chips:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		chipCount = 0
		for index, text in ipairs(lines or {}) do
			local chip = Create("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
				Text = tostring(text),
				Font = FONT_MED,
				TextSize = 11,
				LayoutOrder = index,
				Parent = chips,
			})
			Themed(window, chip, { BackgroundColor3 = "Text", TextColor3 = "SubText" })
			Corner(chip, "pill")
			Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = chip })
			chipCount = chipCount + 1
		end
		resize()
		return card
	end

	function card:SetHealth(value, max)
		max = max or maxHealth
		local previous = health
		health, maxHealth = value, max
		local fraction = math.clamp(value / math.max(max, 1), 0, 1)

		Tween(fill, { Size = UDim2.fromScale(fraction, 1), BackgroundColor3 = HealthColor(fraction) }, 0.22)
		Tween(counter, { Value = value }, 0.3)
		if previous ~= nil and value < previous then
			task.delay(0.35, function()
				if trail.Parent then
					Tween(trail, { Size = UDim2.fromScale(fraction, 1) }, 0.45)
				end
			end)
			flashBorder(theme.Bad)
			shake()
		else
			Tween(trail, { Size = UDim2.fromScale(fraction, 1) }, 0.22)
			if previous ~= nil and value > previous then
				flashBorder(theme.Good)
			end
		end
		setState(value <= 0 and "dead" or (fraction <= 0.25 and "low" or "ok"))
		return card
	end

	-- everything at once: Name, Sub, UserId or Image, Health, MaxHealth, Info
	function card:SetTarget(info)
		info = info or {}
		health = nil -- a new target never plays the damage animation
		card:SetName(info.Name or "Target")
		card:SetSub(info.Sub)
		card:SetAvatar(info.UserId or info.Image)
		card:SetInfo(info.Info)
		if info.Health ~= nil then
			card:SetHealth(info.Health, info.MaxHealth)
		end
		if card.Visible then
			Tween(scale, { Scale = 0.97 }, 0.07)
			task.delay(0.07, function()
				Tween(scale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
			end)
		end
		return card
	end

	-- convenience: fills name, @username and face from a Player (health is still yours to set)
	function card:SetPlayer(player)
		return card:SetTarget({ Name = player.DisplayName, Sub = "@" .. player.Name, UserId = player.UserId })
	end

	function card:SetPosition(name)
		if not POSITIONS[name] then
			return card
		end
		positionName = name
		if card.Visible then
			root.AnchorPoint = POSITIONS[name][1]
			Tween(root, { Position = basePosition() }, 0.3)
		end
		return card
	end

	-- optional convenience: keeps the card's health in sync with a Humanoid
	function card:BindHumanoid(humanoid)
		if humanoidConn then
			humanoidConn:Disconnect()
			humanoidConn = nil
		end
		if humanoid then
			card:SetHealth(humanoid.Health, humanoid.MaxHealth)
			humanoidConn = humanoid.HealthChanged:Connect(function(value)
				card:SetHealth(value, humanoid.MaxHealth)
			end)
		end
		return card
	end

	function card:Destroy()
		if humanoidConn then
			humanoidConn:Disconnect()
		end
		counter:Destroy()
		root:Destroy()
	end

	card:SetHealth(100, 100)
	if opts.Visible then
		card:Show()
	end
	return card
end

return Window
