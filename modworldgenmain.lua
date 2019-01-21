GLOBAL.package.loaded["librarymanager"] = nil
local AutoSubscribeAndEnableWorkshopMods = GLOBAL.require("librarymanager")
if GLOBAL.IsWorkshopMod(modname) then
    AutoSubscribeAndEnableWorkshopMods({"workshop-1378549454"})
else
    --if the Gitlab Versions dont exist fallback on workshop version
    local GEMCORE = GLOBAL.KnownModIndex:GetModActualName("[API] Gem Core - GitLab Version") or "workshop-1378549454"
    AutoSubscribeAndEnableWorkshopMods({GEMCORE})
end