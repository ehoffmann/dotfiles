#!/usr/bin/env bash

# Link dotfiles to ~
ln -s ~/dotfiles/gitignore ~/.gitignore
ln -s ~/dotfiles/gitconfig ~/.gitconfig
ln -s ~/dotfiles/tmuxinator ~/.tmuxinator
ln -s ~/dotfiles/rubocop.yml ~/.rubocop.yml
ln -s ~/dotfiles/spaceshiprc.zsh ~/.spaceshiprc.zsh
ln -s ~/dotfiles/tigrc ~/.tigrc
ln -s ~/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/vimrc ~/.vimrc
ln -s ~/dotfiles/vim_snippets ~/.vim/snippets
ln -s ~/dotfiles/zshrc ~/.zshrc
ln -s ~/dotfiles/alacritty.yml ~/.alacritty.yml
mkdir -p ~/bin
ln -s ~/dotfiles/bin/sixtify.rb ~/bin/sixtify
ln -s ~/dotfiles/bin/backup-deploy.rb ~/bin/backup-deploy
ln -s ~/dotfiles/bin/changelog.rb ~/bin/changelog
ln -s ~/dotfiles/bin/s3.rb ~/bin/s3
