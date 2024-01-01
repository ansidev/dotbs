#!/bin/sh

# Color functions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

color() { COLOR=$1; TEXT=$2; echo "${COLOR}${TEXT}${NO_COLOR}"; }

error() { color "${RED}" "${1}"; }

success() { color "${GREEN}" "${1}"; }

info() { color "${BLUE}" "${1}"; }

warn() { color "${YELLOW}" "${1}"; }

# Feature flags
FEATURE_GPG_KEY="gpg_key"
FEATURE_GITHUB_GPG_KEY="github_gpg_key"

# GPG hard coded configurations
GPG_KEY_TYPE="rsa"
GPG_KEY_LENGTH="4096"
GPG_SUBKEY_TYPE="rsa"
GPG_SUBKEY_LENGTH="4096"

# Utility functions
###################
is_empty() {
  VALUE=$1
  VARIABLE_NAME=$2
  ([[ -z "${VALUE}" ]] && echo "$(warn "${VARIABLE_NAME}") is required." && return 1) || return 0
}

is_contain() {
  local ARRAY=("$1")
  local ELEMENT=$2
  [[ " ${ARRAY[@]} " =~ " ${ELEMENT} " ]]
}

has_substr() {
  local STRING=$1
  local SUBSTRING=$2
  [[ "${STRING}" == *"${SUBSTRING}"* ]]
}
###################

# Load and set default value for some variables
load_variables() {
  [[ -e vars.sh ]] && source vars.sh
  GIT_PROVIDER="${GIT_PROVIDER:-"github"}"
  SSH_DIR="${SSH_DIR:-"${HOME}/.ssh"}"
  SSH_KEY_FILENAME="${SSH_KEY_FILENAME:-"id_ed25519"}"
  SSH_KEY_FILE="${SSH_DIR}/${SSH_KEY_FILENAME}"
  GPG_EMAIL="${GPG_EMAIL:-"${GIT_EMAIL}"}"
  GPG_EXPIRATION="${GPG_EXPIRATION:-"1y"}"
}

pre_check_variables() {
  info "Checking whether required variables are not empty"

  is_empty "${GIT_PROVIDER}" "GIT_PROVIDER"
  is_empty "${GIT_USERNAME}" "GIT_USERNAME"
  is_empty "${GIT_EMAIL}" "GIT_EMAIL"
  is_empty "${SSH_DIR}" "SSH_DIR"
  is_empty "${SSH_KEY_FILE}" "SSH_KEY_FILE"
  is_empty "${SSH_KEY_PASSPHRASE}" "SSH_KEY_PASSPHRASE"
  if [[ -z ${GPG_KEY_ID} ]]; then
    is_empty "${GPG_REAL_NAME}" "GPG_REAL_NAME"
    is_empty "${GPG_EMAIL}" "GPG_EMAIL"
    is_empty "${GPG_EXPIRATION}" "GPG_EXPIRATION"
    is_empty "${GPG_PASSPHRASE}" "GPG_PASSPHRASE"
  fi

  local EXIT_STATUS=$?
  [[ ${EXIT_STATUS} -ne 0 ]] && { echo "Pre-check: $(error "FAILED")."; exit 1; } || echo "Pre-check: $(success "OK")."
}

print_variables() {
  echo "GIT_PROVIDER: ${GIT_PROVIDER}"
  echo "GIT_USERNAME: ${GIT_USERNAME}"
  echo "GIT_EMAIL: ${GIT_EMAIL}"
  echo "SSH_DIR: ${SSH_DIR}"
  echo "SSH_KEY_FILE: ${SSH_KEY_FILE}"
  echo "SSH_KEY_PASSPHRASE: ${SSH_KEY_PASSPHRASE}"
  echo "GPG_REAL_NAME: ${GPG_REAL_NAME}"
  echo "GPG_EMAIL: ${GPG_EMAIL}"
  echo "GPG_EXPIRATION: ${GPG_EXPIRATION}"
  echo "GPG_PASSPHRASE: ${GPG_PASSPHRASE}"
}

# Function to be executed on Ctrl+C
quit() { info "Aborted, exiting..." && exit 1; }

