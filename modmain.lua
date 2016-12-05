
KEYBOARDTOGGLEKEY = GetModConfigData("KEYBOARDTOGGLEKEY")
if type(KEYBOARDTOGGLEKEY) == "string" then
	KEYBOARDTOGGLEKEY = KEYBOARDTOGGLEKEY:lower():byte()
end

ENABLEHOTKEY = GetModConfigData("ENABLEHOTKEY")
AUTOPAUSEMAP = GetModConfigData("AUTOPAUSEMAP")
AUTOPAUSECONSOLE = GetModConfigData("AUTOPAUSECONSOLE")
AUTOPAUSESINGLEPLAYERONLY = GetModConfigData("AUTOPAUSESINGLEPLAYERONLY")
AUTOPAUSEENABLED = AUTOPAUSEMAP or AUTOPAUSECONSOLE
ENABLECLIENTPAUSE = GetModConfigData("ENABLECLIENTPAUSE")


local require = GLOBAL.require

-- structure to hold global pause variables
GLOBAL.GP = {}
GLOBAL.GP.autopaused = false

GLOBAL.GP.client_pause_enabled = ENABLECLIENTPAUSE

-- MOD RPC Handlers do not work when you set things like SetSimPause to true
-- Therefore, clients may only pause, and not unpause the game :(
if ENABLECLIENTPAUSE then
	AddModRPCHandler("GlobalPause", "RPCTogglePause", function() GLOBAL.GPTogglePause() end)
	AddModRPCHandler("GlobalPause", "RPCGlobalPause", function() GLOBAL.globalPauseSet(true) end)
	AddModRPCHandler("GlobalPause", "RPCGlobalUnpause", function() GLOBAL.globalPauseSet(false) end)
end


-- Client Hosted server must be the last person to pause. Therefore, everybody else reports to him the fact that they paused using this function
AddModRPCHandler("GlobalPause", "RPCReportGlobalPaused", function(inst, data)
  GLOBAL.RPCReportGlobalPaused(inst, data)
end)

AddPrefabPostInit("forest_network", function(inst) inst:AddComponent("globalpause") end)
AddPrefabPostInit(  "cave_network", function(inst) inst:AddComponent("globalpause") end)

if ENABLEHOTKEY and ( ENABLECLIENTPAUSE or GLOBAL.TheNet:GetIsServerAdmin() ) then
  AddClassPostConstruct( "widgets/controls", function()
	    GLOBAL.TheInput:AddKeyDownHandler(KEYBOARDTOGGLEKEY, function()
	      GLOBAL.PauseScreenTogglePause()
	    end)
	end)
end

local function GP_OnBecomeActive(self)
	if AUTOPAUSESINGLEPLAYERONLY and table.getn(GLOBAL.AllPlayers) == 1 then
	  if GLOBAL.TheSim:GetTimeScale() ~= 0 then
	    GLOBAL.TheNet:SendRemoteExecute("globalPauseSet(true)", true)
	    GLOBAL.GP.autopaused = true
	  end
	end
  self:oldOnBecomeActive()
end

local function HUD_GPOnGainFocus(self)
	self:oldOnGainFocus()
  if GLOBAL.GP.autopaused then
    GLOBAL.TheNet:SendRemoteExecute("globalPauseSet(false)", true)
  end
  GLOBAL.GP.autopaused = false
end

local function GPAddToScreen(self)
	self.oldOnBecomeActive = self.OnBecomeActive
	self.OnBecomeActive = GP_OnBecomeActive
end

local function GPConsoleOnTextEntered(self)
	if GLOBAL.TheSim:GetTimeScale() == 0 then
		GLOBAL.TheNet:SendRemoteExecute("globalPauseSet(false)", true)
		self.pause_after_run = true
	else
		self.pause_after_run = false
	end
	self:oldOnTextEntered()
end

local function GPConsoleRun(self)
	self:oldRun()
	if self.pause_after_run then
		GLOBAL.TheNet:SendRemoteExecute("globalPauseSet(true)", true)
	end
end
if GLOBAL.TheNet:GetIsServerAdmin() then
	AddClassPostConstruct("screens/consolescreen", function(inst)
		inst.oldOnTextEntered = inst.OnTextEntered
		inst.OnTextEntered = GPConsoleOnTextEntered
		inst.oldRun = inst.Run
		inst.Run = GPConsoleRun
	end)
end

if AUTOPAUSEENABLED then
	if GLOBAL.TheNet:GetIsServerAdmin() then
		if AUTOPAUSEMAP then
	  	AddClassPostConstruct("screens/mapscreen", GPAddToScreen)
		end
		if AUTOPAUSECONSOLE then
			AddClassPostConstruct("screens/consolescreen", GPAddToScreen)
		end
	  AddClassPostConstruct("screens/playerhud", function(self)
	      self.oldOnGainFocus = self.OnGainFocus
	      self.OnGainFocus = HUD_GPOnGainFocus
	  end)
	end
end

-- Apparently this should also work, making it work for any kind of network, forest or cave, but
-- it crashes on the client :S
--[[AddPrefabPostInit("world", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst.net:AddComponent("globalpause")
	end)
end)
]]
