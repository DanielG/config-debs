#!/bin/bash

for p in $(dirname $0)/../dxld-*-config; do
    (
	echo Building $p
	cd $p
	dpkg-buildpackage
    )
done
