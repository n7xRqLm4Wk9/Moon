-- Built-in themes plus the optional extra themes (loaded with Moon:AddThemes()).
local import = ...

local Moon = import("Core/Moon")
local Colors = import("Theme/Colors")
local RGB = Colors.RGB
local Registry = import("Theme/Registry")
local Register = Registry.Register

-- Built in --------------------------------------------------------------

-- Moon: dark, cool and modern. Near-black blue glass with a pale moonlight accent.
Register("Moon", {
	Background = RGB(10, 11, 16),
	Tint = RGB(36, 42, 72),
	Accent = RGB(184, 196, 240),
	Text = RGB(236, 239, 247),
	SubText = RGB(138, 145, 168),
})

-- MoonLight: the daytime version.
Register("MoonLight", {
	Light = true,
	Background = RGB(232, 235, 244),
	Tint = RGB(250, 251, 255),
	Accent = RGB(78, 92, 186),
	Text = RGB(18, 20, 30),
	SubText = RGB(98, 104, 124),
})

Register("Claude", {
	Background = RGB(31, 30, 28),
	Tint = RGB(70, 50, 41),
	Accent = RGB(217, 119, 87),
	Text = RGB(250, 249, 245),
	SubText = RGB(176, 174, 165),
})

Register("ClaudeLight", {
	Light = true,
	Background = RGB(240, 238, 230),
	Tint = RGB(255, 252, 246),
	Accent = RGB(201, 100, 66),
	Text = RGB(20, 20, 19),
	SubText = RGB(107, 106, 100),
})

-- Optional: only registered when you call Moon:AddThemes() ---------------

local EXTRA = {
	{ "Midnight", { Background = RGB(13, 16, 30), Accent = RGB(124, 138, 255) } },
	{ "Eclipse", { Background = RGB(15, 10, 16), Accent = RGB(255, 170, 90) } },
	{ "Mocha", { Background = RGB(34, 26, 22), Accent = RGB(212, 162, 127), Text = RGB(246, 236, 222), SubText = RGB(190, 172, 154) } },
	{ "Rose", { Background = RGB(31, 21, 27), Accent = RGB(232, 121, 160) } },
	{ "Forest", { Background = RGB(17, 27, 23), Accent = RGB(112, 190, 140) } },
	{ "Ocean", { Background = RGB(11, 25, 37), Accent = RGB(0, 190, 200) } },
	{ "Amethyst", { Background = RGB(25, 19, 37), Accent = RGB(167, 125, 240) } },
	{ "Graphite", { Background = RGB(24, 24, 27), Accent = RGB(120, 170, 255) } },
	{ "Sky", { Light = true, Background = RGB(232, 240, 250), Accent = RGB(40, 120, 220), Text = RGB(16, 24, 36) } },
}
for _, entry in ipairs(EXTRA) do
	Moon.ExtraThemes[entry[1]] = entry[2]
	table.insert(Moon._extraOrder, entry[1])
end

return true
