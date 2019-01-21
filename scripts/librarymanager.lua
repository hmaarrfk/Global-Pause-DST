--Copyright (C) 2018 Zarklord
--Everyone is permitted to copy and distribute verbatim copies
--of this source file, but changing it is not allowed.

--If you have a out of date version just use this link to download the latest version.
--Download Link: https://drive.google.com/uc?export=download&id=1b8kluu2-maySFUJ-T4M96y1t8uDPZBfN

--[[Unnofical Terms Of Use:
	Don't be a jerk, seriously dont.
	Don't Modifiy this code, if you do and I find out I will take your mod down without warning(Even if its a bug fix).
	Rather if you find a bug or have a feature request contact me on discord at Zarklord#1337 and I will see what I can do.
	Make sure to list on your mod page all the mods that you will be using for this in the required mod list.
	Don't abuse this, we dont want klei taking away our only method to use library based mods.
]]
package.loaded["librarymanager"] = nil
package.loaded["tools/librarymanager"] = nil

if rawget(_G, "TheFrontEnd") then 

local VERSION = 1.31

if rawget(_G, "LibraryManager") == nil or (rawget(_G, "LibraryManager") ~= nil and rawget(_G, "LibraryManager").VERSION < VERSION) then

--uninstall old Library Manager
if rawget(_G, "LibraryManager") then rawget(_G, "LibraryManager").UninstallLibraryManager() end

local ModsTab = require("widgets/redux/modstab")
local ServerCreationScreen = require("screens/redux/servercreationscreen")
local PopupDialogScreen = require("screens/redux/popupdialog")
local TextListPopup = require("screens/redux/textlistpopup")

local function __index_posnumber(t, k)
    local p = rawget(t, "_")[k]
	if type(p) ~= "number" or p < 0 then 
		return 0
	end
	return p
end

local function __newindex_posnumber(t, k, v)
	rawget(t, "_")[k] = v
end

local function SetPostiveNumberTable(tbl)
	tbl._ = {}
	return setmetatable(tbl, {__index = __index_posnumber, __newindex = __newindex_posnumber})
end

local old_FrontendUnloadMod = ModManager.FrontendUnloadMod
local function new_FrontendUnloadMod(self, modname)
	old_FrontendUnloadMod(self, modname)
	if modname == nil then
		LibraryManager.server_dependency_list = SetPostiveNumberTable({})
 		LibraryManager.dependency_list = {}
 		LibraryManager.notify_list = {}
	else
		for i, v in ipairs(LibraryManager.dependency_list[modname] or {}) do
			LibraryManager.server_dependency_list[v] = LibraryManager.server_dependency_list[v] - 1
		end
		LibraryManager.dependency_list[modname] = nil
 		LibraryManager.notify_list[modname] = nil
	end
end

local old_UpdateForWorkshop = ModsTab.UpdateForWorkshop
local function new_UpdateForWorkshop(self, force_refresh)
	old_UpdateForWorkshop(self, force_refresh)
	for k, v in pairs(self.optionwidgets_server) do
		if not v.is_downloading and LibraryManager.server_dependency_list[v.mod.modname] > 0 and not KnownModIndex:IsModEnabled(v.mod.modname)  then
			local old_ShowModDetails = self.ShowModDetails
			self.ShowModDetails = function() end
			local oldModType = self.currentmodtype
			self.currentmodtype = "server"
			self:EnableCurrent(v.index)
			self.currentmodtype = oldModType
			self.ShowModDetails = old_ShowModDetails
		end
		if not v.is_downloading and (LibraryManager.disable_list[v.mod.modname] or false) and KnownModIndex:IsModEnabled(v.mod.modname)  then
			local old_ShowModDetails = self.ShowModDetails
			self.ShowModDetails = function() end
			local oldModType = self.currentmodtype
			self.currentmodtype = "server"
			self:EnableCurrent(v.index)
			self.currentmodtype = oldModType
			self.ShowModDetails = old_ShowModDetails
			LibraryManager.disable_list[v.mod.modname] = nil
		end
	end
