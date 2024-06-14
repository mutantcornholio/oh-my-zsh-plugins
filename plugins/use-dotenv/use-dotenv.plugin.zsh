#!/usr/bin/env zsh

# Filename of the dotenv file to look for
: "${ZSH_DOTENV_FILE:=.env}"

declare -A ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV
declare -A ZSH_USE_DOTENV_PLUGIN_ENV_DIFF

ZSH_USE_DOTENV_PLUGIN_PROMPT=""
ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME=
ZSH_USE_DOTENV_PLUGIN_DOTENV_ACTIVE_FILE=

## Functions
capture_env() {
  set -A ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV
  env | while read line; do
    IFS='§' read key value <<<"${line/=/§}"
    ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]="${value}"
  done
}

capture_diff() {
  set -A ZSH_USE_DOTENV_PLUGIN_ENV_DIFF
  env | while read line; do
    IFS='§' read key value <<<"${line/=/§}"

    if [[ "${ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]}" != "${value}" ]]; then
      ZSH_USE_DOTENV_PLUGIN_ENV_DIFF[$key]="${value}"
    fi
  done
}

add_env() {
  capture_env
  do_source
  capture_diff
  ZSH_USE_DOTENV_PLUGIN_PROMPT="(${ZSH_DOTENV_FILE} ✓)"
}

restore_env() {
  env | while read line; do
    IFS='§' read key value <<<"${line/=/§}"

    # Don't alter plugin's own variables
    [[ "$key" == ZSH_USE_DOTENV_PLUGIN_* ]] && continue

    # Environment variable changed its value outside of the plugin, let it live its live
    [[ "${ZSH_USE_DOTENV_PLUGIN_ENV_DIFF[$key]}" != "${value}" ]] && continue

    if [[ -z "${ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]}" ]]; then
      unset $key
    else
      export "${key}"=ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]
    fi
  done

  ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME=
  ZSH_USE_DOTENV_PLUGIN_PROMPT=""
}

get_mtime() {
  if strings "$(which stat)" | grep -q 'GNU coreutils'; then
    stat -c %Y "$1"
  else
    stat -f %m "$1"
  fi
}

do_source() {
  setopt localoptions allexport
  ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME="$(get_mtime "$ZSH_DOTENV_FILE")"
  ZSH_USE_DOTENV_PLUGIN_DOTENV_ACTIVE_FILE="$PWD/$ZSH_DOTENV_FILE"
  source $ZSH_DOTENV_FILE
}

handle_precmd() {
  if [[ -n "$ZSH_USE_DOTENV_PLUGIN_DOTENV_ACTIVE_FILE" ]]; then
    # Dotenv file was deleted/moved
    if [[ ! -f "$PWD/$ZSH_DOTENV_FILE" ]]; then
      restore_env
    # Directory change to another dir with dotenv file
    elif [[ "$ZSH_USE_DOTENV_PLUGIN_DOTENV_ACTIVE_FILE" != "$PWD/$ZSH_DOTENV_FILE" ]]; then
      restore_env
      add_env
    else
      local new_mtime="$(get_mtime "$ZSH_DOTENV_FILE")"
      if [[ "$new_mtime" != "$ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME" ]]; then
        restore_env
        add_env
      fi
    fi
  elif [[ -f "$PWD/$ZSH_DOTENV_FILE" ]]; then
    add_env
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd handle_precmd
add-zsh-hook preexec handle_precmd
