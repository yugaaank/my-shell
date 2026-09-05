-- my-shell Hyprland binds (Lua style, cf. dots-hyprland hyprland/keybinds.lua).
-- Every shell action gets TWO binds: live IPC first, dead-shell fallback second.
require("hyprland.lib")

local qsIpc = "qs -c my-shell ipc call"
local qsAlive = qsIpc .. " launcher isOpen"

-- Launcher (SUPER+Space). Fallback: fuzzel.
hl.bind("SUPER + Space", hl.dsp.global("launcher:toggle"), { description = "Shell: Toggle launcher" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd(qsAlive .. " || pkill fuzzel || fuzzel"), { description = "Launcher fallback" })

-- Random wallpaper (SUPER+CTRL+T, cf. dots-hyprland keybinds.lua:49-52).
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd(qsIpc .. " wallpaper random"), { description = "Shell: Random wallpaper" })

-- Notification center (SUPER+N, Win11 Win+N).
hl.bind("SUPER + N", hl.dsp.exec_cmd(qsIpc .. " notifs toggle"), { description = "Shell: Toggle notification center" })

-- Workspace scroll lives on the bar (Bar.qml wheel handler); keep
-- keyboard switching native so the shell never bricks navigation:
-- (add your own workspace binds here or keep Hypr defaults)
