#!/bin/sh

## TODO: TARGET_dir -> cfg_pkg_name and use that in the template instead of
## $cfg_prefix-$package-config!!

set -e

usage () {
    echo "Usage: $(basename $0) [OPTIONS...] PREFIX-PKG-config [DISTRIBUTION]">&2
    echo "Options:">&2
    echo "\t-f, --force">&2
    echo "\t\tDon't look up Priority/Section.">&2
}

parse_args () {
    OPTS=$(getopt -o hf --long help,force -n "$(basename $0)" -- "$@")
    eval set -- "$OPTS"

    while true ; do
	case "$1" in
	    -h|--help)     usage; exit; ;;
            -f|--force)    OPT_FORCE=1; shift ;;

            --) shift; break ;;
            *) echo "Error parsing argument: $1">&2; exit 1 ;;
	esac
    done

    TARGET_dir=$1
    cfg_distro=$2
}

parse_args $@

if [ ! $TARGET_dir ]; then
    usage; exit 1
fi
if [ -e $TARGET_dir ]; then
    echo "Target $TARGET_dir already exists!" >&2
    exit 1
fi

if [ -z "$DEBEMAIL" -o -z "$DEBFULLNAME" ]; then
    echo "Please set \$DEBMAIL and \$DEBFULLNAME" >&2
    exit 1
fi

cfg_package=$(basename $1)

if [ ! $OPT_FORCE ]; then
    cfg_distro=${cfg_distro:-configs}
    cfg_prefix=${cfg_prefix:-$(basename $1 | sed -r 's/([a-zA-Z0-9]+)-(.+)-config$/\1/')}

    package=$(basename $1 | sed -r 's/([a-zA-Z0-9]+)-(.+)-config$/\2/')

    if [ ! $cfg_prefix -o ! $package ] \
	|| [ $(basename $1) == $(basename $1 | sed -r 's/-config$//') ]; then
	usage && exit 1
    fi

    if ! apt-cache show $package >/dev/null; then
	echo "Package $package not found" >&2
	exit 1
    fi

    pkg_prio=$(apt-cache show $package | sed -n 's/Priority: *//p' | head -n1)
    pkg_prio=${pkg_prio:-optional}

    pkg_section=$(apt-cache show $package | sed -n 's/Section: *//p' | head -n1)
    pkg_section=${pkg_section:-config-pkgs}
fi

#
# Finylly, Copy the template
#
mkdir $TARGET_dir
tar -cf - --exclude-vcs --exclude=install-template.sh -C $(dirname $0) . | ( tar -xf - -C $TARGET_dir)

#
# Apply expansions
#
apply_shell_expansion() {
    declare file="$1"
    declare data=$(< "$file")
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}

for f in $(find $1 -type f -regex ".*\.in" | grep -v $(basename $0)); do
    nf=$(echo $f | sed 's/\.in$//')
    echo Expanding $f -> $nf
    apply_shell_expansion $f > $nf
    rm $f
done
