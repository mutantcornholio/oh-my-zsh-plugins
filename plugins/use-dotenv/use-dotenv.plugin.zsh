#!/usr/bin/env zsh

# Filename of the dotenv file to look for
: ${ZSH_DOTENV_FILE:=.env}

declare -A ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV
declare -A ZSH_USE_DOTENV_PLUGIN_ENV_DIFF

ZSH_USE_DOTENV_PLUGIN_PROMPT=""
ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME=

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

restore_env() {
  env | while read line; do
    IFS='§' read key value <<< "${line/=/§}"

    if [[ "${ZSH_USE_DOTENV_PLUGIN_ENV_DIFF[$key]}" == "${value}" ]]; then
      if [[ -z "${ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]}" ]]; then
        unset $key
      else
        export "${key}"=ZSH_USE_DOTENV_PLUGIN_ORIGINAL_ENV[$key]
      fi
    fi
  done

  ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME=
}

do_source() {
  setopt localoptions allexport
  ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME="$(stat -c %Y "$ZSH_DOTENV_FILE")"
  source $ZSH_DOTENV_FILE
}

handle_precmd() {
  if [[ ! -f "$PWD/$ZSH_DOTENV_FILE" ]]; then
    return
  fi

  local new_mtime="$(stat -c %Y "$ZSH_DOTENV_FILE")"
  if [ "$new_mtime" != "$ZSH_USE_DOTENV_PLUGIN_DOTENV_MTIME" ]; then
    restore_env
    do_source
  fi
}

handle_chpwd() {
  if [[ "$OLDPWD" == "$PWD" && -z $1 ]]; then
    return
  fi

  if [[ -f "$OLDPWD/$ZSH_DOTENV_FILE" ]]; then
    restore_env
    ZSH_USE_DOTENV_PLUGIN_PROMPT=""
  fi

  if [[ -f "$PWD/$ZSH_DOTENV_FILE" ]]; then
    capture_env
    do_source
    capture_diff
    ZSH_USE_DOTENV_PLUGIN_PROMPT="(${ZSH_DOTENV_FILE} ✓)"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd handle_chpwd
add-zsh-hook precmd handle_precmd
add-zsh-hook preexec handle_precmd

handle_chpwd true
