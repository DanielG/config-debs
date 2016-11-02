#!/bin/sh

set -e

echo BUploading $1

if [ "x$2" = "x--bump" ]; then
    $(dirname $0)/bump.sh $1
fi

(
    cd $1
    debuild
    reprepro include configs \
      $(dirname $1)/../$(basename $1)_$(dpkg-parsechangelog \
	| sed -n 's/Version: \(.*\)/\1/p')_*.changes
)
