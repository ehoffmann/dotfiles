#!/usr/bin/env bash

# Link dotfiles to ~
ln -sf ~/code/dotfiles/gitignore ~/.gitignore
ln -sf ~/code/dotfiles/gitconfig ~/.gitconfig
ln -snf ~/code/dotfiles/tmuxinator ~/.tmuxinator
ln -sf ~/code/dotfiles/rubocop.yml ~/.rubocop.yml
ln -sf ~/code/dotfiles/tigrc ~/.tigrc
ln -sf ~/code/dotfiles/tmux.conf ~/.tmux.conf
ln -sf ~/code/dotfiles/vimrc ~/.vimrc
ln -snf ~/code/dotfiles/vim_snippets ~/.vim/snippets
ln -sf ~/code/dotfiles/zshrc ~/.zshrc
ln -sf ~/code/dotfiles/alacritty.toml ~/.alacritty.toml
ln -sf ~/code/dotfiles/ehoffmann.zsh-theme ~/.oh-my-zsh/themes/ehoffmann.zsh-theme
mkdir -p ~/.config/git/hooks
ln -sf ~/code/dotfiles/git_hooks/prepare-commit-msg ~/.config/git/hooks/prepare-commit-msg

# Bin
mkdir -p ~/bin
ln -sf ~/code/dotfiles/bin/sixtify.rb ~/bin/sixtify
ln -sf ~/code/dotfiles/bin/backup-deploy.rb ~/bin/backup-deploy
ln -sf ~/code/dotfiles/bin/backup.sh ~/bin/backup
ln -sf ~/code/dotfiles/bin/changelog.rb ~/bin/changelog
ln -sf ~/code/dotfiles/bin/s3.rb ~/bin/s3
ln -sf ~/work/scripts/pdef.sh ~/bin/pdef
