-------------------------------------------------------------------------
--[[ Shard_GlobalPause ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Shard_GlobalPause should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local MAX_TARGETS = 10

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _ismastershard = _world.ismastershard
local _pausestate = net_bool(inst.GUID, "shard_globalpause._pausestate", "shardpausestatedirty")
local _pausedlist = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local AllShardsPaused = _ismastershard and function()
    for k, v in pairs(SHARD_LIST) do
        if not _pausedlist[k] then
            return false
        end
    end
    return true
end or nil

local SetPause = _ismastershard and function(src, pause)
    _pausedlist = {}
    if pause == nil then
        _pausestate:set(not _pausestate:value())
    else
        _pausestate:set(pause)
    end
end or function(src, pause)
    SendShardRPCToServer(SHARD_RPC.GlobalPause.SetPause, pause)
end

local ReportPaused = _ismastershard and function(src, shard_id)
    _pausedlist[shard_id] = true
    if AllShardsPaused() then
        TheSim:SetTimeScale(0)
        SetSimPause(true)
    end
end or function(src, shard_id)
    TheSim:SetTimeScale(0)
    SetSimPause(true)
    SendShardRPCToServer(SHARD_RPC.GlobalPause.ReportPaused)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_pausestate:set(false)

inst:ListenForEvent("shardpausestatedirty", function() _world:PushEvent("shard_setpausedstate", _pausestate:value()) end)
inst:ListenForEvent("shard_setpause", SetPause, _world)
inst:ListenForEvent("shard_reportpaused", ReportPaused, _world)

if _ismastershard then
    inst:ListenForEvent("ms_playercounts", function(src, data)
        if data.total == 0 then
            SetPause(false)
        end
    end)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)