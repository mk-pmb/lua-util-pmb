#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
#
#   A probably-unreliable ersatz for luacheck, in case
#   the latter can't be used for whatever reason.


function find_globals () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly

  local -A CFG=(
    [expect_no_globals]=+
    [ignored_globals]="$LUA_IGNORED_GLOBALS"'
      _G
      _VERSION
      assert
      bit32
      collectgarbage
      coroutine
      debug
      dofile
      error
      getmetatable
      io
      ipairs
      load
      loadfile
      loadstring
      math
      module
      next
      os
      package
      pairs
      pcall
      print
      rawequal
      rawget
      rawlen
      rawset
      require
      select
      setmetatable
      string
      table
      tonumber
      tostring
      type
      unpack
      xpcall
      '
    )
  local REPO_TOP="$(git rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$REPO_TOP" ] && REPO_TOP+='/.'
  local FILES_TODO=(
    /etc
    "${XDG_CONFIG_DIR:-$HOME/.config}"
    "$REPO_TOP"
    .
    )
  local ITEM=
  for ITEM in "${FILES_TODO[@]}"; do
    [ -n "$ITEM" ] || continue
    ITEM+="lua/$FUNCNAME.rc"
    [ -f "$ITEM" ] || continue
    source -- "$ITEM" || return $?
  done

  FILES_TODO=()
  local FILES_CHECKED=0
  local FILES_WITH_GLOBALS=()
  while [ "$#" -ge 1 ]; do
    ITEM="$1"; shift
    case "$ITEM" in
      --allow-stray-globals ) CFG[expect_no_globals]=;;
      --scan ) scan_files || return $?;;
      -- ) FILES_TODO+=( "$@" ); break;;
      -* ) echo "E: unsupported option: $ITEM" >&2; return 2;;
      * ) FILES_TODO+=( "$ITEM" );;
    esac
  done

  for ITEM in "${FILES_TODO[@]}"; do
    check_one_file "$ITEM" || return $?
  done

  sleep 0.2s
  if [ -n "${CFG[expect_no_globals]}" ]; then
    ITEM="${#FILES_WITH_GLOBALS[@]}"
    if [ "$ITEM" == 0 ]; then
      echo "I: Good: None of $FILES_CHECKED files used implicit globals."
    else
      echo "E: Found globals in $ITEM files: ${FILES_WITH_GLOBALS[*]}" >&2
      return 4
    fi
  fi
}


function check_one_file () {
  (( FILES_CHECKED += 1 ))
  local SRC="$1"
  local IGN="${CFG[ignored_globals]}"
  IGN=" ${IGN//[$'\n\t']/ } "
  local REPORT=
  REPORT="$(luac -l -l -p -- "$SRC")" || return $?$(
    echo "E: luac failed to parse $SRC" >&2)
  local FOUND=()
  readarray -t FOUND < <(<<<"$REPORT" sed -nrf <(echo '
    s~^\t[0-9]+\t\[([0-9]+)\]\t([GS]ETTABUP)\s+[0-9 -]+\s*; _ENV "(\S+|$\
      )".*$~\3 \1~p
    ') | sort --version-sort)
  REPORT=
  local KEY= LN= PREV= ACCUM= HAD_ANY=
  for LN in "${FOUND[@]}" ''; do
    KEY="${LN% *}"
    LN="${LN##* }"
    if [ "$KEY" == "$PREV" ]; then
      ACCUM+=",$LN"
    else
      if [ -z "$PREV" ] || [[ "$IGN" == *" $PREV "* ]]; then
        true  # no-op
      else
        echo "${ACCUM##,*}"$'\t'"$SRC"$'\t'"$PREV"$'\t'"$ACCUM"
        HAD_ANY=+
      fi
      [ -z "$LN" ] || ACCUM="$LN"
      PREV="$KEY"
    fi
  done > >(sort --version-sort | cut -f 2-)
  wait
  [ -z "$HAD_ANY" ] || FILES_WITH_GLOBALS+=( "$SRC" )
}


function scan_files () {
  local ADD=()
  readarray -t ADD < <(
    find -type f -name '*.lua' | sort --unique --version-sort)
  [ -z "${ADD[0]}" ] || FILES_TODO+=( "${ADD[@]}" )
}




find_globals "$@"; exit $?