end


local old_OnBecomeActive = ServerCreationScreen.OnBecomeActive
local function new_OnBecomeActive(self)
	old_OnBecomeActive(self)
	self.inst:DoTaskInTime(1, function()
		for k, v in pairs(LibraryManager.notify_list) do
			v()
		end
		LibraryManager.notify_list = {}
	end)
end

--copied from screens/redux/servercreationscreen.lua lines 479-503
local function BuildOptionalModLink(mod_name)
    if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then
        local link_fn, is_generic_url = ModManager:GetLinkForMod(mod_name)
        if is_generic_url then
            return nil
        else
            return link_fn
        end
    else
        return nil
    end
end
local function BuildModList(mod_ids)
    local mods = {}
    for i,v in ipairs(mod_ids) do
        table.insert(mods, {
                text = KnownModIndex:GetModFancyName(v) or v,
                -- Adding onclick with the idea that if you have a ton of
                -- mods, you'd want to be able to jump to information about
                -- the problem ones.
                onclick = BuildOptionalModLink(v),
            })
    end
    return mods
end
--okay this has to be done because TextListPopup adds a button that im not to happy about
--SUPER HACKS
local old_insert = table.insert
local function new_insert(t, v)
	if t.block_new_entries and t.block_new_entries == true then 
		return
	else
	    old_insert(t, v)
	end
end

local old_EnableCurrent = ModsTab.EnableCurrent
local function new_EnableCurrent(localModsTab, idx)
    local modname = nil
    if localModsTab.currentmodtype == "server" then
        modname = localModsTab.modnames_server[idx].modname
    end
    if LibraryManager.server_dependency_list[modname] > 0 and KnownModIndex:IsModEnabled(modname) then
	    local modDependentList = {}
	    for k, v in pairs(LibraryManager.dependency_list) do
	    	for i1, v1 in ipairs(v) do
	    		if v1 == modname then table.insert(modDependentList, k) end
	    	end
	    end
		table.insert = new_insert
		--disable adding new entries to the table, so that the textlistpopup cant be stupid and add a extra button
        TheFrontEnd:PushScreen(TextListPopup(BuildModList(modDependentList), 
        	STRINGS.UI.MODSSCREEN.MOD_DEPENDENTS_TITLE,
        	string.format(STRINGS.UI.MODSSCREEN.MOD_HAS_DEPENDENTS, KnownModIndex:GetModFancyName(modname)),
            {{text=STRINGS.UI.MODSSCREEN.DISABLE_ALL, 
            cb = function()
            	LibraryManager.server_dependency_list[modname] = 0
            	for i, v in pairs(modDependentList) do
						LibraryManager.disable_list[v] = true
            	end
				old_EnableCurrent(localModsTab, idx)
            	TheFrontEnd:PopScreen()
            end,
            controller_control=CONTROL_MENU_MISC_1,},
            {text=STRINGS.UI.MODSSCREEN.CANCEL,
            cb = function()
            	TheFrontEnd:PopScreen()
            end,
            controller_control = CONTROL_CANCEL,},
            block_new_entries = true}))
		table.insert = old_insert
	else
		old_EnableCurrent(localModsTab, idx)
	end
end

local old_Create = ServerCreationScreen.Create
local function new_Create(self, warnedOffline, warnedDisabledMods, warnedOutOfDateMods)
	for k, v in pairs(LibraryManager.server_dependency_list._) do
		if v > 0 and not KnownModIndex:IsModEnabled(k) then
			TheFrontEnd:PushScreen(PopupDialogScreen(
				STRINGS.UI.MODSSCREEN.REQUIRED_MODS_DOWNLOADING_TITLE, 
				STRINGS.UI.MODSSCREEN.REQUIRED_MODS_DOWNLOADING, 
                {{text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
                    TheFrontEnd:PopScreen() 
                end}}))
			return
		end
	end
	old_Create(self, warnedOffline, warnedDisabledMods, warnedOutOfDateMods)
