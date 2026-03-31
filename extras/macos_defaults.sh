#!/usr/bin/env sh

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -int 0
# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

defaults write com.google.Chrome NSRequiresAquaSystemAppearance -bool Yes

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

defaults write com.apple.Dock appswitcher-all-displays -bool true

# Spacers
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'; killall Dock
# defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'; killall Dock

mkdir  ~/Documents/Screenshots
defaults write com.apple.screencapture location ~/Documents/Screenshots

killall Dock
