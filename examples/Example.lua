-- Moon example: a window with every element, the optional themes and the appearance helpers.

local Moon = loadstring(game:HttpGet("https://raw.githubusercontent.com/n7xRqLm4Wk9/Moon/main/dist/Moon.bundle.lua"))()

-- optional themes: load all of them, or pass a list like { "Midnight", "Eclipse" }
Moon:AddThemes()

local Window = Moon:CreateWindow({
	Title = "Moon",
	Subtitle = "example",
	Theme = "Moon",
	ToggleKey = Enum.KeyCode.RightShift,
	Blur = true,
})

local General = Window:AddTab("General")
local Visuals = Window:AddTab("Visuals")
local Settings = Window:AddTab("Settings")

local Player = General:AddSection("Player")
Player:AddToggle({
	Name = "Enabled",
	Description = "Turns the feature on",
	Flag = "Enabled",
	Callback = function(state)
		print("Enabled:", state)
	end,
})
Player:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 16, Flag = "Speed", Callback = print })
Player:AddDropdown({ Name = "Mode", Options = { "Legit", "Balanced", "Rage" }, Default = "Balanced", Callback = print })
Player:AddKeybind({
	Name = "Action",
	Default = Enum.KeyCode.E,
	Callback = function()
		print("action pressed")
	end,
})

local Overlay = Visuals:AddSection("Overlay")
Overlay:AddColorPicker({ Name = "ESP color", Default = Color3.fromRGB(184, 196, 240), Flag = "EspColor", Callback = print })
Overlay:AddTextbox({ Name = "Label", Placeholder = "Type here", Callback = print })
Overlay:AddButton({
	Name = "Test toast",
	Description = "Shows a notification",
	ButtonText = "Show",
	Callback = function()
		Window:Notify({ Title = "Moon", Content = "Everything works.", Duration = 4 })
	end,
})

local Look = Settings:AddSection("Appearance")
Look:AddThemeDropdown() -- every registered theme, fades smoothly
Look:AddAccentPicker() -- recolors the whole UI live
Look:AddBlurSlider() -- background blur strength
Look:AddWatermarkToggle() -- FPS + ping card

print(Moon.Flags.Enabled, Moon.Flags.Speed)
