#!/usr/bin/env bash

# https://shapeshed.com/vim-tmux-alacritty-theme-switcher

set -e

CURRENT_MODE=$(gsettings get org.gnome.desktop.interface color-scheme)
OLD=${CURRENT_MODE#"'prefer-"}
OLD=${OLD%"'"}
NEW=$( [ "$OLD" = "dark" ] && echo "light" || echo "dark" )

echo "Setting to $NEW mode"
gsettings set org.gnome.desktop.interface color-scheme "prefer-$NEW"
sed -i --follow-symlinks "s/_$OLD.toml/_$NEW.toml/" ~/.alacritty.toml
sed -i --follow-symlinks "s/set background=$OLD/set background=$NEW/" ~/.vimrc
tmux list-panes -a -F '#{pane_id} #{pane_current_command}' |
  grep vim |
  cut -d ' ' -f 1 |
  xargs -I PANE tmux send-keys -t PANE ESCAPE ":set background=$NEW" ENTER
