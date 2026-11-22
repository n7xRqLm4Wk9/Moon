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
    │   └── Util.lua             Create, Tween, Corner, input helpers, ...
    ├── Theme/
    │   ├── Colors.lua           color math
    │   ├── Registry.lua         builds full themes from a few colors, registers and resolves them
    │   ├── Presets.lua          Moon, MoonLight, Claude, ClaudeLight + the optional extra themes
    │   └── Binding.lua          theme bindings (this is what makes theme switching fade)
    ├── UI/
    │   ├── Logo.lua             the moon logo
    │   ├── Card.lua             settings card used by every element
    │   └── Elements/            Button, Toggle, Slider, Dropdown, Textbox, Keybind, ColorPicker, ...
    └── Window/
        ├── Window.lua           visibility, blur, theme switching, cleanup
        ├── Create.lua           Moon:CreateWindow
        ├── Tab.lua              tabs
        ├── Notify.lua           toasts
        ├── Watermark.lua        FPS + ping card
        ├── PlayerCard.lua       avatar, name, session playtime
        └── OpenButton.lua       draggable open button
```

Every file starts with `local import = ...` and returns what it exports. `import("Core/Util")` loads `src/Core/Util.lua` once and caches it.

### Developing

Copy the repo into your executor workspace (for example `workspace/Moon/`) and load straight from disk, so you can edit and re-run without pushing:

```lua
getgenv().MOON_DEV_FOLDER = "Moon/"
local Moon = loadstring(readfile("Moon/Moon.lua"))()
```

After changing anything in `src/`, run `python3 build.py` and commit `dist/` too.

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
})
```

Other options: `Size` (UDim2), `NavWidth` (number), `Parent` (Instance).

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