end


local function AutoSubscribeAndEnableWorkshopMod(workshopMod, subscribe)
	if subscribe and not KnownModIndex:DoesModExistAnyVersion(workshopMod) then
		TheSim:SubscribeToMod(workshopMod)
	end
	LibraryManager.server_dependency_list[workshopMod] = LibraryManager.server_dependency_list[workshopMod] + 1
end

local function DoModsExist(modTable)
	for i, v in ipairs(modTable) do
		if not KnownModIndex:DoesModExistAnyVersion(v) then
			return false
		end
	end
	return true
end

--this is the main exposed function for mods to use
local function AutoSubscribeAndEnableWorkshopMods(modsList)
	local modenv = getfenv(2)
	--YOU AREN'T ALLOWED TO CALL THIS MORE THAN ONCE SON!
	if LibraryManager.dependency_list[modenv.modname] ~= nil then
		return
	end
	if #modsList > 10 then
		print("WARNING: trying to auto subscribe to more than 10 mods is not allowed.")
		print("if you have a reason to subscribe to more contact me and I'll see what I can do. -Zarklord")
		return
	end

	local TextListPopupDude = nil
	--copied from screens/redux/servercreationscreen.lua lines 479-503
	local function BuildOptionalModLink(mod_name)
	    if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then
	        local link_fn, is_generic_url = ModManager:GetLinkForMod(mod_name)
	        if is_generic_url then
	            return nil
	        else
	            return link_fn
	        end
	    else
	        return nil
	    end
	end

	local function QueryName(modname, modtable, modnumber)
		if IsWorkshopMod(modname) then
			TheSim:QueryServer(
				"http://steamcommunity.com/sharedfiles/filedetails/?id="..GetWorkshopIdNumber(modname),
				function(result, isSuccessful, resultCode)
					if isSuccessful and string.len(result) > 1 and resultCode == 200 then
						modtable.text = string.match(result, "<title>Steam Workshop :: (.-)</title>")
						if TextListPopupDude ~= nil then
							TextListPopupDude.scroll_list:RefreshView()
						end
					else
						print("Workshop Name Query Failed!")
					end
				end,
				"GET"
			)
		end
	end

	local function BuildModListQueryNames(mod_ids)
	    local mods = {}
	    for i,v in ipairs(mod_ids) do
	        table.insert(mods, {
	                text = KnownModIndex:GetModFancyName(v) or v,
	                -- Adding onclick with the idea that if you have a ton of
	                -- mods, you'd want to be able to jump to information about
	                -- the problem ones.
	                onclick = BuildOptionalModLink(v),
	            })
	        if mods[#mods].text == v then
	        	QueryName(v, mods[#mods], #mods)
	        end
	    end
	    return mods
	end

	local function ConfirmModDependenciesDownload()


		table.insert = new_insert
		--disable adding new entries to the table, so that the textlistpopup cant be stupid and add a extra button
        TheFrontEnd:PushScreen(TextListPopup(BuildModListQueryNames(modsList), 
        	STRINGS.UI.MODSSCREEN.MOD_DEPENDENCIES_TITLE,
        	string.format(STRINGS.UI.MODSSCREEN.MOD_HAS_DEPENDENCIES, modenv.modinfo.name),
            {{text=STRINGS.UI.MODSSCREEN.ENABLE, 
            cb = function()
				LibraryManager.dependency_list[modenv.modname] = modsList
				for i, v in pairs(modsList) do
					AutoSubscribeAndEnableWorkshopMod(v, true)
				end
				TheFrontEnd:PopScreen()
				TextListPopupDude = nil
            end,
            controller_control=CONTROL_MENU_MISC_1,},
            {text=STRINGS.UI.MODSSCREEN.DISABLE, cb = function()
	       		LibraryManager.disable_list[modenv.modname] = true
	       		TheFrontEnd:PopScreen()
				TextListPopupDude = nil
	       	end,
            controller_control = CONTROL_CANCEL,},
            block_new_entries = true}))
		table.insert = old_insert
		TextListPopupDude = TheFrontEnd:GetActiveScreen()
	end

	--a check to see if all dependencies are subbed...
	--we only send this prompt if you aren't subscribed to the mods.
	if DoModsExist(modsList) then
		LibraryManager.dependency_list[modenv.modname] = modsList
		for i, v in pairs(modsList) do
			--even though they are all already enabled we need to do this to make them where you cant disable them without the prompt coming up and warning you...
			AutoSubscribeAndEnableWorkshopMod(v, false)
		end
	else
		--we have to check what screen were on, otherwise the promp can get hidden behind the servercreationscreen
		--the solution for that is to create a queue of sorts for the list of mods trying to do this that's already enabled
		--this situation might occur if a mod is updated and a new dependency is added.
		if tostring(TheFrontEnd:GetActiveScreen().name) ~= "ServerCreationScreen" then
			LibraryManager.notify_list[modenv.modname] = ConfirmModDependenciesDownload
		else
			ConfirmModDependenciesDownload()
		end
	end
end

local function UninstallLibraryManager()
	ModManager.FrontendUnloadMod = old_FrontendUnloadMod
	ModsTab.UpdateForWorkshop = old_UpdateForWorkshop
	ServerCreationScreen.OnBecomeActive = old_OnBecomeActive
	ModsTab.EnableCurrent = old_EnableCurrent
	ServerCreationScreen.Create = old_Create
	LibraryManager.VERSION = nil
	LibraryManager.AutoSubscribeAndEnableWorkshopMods = nil
	LibraryManager.UninstallLibraryManager = nil
end

local function InstallLibraryManager()
	ModManager.FrontendUnloadMod = new_FrontendUnloadMod
	ModsTab.UpdateForWorkshop = new_UpdateForWorkshop
	ServerCreationScreen.OnBecomeActive = new_OnBecomeActive
	ModsTab.EnableCurrent = new_EnableCurrent
	ServerCreationScreen.Create = new_Create
	--have to do this crap cause of strict.h, which is the only way to add to the GLOBAL namespace
	global("LibraryManager")
	LibraryManager = {
		VERSION = VERSION,
		server_dependency_list = SetPostiveNumberTable({}), --for k, v
		dependency_list = {}, --for k, v
		disable_list = {}, --for k, v
		notify_list = {}, --for k, v
		AutoSubscribeAndEnableWorkshopMods = AutoSubscribeAndEnableWorkshopMods,
		UninstallLibraryManager = UninstallLibraryManager,
	}
	STRINGS.UI.MODSSCREEN.MOD_DEPENDENCIES_TITLE = "Dependencies Required"
	STRINGS.UI.MODSSCREEN.MOD_HAS_DEPENDENCIES = "%s requires other mods to run, it will subscribe and enable these if you enable this mod:"
	STRINGS.UI.MODSSCREEN.MOD_DEPENDENTS_TITLE = "Required By Other Mods"
	STRINGS.UI.MODSSCREEN.MOD_HAS_DEPENDENTS = "%s is required for other mods to run, if you disable this mod these mods will be disabled:"
	STRINGS.UI.MODSSCREEN.DISABLE_ALL = "Disable All"
	STRINGS.UI.MODSSCREEN.CANCEL = "Cancel"
	STRINGS.UI.MODSSCREEN.REQUIRED_MODS_DOWNLOADING_TITLE = "Required Mods Are Downloading"
	STRINGS.UI.MODSSCREEN.REQUIRED_MODS_DOWNLOADING = "The game has not finished downloading required mods.\nEither wait until the mods have finished downloading, or disable mods which have dependencies."
end

InstallLibraryManager()

end

return LibraryManager.AutoSubscribeAndEnableWorkshopMods

else

return function() end

end