ensure_file_exists() {
  FILE=$1; [[ ! -f "${FILE}" ]] && (info "Creating empty file ${FILE}" && touch "${FILE}")
}

configure_ssh_dir() {
  [[ ! -d "${SSH_DIR}" ]] && mkdir -p "${SSH_DIR}"
  chmod 0700 "${SSH_DIR}"
}

configure_ssh_config_files() {
  info "Set correct permissions for SSH keys"
  chmod 0600 "${SSH_DIR}/*"
  chmod 0644 "${SSH_DIR}/*.pub"

  info "Ensure SSH config files exist"
  ensure_file_exists "${SSH_DIR}/known_hosts"
  ensure_file_exists "${SSH_DIR}/config"

  info "Set correct permissions for SSH config files"
  chmod 0644 "${SSH_DIR}/known_hosts"
  chmod 0644 "${SSH_DIR}/config"

  info "Set option 'IgnoreUnknown UseKeychain' for all hosts"
  local CONFIG_START_COMMENT="# IGNORE_UNKNOWN - START"
  local CONFIG_END_COMMENT="# IGNORE_UNKNOWN - END"
  local CONFIG_FILE="${SSH_DIR}/config"
  if grep -q -e "${CONFIG_START_COMMENT}" -e "${CONFIG_END_COMMENT}" "${CONFIG_FILE}"; then
    info "IgnoreUnknown config already exists. Skipping..."
  else
    cat <<EOF >> "${CONFIG_FILE}"

${CONFIG_START_COMMENT}
Host *
  IgnoreUnknown UseKeychain
${CONFIG_END_COMMENT}
EOF
  fi
}

configure_ssh_files() {
  configure_ssh_dir
  configure_ssh_config_files
}

configure_ssh_key() {
  configure_ssh_files

  if [[ ! -f "${SSH_KEY_FILE}" ]]; then
    info "Generating SSH key"
    ssh-keygen -t ed25519 -b 8192 -C "${GIT_EMAIL}" -f "${SSH_KEY_FILE}" -N "${SSH_KEY_PASSPHRASE}"
  fi

  (! pgrep -x ssh-agent > /dev/null) && (info "Start ssh-agent in the background" && eval "$(ssh-agent -s)")

  info "Adding SSH key to ssh-agent"
  ssh-add --apple-use-keychain "${SSH_KEY_FILE}"
}

