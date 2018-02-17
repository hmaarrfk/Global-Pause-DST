name = "Global Pause Staging"
description = [[Add the option to pause the game from the start menu.
Only admins may unpause.

Features:
- Pause from the start menu (admin only)
- Hotkey to toggle pause (default "P", default disabled)
- Non admins may now pause, but not unpause (default disabled)
- Pause when map is open (default disabled)
- Pause when console is open (default disabled)

Known quirks:
- If you paused from the menu, then go to run a command, you will see a tiny bit of time passing when you press enter.
  This is unavoidable. Without unpausing for that tiny amount of time, I cannot allow the command to run and the game will hang.

Known bugs:
- Sometimes things keep moving. So strange.
- If the game is paused and the admins leave, there is no way to unpause. Somebody would have to issue the server command GPTogglePause() on the server console.
- I don't know what happens if a player joins and the game is paused.

Future improvements:
Useful for single player:
- Option for AutoPause/AutoUnPause on crafting/inventory

Things that might be impossible:
- Non admin unpause

When the server pauses, most communication is blocked between the clients and
the server. An admin may execute code on the server which bypasses these
limitations. This is what enables the admin to unpause the game. For this
reason, I don't think that vote to unpause or a normal player unpausing will
ever be possible. If you find a way, and want to submit a patch, please do.

Thanks to:
  pennykid
  Droozo Qoocla
for multiplayer testing.

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
version = "1.4.0"

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
      name = "ENABLECLIENTPAUSE",
      label = "Enable everybody to pause",
      hover = "Only admins may unpause.",
      options = {
        {description = "Yes", data = true},
        {description = "No", data = false},
      },
      default = false,
  },
  {
    name = "AUTOPAUSESINGLEPLAYERONLY",
    label = "Autopause single/multi player",
    options = {
      {description = "Single only", data = true},
      {description = "Multi too", data = false},
    },
    default = true,
  },
  {
    name = "AUTOPAUSEMAP",
    label = "Autopause on map",
    hover = "Admin only",
    options = {
      {description = "Yes", data = true},
      {description = "No", data = false},
    },
    default = false,
  },
  {
    name = "AUTOPAUSECONSOLE",
    label = "Autopause on console",
    hover = "Admin only",
    options = {
      {description = "Yes", data = true},
      {description = "No", data = false},
    },
    default = false,
  },
}
