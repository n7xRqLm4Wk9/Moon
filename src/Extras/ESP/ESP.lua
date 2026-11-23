-- ESP: world overlays (box, name, health bar, distance, extra lines) for anything you point it at.
-- Moon does not look for players or read their health for you: you add targets and set the values.
local import = ...

local Moon = import("Core/Moon")
local Services = import("Core/Services")
local RunService = Services.RunService
local Fonts = import("Core/Fonts")
local FONT, FONT_BOLD = Fonts.FONT, Fonts.FONT_BOLD
local Colors = import("Theme/Colors")
local WHITE, RGB, HealthColor = Colors.WHITE, Colors.RGB, Colors.HealthColor
local Util = import("Core/Util")
local Create, Tween, Corner, GetGuiParent = Util.Create, Util.Tween, Util.Corner, Util.GetGuiParent

local RED = RGB(226, 100, 88)
local LINE_COLOR = RGB(214, 218, 230)

local ESP = {
	Enabled = true,
	-- defaults for every object; override one object with ESP:Add(target, { Box = false, ... })
	Settings = {
		Box = true,
		BoxStyle = "Corners", -- "Corners" | "Full"
		Name = true,
		Health = true,
		HealthText = false,
		Distance = true,
		Lines = true,
		Highlight = false,
		AlwaysOnTop = true,
		MaxDistance = 1000,
		Unit = "m",
		Color = RGB(184, 196, 240),
	},
	_objects = {},
	_count = 0,
}
Moon.ESP = ESP

local Object = {}
Object.__index = Object

local function folder()
	if not ESP._folder or not ESP._folder.Parent then
		ESP._folder = Create("Folder", { Name = "MoonESP", Parent = GetGuiParent() })
	end
	return ESP._folder
end

local function rootOf(target)
	if target:IsA("BasePart") then
		return target
	elseif target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function sizeOf(target)
	if target:IsA("Model") then
		local ok, size = pcall(function()
			return target:GetExtentsSize()
		end)
		if ok then
			return size
		end
	elseif target:IsA("BasePart") then
		return target.Size
	end
	return Vector3.new(4, 6, 2)
end

-- per-object option, falling back to the global setting
local function opt(object, key)
	local value = object.Opts[key]
	if value == nil then
		value = ESP.Settings[key]
	end
	return value
end

local function startLoop()
	if ESP._loop then
		return
	end
	ESP._loop = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local now = os.clock()
		for _, object in pairs(ESP._objects) do
			object:Update(camera, now)
		end
	end)
end

local function stopLoop()
	if ESP._loop and ESP._count == 0 then
		ESP._loop:Disconnect()
		ESP._loop = nil
	end
end

----------------------------------------------------------------------
-- One ESP object
----------------------------------------------------------------------

