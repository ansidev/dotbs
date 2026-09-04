#!/bin/sh

source utils.sh
[[ -e vars.sh ]] && source vars.sh

# Variables
###########
ZSHRC_CONFIG_FILE="${ZSHRC_CONFIG_FILE:-"${ZDOTDIR-$HOME}/.zshrc"}"
BREW_PREFIX="${BREW_PREFIX:-"/opt/homebrew"}"
BREW_ZSH_COMPLETIONS_DIR="${BREW_PREFIX}/share/zsh-completions"
FLUID_VIM_CONFIG_DIR_NAME="fluid-vim"
FLUID_VIM_CONFIG_DIR="${HOME}/.config/${FLUID_VIM_CONFIG_DIR_NAME}"
FLUID_VIM_USER_CONFIG_DIR="${FLUID_VIM_CONFIG_DIR}/lua/user"

# Development tool versions
GO_VERSION="${GO_VERSION:-"latest"}"
JAVA_VERSION="${JAVA_VERSION:-"corretto-11.0.24.8.1"}"
MAVEN_VERSION="${MAVEN_VERSION:-"3"}"
MVND_VERSION="${MVND_VERSION:-"1.0-m8-m39"}"
THRIFT_VERSION="${THRIFT_VERSION:-"0.20.0"}"
NODE_VERSION="${NODE_VERSION:-"20.13.1"}"
PNPM_VERSION="${PNPM_VERSION:-"latest"}"
PYTHON_VERSION="${PYTHON_VERSION:-"latest"}"
RUST_VERSION="${RUST_VERSION:-"1.78.0"}"
NEOVIM_VERSION="${NEOVIM_VERSION:-"stable"}"
###########

