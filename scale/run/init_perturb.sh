#!/bin/bash
#===============================================================================
#
#  Prepare an initial ensemble by perturbing an initial condition.
#  August  2014,              Guo-Yuan Lien
#  October 2014, modified,    Guo-Yuan Lien
#
#-------------------------------------------------------------------------------
#
#
#  Usage:
#    init_perturb [STIME S_PATH]
#
#  STIME   Initial time of the ensemble (format: YYYYMMDDHHMMSS)
#  S_PATH  Source of the initial condition including the basename.
#
#  Use settings:
#    config.all
#    config.fcst (optional)
#
#===============================================================================

cd "$(dirname "$0")"
myname=$(basename "$0")
myname1=${myname%.*}

#===============================================================================
# Configuration

. config.all
(($? != 0)) && exit $?

. src/func_datetime.sh
. src/func_init.sh
. src/func_util.sh

#-------------------------------------------------------------------------------

USAGE="
[$myname] Prepare an initial ensemble by perturbing an initial condition.

Usage: $myname [STIME S_PATH]

  STIME   Initial time of the ensemble (format: YYYYMMDDHHMMSS)
  S_PATH  Source of the initial condition including the basename.
"

#-------------------------------------------------------------------------------

if [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
  echo "$USAGE"
  exit 0
fi
if (($# < 2)); then
  echo "$USAGE" >&2
  exit 1
fi

STIME=$(datetime $1)
S_PATH="$2"

#-------------------------------------------------------------------------------

tmppert="$TMPS/perturb"

if [ ! -s "$S_PATH$(printf $SCALE_SFX 0)" ]; then
  echo "[Error] $0: Cannot find scale file '$S_PATH$(printf $SCALE_SFX 0)'" >&2
  exit 1
fi

#===============================================================================

echo
echo "Prepare output directory..."

create_outdir

#===============================================================================

echo
echo "Prepare initial members..."

safe_init_tmpdir $TMPS
cd $TMPS

S_basename="$(basename $S_PATH)"
for m in $(seq $MEMBER); do
  mem=$(printf $MEMBER_FMT $m)
  echo "  member $mem"

  cp -f $S_PATH*.nc .
  $PYTHON $SCRP_DIR/python/init_perturb.py $S_basename
  (($? != 0)) && exit $?

  q=0
  while [ -s "$S_basename$(printf $SCALE_SFX $q)" ]; do
    mv -f "$S_basename$(printf $SCALE_SFX $q)" $OUTDIR/anal/${mem}/$STIME$(printf $SCALE_SFX $q)
  q=$((q+1))
  done
done

safe_rm_tmpdir $TMPS

#===============================================================================

echo

exit 0