function Object:_build(size)
	local root = self.Root

	-- box: a pixel-sized billboard whose size is recalculated from the camera every frame
	self.BoxGui = Create("BillboardGui", {
		Name = "Box",
		Adornee = root,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(40, 60),
		LightInfluence = 0,
		ResetOnSpawn = false,
		Active = false,
		Enabled = false,
		Parent = folder(),
	})
	local boxHolder = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = self.BoxGui })
	self._corners = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = boxHolder })
	self._boxParts = {}
	for _, corner in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local ax, ay = corner[1], corner[2]
		for _, vertical in ipairs({ false, true }) do
			table.insert(self._boxParts, Create("Frame", {
				AnchorPoint = Vector2.new(ax, ay),
				Position = UDim2.fromScale(ax, ay),
				Size = vertical and UDim2.new(0, 2, 0.22, 0) or UDim2.new(0.3, 0, 0, 2),
				BorderSizePixel = 0,
				Parent = self._corners,
			}))
		end
	end
	self._full = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Visible = false,
		Parent = boxHolder,
	})
	self._fullStroke = Create("UIStroke", { Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self._full })

	-- tag: name, health bar, distance, extra lines (constant pixel size, sits above the head)
	self.TagGui = Create("BillboardGui", {
		Name = "Tag",
		Adornee = root,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(180, 60),
		StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 0.8, 0),
		SizeOffset = Vector2.new(0, 0.5),
		LightInfluence = 0,
		ResetOnSpawn = false,
		Active = false,
		Enabled = false,
		Parent = folder(),
	})
	self._group = Create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = self.TagGui,
	})
	self._pop = Create("UIScale", { Parent = self._group })

	self._name = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 13,
		TextStrokeTransparency = 0.4,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		Parent = self._group,
	})

	self._health = Create("Frame", { BackgroundTransparency = 1, Parent = self._group })
	self._track = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(84, 5),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = self._health,
	})
	Corner(self._track, "pill")
	self._trail = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = self._track,
	})
	Corner(self._trail, "pill")
	self._fill = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = HealthColor(1),
		BorderSizePixel = 0,
		Parent = self._track,
	})
	Corner(self._fill, "pill")
	self._healthText = Create("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, 32, 0.5, 0),
		Size = UDim2.fromOffset(40, 12),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = WHITE,
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		Parent = self._health,
	})

	self._distance = Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = LINE_COLOR,
		TextStrokeTransparency = 0.5,
		Parent = self._group,
	})
	self._lines = Create("Frame", { BackgroundTransparency = 1, Parent = self._group })
end

-- stacks the visible rows and sizes the tag billboard to fit
function Object:Layout()
	local y = 0
	local function place(row, show, height)
		row.Visible = show
		if show then
			row.Position = UDim2.fromOffset(0, y)
			row.Size = UDim2.new(1, 0, 0, height)
			y = y + height + 2
		end
	end
	place(self._name, opt(self, "Name") and self.Name ~= "", 16)
	place(self._health, opt(self, "Health") and self.Health ~= nil, 10)
	place(self._distance, opt(self, "Distance"), 14)
	local lineCount = opt(self, "Lines") and #self.Lines or 0
	place(self._lines, lineCount > 0, lineCount * 13)

	local withText = opt(self, "HealthText")
	self._healthText.Visible = withText
	self._track.Position = withText and UDim2.new(0.5, -14, 0.5, 0) or UDim2.fromScale(0.5, 0.5)
	self.TagGui.Size = UDim2.fromOffset(180, math.max(y, 4))
end

function Object:_applyColor()
	local color = self.Color or ESP.Settings.Color
	self._name.TextColor3 = color
	for _, part in ipairs(self._boxParts) do
		part.BackgroundColor3 = color
	end
	self._full.BackgroundColor3 = color
	self._fullStroke.Color = color
	if self._highlight then
		self._highlight.FillColor = color
		self._highlight.OutlineColor = color
	end
end

-- re-applies every option (call after changing settings)
function Object:Refresh()
	self.BoxGui.AlwaysOnTop = opt(self, "AlwaysOnTop")
	self.TagGui.AlwaysOnTop = opt(self, "AlwaysOnTop")
	self.BoxGui.Enabled = self._shown and opt(self, "Box")
	local style = opt(self, "BoxStyle")
	self._corners.Visible = style ~= "Full"
	self._full.Visible = style == "Full"

	if opt(self, "Highlight") then
		if not self._highlight then
			self._highlight = Create("Highlight", {
				Adornee = self.Target,
				FillTransparency = 0.8,
				OutlineTransparency = 0,
				DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
				Parent = folder(),
			})
		end
		self._highlight.Enabled = self._shown
	elseif self._highlight then
		self._highlight.Enabled = false
	end

	self:_applyColor()
	self:Layout()
end

