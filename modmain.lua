SetupGemCoreEnv()

GLOBAL.GLOBALPAUSE = {}

GLOBAL.GLOBALPAUSE.ENABLEHOTKEY = GetModConfigData("ENABLEHOTKEY")

GLOBAL.GLOBALPAUSE.KEYBOARDTOGGLEKEY = GetModConfigData("KEYBOARDTOGGLEKEY")
if type(GLOBAL.GLOBALPAUSE.KEYBOARDTOGGLEKEY) == "string" then
	GLOBAL.GLOBALPAUSE.KEYBOARDTOGGLEKEY = GLOBAL.GLOBALPAUSE.KEYBOARDTOGGLEKEY:lower():byte()
end

--GLOBAL.GLOBALPAUSE.ENABLECLIENTPAUSING = GetModConfigData("ENABLECLIENTPAUSING")

GLOBAL.GLOBALPAUSE.AUTOPAUSESINGLEPLAYER = GetModConfigData("AUTOPAUSESINGLEPLAYER")
GLOBAL.GLOBALPAUSE.AUTOPAUSEMAP = GetModConfigData("AUTOPAUSEMAP")
GLOBAL.GLOBALPAUSE.AUTOPAUSECONSOLE = GetModConfigData("AUTOPAUSECONSOLE")
GLOBAL.GLOBALPAUSE.AUTOPAUSEENABLED = GLOBAL.GLOBALPAUSE.AUTOPAUSESINGLEPLAYER and (GLOBAL.GLOBALPAUSE.AUTOPAUSEMAP or GLOBAL.GLOBALPAUSE.AUTOPAUSECONSOLE)


AddShardComponent("shard_globalpause")

AddModRPCHandler("GlobalPause", "ReportPaused", function(player)
    GLOBAL.TheWorld:PushEvent("ms_reportpaused", player)
end)

AddModRPCHandler("GlobalPause", "SetPause", function(player, pause)
    local ct = GLOBAL.TheNet:GetClientTableForUser(player.userid)
    if ct ~= nil and ct.admin then
        GLOBAL.TheWorld:PushEvent("ms_setpause", pause)
    end
end)

GLOBAL.AddShardRPCHandler("GlobalPause", "ReportPaused", function(shard_id)
    GLOBAL.TheWorld:PushEvent("shard_reportpaused", GLOBAL.tonumber(shard_id))
end)

GLOBAL.AddShardRPCHandler("GlobalPause", "SetPause", function(shard_id, pause)
    if GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("shard_setpause", pause)
    end
end)

GLOBAL.setfenv(1, GLOBAL)

STRINGS.UI.PAUSEMENU.PAUSED_DST_TITLE = "Paused!"
STRINGS.UI.PAUSEMENU.PAUSED_DST_SUBTITLE = "Seriously. It is!"
STRINGS.UI.PAUSEMENU.TOGGLE_PAUSE = "Toggle Pause"
STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE = "Vote To Pause"
STRINGS.UI.PAUSEMENU.CLIENT_VOTE_UNPAUSE = "Vote To Unpause"

if GLOBALPAUSE.ENABLEHOTKEY and TheNet:GetIsServerAdmin() then
    TheInput:AddKeyDownHandler(GLOBALPAUSE.KEYBOARDTOGGLEKEY, function()
        if (TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name or ""):find("HUD") ~= nil then
            TheWorld:SetPause()
        end
    end)
end

local ConsoleScreen = require("screens/consolescreen")

local _ConsoleScreen_OnTextEntered = ConsoleScreen.OnTextEntered
function ConsoleScreen:OnTextEntered(...)
    local retval = {_ConsoleScreen_OnTextEntered(self, ...)}
    if TheWorld.ispaused then
        local task = self.runtask
        if task.arg then
            task.fn(unpack(task.arg))
        else
            task.fn()
        end
        task:Cancel()
    end
    return unpack(retval)
end

local ChatInputScreen = require("screens/chatinputscreen")

