#!/usr/bin/env sh

defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock autohide-delay -float 0

defaults write com.google.Chrome NSRequiresAquaSystemAppearance -bool Yes

killall Dock
