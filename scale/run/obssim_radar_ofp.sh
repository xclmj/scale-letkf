#!/bin/bash


USER=honda
SYS=ofp

#EXP=8km_sc
#. config/${EXP}/config.main.hakushu
EXP=2km_CZ2003
. config/${EXP}/config.main.$SYS

#
LETKF_RUN="$(pwd)"

#WDIR="/scratch/$(id -ng)/${USER}/obssim"
#WDIR=${TMPL}
WDIR=${LETKF_RUN}/../tmp_obssim
OBSSIM_BIN="${LETKF_RUN}/../obs/obssim"
RUNSH=$WDIR/OBSSIM.sh
RUNCONF_COMMON=$WDIR/OBSSIM.conf_common
SCALE_CONF=${LETKF_RUN}/config.nml.scale
TOPO=${OUTDIR}/const/topo


tstart='2000-01-01 0:00:00'
tend='2000-01-01 0:00:00'


#ctint=600 # obssim interval 
#tint=600 # analysis interval (Do not modify!)

ctint=300 # obssim interval 
tint=300 # analysis interval (Do not modify!)

# -- SCALE setting --
MEM_NP=${SCALE_NP}
MEM=mean
TYPE=fcst

SMEM=0 # 
EMEM=${SMEM} # mean
MEM_L=`seq ${SMEM} ${EMEM}`




#if [ ! -e ${WDIR} ] ; then
#fi

# clean up
rm -rf $WDIR
mkdir -p $WDIR


ctime="$tstart"
YYYYh=$(date -ud "$ctime" '+%Y')
MMh=$(date -ud "$ctime" '+%m')
DDh=$(date -ud "$ctime" '+%d')
HHh=$(date -ud "$ctime" '+%H')
MNh=$(date -ud "$ctime" '+%M')
SEh=$(date -ud "$ctime" '+%S')

rm -f $RUNCONF_COMMON
cat << EOF >> $RUNCONF_COMMON

&PARAM_ENSEMBLE
! MEMBER = 100,
/

&PARAM_LETKF_PRC
 NNODES = $((SCALE_NP / PPN )),
 PPN = ${PPN},
 MEM_NODES = $((SCALE_NP / PPN)),
 MEM_NP = ${SCALE_NP},
/


&PARAM_LETKF_RADAR
 USE_OBSERR_RADAR_REF = .true.
 USE_OBSERR_RADAR_VR = .true.
 RADAR_REF_THRES_DBZ = 10.0D0,
 MIN_RADAR_REF_MEMBER = 20,
 MIN_RADAR_REF_MEMBER_OBSREF = 1,
 MIN_RADAR_REF_DBZ = 10.0D0,
 LOW_REF_SHIFT = -5.0D0,
 RADAR_ZMAX = 11.0D3,
/

&PARAM_OBS_ERROR
 OBSERR_RADAR_REF = 5.0D0,
 OBSERR_RADAR_VR = 3.0D0,
/

EOF

#RAD_DAT=${WDIR}/dat/rad
#rm -rf $RAD_DAT
#cp -r ${SCALEDIR}/scale-rm/test/data/rad ${RAD_DAT}




# -- Add header for run sh --
TS=$(expr `date -ud "$tstart" '+%s'` - `date -ud "$tint" '+%s'` )
TE=$(expr `date -ud "$tend" '+%s'` - `date -ud "$tint" '+%s'` )
TS=$(expr $TS / $tint + 1 )
TE=$(expr $TE / $tint + 1 )
TLEV=$(($TE - TS + 1))
echo $TLEV
#exit
TNODE=`expr ${MEM_NP} \* $TLEV`

TNODE_CNT=0
VCODE_CNT=1

echo $RUNSH
rm -f $RUNSH
cat > $RUNSH << EOF
#!/bin/sh

#PJM -N OBSSIM
#PJM -L rscgrp=regular-flat
#PJM -L node=$((SCALE_NP/PPN))
#PJM -L elapse=00:15:00
#PJM --mpi proc=${SCALE_NP}
#PJM --omp thread=${THREADS}
#PJM -g hp150019

ulimit -s unlimited

export FORT_FMT_RECL=400

rm -f machinefile
for inode in \$(cat \$I_MPI_HYDRA_HOST_FILE); do
  for ippn in \$(seq $PPN); do
    echo "\$inode" >> machinefile
  done
done

module load hdf5/1.8.17
module load netcdf/4.4.1
module load netcdf-fortran/4.4.3
ulimit -s unlimited
export OMP_STACKSIZE=128m

EOF


#-- copy init file

