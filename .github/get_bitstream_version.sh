#!/bin/bash
# echo ${$(gdd if=default_720p-2.bit skip=$(($( echo $(env LANG=LC_ALL ggrep -a -b -o -P "\x30\x01\xA0\x01" $1) | gcut -d: -f1)+4)) bs=1 count=8 2>&- | strings)%?}
OFFSET=$(env LANG=LC_ALL grep -a -b -o -P "\x30\x01\xA0\x01" $1 | cut -d: -f1)
DIRTY_VERSION=$(dd if=$1 skip=$(($OFFSET+4)) bs=1 count=8 2>&- | strings)
echo ${DIRTY_VERSION%?}
