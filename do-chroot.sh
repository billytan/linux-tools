#!/bin/bash

#
# Usage:
#    do-chroot.sh  $action
#

action="$1"
[ "x$action" == "x" ] && action="chroot"


_dir=$(dirname $0)

TOPDIR=$(readlink -f $_dir)
export TOPDIR

CHROOT_DIR="$TOPDIR/jessie-amd64-sbuild"


_umount() {

	[ -d "$1" ] && umount "$1" >/dev/null 2>&1
}

do_chroot_cleanup() {

	chroot_dir="$1"

	if [ -d $chroot_dir ]; then

		_umount $chroot_dir/proc 
		_umount $chroot_dir/sys
		_umount $chroot_dir/dev/pts 
		_umount $chroot_dir/dev 

		_umount $chroot_dir/build 
	fi
}


do_chroot_setup() {

	chroot_dir="$1"

	mount -t proc proc $chroot_dir/proc
	mount -t sysfs sysfs $chroot_dir/sys

	mount --bind /dev $chroot_dir/dev
	mount --bind /dev/pts $chroot_dir/dev/pts

	#
	# $build_dir
	#
	mkdir -p $chroot_dir/build
	mount --bind $TOPDIR/build_jessie_amd64 $chroot_dir/build
}


if [ "$action" == "chroot" ]; then

	do_chroot_setup $CHROOT_DIR

	echo "DO NOT FORGET: export LANG=C; export LC_ALL=C"
	chroot $CHROOT_DIR
	
	do_chroot_cleanup $CHROOT_DIR

	exit
fi

if [ "$action" == "cleanup" ]; then

	do_chroot_cleanup $CHROOT_DIR
	
	exit
fi

# NO_DEP_CHECK="-d"

if [ "$action" == "build" ]; then

	dsc_file="$2"
	
	test ! -f $TOPDIR/build_jessie_amd64/$dsc_file && exit

	cat > $CHROOT_DIR/tmp/build.sh  <<EOF
#!/bin/sh

export LANG=C; export LC_ALL=C

cd /build

dpkg-source -x $dsc_file

pkgname=${dsc_file%%_*}

cd "\${pkgname}-"*

apt-get update
apt-get -y --no-install-recommends build-dep \$pkgname

dpkg-checkbuilddeps

DEB_BUILD_OPTIONS="nocheck parallel=2" dpkg-buildpackage -B $NO_DEP_CHECK -uc -us

EOF
	
	do_chroot_setup $CHROOT_DIR
	
	chroot $CHROOT_DIR /bin/sh /tmp/build.sh

	do_chroot_cleanup $CHROOT_DIR
	
	exit
fi


