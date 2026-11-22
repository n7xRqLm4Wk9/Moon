-- The Moon logo: a crescent drawn from thin horizontal slices (no images, no emojis).
-- Pass an asset string (Logo = "rbxassetid://...") to use your own image instead.
local import = ...

local Util = import("Core/Util")
local Create = Util.Create
local Binding = import("Theme/Binding")
local Bind = Binding.Bind

-- the moon is a big disk with a second disk carved out of it (unit coordinates, 0..1)
local DISK = { x = 0.46, y = 0.5, r = 0.44 }
local CUT = { x = 0.64, y = 0.4, r = 0.37 }

local cache = {}

-- returns a list of { x, y, width, height } slices that make up the crescent
local function Crescent(n)
	if cache[n] then
		return cache[n]
	end
	local bars = {}
	for i = 0, n - 1 do
		local y = (i + 0.5) / n
		local dy = y - DISK.y
		if math.abs(dy) < DISK.r then
			local half = math.sqrt(DISK.r ^ 2 - dy ^ 2)
			local a0, a1 = DISK.x - half, DISK.x + half
			local cdy = y - CUT.y
			local pieces
			if math.abs(cdy) < CUT.r then
				local chalf = math.sqrt(CUT.r ^ 2 - cdy ^ 2)
				local c0, c1 = CUT.x - chalf, CUT.x + chalf
				pieces = { { a0, math.min(a1, c0) }, { math.max(a0, c1), a1 } }
			else
				pieces = { { a0, a1 } }
			end
			for _, piece in ipairs(pieces) do
				if piece[2] - piece[1] > 0.004 then
					table.insert(bars, { piece[1], i / n, piece[2] - piece[1], 1 / n })
				end
			end
		end
	end
	cache[n] = bars
	return bars
end

local function CreateLogo(window, parent, size, asset, props)
	local holder = Create("Frame", {
		Name = "Logo",
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		holder[k] = v
	end
	if asset then
		Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = asset,
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		})
		return holder
	end

	for _, bar in ipairs(Crescent(math.clamp(math.floor(size), 12, 40))) do
		local slice = Create("Frame", {
			Position = UDim2.fromScale(bar[1], bar[2]),
			Size = UDim2.fromScale(bar[3], bar[4] + 0.012),
			BorderSizePixel = 0,
			Parent = holder,
		})
		Bind(window, slice, "BackgroundColor3", "Accent")
	end

	-- one small star in the bite of the moon (only when there is room for it)
	if size >= 20 then
		local star = Create("Frame", {
			Position = UDim2.fromScale(0.58, 0.24),
			Size = UDim2.fromScale(0.11, 0.11),
			BorderSizePixel = 0,
			Parent = holder,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		Bind(window, star, "BackgroundColor3", "Accent")
	end
	return holder
end

return CreateLogo
