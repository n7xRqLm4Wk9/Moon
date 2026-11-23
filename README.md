# Moon

A Windows 11 style UI library for Roblox (Luau). Dark modern look with a moon logo, a translucent glass window, smooth animations, a color picker, switchable themes, a player card, a draggable open button and a built-in FPS + ping watermark.

## Load

One request (recommended, built from `src/` by `build.py`):

```lua
local Moon = loadstring(game:HttpGet("https://raw.githubusercontent.com/n7xRqLm4Wk9/Moon/main/dist/Moon.bundle.lua"))()
```

Modular (downloads every file in `src/` at the same time):

```lua
local Moon = loadstring(game:HttpGet("https://raw.githubusercontent.com/n7xRqLm4Wk9/Moon/main/Moon.lua"))()
```

If your repo has a different name, change `MOON_BASE_URL` (or the `BASE` line in `Moon.lua`):

```lua
getgenv().MOON_BASE_URL = "https://raw.githubusercontent.com/YOU/YOUR_REPO/main/"
```

## Project structure

```
Moon/
├── Moon.lua                     modular loader (downloads src/ in parallel, runs it through a tiny module system)
├── build.py                     updates the module list in Moon.lua and builds dist/Moon.bundle.lua
├── dist/
│   └── Moon.bundle.lua          every module in one file (generated)
├── examples/
│   ├── Example.lua              a window using every element
│   └── KeyLoader.luau           the Moon Hub key screen built on Moon
└── src/
    ├── Main.lua                 entry: loads everything in order, returns Moon
    ├── Core/
    │   ├── Moon.lua             the shared library table (Flags, Windows, Themes)
    │   ├── Services.lua         Roblox services
    │   ├── Fonts.lua            fonts with fallbacks
    │   ├── Util.lua             Create, Tween, Corner, input helpers, ...
    │   └── Config.lua           save, load and auto-load configs
    ├── Theme/
    │   ├── Colors.lua           color math
    │   ├── Registry.lua         builds full themes from a few colors, registers and resolves them
    │   ├── Presets.lua          Moon, MoonLight, Claude, ClaudeLight + the optional extra themes
    │   └── Binding.lua          theme bindings (this is what makes theme switching fade)
    ├── UI/
    │   ├── Logo.lua             the moon logo
    │   ├── Card.lua             settings card used by every element
    │   └── Elements/            Button, Toggle, Slider, Dropdown, Textbox, Keybind, ColorPicker, ...
    │                            Track.lua (remembers flagged elements) and Config.lua (config panel)
    └── Window/
        ├── Window.lua           visibility, blur, theme switching, cleanup
        ├── Create.lua           Moon:CreateWindow
        ├── Tab.lua              tabs
        ├── Notify.lua           toasts
        ├── Watermark.lua        FPS + ping card
        ├── PlayerCard.lua       avatar, name, session playtime
        └── OpenButton.lua       draggable open button
```

Optional extras live in `src/Extras/` (`ESP/`, `TargetCard.lua`, `Visuals/`) and only run when you `Moon:Use(...)` them.

Every file starts with `local import = ...` and returns what it exports. `import("Core/Util")` loads `src/Core/Util.lua` once and caches it.

### Developing

Copy the repo into your executor workspace (for example `workspace/Moon/`) and load straight from disk, so you can edit and re-run without pushing:

```lua
getgenv().MOON_DEV_FOLDER = "Moon/"
local Moon = loadstring(readfile("Moon/Moon.lua"))()
```

After changing anything in `src/`, run `python3 build.py` and commit `dist/` too.

Or let GitHub do it: `.github/workflows/build.yml` rebuilds `dist/Moon.bundle.lua` on every push that touches `src/` or `build.py`, and commits the result as `moon-build[bot]`. Because of that, run `git pull --rebase` before your next push.

## Create a window

```lua
local Window = Moon:CreateWindow({
    Title = "My Project",
    Subtitle = "v1.0",                    -- optional
    Theme = "Moon",                       -- "Moon" (default), "MoonLight", "Claude", "ClaudeLight", any registered theme, or a theme table
    ToggleKey = Enum.KeyCode.RightShift,  -- show/hide key
    Logo = nil,                           -- optional "rbxassetid://123" to replace the moon
    Blur = true,                          -- true, false, or a number 0-30 (background blur strength)
    PlayerCard = true,                    -- bottom-left card with avatar, name and playtime
    Watermark = true,                     -- FPS + ping card (false starts it hidden)
    Scale = 1,                            -- UI scale, 0.6 to 1.6 (see Size and scale)
})
```

