-- Lets the `hs` CLI talk to this running instance, e.g.
--   hs -c 'print(watchers.tmuxWindow:isEnabled())'
--   hs -c 'print(hs.application.frontmostApplication():bundleID())'
require("hs.ipc")

local hyper = { "cmd", "alt", "ctrl", "shift" }
-- local hyper = { "cmd", "alt", "ctrl" }

hs.hotkey.bind(hyper, "0", function()
  hs.reload()
end)

-- Focus apps
local function focusApp(name)
  return function()
    local app = hs.application.find(name)
    app:unhide()
    app:activate()
  end
end

hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

hs.window.animationDuration = 0


hs.grid.setMargins(hs.geometry.size(0, 0))
hs.grid.setGrid(hs.geometry.size(4, 4))

-- Show grid
hs.hotkey.bind(hyper, "h", hs.grid.toggleShow)

-- Use Karabiner-EventViewer->Frontmost application to find bundle identifiers
hs.hotkey.bind(hyper, "1", focusApp("com.google.Chrome"))
hs.hotkey.bind(hyper, "2", focusApp("Todoist"))
hs.hotkey.bind(hyper, "3", focusApp("com.microsoft.VSCode"))

hs.hotkey.bind(hyper, "t", focusApp("ghostty"))

hs.hotkey.bind(hyper, "o", focusApp("Todoist"))

hs.hotkey.bind(hyper, "n", focusApp("notion.id"))
hs.hotkey.bind(hyper, "x", focusApp("Notion Calendar")) -- com.cron.electron

hs.hotkey.bind(hyper, "s", focusApp("Slack"))
hs.hotkey.bind(hyper, "d", focusApp("Discord"))

hs.hotkey.bind(hyper, "l", focusApp("Linear"))
hs.hotkey.bind(hyper, "f", focusApp("Figma"))
hs.hotkey.bind(hyper, "e", focusApp("Finder"))
hs.hotkey.bind(hyper, "m", focusApp("com.electron.realtimeboard")) -- Miro
hs.hotkey.bind(hyper, "p", focusApp("1Password"))
hs.hotkey.bind(hyper, "j", focusApp("com.jetbrains.datagrip"))
hs.hotkey.bind(hyper, "z", focusApp("Zoom"))
hs.hotkey.bind(hyper, "c", focusApp("Claude"))
hs.hotkey.bind(hyper, "g", focusApp("ChatGPT"))
hs.hotkey.bind(hyper, "b", focusApp("Blender"))
hs.hotkey.bind(hyper, "a", focusApp("com.ableton.live"))

-- Right option + number -> tmux window
--
-- Device-specific modifier bits in CGEventFlags (present on keyDown events too,
-- so no flagsChanged bookkeeping is needed):
--   0x20 left option    0x40 right option
--   0x01 left ctrl      0x2000 right ctrl
-- 0x40 confirmed on Logitech MX Keys. To verify on another keyboard, paste this
-- into the Hammerspoon console, press the key, and read the printed flags:
--   ft = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
--     print(string.format("flags=0x%x", e:getRawEventData().CGEventData.flags)) end):start()
local RIGHT_OPTION_MASK = 0x40
local GHOSTTY_BUNDLE_ID = "com.mitchellh.ghostty"

-- Resolve tmux once at load time. Hammerspoon's own PATH is the bare system one,
-- so ask the user's login shell first (covers Homebrew on either architecture,
-- MacPorts, Nix, ~/.local/bin, ...), then fall back to well-known locations.
local function findExecutable(name)
  local out = hs.execute("command -v " .. name, true) or ""
  local fromShell = out:match("([^\n]+)%s*$") -- last line, skipping shell startup noise
  if fromShell and hs.fs.attributes(fromShell) then return fromShell end

  local candidates = {
    "/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin", "/usr/bin",
    os.getenv("HOME") .. "/.nix-profile/bin",
  }
  for _, dir in ipairs(candidates) do
    local path = dir .. "/" .. name
    if hs.fs.attributes(path) then return path end
  end
end

local tmux = findExecutable("tmux")
if not tmux then
  hs.notify.new({title="Hammerspoon", informativeText="tmux not found; Right option + number is disabled"}):send()
end

-- Global on purpose: a `local` eventtap is unreachable once init.lua finishes
-- and Lua's garbage collector will reap it, which silently stops the tap.
watchers = {}

watchers.tmuxWindow = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if not tmux then return false end
  local flags = e:getRawEventData().CGEventData.flags
  if (flags & RIGHT_OPTION_MASK) == 0 then return false end
  -- Only act in Ghostty; elsewhere Right option + digit keeps its normal meaning.
  local front = hs.application.frontmostApplication()
  if not front or front:bundleID() ~= GHOSTTY_BUNDLE_ID then return false end
  local n = tonumber(hs.keycodes.map[e:getKeyCode()])
  if not (n and n >= 1 and n <= 9) then return false end
  -- hs.task is async and skips the shell, so the tap callback returns immediately.
  -- macOS disables event taps whose callbacks run too long.
  hs.task.new(tmux, nil, { "select-window", "-t", tostring(n) }):start()
  return true
end)
watchers.tmuxWindow:start()

hs.hotkey.bind(hyper, "k", function()
  local win = hs.window.focusedWindow();
  if not win then return end
  win:moveToScreen(win:screen():next())
end)

-- Toggle Chrome's vertical tab sidebar (see chrome-sidebar.lua)
hs.hotkey.bind(hyper, "v", require("chrome-sidebar"))
