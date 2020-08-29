#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
#
#   A probably-unreliable ersatz for luacheck, in case
#   the latter can't be used for whatever reason.


function find_globals () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly

  local -A CFG=(
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

  for ITEM in "$@"; do
    case "$ITEM" in
      -* ) echo "E: unsupported option: $ITEM" >&2; return 2;;
      * ) check_one_file "$ITEM" || return $?;;
    esac
  done
}


function check_one_file () {
  local SRC="$1"
  local IGN="${CFG[ignored_globals]}"
  IGN=" ${IGN//[$'\n\t']/ } "
  local FOUND=()
  readarray -t FOUND < <(luac -l -l -p -- "$SRC" | sed -nrf <(echo '
    s~^\t[0-9]+\t\[([0-9]+)\]\t([GS]ETTABUP)\s+[0-9 -]+\s*; _ENV "(\S+|$\
      )".*$~\3 \1~p
    ') | sort --version-sort)
  local KEY= LN= PREV= ACCUM=
  for LN in "${FOUND[@]}" ''; do
    KEY="${LN% *}"
    LN="${LN##* }"
    if [ "$KEY" == "$PREV" ]; then
      ACCUM+=",$LN"
    else
      [ -z "$PREV" ] || [[ "$IGN" == *" $PREV "* ]] \
        || echo "${ACCUM##,*}"$'\t'"$SRC"$'\t'"$PREV"$'\t'"$ACCUM"
      ACCUM="$LN"
      PREV="$KEY"
    fi
  done | sort --version-sort | cut -f 2-
}




find_globals "$@"; exit $?
