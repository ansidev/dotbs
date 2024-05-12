#!/bin/sh

source utils.sh
[[ -e vars.sh ]] && source vars.sh

# Variables
###########
ZSHRC_CONFIG_FILE="${ZSHRC_CONFIG_FILE:-"${HOME}/.zshrc"}"
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

configure_gpg() {
  local GPG_CONFIG_DIR="${HOME}/.gnupg"
  local GPG_CONFIG_FILE="${GPG_CONFIG_DIR}/gpg.conf"
  local GPG_AGENT_CONFIG_FILE="${GPG_CONFIG_DIR}/gpg-agent.conf"
  info "Configuring GPG"
  brew install gnupg pinentry-mac

  ensure_dir_exists "${GPG_CONFIG_DIR}"
  ensure_file_exists "${GPG_CONFIG_FILE}"
  ensure_file_exists "${GPG_AGENT_CONFIG_FILE}"

  modify_oneline_config 'use-agent' "${GPG_CONFIG_FILE}"

  modify_oneline_config "pinentry-program ${BREW_PREFIX}/bin/pinentry" "${GPG_AGENT_CONFIG_FILE}"
  modify_oneline_config 'default-cache-ttl 34560000' "${GPG_AGENT_CONFIG_FILE}"
  modify_oneline_config 'max-cache-ttl 34560000' "${GPG_AGENT_CONFIG_FILE}"

  local GPG_CONFIG_START_COMMENT="# GPG_CONFIG - START"
  local GPG_CONFIG_END_COMMENT="# GPG_CONFIG - END"
  if grep -q -e "${GPG_CONFIG_START_COMMENT}" -e "${GPG_CONFIG_END_COMMENT}" "${ZSHRC_CONFIG_FILE}"; then
    warn "GPG configurations already exist. Skipping..."
  else
    cat <<EOF >> "${ZSHRC_CONFIG_FILE}"

${GPG_CONFIG_START_COMMENT}
export GPG_TTY=\$(tty)
gpgconf --launch gpg-agent
${GPG_CONFIG_END_COMMENT}
EOF
  fi
}

configure_eza() {
  info "Configuring eza"
  brew install eza
  modify_oneline_config 'alias ll="eza -la"' "${ZSHRC_CONFIG_FILE}"
}

configure_atuin() {
  info "Configuring atuin"
  brew install atuin
  modify_oneline_config 'eval "$(atuin init zsh --disable-up-arrow)"' "${ZSHRC_CONFIG_FILE}"
}

configure_starship() {
  info "Configuring starship"
  brew install starship
  modify_oneline_config 'eval "$(starship init zsh)"' "${ZSHRC_CONFIG_FILE}"
}

configure_lazygit() {
  info "Configuring lazygit"
  brew install lazygit
  modify_oneline_config 'alias lg="lazygit"' "${ZSHRC_CONFIG_FILE}"
}

configure_asdf() {
  info "Configuring asdf"
  brew install asdf
  . ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh

  local ASDF_CONFIG_START_COMMENT="# ASDF_CONFIG - START"
  local ASDF_CONFIG_END_COMMENT="# ASDF_CONFIG - END"

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Configuring asdf"
  modify_oneline_config '. ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh' "${ZSHRC_CONFIG_FILE}"
}

configure_jdk() {
  local JAVA_VERSION=$1
  info "Configuring JDK ${JAVA_VERSION}"
  asdf plugin-add java https://github.com/halcyon/asdf-java.git
  asdf install java "${JAVA_VERSION}"
  asdf global java "${JAVA_VERSION}"

  local ASDF_JAVA_CONFIG_START_COMMENT="# ASDF_JAVA_CONFIG - START"
  local ASDF_JAVA_CONFIG_END_COMMENT="# ASDF_JAVA_CONFIG - END"

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Configuring JDK"
  modify_oneline_config '. ~/.asdf/plugins/java/set-java-home.zsh' "${ZSHRC_CONFIG_FILE}"
}

configure_node() {
  local NODE_VERSION=$1
  info "Configuring NodeJS ${NODE_VERSION}"
  asdf plugin-add nodejs
  asdf install nodejs "${NODE_VERSION}"
  asdf global nodejs "${NODE_VERSION}"
}

configure_python() {
  local PYTHON_VERSION=$1
  info "Configuring Python ${PYTHON_VERSION}"
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

configure_rust() {
  local RUST_VERSION=$1
  info "Configuring Rust ${RUST_VERSION}"
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
  configure_gpg

  # configure_eza
  # configure_atuin
  # configure_starship
  # configure_lazygit

  # configure_asdf
  # configure_jdk "${JAVA_VERSION}"
  # configure_python "${PYTHON_VERSION}"
  # configure_node "${NODE_VERSION}"
  # configure_rust "${RUST_VERSION}"

  # configure_macos_preferences
}

# BEGIN

# Set the trap to call the cleanup function on Ctrl+C
trap quit INT

main "$@"
