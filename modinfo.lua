name = "Global Pause"
description = [[Add the option to pause the game from the start menu.

Features:
- Pause from the start menu (admin only)
- Vote to pause from the start menu (everyone else, not yet implemented)
- Hotkey to toggle pause (default "P", default disabled, admin only)
- Pause when map is open (default disabled, singleplayer only)
- Pause when console is open (default disabled, singleplayer only)

When joining a server that is "paused" youll be stuck at the connecting screen, I cannot do anything to fix this.

Future improvements:
Useful for multi player:
- vote to (un)pause, which allows servers without an admin present to pause(and unpause) the game.
Useful for single player:
- Option for AutoPause/AutoUnPause on crafting/inventory

Thanks to:
  pennykid
  Droozo Qoocla
  SKKiro
for multiplayer testing.

v1.5.0
Improved compatibility with other mods that mess with the pausescreen.
Clients pause properly, no more rain particles building up on clients!
Servers pause properly, no more desyncing servers by pausing in caves, 
this mod now makes use of GemCore to make pausing on any shard possible, 
pause the whole server, and not just the current shard.
Made servers automaticaly unpause, when the last player leaves the game.
Console and Chat no longer hang or cause the server to(temporarily) unpause.

v1.4.1
Fixed the name of the Mod and Zarklord's name.

v1.4.0
Zarklord: Updated the pause menu for the Redux update.

v1.3.2
Non-admin pause. Comments in the code explain why non-admins may not unpause.

v1.3.1
Console no longer hangs.

v1.3.0
Autopause added for map and console.

v1.2.2
Hotkey added. Default state is off.

v1.2.1
Added a proper icon in the game mod list.

v1.2.0 changes
Multiplayer pausing should now work (changed logic for this work).
The ClientHost now only SetTimeScale(0) after everybody else has.

Also, for some reason, now the animations stop when you pause. that means that animals won't keep moving after you pause.
I have no idea what fixed this...

On Klei: http://forums.kleientertainment.com/files/file/1579-global-pause-dst/
On Steam: http://steamcommunity.com/sharedfiles/filedetails/?id=758532836
]]
author = "hmaarrfk"
version = "1.5.0"


folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = " " .. name .. " Staging"
end


forumthread = "/files/file/1579-global-pause-dst/"

api_version = 10

priority = 10 -- Do not set this to -1, it doesn't work with Combined status

-- Compatible with the base game & ROG
dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

--These let clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = true

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = false

--This lets people search for servers with this mod by these tags
server_filter_tags = {}



-- took this from globalposition
local KEY_A = 65
local keyslist = {}
local string = "" -- can't believe I have to do this... -____-
for i = 1, 26 do
	local ch = string.char(KEY_A + i - 1)
	keyslist[i] = {description = ch, data = ch}
end

configuration_options =
{
    {
        name = "ENABLEHOTKEY",
        label = "Use hotkey",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
    },
    {
        name = "KEYBOARDTOGGLEKEY",
        label = "Toggle key",
        hover = "The key hotkey to toggle the pause state.",
        options = keyslist,
        default = "P", --P
    },
    {
        name = "ENABLECLIENTPAUSING",
        label = "Enable everybody vote to (un)pause",
        hover = "Not yet implemented",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
    },
    {
        name = "AUTOPAUSESINGLEPLAYER",
        label = "Autopause for singleplayer",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = true,
    },
    {
        name = "AUTOPAUSEMAP",
        label = "Autopause on map",
        hover = "Singeplayer only",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
    },
    {
        name = "AUTOPAUSECONSOLE",
        label = "Autopause on console",
        hover = "Singeplayer only",
        options = {
            {description = "Yes", data = true},
            {description = "No", data = false},
        },
        default = false,
    },
}