#!/bin/sh

! [ -x "$(command -v brew)" ] && (echo "Installing brew" && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
! [ -x "$(command -v task)" ] && (echo "Installing task" && brew install go-task)
[ ! -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && (echo "Installing zsh-autosuggestions" && brew install zsh-autosuggestions)