Other options: `Size` (UDim2), `NavWidth` (number), `Parent` (Instance).

## Size and scale

- **Resize:** drag the dotted grip in the bottom-right corner of the window (minimum 380x270). It does not appear while the window is maximized.
- **UI scale:** makes the whole window and its text bigger or smaller, which helps on small phones. It never grows past what fits on screen.

```lua
Window:SetScale(1.2)         -- 0.6 to 1.6
print(Window:GetScale())

Look:AddScaleSlider()        -- ready-made slider (the window resizes a moment after you let go)
```

## Tabs

Each tab appears in the left navigation pane. The first tab is selected automatically. Switching tabs fades and slides the page in.

```lua
local General = Window:AddTab("General")
local Visuals = Window:AddTab("Visuals")

General:Select() -- switch to a tab from code
```

## Sections

Sections are optional group headers inside a tab. You can add elements to a tab or to a section.

```lua
local Player = General:AddSection("Player")
```

## Elements

Every element accepts `Name` and an optional `Description`.

```lua
-- Button
Player:AddButton({
    Name = "Reset",
    Description = "Resets your character",
    ButtonText = "Run",
    Callback = function() print("clicked") end,
})

-- Toggle
local toggle = Player:AddToggle({
    Name = "Enabled",
    Default = false,
    Flag = "Enabled",
    Callback = function(state) print(state) end,
})

-- Slider
Player:AddSlider({
    Name = "Speed",
    Min = 0, Max = 100, Default = 16,
    Increment = 1,
    Suffix = "",
    Flag = "Speed",
    Callback = function(value) print(value) end,
})

-- Dropdown
local mode = Player:AddDropdown({
    Name = "Mode",
    Options = { "Legit", "Balanced", "Rage" },
    Default = "Balanced",
    Flag = "Mode",
    Callback = function(value) print(value) end,
})

-- Textbox
Player:AddTextbox({
    Name = "Name",
    Placeholder = "Type here",
    Default = "",
    ClearOnFocus = false,
    Callback = function(text, enterPressed) print(text) end,
})

-- Keybind
Player:AddKeybind({
    Name = "Action",
    Default = Enum.KeyCode.E,
    Callback = function() print("key pressed") end,
    OnChanged = function(newKey) print(newKey.Name) end,
})

-- Color picker
local esp = Player:AddColorPicker({
    Name = "ESP color",
    Default = Color3.fromRGB(184, 196, 240),
    Flag = "EspColor",
    Callback = function(color) print(color) end,
})

-- Label
local label = Player:AddLabel("Some info text")
```

### Changing elements from code

```lua
toggle:Set(true)                -- updates and fires the callback
toggle:Set(true, true)          -- updates silently
print(toggle:Get())

mode:Refresh({ "A", "B", "C" }) -- replace dropdown options
label:Set("New text")
esp:Set(Color3.fromRGB(120, 200, 140))
```

Toggle, Slider, Dropdown, Textbox, Keybind and ColorPicker all have `:Set()` and `:Get()`. Buttons have `:SetText()`.

### Flags

Elements with a `Flag` save their value here automatically:

```lua
print(Moon.Flags.Enabled)
print(Moon.Flags.EspColor)
```

### Color picker

Click the row (or the swatch) to open it: a saturation/brightness square, a hue bar, a hex box (`#RRGGBB`) and preset colors. Pass your own with `Presets = { Color3.new(1, 0, 0), ... }`.

### Dropdowns

The option list opens as a floating popup. On PC it sits under the box (or above it when there is no room) and closes when you scroll. On phones it opens as a centered sheet with a dim backdrop and large rows, so it never fights the page for scrolling.

## Themes

Built in: `Moon` (default, dark), `MoonLight`, `Claude`, `ClaudeLight`.

### Optional extra themes

Extra themes are only loaded when you ask for them:

```lua
Moon:AddThemes()                           -- every extra theme
Moon:AddThemes({ "Midnight", "Eclipse" })  -- or only some
```

Extras: `Midnight`, `Eclipse`, `Mocha`, `Rose`, `Forest`, `Ocean`, `Amethyst`, `Graphite`, `Sky` (light). Call `AddThemes` before `CreateWindow` if you want to start with one of them.

### Your own theme

Only `Background` and `Accent` are required. Everything else is generated.

