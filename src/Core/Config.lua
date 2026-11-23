-- Config saving: stores every element that has a Flag (toggles, sliders, dropdowns, textboxes,
-- keybinds, color pickers) as JSON in the executor workspace, and applies it back later.
local import = ...

local Moon = import("Core/Moon")
local Services = import("Core/Services")
local HttpService = Services.HttpService

local VERSION = 1

-- these flags are applied first, so a saved accent color wins over the saved theme
local PRIORITY = { Theme = 1, Accent = 2 }

local function clean(name)
	name = tostring(name or "")
	name = string.gsub(name, "[^%w _%-]", "")
	return (string.match(name, "^%s*(.-)%s*$"))
end

local function folder()
	return Moon.ConfigFolder .. "/configs"
end

local function pathOf(name)
	return folder() .. "/" .. name .. ".json"
end

local function autoloadPath()
	return Moon.ConfigFolder .. "/autoload.txt"
end

local function ensureFolders()
	if not (makefolder and isfolder) then
		return
	end
	pcall(function()
		if not isfolder(Moon.ConfigFolder) then
			makefolder(Moon.ConfigFolder)
		end
		if not isfolder(folder()) then
			makefolder(folder())
		end
	end)
end

-- values -> json-safe tables ------------------------------------------------

local function encode(value)
	local kind = typeof(value)
	if kind == "boolean" or kind == "number" or kind == "string" then
		return value
	elseif kind == "Color3" then
		return { __t = "Color3", v = { value.R, value.G, value.B } }
	elseif kind == "EnumItem" then
		local enumName = string.gsub(tostring(value.EnumType), "^Enum%.", "")
		return { __t = "Enum", e = enumName, n = value.Name }
	elseif kind == "table" then
		local out = {}
		for k, v in pairs(value) do
			local encoded = encode(v)
			if encoded ~= nil then
				out[k] = encoded
			end
		end
		return out
	end
	return nil
end

local function decode(value)
	if type(value) ~= "table" then
		return value
	end
	if value.__t == "Color3" and type(value.v) == "table" then
		return Color3.new(value.v[1], value.v[2], value.v[3])
	elseif value.__t == "Enum" then
		local ok, item = pcall(function()
			return Enum[value.e][value.n]
		end)
		return ok and item or nil
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = decode(v)
	end
	return out
end

-- public api ----------------------------------------------------------------

-- where configs live: <folder>/configs/<name>.json (default folder: "Moon")
function Moon:SetFolder(name)
	local cleaned = clean(name)
	Moon.ConfigFolder = cleaned ~= "" and cleaned or "Moon"
	return Moon
end

function Moon:ConfigsSupported()
	return writefile ~= nil and readfile ~= nil and isfile ~= nil
end

-- returns ok, nameOrError
function Moon:SaveConfig(name)
	name = clean(name)
	if name == "" then
		return false, "enter a config name"
	end
	if not Moon:ConfigsSupported() then
		return false, "this executor has no file access"
	end
	ensureFolders()
	local flags = {}
	for flag, value in pairs(Moon.Flags) do
		local encoded = encode(value)
		if encoded ~= nil then
			flags[flag] = encoded
		end
	end
	local encodedOk, json = pcall(function()
		return HttpService:JSONEncode({ version = VERSION, flags = flags })
	end)
	if not encodedOk then
		return false, "could not encode the config"
	end
	local wrote, err = pcall(writefile, pathOf(name), json)
	if not wrote then
		return false, tostring(err)
	end
	Moon._currentConfig = name
	return true, name
end

-- applies a saved config to the elements on screen; returns ok, appliedCountOrError
function Moon:LoadConfig(name)
	name = clean(name)
	if name == "" then
		return false, "pick a config"
	end
	if not Moon:ConfigsSupported() or not isfile(pathOf(name)) then
		return false, "config not found"
	end
	local readOk, content = pcall(readfile, pathOf(name))
	if not readOk then
		return false, "could not read the file"
	end
	local decodedOk, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not decodedOk or type(data) ~= "table" or type(data.flags) ~= "table" then
		return false, "config file is corrupted"
	end

	local keys = {}
	for flag in pairs(data.flags) do
		table.insert(keys, flag)
	end
	table.sort(keys, function(a, b)
		local pa, pb = PRIORITY[a] or 99, PRIORITY[b] or 99
		if pa ~= pb then
			return pa < pb
		end
		return a < b
	end)

	local applied = 0
	Moon._loading = true
	local loopOk, loopErr = pcall(function()
		for _, flag in ipairs(keys) do
			local element = Moon._elements[flag]
			local value = decode(data.flags[flag])
			if element and value ~= nil then
				local ok, err = pcall(element.Set, element, value)
				if ok then
					applied = applied + 1
				else
					warn("[Moon] could not apply '" .. flag .. "': " .. tostring(err))
				end
			end
		end
	end)
	Moon._loading = false
	if not loopOk then
		return false, tostring(loopErr)
	end

	Moon._currentConfig = name
	return true, applied
end

function Moon:DeleteConfig(name)
	name = clean(name)
	if not (isfile and delfile) or not isfile(pathOf(name)) then
		return false, "config not found"
	end
	local ok, err = pcall(delfile, pathOf(name))
	if not ok then
		return false, tostring(err)
	end
	if Moon:GetAutoLoad() == name then
		Moon:SetAutoLoad(nil)
	end
	if Moon._currentConfig == name then
		Moon._currentConfig = nil
	end
	return true
end

function Moon:ListConfigs()
	local names = {}
	if not (listfiles and isfolder) or not isfolder(folder()) then
		return names
	end
	local ok, files = pcall(listfiles, folder())
	if ok and type(files) == "table" then
		for _, path in ipairs(files) do
			local name = string.match(tostring(path), "([^/\\]+)%.json$")
			if name then
				table.insert(names, name)
			end
		end
	end
	table.sort(names)
	return names
end

-- auto load: call Moon:LoadAutoConfig() at the END of your script, after the UI is built
function Moon:SetAutoLoad(name)
	if not Moon:ConfigsSupported() then
		return false
	end
	ensureFolders()
	local cleaned = name ~= nil and clean(name) or ""
	if cleaned == "" then
		if delfile and isfile(autoloadPath()) then
			pcall(delfile, autoloadPath())
		end
	else
		pcall(writefile, autoloadPath(), cleaned)
	end
	return true
end

function Moon:GetAutoLoad()
	if not (isfile and readfile) or not isfile(autoloadPath()) then
		return nil
	end
	local ok, content = pcall(readfile, autoloadPath())
	local name = ok and clean(content) or ""
	if name ~= "" and isfile(pathOf(name)) then
		return name
	end
	return nil
end

function Moon:LoadAutoConfig()
	local name = Moon:GetAutoLoad()
	if not name then
		return false, "no auto load config set"
	end
	return Moon:LoadConfig(name)
end

-- auto save: saves to the current config (the last one saved or loaded) 1.5s after a change
function Moon:SetAutoSave(enabled, name)
	Moon._autoSave = enabled and true or false
	if name and clean(name) ~= "" then
		Moon._currentConfig = clean(name)
	end
	return Moon
end

Moon._onFlag = function()
	if Moon._loading or not Moon._autoSave or not Moon._currentConfig then
		return
	end
	local token = (Moon._saveToken or 0) + 1
	Moon._saveToken = token
	task.delay(1.5, function()
		if Moon._saveToken == token and Moon._autoSave and Moon._currentConfig then
			Moon:SaveConfig(Moon._currentConfig)
		end
	end)
end

return Moon
