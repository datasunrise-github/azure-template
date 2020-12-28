#!/bin/bash

INST_CAPT="DS "

logSeparator() {
  echo -ne "# -------------------------------------------------------------------------------\n"
}

log() {
  echo -ne "$INST_CAPT: $@\n"
}

logBeginAct() {
  logSeparator
  log $@
}

logEndAct() {
  log $@
  logSeparator
}
