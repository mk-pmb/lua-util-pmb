#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
#
#   A probably-unreliable ersatz for luacheck, in case
#   the latter can't be used for whatever reason.


function find_globals () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly

  local -A CFG=(
    [expect_no_globals]=+
    [ignored_globals]='
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
  local XDG_CFG="${XDG_CONFIG_DIR:-$HOME/.config}"
  local ITEM=
  for ITEM in {/etc/,"$XDG_CFG/",.}lua/"$FUNCNAME".rc; do
    [ -f "$ITEM" ] || continue
    source -- "$ITEM" || return $?
  done

  local FILES_CHECKED=0
  local FILES_WITH_GLOBALS=()
  for ITEM in "$@"; do
    case "$ITEM" in
      --allow-stray-globals ) CFG[expect_no_globals]=;;
      -* ) echo "E: unsupported option: $ITEM" >&2; return 2;;
      * ) check_one_file "$ITEM" || return $?;;
    esac
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




find_globals "$@"; exit $?
