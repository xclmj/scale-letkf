#!/bin/bash
#===============================================================================
#
#  Script to post-process the LETKF outputs.
#  December 2014  created,  Guo-Yuan Lien
#
#===============================================================================

. config.main

if (($# < 4)); then
  cat >&2 << EOF

[post_letkf.sh]

Usage: $0 MYRANK ATIME TMPDIR LOG_OPT

  MYRANK  My rank number (not used)
  ATIME   Analysis time (format: YYYYMMDDHHMMSS)
  TMPDIR  Temporary directory to run the program
  LOG_OPT

EOF
  exit 1
fi

MYRANK="$1"; shift
ATIME="$1"; shift
TMPDIR="$1"; shift
LOG_OPT="$1"

#===============================================================================

if ((LOG_OPT <= 4 && MYRANK == 0)); then
  if [ -f "$TMPDIR/letkf.conf" ]; then
    mv -f $TMPDIR/letkf.conf $TMPOUT/${ATIME}/log/letkf/letkf.conf
    mv -f $TMPDIR/LOG.pe000000 $TMPOUT/${ATIME}/log/letkf/LOG.pe000000
  fi
fi

#===============================================================================


# --- Parameter estimation (Tomita 2008) ----
if ((MYRANK == 0 )) && [ "$PARAM_EST" == "T" ] ; then
  if [ -e $TMPDIR/EPARAM_TOMITA_ANAL.txt ] ; then
    cp $TMPDIR/EPARAM_TOMITA_ANAL.txt ${TMPDAT}/param/EPARAM_TOMITA_ANAL${ATIME}.txt
    cp $TMPDIR/EPARAM_TOMITA_ANAL.txt ${TMPOUT}/param/EPARAM_TOMITA_ANAL${ATIME}.txt
    mv -f $TMPDIR/EPARAM_TOMITA_ANAL.txt $TMPOUT/${ATIME}/log/letkf/EPARAM_TOMITA_ANAL${ATIME}.txt
  else
    echo "[Error] No parameter analysis after DA!!"
    exit 1
  fi
fi

# -------------------------------------------

exit 0
