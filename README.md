 # Global Pause Staging

Add the option to pause the game from the start menu.
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
