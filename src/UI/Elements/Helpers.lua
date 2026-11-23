-- Ready-made appearance helpers: watermark toggle, theme dropdown, accent picker, blur slider.
local import = ...

local Moon = import("Core/Moon")
local Elements = import("UI/Elements/Base")
local Util = import("Core/Util")
local Safe = Util.Safe

-- Ready-made toggle that shows/hides the built-in FPS + ping watermark
function Elements:AddWatermarkToggle(opts)
	opts = opts or {}
	local window = self.Window
	local userCallback = opts.Callback
	local default
	if opts.Default ~= nil then
		default = opts.Default
	else
		default = window.Watermark:IsVisible()
	end
	local toggle = self:AddToggle({
		Name = opts.Name or "Watermark",
		Description = opts.Description or "Shows FPS and ping",
		Default = default,
		Flag = opts.Flag or "Watermark",
		Callback = function(state)
			window.Watermark:SetVisible(state)
			Safe(userCallback, state)
		end,
	})
	window.Watermark:SetVisible(default)
	return toggle
end

-- Ready-made dropdown that switches the theme with a smooth fade
function Elements:AddThemeDropdown(opts)
	opts = opts or {}
	local window = self.Window
	local userCallback = opts.Callback
	local default = window.ThemeName
	if not table.find(Moon._order, default) then
		default = nil
	end
	return self:AddDropdown({
		Name = opts.Name or "Theme",
		Description = opts.Description,
		Options = Moon:GetThemeNames(),
		Default = default,
		Flag = opts.Flag or "Theme",
		Callback = function(name)
			window:SetTheme(name)
			Safe(userCallback, name)
		end,
	})
end

-- Ready-made color picker that recolors the whole UI live
function Elements:AddAccentPicker(opts)
	opts = opts or {}
	local window = self.Window
	local userCallback = opts.Callback
	local picker = self:AddColorPicker({
		Name = opts.Name or "Accent color",
		Description = opts.Description,
		Default = window.Theme.Accent,
		Flag = opts.Flag or "Accent",
		Presets = opts.Presets,
		Callback = function(color)
			window:SetAccent(color)
			Safe(userCallback, color)
		end,
	})
	table.insert(window._accentPickers, picker)
	return picker
end

-- Ready-made slider for the background blur strength
-- Ready-made slider that scales the whole window (handy on small phones).
-- The window resizes a moment after you let go, so the slider does not move under your finger.
function Elements:AddScaleSlider(opts)
	opts = opts or {}
	local window = self.Window
	local userCallback = opts.Callback
	local token = 0
	return self:AddSlider({
		Name = opts.Name or "UI scale",
		Description = opts.Description or "Bigger or smaller window",
		Min = 60,
		Max = 160,
		Increment = 5,
		Suffix = "%",
		Default = math.floor(window:GetScale() * 100 + 0.5),
		Flag = opts.Flag or "UI.Scale",
		Callback = function(value)
			token = token + 1
			local mine = token
			task.delay(0.35, function()
				if token == mine then
					window:SetScale(value / 100)
				end
			end)
			Safe(userCallback, value)
		end,
	})
end

function Elements:AddBlurSlider(opts)
	opts = opts or {}
	local window = self.Window
	local userCallback = opts.Callback
	return self:AddSlider({
		Name = opts.Name or "Background blur",
		Description = opts.Description,
		Min = 0,
		Max = opts.Max or 30,
		Default = window._blurSize,
		Flag = opts.Flag or "Blur",
		Callback = function(value)
			window:SetBlur(value)
			Safe(userCallback, value)
		end,
	})
end

return Elements
