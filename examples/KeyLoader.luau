--!nonstrict

-- Moon Hub key loader (Luau) - built on the Moon UI library
-- nonstrict mode so executor globals (getgenv, setclipboard, isfile, ...) don't error

type KeyResult = {
	valid: boolean?,
	error: string?,
}

type JunkieLib = {
	service: string,
	identifier: string,
	provider: string,
	check_key: (key: string) -> KeyResult,
	get_key_link: () -> string?,
}

local genv = getgenv()

if genv.__MOON_HUB_LOADED then
	return
end
genv.__MOON_HUB_LOADED = true

setclipboard("https://discord.gg/DfaaB3cd8B")

genv.SCRIPT_KEY = "KEYLESS"

local Moon = loadstring(game:HttpGet("https://raw.githubusercontent.com/n7xRqLm4Wk9/Moon/main/dist/Moon.bundle.lua"))()
local Junkie: JunkieLib = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "service"
Junkie.identifier = "1103859"
Junkie.provider = "provider"

local HUB_URL: string = "https://api.jnkie.com/api/v1/luascripts/public/f7bae845c5ff96248a6fb26fbb55278c6283b8e71d6559b002f45fc48b07cee1/download"
local KEY_FILE: string = "moon_key.txt"
local MAX_ATTEMPTS: number = 5
local attempts: number = 0

local function saveKey(key: string)
	pcall(writefile, KEY_FILE, key)
end

local function loadSavedKey(): string?
	if not isfile(KEY_FILE) then
		return nil
	end
	local ok, content = pcall(readfile, KEY_FILE)
	if ok and content ~= "" then
		return content
	end
	return nil
end

local function deleteSavedKey()
	if isfile(KEY_FILE) then
		pcall(delfile, KEY_FILE)
	end
end

-- returns (isValid, errorMessage)
local function checkKey(key: string): (boolean, string?)
	local ok, result = pcall(Junkie.check_key, key)
	if ok and result then
		return result.valid and true or false, result.error
	end
	return false, nil
end

local savedKey = loadSavedKey()
if savedKey then
	local valid = checkKey(savedKey)
	if valid then
		genv.SCRIPT_KEY = savedKey
		loadstring(game:HttpGet(HUB_URL))()
		return
	else
		deleteSavedKey()
	end
end

local Window = Moon:CreateWindow({
	Title = "Moon Hub",
	Subtitle = "welcome to moon!",
	Theme = "Moon",
	Size = UDim2.fromOffset(520, 360),
	PlayerCard = false,
	Watermark = false,
	Blur = true,
})

local AccessTab = Window:AddTab("Access")
local userKey: string = ""
local isChecking: boolean = false

local GetKey = AccessTab:AddSection("Get a Key")
GetKey:AddButton({
	Name = "Copy Key Link",
	Description = "Open your browser and complete the steps to get a key",
	ButtonText = "Copy",
	Callback = function()
		task.spawn(function()
			local ok, link = pcall(Junkie.get_key_link)
			if ok and link then
				setclipboard(link)
			else
				setclipboard("https://jnkie.com/get-key/moonhub")
			end
			Window:Notify({
				Title = "Link Copied!",
				Content = "Open browser and complete steps to get your key.",
				Duration = 8,
			})
		end)
	end,
})

local EnterKey = AccessTab:AddSection("Enter Your Key")
EnterKey:AddTextbox({
	Name = "Key",
	Placeholder = "Paste key here...",
	ClearOnFocus = false,
	Callback = function(text: string)
		userKey = text
	end,
})

EnterKey:AddButton({
	Name = "Continue",
	ButtonText = "Continue",
	Callback = function()
		if isChecking then
			return
		end

		if userKey == "" then
			Window:Notify({ Title = "Error", Content = "Enter a key first", Duration = 3 })
			return
		end

		attempts += 1
		if attempts > MAX_ATTEMPTS then
			Window:Notify({ Title = "Locked", Content = "Too many attempts. Restart.", Duration = 5 })
			return
		end

		isChecking = true
		task.spawn(function()
			local valid, errorMessage = checkKey(userKey)

			if valid then
				saveKey(userKey)
				genv.SCRIPT_KEY = userKey
				Window:Notify({ Title = "Success", Content = "Loading hub...", Duration = 2 })
				task.wait(0.3)
				Window:Destroy()
				loadstring(game:HttpGet(HUB_URL))()
			else
				local message: string = errorMessage or "Invalid key"
				if message == "KEY_EXPIRED" then
					deleteSavedKey()
				end
				Window:Notify({ Title = "Error", Content = message, Duration = 5 })
				isChecking = false
			end
		end)
	end,
})