```lua
Moon:AddTheme("Sunset", {
    Background = Color3.fromRGB(34, 22, 24),
    Accent = Color3.fromRGB(255, 130, 90),
    -- optional: Light = true, Text = ..., SubText = ..., Tint = ..., BackgroundTransparency = 0.13
})
```

### Switching themes (smooth transition)

Every color in the UI fades to the new theme over about 0.4 seconds.

```lua
Window:SetTheme("Midnight")
Window:SetTheme("Midnight", true)               -- instant
Window:SetAccent(Color3.fromRGB(120, 200, 140)) -- only the accent color
print(Moon:GetThemeNames())
```

### Appearance helpers

Drop these into any tab to let users change the look:

```lua
local Look = Settings:AddSection("Appearance")
Look:AddThemeDropdown()      -- every registered theme, fades smoothly
Look:AddAccentPicker()       -- color picker that recolors the whole UI live
Look:AddBlurSlider()         -- background blur strength
Look:AddScaleSlider()        -- UI scale
Look:AddWatermarkToggle()    -- show/hide the FPS + ping card
```

## Blur and glass look

The window is translucent with a soft colored sheen. Roblox cannot blur UI itself, so the blur is applied to the game world behind the window (it fades in and out with the window).

```lua
Window:SetBlur(16)     -- strength 0-30
Window:SetBlur(false)  -- off
```

## Player card

A card at the bottom of the left pane shows your avatar, display name and the time you have spent in the current game session. On by default; turn it off with `PlayerCard = false`.

## Watermark

A small card with the moon logo, your title, FPS and ping. FPS and ping turn green, amber or red depending on how good they are. It sits in the top right below the Roblox top bar and inside device safe areas, so it does not cover Roblox buttons on mobile.

```lua
Window.Watermark:SetVisible(false)
Window.Watermark:Toggle()
Window.Watermark:SetTitle("My Project")
```

## Notifications

```lua
Window:Notify({ Title = "Loaded", Content = "Moon is ready", Duration = 4 })
```

Toasts appear bottom-right on PC and top-right on touch devices (so they do not cover the jump button). Tap one to dismiss it early.

## Window controls

```lua
Window:SetVisible(false) -- hide (the open button appears)
Window:Toggle()
Window:Destroy()
Moon:Unload()            -- removes every window
```

The title bar has minimize, maximize and close buttons. Minimize hides the window and shows a small open button with the moon logo. Hold and drag that button anywhere on the screen, and tap it to bring the window back. The toggle key does the same on PC.

## Config saving

Every element that has a `Flag` is saved: toggles, sliders, dropdowns, textboxes, keybinds and color pickers (including the theme and accent from the appearance helpers). Configs are JSON files in your executor workspace: `Moon/configs/<name>.json`.

### Ready-made panel

```lua
local Configs = Settings:AddSection("Configs")
Configs:AddConfigManager()
```

It adds a config dropdown, a name box, Save / Load / Delete buttons, and **Auto load** and **Auto save** toggles. Loading a config sets every saved element and fires its callback, so your features switch on or off the same way they would if you clicked them.

### From code

```lua
Moon:SetFolder("MoonHub")          -- optional: configs go to MoonHub/configs/ (default "Moon")

Moon:SaveConfig("legit")           -- returns true or false, error
Moon:LoadConfig("legit")           -- returns true, appliedCount or false, error
Moon:DeleteConfig("legit")
print(Moon:ListConfigs())          -- { "legit", "rage" }

Moon:SetAutoLoad("legit")          -- remembered between runs (nil to turn it off)
Moon:SetAutoSave(true, "legit")    -- saves 1.5s after any change

Moon:LoadAutoConfig()              -- put this at the END of your script
```

`LoadAutoConfig` has to run after your UI is built, because it can only set elements that already exist. Elements without a `Flag` are never saved, so give every setting you want to keep one:

```lua
Player:AddToggle({ Name = "Enabled", Flag = "Enabled" })
```

Saving needs an executor with `writefile`, `readfile` and `isfile`. Without them `SaveConfig` returns `false, "this executor has no file access"` and nothing breaks.

## Extras (optional)

Extras are not loaded unless you ask for them:

```lua
Moon:Use("ESP")
Moon:Use({ "ESP", "TargetCard", "Visuals" })
```

Moon never looks for players or reads their health for you. You decide what to show and set the values; Moon draws it and animates the changes.

### ESP

Overlays for any Model or part: a box (corners or full), name, health bar, distance, extra info lines and an optional glow outline.

