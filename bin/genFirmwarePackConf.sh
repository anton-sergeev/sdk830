#!/bin/bash


addToFWNAME() {
		FWNAME=${FWNAME}${1:+.$1}
}

CUR_DIR=$(dirname $0)
UPDATE_DIR=$PRJROOT/src/update
OUTDIR=$BUILDROOT/firmware
COMPDIR=$BUILDROOT/comps
SCRIPT_PATH=$PRJROOT/src/update/scripts


source $CUR_DIR/../etc/checkEnvs.sh
source $PRJROOT/etc/vcs.sh
pushd $PRJROOT 1>/dev/null

get_ver="git svn info"
if ! $get_ver &> /dev/null; then
	get_ver="svn info"
	if ! $get_ver &> /dev/null; then
		get_ver="echo Last Changed Rev: 0"
	fi
fi

if [ ! "$UPD_CONFIG" ]; then
	UPD_CONFIG=dev
#	UPD_CONFIG=rel
fi
#echo "UPD_CONFIG=\"$UPD_CONFIG\""

upd_config_rev=0
if [ "$UPD_CONFIG" = "dev" ]; then
	ALWAYSUPDATE=1
	if [ ! -e $UPDATE_DIR/.development_revision ]; then
		echo "1" > $UPDATE_DIR/.development_revision
	fi
	upd_config_rev=`cat $UPDATE_DIR/.development_revision`
else if [ "$UPD_CONFIG" = "rel" ]; then
	ALWAYSUPDATE=0
	upd_config_rev=`cat $UPDATE_DIR/.release_revision`
else
	echo "Firmware configuration setted not properly UPD_CONFIG=\"$UPD_CONFIG\", should be dev/rel"
	popd
	exit 1
fi
fi
UPD_CONFIG_REV=`printf %04d $upd_config_rev`
SYSID=02-001-1-00-00.01
DATE=`date +'%Y%m%d%H%M'`
DATE_READABLE=`date +'%Y-%m-%d %H:%M:%S'`
HOSTNAME=`uname -n`
SYSREV_PKG=${DATE#??}

KERNELVER=0
ROOTFSVER=0
USERFSVER=0
STBMAINAPPVER=0
FIRMWAREVER=0

STB830_vcs_get_version src/linux src/initramfs src/elecard/updater
KERNELVER=$Return_Val
KERNELVER_GIT=$Return_Val2
echo "KERNELVER_GIT=$KERNELVER_GIT"

STB830_vcs_get_version src/rootfs src/apps src/modules src/elecard/stapisdk src/elecard/updater
ROOTFSVER=$Return_Val
ROOTFSVER_GIT=$Return_Val2
echo "ROOTFSVER_GIT=$ROOTFSVER_GIT"

STB830_vcs_get_version $PRJROOT/src/apps/StbMainApp
STBMAINAPPVER=$Return_Val
STBMAINAPPVER_GIT=$Return_Val2
echo "STBMAINAPPVER_GIT=$STBMAINAPPVER_GIT"

STB830_vcs_get_version $PRJROOT
FIRMWAREVER=$Return_Val
FIRMWAREVER_GIT=$Return_Val2
echo "FIRMWAREVER_GIT=$FIRMWAREVER_GIT"


BRANCH=`git branch 2>/dev/null | grep '^\* *' | sed 's/\* //'`
#LANG=ENG
LANG=

if [ -n "$BUILD_SCRIPT_FW" ]; then
	COMPONENTS=script
fi
if [ "$BUILD_WITHOUT_COMPONENTS_FW" != "1" ]; then
	if [ -n "$COMPONENTS" ]; then
		COMPONENTS=${COMPONENTS}_
	fi
	COMPONENTS=${COMPONENTS}comps
fi


#FWNAME=STB830.$UPD_CONFIG.rev$UPD_CONFIG_REV.$DATE.${BRANCH}svn${FIRMWAREVER}.${LANG}${HOSTNAME}${COMPONENTS}${COMMENT}
FWNAME=STB830
addToFWNAME $UPD_CONFIG
addToFWNAME rev$UPD_CONFIG_REV
addToFWNAME $DATE
addToFWNAME $BRANCH
#addToFWNAME $FIRMWAREVER
addToFWNAME $LANG
addToFWNAME $HOSTNAME
addToFWNAME $COMPONENTS
addToFWNAME $SHORT_COMMENT



export ALWAYSUPDATE SYSID SYSREV_PKG FWNAME OUTDIR COMPDIR KERNELVER ROOTFSVER USERFSVER BUILD_SCRIPT_FW BUILD_WITHOUT_COMPONENTS_FW
$PRJROOT/bin/prjfilter $PRJROOT/etc/stb830.conf.in $COMPDIR/stb830_efp.conf

printEnv() {
	if [ -n "${!1}" ]; then
		echo "$1=${!1}" >> ${descFile}
	else
		echo "#$1" >> ${descFile}
	fi
}

# Create description file
descFile=$COMPDIR/firmwareDesc
echo "#Elecard STB Firmware Update Pack" > ${descFile}
echo "#Firmware pack name:       " $FWNAME >> ${descFile}
echo "#Firmware Pack Ver(date):  " $SYSREV_PKG >> ${descFile}
echo "#System id:                " $SYSID >> ${descFile}
echo "#Build configuration:      " $UPD_CONFIG >> ${descFile}
echo "#Always Update Flag:       " $ALWAYSUPDATE >> ${descFile}

echo "#STAPISDK version:         " $STAPISDK_VERSION >> ${descFile}
# echo "#Build Host: "              $HOSTNAME >> ${descFile}
# echo "#Output Standard:"        $STANDARD >> ${descFile}
# echo "#Default System Serial:"  $SYSSER >> ${descFile}
# echo "#Default MAC Address:"    $SYSMAC >> ${descFile}
echo -e "\n\n" >> ${descFile}
printEnv HOSTNAME
printEnv DATE_READABLE

if [ -n "$BUILD_SCRIPT_FW" ]; then
	echo "#Script:" >> ${descFile}
	printEnv BUILD_SCRIPT_FW
fi

if [ "$BUILD_WITHOUT_COMPONENTS_FW" != "1" ]; then
	echo "#Components:" >> ${descFile}
	printEnv KERNELVER_GIT
	printEnv ROOTFSVER_GIT
	printEnv STBMAINAPPVER_GIT
	printEnv FIRMWAREVER_GIT
	printEnv KERNELVER
	printEnv ROOTFSVER
	printEnv USERFSVER
	printEnv STBMAINAPPVER
	printEnv FIRMWAREVER
	printEnv ENABLE_VIDIMAX
	# echo "#Signatures:"             `ls $UPDATER_DIR/certificates` >> ${descFile}
	#echo "ENABLE_VERIMATRIX="         $ENABLE_VERIMATRIX >> ${descFile}
	#echo "ENABLE_SECUREMEDIA="        $ENABLE_SECUREMEDIA >> ${descFile}
fi



#create script tgz
if [ -n "$BUILD_SCRIPT_FW" ]; then
	rm -f $COMPDIR/script.tgz
	pushd $SCRIPT_PATH/$BUILD_SCRIPT_FW
	tar -czf $COMPDIR/script.tgz ./*
	popd
fi


if [ "$UPD_CONFIG" = "dev" ]; then
	echo $(($upd_config_rev+1)) > $UPDATE_DIR/.development_revision
fi

popd 1>/dev/null
exit 0