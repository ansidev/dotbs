#!/bin/sh

source utils.sh
[[ -e vars.sh ]] && source vars.sh

# Variables
###########
ZSHRC_CONFIG_FILE="${ZSHRC_CONFIG_FILE:-"${ZDOTDIR-$HOME}/.zshrc"}"
BREW_PREFIX="${BREW_PREFIX:-"/opt/homebrew"}"

# Development tool versions
GO_VERSION="${GO_VERSION:-"latest"}"
JAVA_VERSION="${JAVA_VERSION:-"corretto-11.0.23.9.1"}"
MVND_VERSION="${MVND_VERSION:-"1.0-m8-m39"}"
NODE_VERSION="${NODE_VERSION:-"20.13.1"}"
PNPM_VERSION="${PNPM_VERSION:-"latest"}"
PYTHON_VERSION="${PYTHON_VERSION:-"latest"}"
RUST_VERSION="${RUST_VERSION:-"1.78.0"}"
NEOVIM_VERSION="${NEOVIM_VERSION:-"stable"}"
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

# deprecated
install_asdf() {
  info "Installing asdf"
  brew install asdf
  . ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  info "Installing asdf"
  modify_oneline_config '. ${BREW_PREFIX}/opt/asdf/libexec/asdf.sh' "${ZSHRC_CONFIG_FILE}"
}

install_mise() {
  info "Configuring mise"
  brew install mise
  mise use -g usage
  mise completion zsh > ${BREW_PREFIX}/share/zsh-completions/_mise
  mise activate zsh

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  modify_oneline_config 'eval "$(mise activate zsh)"' "${ZSHRC_CONFIG_FILE}"
}

install_go() {
  local GO_VERSION=$1
  local GOPATH="${HOME}/.go"

  info "Installing Go ${GO_VERSION}"

  mise use -g "go@${GO_VERSION}"
  ensure_dir_exists "${GOPATH}"
  go env -w GOPATH="${GOPATH}"

  local MISE_GO_CONFIG_START_COMMENT="# MISE_GO_CONFIG - START"
  local MISE_GO_CONFIG_END_COMMENT="# MISE_GO_CONFIG - END"
  local MISE_GO_CONFIG=$(cat <<EOF
export GOPATH="\${HOME}/.go"
export PATH="\${GOPATH}/bin:\${PATH}"
EOF
)

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  modify_multiline_config "${MISE_GO_CONFIG_START_COMMENT}" "${MISE_GO_CONFIG_END_COMMENT}" "${MISE_GO_CONFIG}" "${ZSHRC_CONFIG_FILE}"
}

install_jdk() {
  local JAVA_VERSION=$1
  info "Installing JDK ${JAVA_VERSION}"
  mise plugins install java https://github.com/halcyon/asdf-java --force
  mise use -g "java@${JAVA_VERSION}"
}

install_mvnd() {
  local MVND_VERSION=$1
  info "Installing mvnd ${MVND_VERSION}"
  mise plugins install mvnd https://github.com/joschi/asdf-mvnd --force
  mise use -g "mvnd@${MVND_VERSION}"
}

install_node() {
  local NODE_VERSION=$1
  info "Installing NodeJS ${NODE_VERSION}"
  mise use -g "nodejs@${NODE_VERSION}"
}

install_pnpm() {
  local PNPM_VERSION=$1
  info "Installing pnpm ${PNPM_VERSION}"
  mise plugins install pnpm https://github.com/jonathanmorley/asdf-pnpm --force
  mise use -g "pnpm@${PNPM_VERSION}"
}

install_python() {
  local MISE_PYTHON_VERSION=$1
  info "Installing Python ${PYTHON_VERSION}"
  mise use -g "python@${PYTHON_VERSION}"

  local PYTHON_VERSION=$(python -V | cut -d' ' -f2)
  local PYTHON_PATH=$([ "${MISE_PYTHON_VERSION}" != "${PYTHON_VERSION}" ] && echo "\${HOME}/.local/share/mise/installs/python/${MISE_PYTHON_VERSION}" || echo "\${HOME}/.local/share/mise/installs/python/\${PYTHON_VERSION}")
  local MISE_PYTHON_CONFIG_START_COMMENT="# MISE_PYTHON_CONFIG - START"
  local MISE_PYTHON_CONFIG_END_COMMENT="# MISE_PYTHON_CONFIG - END"
  local MISE_PYTHON_CONFIG=$(cat <<EOF
export PYTHON_VERSION=${PYTHON_VERSION}
export PYTHON_PATH=${PYTHON_PATH}
export PATH=\$PYTHON_PATH/bin:\$PATH
EOF
)

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  modify_multiline_config "${MISE_PYTHON_CONFIG_START_COMMENT}" "${MISE_PYTHON_CONFIG_END_COMMENT}" "${MISE_PYTHON_CONFIG}" "${ZSHRC_CONFIG_FILE}"
}

install_rust() {
  local RUST_VERSION=$1
  info "Installing Rust ${RUST_VERSION}"
  mise plugins install rust https://github.com/code-lever/asdf-rust --force
  RUST_WITHOUT=rust-docs mise use -g "rust@${RUST_VERSION}"
}

install_neovim() {
  local NEOVIM_VERSION=$1
  info "Installing NeoVim ${NEOVIM_VERSION}"
  mise plugins install neovim https://github.com/richin13/asdf-neovim --force
  mise use -g "neovim@${NEOVIM_VERSION}"
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

  install_mise
  install_go "${GO_VERSION}"
  install_jdk "${JAVA_VERSION}"
  install_mvnd "${MVND_VERSION}"
  install_python "${PYTHON_VERSION}"
  install_node "${NODE_VERSION}"
  install_pnpm "${PNPM_VERSION}"
  install_rust "${RUST_VERSION}"

  install_neovim "${NEOVIM_VERSION}"

  configure_macos_preferences
  info "Done."
}

# BEGIN

# Set the trap to call the cleanup function on Ctrl+C
trap quit INT

main "$@"