local _ChatInputScreen_OnTextEntered = ChatInputScreen.OnTextEntered
function ChatInputScreen:OnTextEntered(...)
    local retval = {_ChatInputScreen_OnTextEntered(self, ...)}
    if TheWorld.ispaused then
        local task = self.runtask
        if task.arg then
            task.fn(unpack(task.arg))
        else
            task.fn()
        end
        task:Cancel()
    end
    return unpack(retval)
end

if GLOBALPAUSE.AUTOPAUSEENABLED then
    if TheNet:GetIsServerAdmin() then
        local autopaused = false

        local function GetPlayerCount()
            local ClientObjs = TheNet:GetClientTable()
            if ClientObjs == nil then
                return #{}
            elseif TheNet:GetServerIsClientHosted() then
                return #ClientObjs
            end

            --remove dedicate host from player list
            for i, v in ipairs(ClientObjs) do
                if v.performance ~= nil then
                    table.remove(ClientObjs, i)
                    break
                end
            end
            return #ClientObjs 
        end

        if GLOBALPAUSE.AUTOPAUSEMAP then
            local MapScreen = require("screens/mapscreen")

            local _OnBecomeActive = MapScreen.OnBecomeActive
            function MapScreen:OnBecomeActive(...)
                if GetPlayerCount() == 1 then
                    if not TheWorld.ispaused then
                        TheWorld:SetPause(true)
                        autopaused = true
                    end
                end
                return _OnBecomeActive(self, ...)
            end
        end
        if GLOBALPAUSE.AUTOPAUSECONSOLE then
            local _OnBecomeActive = ConsoleScreen.OnBecomeActive
            function ConsoleScreen:OnBecomeActive(...)
                if GetPlayerCount() == 1 then
                    if not TheWorld.ispaused then
                        TheWorld:SetPause(true)
                        autopaused = true
                    end
                end
                return _OnBecomeActive(self, ...)
            end
        end

        local PlayerHud = require("screens/playerhud")

        local _OnGainFocus = PlayerHud.OnGainFocus
        function PlayerHud:OnGainFocus(...)
            if autopaused then
                TheWorld:SetPause(false)
            end
            autopaused = false
            return _OnGainFocus(self, ...)
        end
    end
end

GEMENV.AddPrefabPostInitAny(function(inst) 
    if TheWorld ~= nil and TheWorld.net == inst then
        inst:AddComponent("globalpause")
    end
end)

--PauseScreen post inits.

local PauseScreen = require("screens/pausescreen")

function PauseScreen:UpdateText()
    if not TheWorld.ispaused then
        self:UnpauseText()
    else
        self:PauseText()
    end
end

function PauseScreen:PauseText()
    self.title:SetString(STRINGS.UI.PAUSEMENU.PAUSED_DST_TITLE)
    self.subtitle:SetString(STRINGS.UI.PAUSEMENU.PAUSED_DST_SUBTITLE)
    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE)
    end

    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_UNPAUSE)
    end
end

function PauseScreen:UnpauseText()
    self.title:SetString(STRINGS.UI.PAUSEMENU.DST_TITLE)
    self.subtitle:SetString(STRINGS.UI.PAUSEMENU.DST_SUBTITLE)
    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE)
    end

    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_UNPAUSE)
    end
end

function PauseScreen:ToggleGlobalPause()
    TheWorld:SetPause()
end

