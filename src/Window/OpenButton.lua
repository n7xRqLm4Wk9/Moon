-- Draggable open button shown while the window is hidden. Hold and drag to move, tap to open.
local import = ...

local CreateLogo = import("UI/Logo")
local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Util = import("Core/Util")
local Create, Tween, Corner, IsPress, IsMove = Util.Create, Util.Tween, Util.Corner, Util.IsPress, Util.IsMove
local Binding = import("Theme/Binding")
local Bind, Stroke = Binding.Bind, Binding.Stroke

local function BuildOpenButton(self, overlay, opts)
	local tray = Create("Frame", {
		Name = "OpenButton",
		Size = UDim2.fromOffset(52, 44),
		Position = UDim2.new(0.5, -26, 1, -64),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Active = true,
		Visible = false,
		Parent = overlay,
	})
	Bind(self, tray, "BackgroundColor3", "Background")
	Corner(tray, 10)
	Stroke(self, tray, "Border", "BorderTransparency")
	CreateLogo(self, tray, 22, opts.Logo, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -3),
	})
	local indicator = Create("Frame", {
		Size = UDim2.fromOffset(14, 3),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		BorderSizePixel = 0,
		Parent = tray,
	})
	Bind(self, indicator, "BackgroundColor3", "Accent")
	Corner(indicator, "pill")
	self._tray = tray
	self._trayScale = Create("UIScale", { Parent = tray })

	local trayDragging, trayMoved, trayStart, trayOrigin, trayInput
	tray.InputBegan:Connect(function(input)
		if IsPress(input) then
			trayDragging, trayMoved = true, false
			trayInput = input
			trayStart = input.Position
			trayOrigin = tray.AbsolutePosition - overlay.AbsolutePosition
			Tween(tray, { BackgroundTransparency = 0.02 }, 0.08)
			Tween(self._trayScale, { Scale = 0.94 }, 0.08)
		end
	end)
	self:_connect(UserInputService.InputChanged, function(input)
		if not trayDragging or not IsMove(input) then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= trayInput then
			return
		end
		local delta = input.Position - trayStart
		if not trayMoved and delta.Magnitude > 6 then
			trayMoved = true
		end
		if trayMoved then
			local view, traySize = overlay.AbsoluteSize, tray.AbsoluteSize
			tray.Position = UDim2.fromOffset(
				math.clamp(trayOrigin.X + delta.X, 6, math.max(6, view.X - traySize.X - 6)),
				math.clamp(trayOrigin.Y + delta.Y, 6, math.max(6, view.Y - traySize.Y - 6))
			)
		end
	end)
	self:_connect(UserInputService.InputEnded, function(input)
		if not trayDragging or not IsPress(input) then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= trayInput then
			return
		end
		trayDragging = false
		Tween(tray, { BackgroundTransparency = 0.1 }, 0.1)
		Tween(self._trayScale, { Scale = 1 }, 0.15)
		if not trayMoved then
			self:SetVisible(true)
		end
	end)
end

return BuildOpenButton