configure_github_ssh_key() {
  info "Adding SSH config for github.com"
  local CONFIG_START_COMMENT="# GITHUB_SSH_KEY - START"
  local CONFIG_END_COMMENT="# GITHUB_SSH_KEY - END"
  local CONFIG_FILE="${SSH_DIR}/config"
  if grep -q -e "${CONFIG_START_COMMENT}" -e "${CONFIG_END_COMMENT}" "${CONFIG_FILE}"; then
    echo "GitHub SSH config already exists. Skipping..."
  else
    cat <<EOF >> "${CONFIG_FILE}"

${CONFIG_START_COMMENT}
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ${SSH_KEY_FILE}
  ForwardAgent yes
${CONFIG_END_COMMENT}
EOF
  fi

  ! [[ -x "$(command -v gh)" ]] && (info "Installing GitHub CLI" && brew install gh)
  GH_AUTH_STATUS=$(gh auth status | grep 'Token scopes:')
  [[ -z "${GH_AUTH_STATUS}" ]] && (info "Logging in to GitHub CLI" && gh auth login)

  GH_AUTH_STATUS=$(gh auth status | grep 'Token scopes:')
  TOKEN_SCOPES=$(echo ${GH_AUTH_STATUS#"  - Token scopes: "})
  if ! has_substr "${TOKEN_SCOPES}" "write:public_key" && ! has_substr "${TOKEN_SCOPES}" "admin:public_key"; then
    info "Requesting API permission to upload the SSH public key"
    gh auth refresh -h github.com -s write:public_key
  fi

  info "Adding SSH key to GitHub account"
  gh ssh-key add "${SSH_KEY_FILE}.pub"

  info "Testing SSH connection"
  ssh -T git@github.com
}

configure_gpg_key() {
  ! [[ -x "$(command -v gpg)" ]] && (info "Installing GnuPG" && brew install gnupg)

  info "Generating GPG key"
  gpg --batch --full-generate-key <<EOF
  Key-Type: ${GPG_KEY_TYPE}
  Key-Length: ${GPG_KEY_LENGTH}
  Subkey-Type: ${GPG_SUBKEY_TYPE}
  Subkey-Length: ${GPG_SUBKEY_LENGTH}
  Name-Real: ${GPG_REAL_NAME}
  Name-Email: ${GPG_EMAIL}
  Expire-Date: ${GPG_EXPIRATION}
  Passphrase: ${GPG_PASSPHRASE}
  %commit
  %echo Generated GPG key successfully.
EOF
}

configure_github_gpg_key() {
  ! [[ -x "$(command -v gpg)" ]] && (info "Installing GnuPG" && brew install gnupg)

  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d '/' -f 2 | head -n 1)
  GPG_PUBLIC_KEY_FILE="/tmp/gpg_public_key_${GPG_PUBLIC_KEY_ID}.asc"

  info "Exporting the generated GPG key: ${GPG_KEY_ID}"
  GPG_EXPORT_RESULT=$(gpg --batch --yes --armor --output "${GPG_PUBLIC_KEY_FILE}" --export "${GPG_KEY_ID}" 2>&1)
  if [[ ! -z "${GPG_EXPORT_RESULT}" ]]; then
    error "Failed to export GPG public key. Please re-check whether your GPG key ID is invalid!"
    exit 1
  fi

  info "Adding GPG public key to github.com"

  ! [[ -x "$(command -v gh)" ]] && (info "Installing GitHub CLI" && brew install gh)
  GH_AUTH_STATUS=$(gh auth status | grep 'Token scopes:')
  [[ -z "${GH_AUTH_STATUS}" ]] && (info "Logging in to GitHub CLI" && gh auth login)

  GH_AUTH_STATUS=$(gh auth status | grep 'Token scopes:')
  TOKEN_SCOPES=$(echo ${GH_AUTH_STATUS#"  - Token scopes: "})
  if ! has_substr "${TOKEN_SCOPES}" "write:gpg_key" && ! has_substr "${TOKEN_SCOPES}" "admin:gpg_key"; then
    info "Requesting API permission to upload GPG key"
    gh auth refresh -h github.com -s write:gpg_key
  fi
  info "Adding GPG key to GitHub account"
  gh gpg-key add "${GPG_PUBLIC_KEY_FILE}"

  info "Configuring Git to use GPG key..."
  git config --global gpg.program gpg
  git config --global user.signingkey ${GPG_KEY_ID}
  git config --global commit.gpgSign true
}

main() {
  load_variables
  if is_contain "$@" "--check"; then
    print_variables
  fi
  pre_check_variables

  if is_contain "$@" "--check"; then
    info "Running in check mode. Exiting..."
    exit 0
  fi

  ! [[ -x "$(command -v brew)" ]] && (echo "Installing brew" && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
  grep -qFx 'eval "$(/opt/homebrew/bin/brew shellenv)"' "${HOME}/.zprofile" || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  [[ ! -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && (echo "Installing zsh-autosuggestions" && brew install zsh-autosuggestions)
  ensure_file_exists "${HOME}/.zshrc"
  grep -qFx 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' "${HOME}/.zshrc" || echo 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "${HOME}/.zshrc"

  configure_ssh_key
  if ! is_contain "${DISABLED_FEATURES}" "${FEATURE_GPG_KEY}" && [[ -z ${GPG_KEY_ID} ]]; then
    configure_gpg_key
  fi

  if [[ "${GIT_PROVIDER}" == "github" ]]; then
    configure_github_ssh_key
    if ! is_contain "${DISABLED_FEATURES}" "${FEATURE_GPG_KEY}" && ! is_contain "${DISABLED_FEATURES}" "${FEATURE_GITHUB_GPG_KEY}"; then
      configure_github_gpg_key
    fi
  fi

  info "Bootstrapping is finished. Exiting..."
}

# BEGIN

# Set the trap to call the cleanup function on Ctrl+C
trap quit INT

main "$@"