GEMENV.AddClassPostConstruct("screens/pausescreen", function(self)
    local extra_menu_height
    if GLOBALPAUSE.ENABLECLIENTPAUSING or TheNet:GetIsServerAdmin() then
        extra_menu_height = 50 -- should be an even number (I think)
    else
        extra_menu_height = 0
    end

    --throw up the background

    local w, h = self.bg:GetSize()
    h = h + extra_menu_height
    self.bg:SetSize(w, h)

    w, h = self.bg.fill:GetSize()
    h = h + extra_menu_height
    self.bg.fill:SetSize(w, h)

    --title
    local point = self.title:GetPosition()
    point.y = point.y + extra_menu_height / 2
    self.title:SetPosition(point)

    --subtitle
    point = self.subtitle:GetPosition()
    point.y = point.y + extra_menu_height / 2
    self.subtitle:SetPosition(point)

    self:UpdateText()

    local togglepausestring = TheNet:GetIsServerAdmin() and STRINGS.UI.PAUSEMENU.TOGGLE_PAUSE or GLOBALPAUSE.ENABLECLIENTPAUSING and STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE or nil
    if togglepausestring then
        self.togglepause = self.menu:AddItem(togglepausestring, function() self:ToggleGlobalPause() end)
        table.removearrayvalue(self.menu.items, self.togglepause)
        table.insert(self.menu.items, 2, self.togglepause)
        for i, v in ipairs(self.menu.items) do
            local pos = Vector3(0,0,0)
            if self.horizontal then
                pos.x = pos.x + self.menu.offset * (i - 1)
            else
                pos.y = pos.y + self.menu.offset * (i - 1)
            end
            v:SetPosition(pos)
            v:SetScale(0.7)
        end
        self.menu:DoFocusHookups()
    end
    
    point = self.menu:GetPosition()
    point.y = point.y + extra_menu_height / 2
    self.menu:SetPosition(point)

    self.inst:ListenForEvent("pausestatedirty", function() self:UpdateText() end, TheWorld.net);
end)

PauseScreen = require("screens/redux/pausescreen")

function PauseScreen:UpdateText()
    if not TheWorld.ispaused then
        self:UnpauseText()
    else
        self:PauseText()
    end
end

function PauseScreen:PauseText()
    self.bg.title:SetString(STRINGS.UI.PAUSEMENU.PAUSED_DST_TITLE)
    self.bg.body:SetString(STRINGS.UI.PAUSEMENU.PAUSED_DST_SUBTITLE)
    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE)
    end
end

function PauseScreen:UnpauseText()
    self.bg.title:SetString(STRINGS.UI.PAUSEMENU.DST_TITLE)
    self.bg.body:SetString(STRINGS.UI.PAUSEMENU.DST_SUBTITLE)
    if not TheNet:GetIsServerAdmin() and GLOBALPAUSE.ENABLECLIENTPAUSING then
        self.togglepause:SetText(STRINGS.UI.PAUSEMENU.CLIENT_VOTE_UNPAUSE)
    end
end

function PauseScreen:ToggleGlobalPause()
    TheWorld:SetPause()
end

GEMENV.AddClassPostConstruct("screens/redux/pausescreen", function(self)
    local extra_menu_height
    if GLOBALPAUSE.ENABLECLIENTPAUSING or TheNet:GetIsServerAdmin() then
        extra_menu_height = 50 -- should be an even number (I think)
    else
        extra_menu_height = 0
    end

    --throw up the background
    local w, h = self.bg:GetSize()
    h = math.clamp(h + extra_menu_height or 200, 90, 500)
    self.bg:SetSize(w, h)
    self:UpdateText()

    local togglepausestring = TheNet:GetIsServerAdmin() and STRINGS.UI.PAUSEMENU.TOGGLE_PAUSE or GLOBALPAUSE.ENABLECLIENTPAUSING and STRINGS.UI.PAUSEMENU.CLIENT_VOTE_PAUSE or nil
    if togglepausestring then
        self.togglepause = self.menu:AddItem(togglepausestring, function() self:ToggleGlobalPause() end)
        table.removearrayvalue(self.menu.items, self.togglepause)
        table.insert(self.menu.items, 2, self.togglepause)
        for i, v in ipairs(self.menu.items) do
            local pos = Vector3(0,0,0)
            if self.horizontal then
                pos.x = pos.x + self.menu.offset * (i - 1)
            else
                pos.y = pos.y + self.menu.offset * (i - 1)
            end
            v:SetPosition(pos)
            v:SetScale(0.7)
        end
        self.menu:DoFocusHookups()
    end

    local point = self.menu:GetPosition()
    point.y = point.y + extra_menu_height / 2
    self.menu:SetPosition(point)

    self.inst:ListenForEvent("pausestatedirty", function() self:UpdateText() end, TheWorld.net)
end)