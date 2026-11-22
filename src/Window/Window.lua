-- The Window class: visibility, blur, theme switching and cleanup.
local import = ...

local Moon = import("Core/Moon")
local Services = import("Core/Services")
local TweenService, Lighting = Services.TweenService, Services.Lighting
local Colors = import("Theme/Colors")
local Luma, AccentKeys = Colors.Luma, Colors.AccentKeys
local Util = import("Core/Util")
local Create, Tween = Util.Create, Util.Tween
local Registry = import("Theme/Registry")
local ResolveTheme, ALIAS = Registry.ResolveTheme, Registry.ALIAS

local Window = {}
Window.__index = Window

function Window:_connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(self._conns, connection)
	return connection
end

-- Roblox cannot blur UI itself, so the glass look uses a BlurEffect on the game world
-- behind the (translucent) window. It fades in/out with the window.
function Window:_syncBlur()
	local target = (self.Visible and self._blurSize) or 0
	if target > 0 and not self._blur then
		self._blur = Create("BlurEffect", {
			Name = "MoonBlur_" .. self.Title,
			Size = 0,
			Parent = Lighting,
		})
	end
	local blur = self._blur
	if not blur then
		return
	end
	if target > 0 then
		blur.Enabled = true
	end
	local tween = Tween(blur, { Size = target }, 0.3)
	tween.Completed:Connect(function()
		if blur.Parent and blur.Size <= 0 then
			blur.Enabled = false
		end
	end)
end

function Window:SetBlur(size)
	if size == true then
		size = 12
	elseif not size then
		size = 0
	end
	self._blurSize = math.clamp(size, 0, 56)
	self:_syncBlur()
end

function Window:SetVisible(visible)
	visible = visible and true or false
	self.Visible = visible
	self._tray.Visible = not visible
	self:_syncBlur()
	if visible then
		self.Main.Visible = true
		self.Main.GroupTransparency = 1
		self._scale.Scale = 0.95
		Tween(self.Main, { GroupTransparency = 0 }, 0.2)
		Tween(self._scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
	else
		self._trayScale.Scale = 0.6
		Tween(self._trayScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
		Tween(self.Main, { GroupTransparency = 1 }, 0.14)
		Tween(self._scale, { Scale = 0.95 }, 0.14)
		task.delay(0.15, function()
			if not self.Visible and self.Main.Parent then
				self.Main.Visible = false
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

-- Smoothly fades every themed color from the current theme to the new one.
-- theme: a registered theme name, a full theme table, or { Background =, Accent = } (built automatically)
function Window:SetTheme(theme, instant)
	local new = ResolveTheme(theme)
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	for i = #self._bindings, 1, -1 do
		local binding = self._bindings[i]
		if not binding.inst.Parent then
			table.remove(self._bindings, i)
		else
			local target = binding.get(new)
			if instant then
				binding.inst[binding.prop] = target
			else
				TweenService:Create(binding.inst, info, { [binding.prop] = target }):Play()
			end
		end
	end
	for key in pairs(Moon.Themes.Moon) do
		self.Theme[key] = new[key]
	end
	if type(theme) == "string" then
		self.ThemeName = ALIAS[theme] or theme
	else
		self.ThemeName = "Custom"
	end
	for _, picker in ipairs(self._accentPickers) do
		picker:Set(self.Theme.Accent, true)
	end
end

-- Changes only the accent color (used by the accent color picker)
function Window:SetAccent(color)
	local new = {}
	for key in pairs(Moon.Themes.Moon) do
		new[key] = self.Theme[key]
	end
	for key, value in pairs(AccentKeys(color)) do
		new[key] = value
	end
	local light = Luma(self.Theme.Background) > 0.5
	new.Tint = self.Theme.Background:Lerp(color, light and 0.1 or 0.2)
	self:SetTheme(new)
end

function Window:Destroy()
	for _, connection in ipairs(self._conns) do
		connection:Disconnect()
	end
	table.clear(self._conns)
	local index = table.find(Moon.Windows, self)
	if index then
		table.remove(Moon.Windows, index)
	end
	if self._blur then
		self._blur:Destroy()
	end
	self.Gui:Destroy()
	if self.Overlay then
		self.Overlay:Destroy()
	end
end

return Window
