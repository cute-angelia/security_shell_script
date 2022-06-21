#!/bin/bash

if [ $# -eq 0 ]; then
    echo -n "filename> "
    read filename
else
    filename=$1
fi

if [ ! -f "$filename" ]; then
    echo "No such file: $filename"
    exit $?
fi

case $filename in
    *.tar)      tar xvf $filename;;
    *.tar.bz2)  tar xvjf $filename;;
    *.tbz)      tar xvjf $filename;;
    *.tbz2)     tar xvjf $filename;;
    *.tgz)      tar xvzf $filename;;
    *.tar.gz)   tar xvzf $filename;;
    *.gz)       gunzip -v $filename;;
    *.bz2)      bunzip2 -v $filename;;
    *.zip)      unzip -v $filename;;
    *.Z)        uncompress -v $filename;;
    *)          echo "No extract option for $filename"
esac