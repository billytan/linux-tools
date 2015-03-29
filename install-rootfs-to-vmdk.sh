#!/bin/bash

BASE_DIR=$(pwd)

#
# where we are ...
#
TOPDIR=$BASE_DIR/working/openbricks
[ -d $TOPDIR/build/build.i386.eglibc/rootfs ] || exit 1

#
# ensure that the following packages are installed: qemu-utils, mksh, kpartx
#
[ -e /usr/bin/qemu-img ] || exit 1
[ -e /bin/mksh ] || exit 1
[ -e /sbin/kpartx ] || exit 1

#
# by default, the disk image size in bytes. Optional suffixes "k" or "K" (kilobyte, 1024) "M" (megabyte, 1024k) 
# and "G" (gigabyte, 1024M) and T (terabyte, 1024G) are supported.  "b" is ignored.
#
VMSIZE=100M

VM_FILE=$1

[ "x$VM_FILE" == "x" ] && VM_FILE=./testfile.vmdk

qemu-img create -f raw $VM_FILE $VMSIZE

echo 4 66 | /bin/mksh $BASE_DIR/bootgrub.mksh -A | dd of=$VM_FILE conv=notrunc

#
# clear the partition table
#
dd if=/dev/zero bs=1 conv=notrunc count=64 seek=446 of=$VM_FILE

#
# -s	never prompts for user intervention
#
# mkpart part-type [fs-type] start end
#
parted -s $VM_FILE 'mkpart primary ext4 2M -1'

#
# mount all the partitions in a raw disk image; This will output lines such as:
#	add map loop0p1 (252:2): 0 200704 linear /dev/loop0 4096
#
RESULT=$(kpartx -av $VM_FILE)

[ -z "$RESULT" ] && exit 1

echo RESULT: $RESULT

#
# /dev/loop1
#
LOOP_DEV=$(echo "$RESULT" | sed 's/.* linear //; s/ [[:digit:]]*//')

BLOCK_DEV=$(echo "$RESULT" | sed -e 's/.* (\(.*:.*\)).*/\1/')

LOOP_PART=$(echo "${RESULT##add map }" | sed 's/ .*//')

echo LOOP_PART: $LOOP_PART

#
# /dev/mapper/loop1p1
#
VM_PART="/dev/mapper/$LOOP_PART"

#
# BLKRRPART: Invalid argument
#
blockdev --rereadpt $LOOP_DEV  >/dev/null 2>&1 || true

sfdisk -l $LOOP_DEV

#
# then create the ext4 file system
#
/sbin/mkfs.ext4 $VM_PART

/sbin/tune2fs -c0 -i0 $VM_PART

#
# mount it, and copy the root file system
#
mount -o rw,suid,dev $VM_PART /mnt

#
# finally, copy the rootfs, 174MB
#
# -P	never follow symbolic links in SOURCE
# -R	copy directories recursively
#

# cp -PR $TOPDIR/build/build.i386.eglibc/rootfs/* /mnt

#
# cleanup ...
#
umount /mnt

kpartx -d $VM_FILE

#
# FIXME: unmount the loop device
#
# 	kpartx -d $VM_FILE
#
cat > $BASE_DIR/cleanup.sh <<EOF
#!/bin/sh

kpartx -d $VM_FILE

EOF

chmod +x $BASE_DIR/cleanup.sh




