#!/bin/sh

source utils.sh
[[ -e vars.sh ]] && source vars.sh

# Variables
###########
ZSHRC_CONFIG_FILE="${ZSHRC_CONFIG_FILE:-"${ZDOTDIR-$HOME}/.zshrc"}"
BREW_PREFIX="${BREW_PREFIX:-"/opt/homebrew"}"

# Development tool versions
JAVA_VERSION="${JAVA_VERSION:-"latest:openjdk-22"}"
NODE_VERSION="${NODE_VERSION:-"latest:20"}"
PYTHON_VERSION="${PYTHON_VERSION:-"3.12.3"}"
RUST_VERSION="${RUST_VERSION:-"1.78.0"}"
###########

configure_zsh() {
  local ZSH_CONFIG_START_COMMENT="# ZSH_CONFIG - START"
  local ZSH_CONFIG_END_COMMENT="# ZSH_CONFIG - END"

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Configuring .zshrc"
  if grep -q -e "${ZSH_CONFIG_START_COMMENT}" -e "${ZSH_CONFIG_END_COMMENT}" "${ZSHRC_CONFIG_FILE}"; then
    warn "ZSH configurations already exist. Skipping..."
  else
    cat <<EOF >> "${ZSHRC_CONFIG_FILE}"

${ZSH_CONFIG_START_COMMENT}
# ZSH base configurations
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey '\t'      complete-word       # tab          | complete
bindkey '^[[Z'    autosuggest-accept  # shift + tab  | autosuggest

HISTFILE=\$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# ZSH aliases
alias cls="printf '\033[3J' && clear"
alias timestamp="date +%s"
${ZSH_CONFIG_END_COMMENT}
EOF
  fi
}

install_eza() {
  info "Installing eza"
  brew install eza
  modify_oneline_config 'alias ll="eza -la"' "${ZSHRC_CONFIG_FILE}"
}

install_atuin() {
  info "Installing atuin"
  brew install atuin
  modify_oneline_config 'eval "$(atuin init zsh --disable-up-arrow)"' "${ZSHRC_CONFIG_FILE}"
}

install_starship() {
  info "Installing starship"
  brew install starship
  modify_oneline_config 'eval "$(starship init zsh)"' "${ZSHRC_CONFIG_FILE}"
}

install_lazygit() {
  info "Installing lazygit"
  brew install lazygit
  modify_oneline_config 'alias lg="lazygit"' "${ZSHRC_CONFIG_FILE}"
}

install_asdf() {
  info "Installing asdf"
  brew install asdf
  . ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Installing asdf"
  modify_oneline_config '. ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh' "${ZSHRC_CONFIG_FILE}"
}

install_jdk() {
  local JAVA_VERSION=$1
  info "Installing JDK ${JAVA_VERSION}"
  asdf plugin-add java https://github.com/halcyon/asdf-java.git
  asdf install java "${JAVA_VERSION}"
  asdf global java "${JAVA_VERSION}"

  local ASDF_JAVA_CONFIG_START_COMMENT="# ASDF_JAVA_CONFIG - START"
  local ASDF_JAVA_CONFIG_END_COMMENT="# ASDF_JAVA_CONFIG - END"

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Installing JDK"
  modify_oneline_config '. ~/.asdf/plugins/java/set-java-home.zsh' "${ZSHRC_CONFIG_FILE}"
}

install_node() {
  local NODE_VERSION=$1
  info "Installing NodeJS ${NODE_VERSION}"
  asdf plugin-add nodejs
  asdf install nodejs "${NODE_VERSION}"
  asdf global nodejs "${NODE_VERSION}"
}

install_python() {
  local PYTHON_VERSION=$1
  info "Installing Python ${PYTHON_VERSION}"
  asdf plugin-add python
  asdf install python "${PYTHON_VERSION}"
  asdf global python "${PYTHON_VERSION}"

  local ASDF_PYTHON_CONFIG_START_COMMENT="# ASDF_PYTHON_CONFIG - START"
  local ASDF_PYTHON_CONFIG_END_COMMENT="# ASDF_PYTHON_CONFIG - END"

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  if grep -q -e "${ASDF_PYTHON_CONFIG_START_COMMENT}" -e "${ASDF_PYTHON_CONFIG_END_COMMENT}" "${ZSHRC_CONFIG_FILE}"; then
    warn "asdf Python configurations already exist. Skipping..."
  else
    cat <<EOF >> "${ZSHRC_CONFIG_FILE}"

${ASDF_PYTHON_CONFIG_START_COMMENT}
export PYTHON_VERSION=$PYTHON_VERSION
export PYTHON_PATH=\$HOME/.asdf/installs/python/\$PYTHON_VERSION
export PATH=\$PYTHON_PATH/bin:\$PATH
${ASDF_PYTHON_CONFIG_END_COMMENT}
EOF
  fi
}

install_rust() {
  local RUST_VERSION=$1
  info "Installing Rust ${RUST_VERSION}"
  asdf plugin-add rust https://github.com/asdf-community/asdf-rust.git
  RUST_WITHOUT=rust-docs asdf install rust "${RUST_VERSION}"
  asdf global rust "${RUST_VERSION}"
}

configure_macos_preferences() {
  info "Configuring macOS preferences"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  defaults write com.apple.dock scroll-to-open -bool TRUE; killall Dock
}

main() {
  configure_zsh

  install_eza
  install_atuin
  install_starship
  install_lazygit

  install_asdf
  install_jdk "${JAVA_VERSION}"
  install_python "${PYTHON_VERSION}"
  install_node "${NODE_VERSION}"
  install_rust "${RUST_VERSION}"

  configure_macos_preferences
}

# BEGIN

# Set the trap to call the cleanup function on Ctrl+C
trap quit INT

main "$@"
