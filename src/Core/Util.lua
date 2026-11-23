-- General helpers: instance creation, tweens, layout shortcuts, input helpers.
local import = ...

local UserInputService = import("Core/Services").UserInputService

local Moon = import("Core/Moon")
local Services = import("Core/Services")
local Players, TweenService = Services.Players, Services.TweenService

local function Create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(inst, props, duration, style, direction)
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function Apply(inst, props, instant, duration)
	if instant then
		for k, v in pairs(props) do
			inst[k] = v
		end
	else
		Tween(inst, props, duration)
	end
end

local function Corner(parent, radius)
	return Create("UICorner", {
		CornerRadius = radius == "pill" and UDim.new(1, 0) or UDim.new(0, radius or 6),
		Parent = parent,
	})
end

local function Pad(parent, left, top, right, bottom)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		Parent = parent,
	})
end

local function List(parent, padding)
	return Create("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function Safe(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[Moon] callback error: " .. tostring(err))
	end
end

local function SetFlag(opts, value)
	if opts.Flag then
		Moon.Flags[opts.Flag] = value
		if Moon._onFlag then
			Moon._onFlag(opts.Flag)
		end
	end
end

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function GetGuiParent()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- true when the last thing the player used was a touchscreen
local function IsTouchInput()
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

-- scrolls `page` so `target` is fully visible (used after a card expands near the bottom)
local function ScrollIntoView(page, target)
	task.delay(0.26, function()
		if not (page.Parent and target.Parent) then
			return
		end
		local overflow = (target.AbsolutePosition.Y + target.AbsoluteSize.Y) - (page.AbsolutePosition.Y + page.AbsoluteSize.Y) + 12
		if overflow > 0 then
			Tween(page, { CanvasPosition = Vector2.new(0, page.CanvasPosition.Y + overflow) }, 0.2)
		end
	end)
end

return {
	IsTouchInput = IsTouchInput,
	ScrollIntoView = ScrollIntoView,
	Create = Create,
	Tween = Tween,
	Apply = Apply,
	Corner = Corner,
	Pad = Pad,
	List = List,
	Safe = Safe,
	SetFlag = SetFlag,
	IsPress = IsPress,
	IsMove = IsMove,
	GetGuiParent = GetGuiParent,
}