configure_zsh() {
  info "Configuring .zshrc"

  local ZSH_BASE_CONFIG_START_COMMENT="# ZSH_BASE_CONFIG - START"
  local ZSH_BASE_CONFIG_END_COMMENT="# ZSH_BASE_CONFIG - END"
  local ZSH_BASE_CONFIG=$(cat <<EOF
# ZSH base configurations
bindkey "^[[H"  beginning-of-line
bindkey "^[[F"  end-of-line
bindkey "^[[3~" delete-char
bindkey "\t"    complete-word       # tab          | complete
bindkey "^[[Z"  autosuggest-accept  # shift + tab  | autosuggest

HISTFILE=\${HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Brew prefix
BREW_PREFIX="$(brew --prefix)"

if type brew &>/dev/null; then
  fpath=(\${BREW_PREFIX}/share/zsh-completions \$fpath)
  autoload -Uz compinit
  compinit
fi
EOF
)

  local ZSH_ALIASES_CONFIG_START_COMMENT="# ZSH_ALIASES_CONFIG - START"
  local ZSH_ALIASES_CONFIG_END_COMMENT="# ZSH_ALIASES_CONFIG - END"
  local ZSH_ALIASES_CONFIG=$(cat <<EOF
# ZSH aliases
alias cls="printf '\033[3J' && clear"
alias timestamp="date +%s"
alias reset-display='/Applications/RDM.app/Contents/MacOS/RDM -d 0 -w 2560 -h 1440'
alias picmux="PI_TERMINAL_MUX=cmux PI_SUBAGENT_MUX=cmux pi -a '/approval-mode act'"
alias pia="pi -a '/approval-mode act'"
alias reload-zsh="source ${ZSHRC_CONFIG_FILE}"
EOF
)

  local ZSH_FUNCTIONS_CONFIG_START_COMMENT="# ZSH_FUNCTIONS_CONFIG - START"
  local ZSH_FUNCTIONS_CONFIG_END_COMMENT="# ZSH_FUNCTIONS_CONFIG - END"
  local ZSH_FUNCTIONS_CONFIG=$(cat <<EOF
# ZSH functions
function git-log-branch() {
  git log --graph --color=always --decorate --pretty=format:'Commit: %C(yellow)%H%C(reset) %nAuthor: %an <%ae>%nDate: %ad%nSigned by: %C(green)%GS%C(reset)%n%G?%n%n%C(green)%s%C(reset)%n%n%C(cyan)%b%C(reset)%n' "\$1" -- | sed -E 's/G$/Signature status: \x1b[32mvalid signature\x1b[0m/; s/B$/Signature status: \x1b[31mbad signature\x1b[0m/; s/U$/Signature status: \x1b[31muntrusted signature\x1b[0m/; s/X$/Signature status: \x1b[31mexpired signature\x1b[0m/; s/Y$/Signature status: \x1b[31mexpired key signature\x1b[0m/; s/R$/Signature status: \x1b[31mrevoked key signature\x1b[0m/; s/E$/Signature status: \x1b[31mcannot check signature\x1b[0m/; s/N$/Signature status: \x1b[31mno signature\x1b[0m/' | sed -E '/Signed by: \x1b\[32m\x1b\[m$/d' | less -R
}

function ws-new() {
  local WORKSPACE_DIR="\${1:-\$PWD}"
  herdr workspace create --cwd "\${WORKSPACE_DIR}" \${@:2}
}

function ws-list() {
  herdr workspace list | jq -r '
  .result.workspaces
  | (["#", "Label", "Status", "Focused", "Panes", "Tabs", "Workspace ID"],
     (.[] | [.number, .label, .agent_status, .focused, .pane_count, .tab_count, .workspace_id]))
  | @tsv
' | column -t -s $'\t'
}

function ws-open() {
  local WORKSPACE_DIR="\${1:-\$PWD}"
  herdr workspace create --cwd "\${WORKSPACE_DIR}" --focus
}

function ws-close() {
  local workspace_id

  workspace_id=\$(herdr workspace list |
    jq -r --arg value "\$1" '
      .result.workspaces[]
      | select(.label == \$value or .workspace_id == \$value)
      | .workspace_id
    ')

  if [[ -z "\$workspace_id" ]]; then
    echo "Workspace not found: \$1" >&2
    return 1
  fi

  herdr workspace close "\$workspace_id"
}

# Worktree management functions

wt-dir() {
  local BRANCH=\$1
  git worktree list --porcelain |
    awk -v branch="refs/heads/\$BRANCH" '
      /^worktree / { dir= substr(\$0, 10) }
      /^branch / && \$2 == branch { print dir }
    '
}

function wt-delete() {
  CURRENT_DIR=\$(basename \${PWD})
  REPO=\${2:-"\${CURRENT_DIR}"}
  BRANCH=\$1
  WORKTREE_DIR=\$(wt-dir \$BRANCH)

  echo "============================="
  echo "REPO: \$REPO"
  echo "BRANCH: \$BRANCH"
  echo "WORKTREE_DIR: \$WORKTREE_DIR"
  echo "============================="

  if [[ -n "\${WORKTREE_DIR}" ]]; then
    echo "Removing worktree"
    git worktree remove --force "\${WORKTREE_DIR}" &>/dev/null || echo "Worktree \${WORKTREE_DIR} does not exist or has already been removed."
  else
    echo "Worktree for branch \$BRANCH does not exist. Skip deletion."
  fi

  if git show-ref --verify --quiet "refs/heads/\$BRANCH"; then
    echo "Removing branch \$BRANCH..."
    git branch -D "\$BRANCH"
  else
    echo "Branch \$BRANCH does not exist. Skip deletion."
  fi

  if [[ -n "\${WORKTREE_DIR}" ]]; then
    echo "Removing worktree directory \$WORKTREE_DIR..."
    rm -rf \$WORKTREE_DIR
  else
    echo "Worktree directory \$WORKTREE_DIR does not exist. Skip deletion."
  fi

  (echo "Closing herdr workspace \$BRANCH..." && ws-close \$1)
  echo "Repo \${REPO} - Worktree \$BRANCH deleted."
}

function install-skill() {
  pnpx skills add "\$1" -g \${@:2}
}

function gh-clone() {
  local OWNER_REPO="\$1"
  local TARGET_DIR="\${2:-\$HOME/projects/oss}"

  if [[ "\$OWNER_REPO" == https://github.com/* ]]; then
    OWNER_REPO="\${OWNER_REPO#https://github.com/}"
  fi

  local REPO="\${OWNER_REPO#*/}"

  git clone https://github.com/\$OWNER_REPO \$TARGET_DIR/\$REPO
  cd \$TARGET_DIR/\$REPO
}
EOF
)

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  modify_multiline_config "${ZSH_BASE_CONFIG_START_COMMENT}" "${ZSH_BASE_CONFIG_END_COMMENT}" "${ZSH_BASE_CONFIG}" "${ZSHRC_CONFIG_FILE}"
  modify_multiline_config "${ZSH_ALIASES_CONFIG_START_COMMENT}" "${ZSH_ALIASES_CONFIG_END_COMMENT}" "${ZSH_ALIASES_CONFIG}" "${ZSHRC_CONFIG_FILE}"
  modify_multiline_config "${ZSH_FUNCTIONS_CONFIG_START_COMMENT}" "${ZSH_FUNCTIONS_CONFIG_END_COMMENT}" "${ZSH_FUNCTIONS_CONFIG}" "${ZSHRC_CONFIG_FILE}"
  info "Finished configuring .zshrc"
}

install_eza() {
  info "Installing eza"
  brew install eza
  modify_oneline_config 'alias ll="eza -la"' "${ZSHRC_CONFIG_FILE}"
}

install_atuin() {
  info "Installing atuin"
  brew install atuin
  atuin gen-completions --shell zsh --out-dir "${BREW_ZSH_COMPLETIONS_DIR}"
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
  mise completion zsh > "${BREW_ZSH_COMPLETIONS_DIR}/_mise"
  mise activate zsh

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  modify_oneline_config 'eval "$(mise activate zsh)"' "${ZSHRC_CONFIG_FILE}"
}

install_go() {
  local MISE_GO_VERSION=$1
  info "Installing Go ${MISE_GO_VERSION}"
  mise use -g "go@${MISE_GO_VERSION}"

  local GO_VERSION=$(go version | cut -d' ' -f3 | cut -c3-)
  local GOPATH=$([ "${MISE_GO_VERSION}" != "${GO_VERSION}" ] && echo "${HOME}/.local/share/mise/installs/go/${MISE_GO_VERSION}" || echo "${HOME}/.local/share/mise/installs/go/\${GO_VERSION}")
  local MISE_GO_CONFIG_START_COMMENT="# MISE_GO_CONFIG - START"
  local MISE_GO_CONFIG_END_COMMENT="# MISE_GO_CONFIG - END"
  local MISE_GO_CONFIG=$(cat <<EOF
export GO_VERSION=${GO_VERSION}
export GOPATH=${GOPATH}
export PATH="\${GOPATH}/bin:\${PATH}"
EOF
)

  ensure_file_exists "${ZSHRC_CONFIG_FILE}"

  go env -w GOPATH="${GOPATH}"
  modify_multiline_config "${MISE_GO_CONFIG_START_COMMENT}" "${MISE_GO_CONFIG_END_COMMENT}" "${MISE_GO_CONFIG}" "${ZSHRC_CONFIG_FILE}"
}

install_jdk() {
  local JAVA_VERSION=$1
  info "Installing JDK ${JAVA_VERSION}"
  mise plugins install java https://github.com/halcyon/asdf-java --force
  mise use -g "java@${JAVA_VERSION}"
}

install_maven() {
  local MAVEN_VERSION=$1
  info "Installing Maven ${MAVEN_VERSION}"
  mise plugin install maven --force
  mise use -g "maven@${MAVEN_VERSION}"
}

install_mvnd() {
  local MVND_VERSION=$1
  info "Installing mvnd ${MVND_VERSION}"
  mise plugins install mvnd https://github.com/joschi/asdf-mvnd --force
  mise use -g "mvnd@${MVND_VERSION}"
}

install_thrift() {
  local THRIFT_VERSION=$1
  info "Installing dependency tools"
  brew install automake bison libtool pkg-config
  export PATH=/opt/homebrew/Cellar/m4/1.4.19/bin:$PATH
  info "Installing Thrift ${THRIFT_VERSION}"
  mise plugins install thrift https://github.com/alisaifee/asdf-thrift --force
  mise use -g "thrift@${THRIFT_VERSION}"
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

install_fluidvim() {
  [[ ! -d "${FLUID_VIM_CONFIG_DIR}" ]] && \
    echo "Downloading FluidVim" && \
    git clone git@github.com:ansidev/fluid-vim.git "${FLUID_VIM_CONFIG_DIR}"

  [[ ! -d "${FLUID_VIM_USER_CONFIG_DIR}" ]] && \
    echo "Downloading FluidVim user configurations" && \
    git clone git@github.com:ansidev/fluid-vim-configs.git "${FLUID_VIM_USER_CONFIG_DIR}"

  modify_oneline_config "alias fvim='NVIM_APPNAME=${FLUID_VIM_CONFIG_DIR_NAME} nvim'" "${ZSHRC_CONFIG_FILE}"
}

configure_zoxide() {
  info "Installing zoxide and fzf"
  brew insta
  info "Configuring zoxide"
  modify_oneline_config 'eval "$(zoxide init zsh)"' "${ZSHRC_CONFIG_FILE}"
}

configure_macos_preferences() {
  info "Configuring macOS preferences"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
  defaults write com.apple.dock scroll-to-open -bool TRUE; killall Dock
}

###########

# Module dispatcher
run_module() {
  local module=$1
  local prefix
  echo "$module" | grep -E '^(zsh|macos)$' > /dev/null && prefix="configure" || prefix="install"
  local args=""
  case "$module" in
    go) args="$GO_VERSION" ;;
    jdk) args="$JAVA_VERSION" ;;
    maven) args="$MAVEN_VERSION" ;;
    mvnd) args="$MVND_VERSION" ;;
    thrift) args="$THRIFT_VERSION" ;;
    node) args="$NODE_VERSION" ;;
    pnpm) args="$PNPM_VERSION" ;;
    python) args="$PYTHON_VERSION" ;;
    rust) args="$RUST_VERSION" ;;
    neovim) args="$NEOVIM_VERSION" ;;
  esac
  "${prefix}_${module}" $args
}
###########