function Object:_setShown(shown)
	self._shown = shown
	self.TagGui.Enabled = shown
	self.BoxGui.Enabled = shown and opt(self, "Box")
	if self._highlight then
		self._highlight.Enabled = shown and opt(self, "Highlight")
	end
	if shown then
		self._group.GroupTransparency = 1
		self._pop.Scale = 0.85
		Tween(self._group, { GroupTransparency = 0 }, 0.25)
		Tween(self._pop, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end
end

function Object:Update(camera, now)
	local root = self.Root
	if not root.Parent then
		-- the part was replaced (for example the character respawned its root)
		local replacement = rootOf(self.Target)
		if not replacement then
			if self._shown then
				self:_setShown(false)
			end
			return
		end
		self.Root = replacement
		root = replacement
		self.BoxGui.Adornee = replacement
		self.TagGui.Adornee = replacement
	end

	local position = root.Position
	local distance = (camera.CFrame.Position - position).Magnitude
	local shown = ESP.Enabled and self.Visible and distance <= opt(self, "MaxDistance")
	if shown ~= self._shown then
		self:_setShown(shown)
	end
	if not shown then
		return
	end

	if opt(self, "Box") then
		local top = camera:WorldToViewportPoint(position + Vector3.new(0, self._halfHeight, 0))
		local bottom = camera:WorldToViewportPoint(position - Vector3.new(0, self._halfHeight, 0))
		local height = math.max(math.abs(top.Y - bottom.Y), 10)
		self.BoxGui.Size = UDim2.fromOffset(height * self._aspect, height)
	end
	if opt(self, "Distance") then
		local value = math.floor((self.DistanceOverride or distance) + 0.5)
		if value ~= self._lastDistance then
			self._lastDistance = value
			self._distance.Text = value .. opt(self, "Unit")
		end
	end
	if self._low then
		self._fill.BackgroundColor3 = RED:Lerp(WHITE, (math.sin(now * 7) + 1) * 0.2)
	end
end

-- values you set ---------------------------------------------------------

function Object:SetName(text)
	self.Name = tostring(text or "")
	self._name.Text = self.Name
	self:Layout()
	return self
end

function Object:SetHealth(value, max)
	max = max or self.MaxHealth or 100
	local previous = self.Health
	self.Health, self.MaxHealth = value, max
	local fraction = math.clamp(value / math.max(max, 1), 0, 1)

	Tween(self._fill, { Size = UDim2.fromScale(fraction, 1), BackgroundColor3 = HealthColor(fraction) }, 0.2)
	if previous ~= nil and value < previous then
		-- damage: the white trail lingers, then catches up; the name flashes red
		task.delay(0.35, function()
			if self._trail.Parent then
				Tween(self._trail, { Size = UDim2.fromScale(fraction, 1) }, 0.45)
			end
		end)
		self._name.TextColor3 = RED
		Tween(self._name, { TextColor3 = self.Color or ESP.Settings.Color }, 0.4)
	else
		Tween(self._trail, { Size = UDim2.fromScale(fraction, 1) }, 0.2)
	end
	self._healthText.Text = tostring(math.floor(value + 0.5))
	self._low = fraction > 0 and fraction <= 0.25
	self:Layout()
	return self
end

function Object:SetDistance(value)
	self.DistanceOverride = value
	return self
end

function Object:SetLines(lines)
	self.Lines = lines or {}
	for _, label in ipairs(self._lineLabels) do
		label:Destroy()
	end
	table.clear(self._lineLabels)
	for index, text in ipairs(self.Lines) do
		table.insert(self._lineLabels, Create("TextLabel", {
			Position = UDim2.fromOffset(0, (index - 1) * 13),
			Size = UDim2.new(1, 0, 0, 13),
			BackgroundTransparency = 1,
			Text = tostring(text),
			Font = FONT,
			TextSize = 11,
			TextColor3 = LINE_COLOR,
			TextStrokeTransparency = 0.5,
			Parent = self._lines,
		}))
	end
	self:Layout()
	return self
end

function Object:SetColor(color)
	self.Color = color
	self:_applyColor()
	return self
end

function Object:SetVisible(visible)
	self.Visible = visible and true or false
	return self
end

-- optional convenience: keeps the health bar in sync with a Humanoid
function Object:BindHumanoid(humanoid)
	if self._humanoidConn then
		self._humanoidConn:Disconnect()
		self._humanoidConn = nil
	end
	if humanoid then
		self:SetHealth(humanoid.Health, humanoid.MaxHealth)
		self._humanoidConn = humanoid.HealthChanged:Connect(function(health)
			self:SetHealth(health, humanoid.MaxHealth)
		end)
	end
	return self
end

-- set several things at once: object:Set({ Name = "Bot", Health = 80, MaxHealth = 100, Lines = { "Red team" }, Box = false })
function Object:Set(values)
	local VALUE_KEYS = { Name = true, Health = true, MaxHealth = true, Distance = true, Lines = true, Color = true, Visible = true }
	for key, value in pairs(values) do
		if not VALUE_KEYS[key] then
			self.Opts[key] = value
		end
	end
	if values.Name ~= nil then
		self:SetName(values.Name)
	end
	if values.MaxHealth ~= nil then
		self.MaxHealth = values.MaxHealth
	end
	if values.Health ~= nil then
		self:SetHealth(values.Health, values.MaxHealth)
	end
	if values.Distance ~= nil then
		self:SetDistance(values.Distance)
	end
	if values.Lines ~= nil then
		self:SetLines(values.Lines)
	end
	if values.Color ~= nil then
		self.Color = values.Color
	end
	if values.Visible ~= nil then
		self.Visible = values.Visible and true or false
	end
	self:Refresh()
	return self
end

function Object:Destroy()
	if ESP._objects[self.Target] ~= self then
		return
	end
	ESP._objects[self.Target] = nil
	ESP._count = ESP._count - 1
	for _, connection in ipairs(self._conns) do
		connection:Disconnect()
	end
	if self._humanoidConn then
		self._humanoidConn:Disconnect()
	end
	self.BoxGui:Destroy()
	self.TagGui:Destroy()
	if self._highlight then
		self._highlight:Destroy()
	end
	stopLoop()
end

----------------------------------------------------------------------
-- Manager
----------------------------------------------------------------------

-- Adds (or updates) an ESP object for a Model or a part. Returns the object.
function ESP:Add(target, opts)
	if typeof(target) ~= "Instance" then
		error("[Moon.ESP] Add expects an Instance (a Model or a part)", 2)
	end
	local existing = ESP._objects[target]
	if existing then
		existing:Set(opts or {})
		return existing
	end
	local root = rootOf(target)
	if not root then
		warn("[Moon.ESP] no part found inside " .. target:GetFullName())
		return nil
	end

	local size = sizeOf(target)
	local object = setmetatable({
		Target = target,
		Root = root,
		Opts = {},
		Name = target.Name,
		MaxHealth = 100,
		Lines = {},
		Visible = true,
		_shown = false,
		_halfHeight = size.Y / 2,
		_aspect = math.clamp(math.max(size.X, size.Z) / math.max(size.Y, 0.1), 0.35, 1.2),
		_lineLabels = {},
		_low = false,
		_conns = {},
	}, Object)
	object:_build(size)
	object._name.Text = object.Name
	table.insert(object._conns, target.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			object:Destroy()
		end
	end))

	ESP._objects[target] = object
	ESP._count = ESP._count + 1
	object:Set(opts or {})
	startLoop()
	return object
end

function ESP:Get(target)
	return ESP._objects[target]
end

function ESP:Remove(target)
	local object = ESP._objects[target]
	if object then
		object:Destroy()
	end
end

function ESP:Clear()
	for _, object in pairs(table.clone(ESP._objects)) do
		object:Destroy()
	end
end

function ESP:Count()
	return ESP._count
end

-- master switch for every object
function ESP:SetEnabled(enabled)
	ESP.Enabled = enabled and true or false
	return ESP
end

-- change the defaults for every object: ESP:Configure({ Box = false, MaxDistance = 500, Color = Color3.new(1, 0, 0) })
function ESP:Configure(settings)
	for key, value in pairs(settings) do
		ESP.Settings[key] = value
	end
	for _, object in pairs(ESP._objects) do
		object:Refresh()
	end
	return ESP
end

return ESP
