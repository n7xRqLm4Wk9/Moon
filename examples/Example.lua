-- Moon example: a window with every element, the optional themes and the appearance helpers.

local Moon = loadstring(game:HttpGet("https://raw.githubusercontent.com/n7xRqLm4Wk9/Moon/main/dist/Moon.bundle.lua"))()

-- optional themes: load all of them, or pass a list like { "Midnight", "Eclipse" }
Moon:AddThemes()

-- optional extras: only loaded when you ask for them
Moon:Use({ "ESP", "TargetCard", "Visuals" })

local Window = Moon:CreateWindow({
	Title = "Moon",
	Subtitle = "example",
	Theme = "Moon",
	ToggleKey = Enum.KeyCode.RightShift,
	Blur = true,
})

local General = Window:AddTab("General")
local Visuals = Window:AddTab("Visuals")
local Extras = Window:AddTab("Extras")
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

-- ready-made ESP and visuals controls
Extras:AddSection("ESP"):AddESPControls()
Extras:AddSection("Visuals"):AddVisualsControls()

-- enemy card + ESP demo: YOU provide the data, Moon draws and animates it
local card = Window:CreateTargetCard({ Position = "TopCenter" })
local enemy = { Health = 100 }
local Demo = Extras:AddSection("Demo")
Demo:AddButton({
	Name = "Show enemy card",
	ButtonText = "Show",
	Callback = function()
		enemy.Health = 100
		card:SetTarget({
			Name = "Enemy",
			Sub = "@builderman",
			UserId = 156,
			Health = 100,
			MaxHealth = 100,
			Info = { "Team: Red", "AK-47", "42m" },
		}):Show()
	end,
})
Demo:AddButton({
	Name = "Take damage",
	ButtonText = "-25",
	Callback = function()
		enemy.Health = math.max(0, enemy.Health - 25)
		card:SetHealth(enemy.Health)
	end,
})
Demo:AddButton({
	Name = "Hide card",
	ButtonText = "Hide",
	Callback = function()
		card:Hide()
	end,
})
Demo:AddToggle({
	Name = "ESP demo dummy",
	Description = "Spawns a test dummy in front of you (turn the ESP switch on above)",
	Callback = function(on)
		if on then
			Moon.ESP:Demo()
		else
			Moon.ESP:StopDemo()
		end
	end,
})

local Look = Settings:AddSection("Appearance")
Look:AddThemeDropdown() -- every registered theme, fades smoothly
Look:AddAccentPicker() -- recolors the whole UI live
Look:AddBlurSlider() -- background blur strength
Look:AddScaleSlider() -- bigger or smaller window
Look:AddWatermarkToggle() -- FPS + ping card

local Configs = Settings:AddSection("Configs")
Configs:AddConfigManager() -- save, load, delete, auto load, auto save

print(Moon.Flags.Enabled, Moon.Flags.Speed)

-- keep this LAST: applies the config you marked "Auto load" (after every element exists)
Moon:LoadAutoConfig()