```lua
local esp = Moon.ESP:Add(character, {
    Name = "Enemy",
    Health = 100,
    MaxHealth = 100,
    Lines = { "Team: Red", "AK-47" },
    Color = Color3.fromRGB(255, 120, 120),   -- optional, per object
})

esp:SetHealth(60)             -- bar animates, a white trail catches up, name flashes red
esp:SetName("Boss")
esp:SetLines({ "Team: Blue" })
esp:SetColor(Color3.new(1, 0, 0))
esp:SetDistance(123)          -- optional: show your own number instead of the real distance
esp:SetVisible(false)
esp:BindHumanoid(humanoid)    -- optional: keep health in sync automatically
esp:Set({ Name = "Bot", Health = 80, Box = false })   -- several things at once
esp:Destroy()
```

Global controls:

```lua
Moon.ESP:SetEnabled(false)                 -- master switch
Moon.ESP:Configure({ Box = true, BoxStyle = "Full", Name = true, Health = true, HealthText = true,
                     Distance = true, Lines = true, Highlight = false, MaxDistance = 800,
                     Unit = "m", Color = Color3.fromRGB(184, 196, 240) })
Moon.ESP:Remove(character)
Moon.ESP:Clear()
```

Ready-made controls for your menu (toggles, box style, max distance, color):

```lua
Visuals:AddSection("ESP"):AddESPControls()
```

No other players to test with? Spawn a test dummy in front of your camera (its health drops every couple of seconds):

```lua
Moon.ESP:Demo()
Moon.ESP:StopDemo()
```

If an overlay cannot be built, Moon prints a `[Moon.ESP]` warning in the console with the reason.

Low health makes the bar pulse red. Overlays fade in and out, and they are removed automatically when the target is destroyed.

### Target card

A glass card with a player's face, name, health bar and info chips. It slides in, the health number counts, damage shakes the card and flashes the border, and low health pulses the ring.

```lua
local card = Window:CreateTargetCard({ Position = "TopCenter" })   -- TopCenter, TopLeft, TopRight, BottomCenter

card:SetTarget({
    Name = "Enemy",
    Sub = "@enemy123",
    UserId = 1234567,            -- loads that player's face (or use Image = "rbxassetid://...")
    Health = 100,
    MaxHealth = 100,
    Info = { "Team: Red", "AK-47", "42m" },
}):Show()

card:SetHealth(60)               -- animated
card:SetPlayer(player)           -- fills name, @username and face from a Player
card:SetInfo({ "Reloading" })
card:BindHumanoid(humanoid)      -- optional: keep health in sync automatically
card:Hide()
card:Destroy()
```

The card sits in the safe area, so it never covers the Roblox top bar.

### Visuals

Lighting and post-processing presets that blend in smoothly. `Reset` puts the game back exactly as it was.

```lua
Moon.Visuals:Apply("Cinematic")      -- Cinematic, Vivid, Soft Glow, Moonlight, Warm Sunset, Noir
Moon.Visuals:Set("Bloom", { Intensity = 1.2 })
Moon.Visuals:Set("Lighting", { ClockTime = 20 })
Moon.Visuals:Set("Camera", { FieldOfView = 90 })
Moon.Visuals:Reset()

Moon.Visuals:AddPreset("Mine", {
    Bloom = { Intensity = 0.7, Size = 30, Threshold = 1 },
    ColorCorrection = { Contrast = 0.1, Saturation = 0.2 },
    Lighting = { ClockTime = 18 },
})
```

Effects: `Bloom`, `ColorCorrection`, `SunRays`, `DepthOfField`, `Atmosphere`, plus `Lighting` and `Camera` properties. Ready-made controls (preset dropdown, bloom, contrast, saturation, brightness, sun rays, depth of field, time of day, field of view, tint, reset):

```lua
Settings:AddSection("Visuals"):AddVisualsControls()
```

All of these controls have Flags, so config saving remembers them.

## Adding your own element

Create `src/UI/Elements/MyThing.lua`:

```lua
local import = ...

local Elements = import("UI/Elements/Base")
local Card = import("UI/Card")

function Elements:AddMyThing(opts)
    local card = Card(self, opts)
    -- build your control inside `card`
    return { Instance = card }
end

return Elements
```

Add `import("UI/Elements/MyThing")` to `src/UI/Elements/Index.lua`, then run `python3 build.py`. It is now available on every tab and section as `:AddMyThing({...})`.
