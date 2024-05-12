#!/bin/sh

# Color functions
#################
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
#################

# Utility functions
###################
is_empty() {
  VALUE=$1
  VARIABLE_NAME=$2
  ([[ -z "${VALUE}" ]] && echo "$(warn "${VARIABLE_NAME}") $(error 'is required.')" && return 1) || return 0
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

ensure_file_exists() {
  FILE=$1; [[ ! -f "${FILE}" ]] && (info "Creating empty file ${FILE}" && touch "${FILE}")
}

ensure_dir_exists() {
  DIR=$1; [[ ! -d "${DIR}" ]] && (info "Creating empty directory ${DIR}" && mkdir -p "${DIR}")
}

modify_oneline_config() {
  CONFIG=$1
  CONFIG_FILE=$2
  grep -qFx "$CONFIG" "$CONFIG_FILE" || echo "$CONFIG" >> "$CONFIG_FILE"
}
###################
