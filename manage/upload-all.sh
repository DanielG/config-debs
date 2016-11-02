#!/bin/sh

for p in $(dirname $0)/../*-*-config*.changes; do
    (
	echo Uploading $p
	export REPREPRO_PROMISE_WILL_RSYNC=1
	reprepro include configs $p
    )
done

~/srv/reprepro/conf/rsync-db.sh
