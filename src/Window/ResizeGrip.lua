-- Resize grip in the bottom-right corner: drag it to resize the window (not available while maximized).
local import = ...

local Services = import("Core/Services")
local UserInputService = Services.UserInputService
local Util = import("Core/Util")
local Create, IsPress, IsMove = Util.Create, Util.IsPress, Util.IsMove
local Binding = import("Theme/Binding")
local Bind = Binding.Bind

local MIN_WIDTH, MIN_HEIGHT = 380, 270

local function BuildResizeGrip(self, main)
	-- a big invisible touch target with a small triangle of dots
	local grip = Create("TextButton", {
		Name = "ResizeGrip",
		Size = UDim2.fromOffset(30, 30),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = main,
	})
	for _, dot in ipairs({ { 5, 5 }, { 10, 5 }, { 15, 5 }, { 5, 10 }, { 10, 10 }, { 5, 15 } }) do
		local mark = Create("Frame", {
			Size = UDim2.fromOffset(2, 2),
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -dot[1], 1, -dot[2]),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = grip,
		})
		Bind(self, mark, "BackgroundColor3", "SubText")
	end

	local dragging, dragInput, startPointer, startPos, startWidth, startHeight, startScale
	grip.InputBegan:Connect(function(input)
		if IsPress(input) and not self._maximized then
			dragging = true
			dragInput = input
			startPointer = input.Position
			startPos = main.Position
			startScale = math.max(self._scale.Scale, 0.1)
			startWidth = main.AbsoluteSize.X / startScale
			startHeight = main.AbsoluteSize.Y / startScale
		end
	end)

	self:_connect(UserInputService.InputChanged, function(input)
		if not dragging or not IsMove(input) then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then
			return
		end
		local view = self.Gui.AbsoluteSize
		local delta = input.Position - startPointer
		local width = math.clamp(startWidth + delta.X / startScale, MIN_WIDTH, math.max(MIN_WIDTH, (view.X - 12) / startScale))
		local height = math.clamp(startHeight + delta.Y / startScale, MIN_HEIGHT, math.max(MIN_HEIGHT, (view.Y - 12) / startScale))
		main.Size = UDim2.fromOffset(width, height)
		-- the window is centered on its position, so move it by half the change to keep the top-left corner still
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + (width - startWidth) * startScale / 2,
			startPos.Y.Scale, startPos.Y.Offset + (height - startHeight) * startScale / 2
		)
		self._normalSize = main.Size
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if not dragging or not IsPress(input) then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then
			return
		end
		dragging = false
	end)

	return grip
end

return BuildResizeGrip
