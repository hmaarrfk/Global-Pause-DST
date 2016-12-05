
--[[
Alright, this is how this mod will work:

To pause:
the server needs to Call SetSimPause(true)
all clients need to TheSim:SetTimeScale(0)
if the client is hosting, he has to call TheSim:SetTimeScale(0) AFTER everybody else has called it.
Therefore all clients report that the SetTimeScale(0), and THEN the ClientServer can call it

To unpause
the server needs to Call SetSimPause(false)
all clients need to TheSim:SetTimeScale(1)

Apparently the dedicated server can call SetTimeScale(0) too. This simplifies the logic

Apparently, we need to do the following for communication:
client->server use this thing called RPC, maybe RPC_HANDLERS, in networkclientrpc.lua

server->client use net_event

Unfortunately, you can't actually USE ModRPC when things are Paused. So I had to make this an admin only mod, whereby
only administrators are allowed to pause and unpause
]]

-- TheNet:GetIsServer()  -> Server, either dedicated or the player hosting
-- TheNet:GetIsClient() -> Anybody connected to the server, only players, not the player that is hosting for himself
-- TheNet:GetIsHosting() -> Only true for dedicated Dedicated Server
-- TheNet:GetServerIsDedicated() -> Only true if conneceted to dedicated servers
-- TheNet:GetIsServerAdmin() -> you can send remove commands to be executed on the server


local function isplayer(p, isdedicated)
  return not isdedicated or p.performance == nil
end

local function checkAllPlayersPaused()
  -- after each response, check that all the timescales,
  -- of all players that are not servers
  -- are reported to have been paused
  -- if this is not the case, simply stop the execution of this function
  -- if it is the case, then finally pause the simulation
  for i, v in ipairs(AllPlayers) do
      if not v.IsTimeScale0 then
        return false
      end
  end
  return true
end

function RPCReportGlobalPaused(inst, player_id)
  -- I don't really know what inst is, it might be the Net:Player that sent in the RPC
  for i, v in ipairs(AllPlayers) do
      if v.userid == player_id then
        v.IsTimeScale0 = true
      end
  end
  --if checkAllPlayersPaused() and not TheNet:GetIsHosting() then
  if checkAllPlayersPaused() then
    TheSim:SetTimeScale(0)
    SetSimPause(true)
  end
end



function globalPauseSet(state)
  -- We should reset the client answers
  -- everytime we ask to pause the game.
  local isdedicated = not TheNet:GetServerIsClientHosted()
  for i, v in ipairs(AllPlayers) do
      v.IsTimeScale0 = false
  end
  TheWorld.net.GP.pause_state:set(state)
end

function GPTogglePause()
  print("toggling")

  GP.autopaused = false
  globalPauseSet(not TheWorld.net.GP.pause_state:value())
end


local function OnGPPause(inst)
  -- Everybody with a player running needs to set the timescale to 0
  -- You would think that GetIsClient would be good, but actually you need to
  -- account for people that host games without dedicated servers.
  -- In that case, they will be hosts, but GetIsHosting only returns true for the dedicated server
  --if not TheNet:GetIsHosting() then
    -- if the system is client hosted, then we need to wait for everybody to reported
    -- that they paused before we do, else we will not receive events... sucks
    if not TheWorld.ismastersim then
      TheSim:SetTimeScale(0)
    end
    -- This is an easy way to check if it is a dedicated servers
    if ThePlayer ~= nil then
      SendModRPCToServer(MOD_RPC.GlobalPause.RPCReportGlobalPaused, ThePlayer.userid)
    end
  --end
end

local function OnGPUnpause(inst)
  print("OnGPUnpause")
  if TheNet:GetIsServer() then
    SetSimPause(false)
  end
  --if not TheNet:GetIsHosting() then
    TheSim:SetTimeScale(1)
  --end
end

function OnGPPauseDirty(inst)
  if TheWorld.net.GP.pause_state:value() then
    OnGPPause(inst)
  else
    OnGPUnpause(inst)
  end
end

local GlobalPause = Class(function(self, inst)
    self.inst = inst

    inst.GP               = {}
    inst.GP.pause_state   =  net_bool(inst.GUID, "gp_pause_state", "gp_pause_state")

    inst.GP.pause_state:set(
    false)

    inst:ListenForEvent("gp_pause_state", OnGPPauseDirty)
  end
)

function PauseScreenTogglePause()
  -- Admins can toggle
  if TheNet:GetIsServerAdmin() then
    --[[
    Send remove execute bypasses the requirement taht the simulation
    must be running on the server. This is what enables unpausing.
    ]]
    TheNet:SendRemoteExecute("GPTogglePause()", true)
  else
    -- everybody else must use SendModRPCToServer
    if TheWorld.net.GP.pause_state:value() then
      SendModRPCToServer(MOD_RPC.GlobalPause.RPCGlobalPause)
    --[[
    else
      print("sending unpause")
      TheSim:SetTimeScale(1)
      SetSimPause(false)
      -- this is needed to unpause via events. I guess the server will not accept events
      -- unless the simulation is unpaused
      -- therefore, clients without admin prividegles will never be able to unpause
      SendModRPCToServer(MOD_RPC.GlobalPause.RPCGlobalUnpause)
      ]]
    end
  end
end

return GlobalPause
