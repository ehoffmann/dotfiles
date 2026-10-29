#!/usr/bin/env bash
ln -sbf ~/code/dotfiles/gitignore ~/.gitignore
ln -sbf ~/code/dotfiles/gitconfig ~/.gitconfig
ln -sbnf ~/code/dotfiles/tmuxinator ~/.tmuxinator
ln -sbf ~/code/dotfiles/rubocop.yml ~/.rubocop.yml
ln -sbf ~/code/dotfiles/tigrc ~/.tigrc
ln -sbf ~/code/dotfiles/tmux.conf ~/.tmux.conf
mkdir -p ~/.vim
ln -sbf ~/code/dotfiles/vimrc ~/.vimrc
# vimrc adds vim/ (including snippets) and vim/after/ to runtimepath.
mkdir -p ~/.zsh
ln -sbf ~/code/dotfiles/zshrc ~/.zshrc
ln -sbf ~/code/dotfiles/profile ~/.profile
ln -sbf ~/code/dotfiles/zsh/aliases.zsh ~/.zsh/aliases.zsh
ln -sbf ~/code/dotfiles/zsh/functions.zsh ~/.zsh/functions.zsh
ln -sbf ~/code/dotfiles/zsh/prompt.zsh ~/.zsh/prompt.zsh
ln -sbf ~/code/dotfiles/alacritty.toml ~/.alacritty.toml
mkdir -p ~/.config/git/hooks
ln -sbf ~/code/dotfiles/git_hooks/prepare-commit-msg ~/.config/git/hooks/prepare-commit-msg
ln -sbf ~/code/dotfiles/gdbinit ~/.gdbinit
ln -sbf ~/code/dotfiles/inputrc ~/.inputrc
