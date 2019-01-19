--[[
Alright, this is how this mod will work:

To pause:
everything needs to Call:
SetSimPause(true)
TheSim:SetTimeScale(0)

To unpause
everything needs to Call:
SetSimPause(false)
TheSim:SetTimeScale(1)
]]

--------------------------------------------------------------------------
--[[ GlobalPause class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastersim = _world.ismastersim
local _ismastershard = _world.ismastershard
local _pausestate = net_bool(inst.GUID, "globalpause._pausestate", "pausestatedirty")
local _pausedlist = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local AllPlayersPaused = _ismastersim and function()
    for i, v in ipairs(AllPlayers) do
        if not _pausedlist[v] then
            return false
        end
    end
    return true
end or nil

local SetPause = _ismastersim and function(src, pause)
    _world:PushEvent("shard_setpause", pause)
end or nil

local SetPausedState = _ismastersim and function(src, pause)
    _pausedlist = {}
    _pausestate:set(pause)
end or nil

local ReportPaused = _ismastersim and function(src, player)
    if player then
        _pausedlist[player] = true
    end
    if AllPlayersPaused() then
        TheWorld:PushEvent("shard_reportpaused", tonumber(TheShard:GetShardId()))
    end
end or nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPauseStateDirty()
    _world.ispaused = _pausestate:value()
    if _world.ispaused then
        if not _ismastersim then
            TheSim:SetTimeScale(0)
            SetSimPause(true)
            SendModRPCToServer(MOD_RPC.GlobalPause.ReportPaused)
        else
            ReportPaused(nil, TheLocalPlayer)
        end
    else
        SetSimPause(false)
        TheSim:SetTimeScale(1)
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_pausestate:set(false)

inst:ListenForEvent("pausestatedirty", OnPauseStateDirty)

if _ismastersim then
    inst:ListenForEvent("shard_setpausedstate", SetPausedState, _world)
    inst:ListenForEvent("ms_setpause", SetPause, _world)
    inst:ListenForEvent("ms_reportpaused", ReportPaused, _world)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function _world:SetPause(pause)
    if TheNet:GetIsClient() and TheNet:GetIsServerAdmin() then
        SendModRPCToServer(MOD_RPC.GlobalPause.SetPause, pause)
    elseif TheNet:GetIsServer() then
        _world:PushEvent("ms_setpause", pause)
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)