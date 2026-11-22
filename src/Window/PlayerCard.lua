-- Player card (bottom-left of the navigation pane): avatar, name and session playtime.
local import = ...

local Services = import("Core/Services")
local Players = Services.Players
local Fonts = import("Core/Fonts")
local FONT = Fonts.FONT
local Util = import("Core/Util")
local Create, Corner = Util.Create, Util.Corner
local Binding = import("Theme/Binding")
local Bind, Themed, NewText, Stroke = Binding.Bind, Binding.Themed, Binding.NewText, Binding.Stroke

local function SessionSeconds()
	local ok, seconds = pcall(time)
	if ok and type(seconds) == "number" then
		return seconds
	end
	return os.clock()
end

local function FormatTime(seconds)
	seconds = math.floor(seconds)
	return string.format(
		"%d:%02d:%02d",
		math.floor(seconds / 3600),
		math.floor((seconds % 3600) / 60),
		seconds % 60
	)
end

local function BuildPlayerCard(self, nav, gui, navWidth, localPlayer)
	local card = Create("Frame", {
		Name = "PlayerCard",
		Size = UDim2.new(1, -16, 0, 52),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		BorderSizePixel = 0,
		Parent = nav,
	})
	Themed(self, card, { BackgroundColor3 = "Card", BackgroundTransparency = "CardTransparency" })
	Corner(card, 8)
	Stroke(self, card, "Stroke", "StrokeTransparency")

	local avatar = Create("ImageLabel", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		Parent = card,
	})
	Themed(self, avatar, { BackgroundColor3 = "Control", BackgroundTransparency = "ControlTransparency" })
	Corner(avatar, "pill")
	Stroke(self, avatar, "Accent", 0.3, 1.5)

	local dot = Create("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.fromOffset(34, 34),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = card,
	})
	Bind(self, dot, "BackgroundColor3", "Good")
	Corner(dot, "pill")
	Stroke(self, dot, "Background", 0, 2)

	NewText(self, card, localPlayer.DisplayName, {
		Size = UDim2.new(1, -56, 0, 16),
		Position = UDim2.fromOffset(51, 10),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local timeLabel = NewText(self, card, "", {
		Size = UDim2.new(1, -56, 0, 14),
		Position = UDim2.fromOffset(51, 27),
		Font = FONT,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "SubText")

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				localPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok and avatar.Parent then
			avatar.Image = content
		end
	end)

	local prefix = navWidth >= 150 and "Playtime " or ""
	task.spawn(function()
		while gui.Parent do
			timeLabel.Text = prefix .. FormatTime(SessionSeconds())
			task.wait(1)
		end
	end)
end

return BuildPlayerCard