ctime="$tstart"
while (($(date -ud "$ctime" '+%s') <= $(date -ud "$tend" '+%s'))); do # -- time

  YYYYh=$(date -ud "$ctime" '+%Y')
  MMh=$(date -ud "$ctime" '+%m')
  DDh=$(date -ud "$ctime" '+%d')
  HHh=$(date -ud "$ctime" '+%H')
  MNh=$(date -ud "$ctime" '+%M')
  SEh=$(date -ud "$ctime" '+%S')

  HTIME=${YYYYh}${MMh}${DDh}${HHh}${MNh}${SEh}

  for MEM in $MEM_L # MEM
  do


  if [ $MEM == 0 ] ; then
     MEM=mean
  else
     MEM=$(printf '%04d' $MEM)
  fi
  ORG_DIR=${OUTDIR}/${HTIME}/${TYPE}/${MEM}

  ONAME=${ORG_DIR}/radar_${HTIME}_${MEM}.dat

  #-- copy bin & RTTOV coef files

#  DAT_DIR=${WDIR}/dat/${EXP}/${HTIME}/${TYPE}/${MEM}
#  mkdir -p $DAT_DIR
#  echo $HTIME
#
#  if [ ! -e ${WDIR}/${OBSSIM_BIN} ] ; then 
#    cp ${OBSSIM_BIN} ${WDIR}/
#  fi
#
#  if [ ! -e ${WDIR}/out/${EXP}/${TYPE}/${MEM} ] ; then
#    mkdir -p ${WDIR}/out/${EXP}/${TYPE}
#  fi
#  if [ ! -e ${DAT_DIR} ] ; then
#    mkdir -p ${DAT_DIR}
#  fi
#
#  cp ${ORG_DIR}/history.pe*[0,1].nc ${DAT_DIR}/ &
#  cp ${ORG_DIR}/history.pe*[2,3].nc ${DAT_DIR}/ &
#  cp ${ORG_DIR}/history.pe*[4,5].nc ${DAT_DIR}/ &
#  cp ${ORG_DIR}/history.pe*[6,7].nc ${DAT_DIR}/ &
#  cp ${ORG_DIR}/history.pe*[8,9].nc ${DAT_DIR}/ 

#  echo $DAT_DIR
#  wait

  # copy common parts of obssim.conf 
  RUNCONF=${WDIR}/OBSSIM_$(printf %03d $VCODE_CNT).conf
  rm -f $RUNCONF

cat ${RUNCONF_COMMON} > ${RUNCONF}

cat << EOF >> $RUNCONF

&PARAM_OBSSIM
 OBSSIM_IN_TYPE = "history",
! OBSSIM_RESTART_IN_BASENAME = "${DAT_DIR}/init",
 OBSSIM_HISTORY_IN_BASENAME = "${ORG_DIR}/history",
 OBSSIM_TOPO_IN_BASENAME = "${WDIR}/dat/topo/topo",
 OBSSIM_TIME_START = 1,
 OBSSIM_TIME_END = 25,
 OBSSIM_GRADS_OUT_NAME = "${ONAME}",
 OBSSIM_NUM_3D_VARS = 2,
 OBSSIM_3D_VARS_LIST = 4001, 4002, !2819, 2820,
! OBSSIM_NUM_2D_VARS = 10,
! OBSSIM_2D_VARS_LIST = 8800,8800,8800,8800,8800,8800,8800,8800,8800,8800,
 OBSSIM_RADAR_LON = 100.0d3,
 OBSSIM_RADAR_LAT = 100.0d3,
 OBSSIM_RADAR_Z = 0.0d0,

/
EOF

  # Add SCALE config
  cat $SCALE_CONF >> $RUNCONF



#  echo "mpirun -n ${MEM_NP} ${WDIR}/obssim ${RUNCONF} &" >> $RUNSH
  echo "mpiexec -n ${SCALE_NP} ${LETKF_RUN}/../obs/obssim ${RUNCONF} ${WDIR}/NOUT &" >> $RUNSH

  TNODE_CNT=$(expr ${TNODE_CNT} + ${MEM_NP})   
  VCODE_CNT=$(expr ${VCODE_CNT} + 1)   


  done # -- MEM

  ctime=$(date -ud "${ctint} second $ctime" '+%Y-%m-%d %H:%M:%S')
done # -- time
echo "wait" >> $RUNSH


#sed -i -e  's/<TNODE_CNT>/'${TNODE_CNT}'/g' $RUNSH
#
#echo ${WDIR}

cd $WDIR
pjsub $RUNSH
cd -

exit


