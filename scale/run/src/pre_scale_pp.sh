#!/bin/bash
#===============================================================================
#
#  Script to prepare the directory of SCALE topo creation.
#  October 2014  created,  Guo-Yuan Lien
#
#===============================================================================

. config.main

if (($# < 5)); then
  cat >&2 << EOF

[pre_scale_pp.sh] Prepare a temporary directory for scale-les_pp run.

Usage: $0 MYRANK STIME TMPDIR EXECDIR DATADIR

  MYRANK   My rank number (not used)
  STIME    Start time (format: YYYYMMDDHHMMSS)
  TMPDIR   Temporary directory to run scale-les_pp
  EXECDIR  Directory of SCALE executable files
  DATADIR  Directory of SCALE data files

EOF
  exit 1
fi

MYRANK="$1"; shift
STIME="$1"; shift
TMPDIR="$1"; shift
EXECDIR="$1"; shift
DATADIR="$1"

S_YYYY=${STIME:0:4}
S_MM=${STIME:4:2}
S_DD=${STIME:6:2}
S_HH=${STIME:8:2}
S_II=${STIME:10:2}
S_SS=${STIME:12:2}

#===============================================================================

mkdir -p $TMPDIR
rm -fr $TMPDIR/*

CONVERT_TOPO='.false.'
if [ "$TOPO_FORMAT" != 'prep' ]; then
#  ln -fs $DATADIR/topo/${TOPO_FORMAT}/Products $TMPDIR/input_topo
  CONVERT_TOPO='.true.'
fi

CONVERT_LANDUSE='.false.'
if [ "$LANDUSE_FORMAT" != 'prep' ]; then
#  ln -fs $DATADIR/landuse/${LANDUSE_FORMAT}/Products $TMPDIR/input_landuse
  CONVERT_LANDUSE='.true.'
fi

#===============================================================================

TMPSUBDIR=$(basename "$(cd "$TMPDIR" && pwd)")

cat $TMPDAT/conf/config.nml.scale_pp | \
    sed -e "/!--IO_LOG_BASENAME--/a IO_LOG_BASENAME = \"${TMPSUBDIR}\/pp_LOG\"," \
        -e "/!--TOPO_OUT_BASENAME--/a TOPO_OUT_BASENAME = \"${TMPSUBDIR}\/topo\"," \
        -e "/!--LANDUSE_OUT_BASENAME--/a LANDUSE_OUT_BASENAME = \"${TMPSUBDIR}\/landuse\"," \
        -e "/!--TIME_STARTDATE--/a TIME_STARTDATE = $S_YYYY, $S_MM, $S_DD, $S_HH, $S_II, $S_SS," \
        -e "/!--CONVERT_TOPO--/a CONVERT_TOPO = $CONVERT_TOPO," \
        -e "/!--CONVERT_LANDUSE--/a CONVERT_LANDUSE = $CONVERT_LANDUSE," \
        -e "/!--CNVTOPO_name--/a CNVTOPO_name = '$TOPO_FORMAT'," \
        -e "/!--CNVLANDUSE_name--/a CNVLANDUSE_name = '$LANDUSE_FORMAT'," \
    > $TMPDIR/pp.conf

#===============================================================================

exit 0
