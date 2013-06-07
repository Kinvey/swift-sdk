#!/bin/sh

#if [ $# -lt 1 ]
#then
#	echo "Usage: ./pullsample.sh gitloc"
#	exit
#fi 


##a
mkdir samples
cd samples
##


#gitloc="$1"
sample="TestDrive-iOS"
gitloc="git@github.com:KinveyApps/${sample}.git"

#clone the project
if [ ! -d $sample ]
then
    cloneCMD="git clone ${gitloc}"
    $cloneCMD
    cd $sample
else
    echo "${sample} already created, updating"
    cd $sample
    git pull
fi

#replace KinveyKit with latest
# -- need to have done release-kinvey first
#if [ ! -d KinveyKit.framework ]
#then
#  echo "no kinvey kit"
#  exit 1
#fi

rm -rf KinveyKit.framework
cp -r ../../out/KinveyKit.framework .

xcodebuild clean
xcodebuild -sdk iphonesimulator6.1  GCC_TREAT_WARNINGS_AS_ERRORS=YES

# check status
STATUS=$?
echo "Build Status: $STATUS"
if [ $STATUS -ne 0 ]
then
echo "exit, error"
exit 1
fi


