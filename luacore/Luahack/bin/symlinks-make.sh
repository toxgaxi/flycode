#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

if [ -d ~/Library/InputManagers/Luahack ]; then
    rm -rf ~/Library/InputManagers/Luahack
fi

#ln -s 

mkdir ~/Library/InputManagers/Luahack

cd ~/Library/InputManagers/Luahack

ln -s $SRC_HOME/Info .

ln -s $SRC_HOME/build/Debug/Luahack.bundle .