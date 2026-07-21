#!/usr/bin/env sh

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -int 0
# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

defaults write com.google.Chrome NSRequiresAquaSystemAppearance -bool Yes

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

defaults write com.apple.Dock appswitcher-all-displays -bool true

# Position the Dock on the left side of the screen
defaults write com.apple.dock orientation -string left

# Spacers
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'; killall Dock
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'; killall Dock

mkdir -p ~/Documents/Screenshots
defaults write com.apple.screencapture location ~/Documents/Screenshots

# Disable Spotlight keyboard shortcuts (Keyboard > Keyboard Shortcuts > Spotlight)
# 64 = Show Spotlight search (^⌘Space), 65 = Show Finder search window (⌥⌘Space)
# value block preserves the key binding so only the enabled flag is flipped
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  '{ enabled = 0; value = { parameters = (32, 49, 1310720); type = standard; }; }'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 \
  '{ enabled = 0; value = { parameters = (32, 49, 1572864); type = standard; }; }'
# Reload the symbolic hotkeys service so the change takes effect without logout
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

killall Dock
