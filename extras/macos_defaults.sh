#!/usr/bin/env sh

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -int 0
# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

defaults write com.google.Chrome NSRequiresAquaSystemAppearance -bool Yes

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

killall Dock
