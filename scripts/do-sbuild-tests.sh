#!/bin/sh

_dir=`dirname $0`

DSC_FILE="wget_1.16-1.dsc"

cd $_dir/build_jessie_amd64

sbuild --chroot=jessie-amd64-sbuild $DSC_DILE

