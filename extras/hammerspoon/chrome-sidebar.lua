-- Toggle Chrome's vertical tab sidebar (chrome://flags/#vertical-tabs).
-- Chrome ships no shortcut for this, so we walk its accessibility tree to
-- find the "Expand/Collapse tabs" button and AXPress it. Adapted from
-- github.com/Ha1baraA11/Chrome-Vertical-Tab-Sidebar-Toggle, trimmed to a
-- plain function (no Cmd+S hijack, so no eventtap/watcher scaffolding).
-- Requires Accessibility permission for Hammerspoon.
--
-- Returns the toggle function; init.lua binds it to a hotkey.

-- Button labels are localized; these are the English ones. If the toggle
-- silently no-ops, your Chrome locale uses different labels -- add them here
-- (lower-case). Discover them by dumping Chrome's AXButtons in the Console.
local SIDEBAR_LABELS = {
  "expand tabs", "collapse tabs",
}

local function findSidebarButton(el, depth)
  depth = depth or 0
  if not el or depth > 25 then return nil end
  if el:attributeValue("AXRole") == "AXButton" then
    local title = string.lower(tostring(el:attributeValue("AXTitle") or ""))
    local desc = string.lower(tostring(el:attributeValue("AXDescription") or ""))
    for _, label in ipairs(SIDEBAR_LABELS) do
      if title == label or desc == label then return el end
    end
  end
  local children = el:attributeValue("AXChildren")
  if children then
    for _, child in ipairs(children) do
      local found = findSidebarButton(child, depth + 1)
      if found then return found end
    end
  end
  return nil
end

local function toggleChromeSidebar()
  local chrome = hs.application.find("com.google.Chrome")
  if not chrome then return end
  local axApp = hs.axuielement.applicationElement(chrome)
  if not axApp then return end
  for _, win in ipairs(axApp:attributeValue("AXWindows") or {}) do
    local button = findSidebarButton(win)
    if button then
      button:performAction("AXPress")
      return
    end
  end
  hs.alert.show("Chrome sidebar button not found")
end

return toggleChromeSidebar
