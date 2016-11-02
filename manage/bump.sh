#!/bin/sh

[ ! $1 ] && ( echo "Usage: bump.sh package"; exit 1 )

(cd $1 && dch --force-distribution -D configs -u low)
