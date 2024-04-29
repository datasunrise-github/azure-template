#!/bin/bash

INST_CAPT="$(hostname): "

logTimestamp() {
  local CURR_TS=`date "+%T.%6N"`
  echo -ne "$CURR_TS "
}

logSeparator() {
  logTimestamp
  echo -ne "# -------------------------------------------------------------------------------\n"
}

log() {
  logTimestamp
  echo -ne "$INST_CAPT: $@\n" | tee -a $PREP_LOG
}

logBeginAct() {
  logSeparator
  log "$@"
}

logEndAct() {
  log "$@"
  logSeparator
}
