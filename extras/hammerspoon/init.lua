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
hs.hotkey.bind(hyper, "2", focusApp("com.googlecode.iterm2"))
hs.hotkey.bind(hyper, "t", focusApp("com.googlecode.iterm2"))
hs.hotkey.bind(hyper, "3", focusApp("Code")) -- com.microsoft.VSCode
hs.hotkey.bind(hyper, "4", focusApp("notion.id"))
hs.hotkey.bind(hyper, "n", focusApp("notion.id"))
hs.hotkey.bind(hyper, "x", focusApp("Notion Calendar")) -- com.cron.electron
hs.hotkey.bind(hyper, "5", focusApp("Slack"))
hs.hotkey.bind(hyper, "s", focusApp("Slack"))
hs.hotkey.bind(hyper, "l", focusApp("Linear"))
hs.hotkey.bind(hyper, "6", focusApp("Discord"))
hs.hotkey.bind(hyper, "d", focusApp("Discord"))
hs.hotkey.bind(hyper, "7", focusApp("Figma"))
hs.hotkey.bind(hyper, "f", focusApp("Figma"))
hs.hotkey.bind(hyper, "m", focusApp("Miro"))
hs.hotkey.bind(hyper, "g", focusApp("DataGrip"))
hs.hotkey.bind(hyper, "z", focusApp("Zoom"))
hs.hotkey.bind(hyper, "c", focusApp("Claude"))
hs.hotkey.bind(hyper, "g", focusApp("ChatGPT"))

hs.hotkey.bind(hyper, "k", function()
  local win = hs.window.focusedWindow();
  if not win then return end
  win:moveToScreen(win:screen():next())
end)
