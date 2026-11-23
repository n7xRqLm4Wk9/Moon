-- Ready-made config panel: pick, save, load and delete configs, plus auto load / auto save.
local import = ...

local Moon = import("Core/Moon")
local Elements = import("UI/Elements/Base")

function Elements:AddConfigManager()
	local window = self.Window
	local selected = Moon:GetAutoLoad()
	local typedName = ""
	local autoLoad, autoSave

	local function notify(title, content)
		window:Notify({ Title = title, Content = content, Duration = 3 })
	end

	local list = self:AddDropdown({
		Name = "Config",
		Description = "Pick a saved config",
		Options = Moon:ListConfigs(),
		Default = selected,
		Callback = function(value)
			selected = value
		end,
	})

	local function refresh(keep)
		list:Refresh(Moon:ListConfigs(), true)
		list:Set(keep, true)
	end

	self:AddTextbox({
		Name = "New config",
		Placeholder = "name",
		Callback = function(text)
			typedName = text
		end,
	})

	self:AddButton({
		Name = "Save",
		Description = "Saves your current settings",
		ButtonText = "Save",
		Callback = function()
			local name = typedName ~= "" and typedName or selected
			if not name or name == "" then
				notify("Config", "Type a name or pick a config first")
				return
			end
			local ok, result = Moon:SaveConfig(name)
			if ok then
				selected = result
				refresh(result)
				notify("Config saved", result)
			else
				notify("Could not save", tostring(result))
			end
		end,
	})

	self:AddButton({
		Name = "Load",
		Description = "Applies the selected config",
		ButtonText = "Load",
		Callback = function()
			if not selected then
				notify("Config", "Pick a config first")
				return
			end
			local ok, result = Moon:LoadConfig(selected)
			if ok then
				notify("Config loaded", selected .. " (" .. tostring(result) .. " settings)")
			else
				notify("Could not load", tostring(result))
			end
		end,
	})

	self:AddButton({
		Name = "Delete",
		Description = "Deletes the selected config",
		ButtonText = "Delete",
		Callback = function()
			if not selected then
				notify("Config", "Pick a config first")
				return
			end
			local ok, err = Moon:DeleteConfig(selected)
			if ok then
				notify("Config deleted", selected)
				selected = nil
				refresh(nil)
				autoLoad:Set(Moon:GetAutoLoad() ~= nil, true)
			else
				notify("Could not delete", tostring(err))
			end
		end,
	})

	autoLoad = self:AddToggle({
		Name = "Auto load",
		Description = "Loads the selected config when the script starts",
		Default = Moon:GetAutoLoad() ~= nil,
		Callback = function(state)
			if state and not selected then
				notify("Config", "Pick a config first")
				autoLoad:Set(false, true)
				return
			end
			Moon:SetAutoLoad(state and selected or nil)
		end,
	})

	autoSave = self:AddToggle({
		Name = "Auto save",
		Description = "Saves the selected config whenever you change something",
		Default = false,
		Callback = function(state)
			local target = selected or Moon._currentConfig
			if state and not target then
				notify("Config", "Pick or save a config first")
				autoSave:Set(false, true)
				return
			end
			Moon:SetAutoSave(state, target)
		end,
	})

	return { Refresh = refresh }
end

return Elements
