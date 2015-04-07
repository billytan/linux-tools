#!/bin/bash

#
# DO NOT USE THIS SCRIPT ....
#
#   Use "sbuild-update --keygen" instead;
#

#
# "Not enough random bytes available"
#
# while true ; do cat /proc/sys/kernel/random/entropy_avail ; sudo find / > /tmp/find.log ; sync ; done
#
gpg --batch --gen-key --cert-digest-algo SHA256 --status-fd 3 3>/tmp/keygen.log <<EOT
%echo Generating key for Debian auto-builder box ...
Key-Type: RSA
Key-Usage: sign
Key-Length: 4096
Name-Real: auto-builder autosigning key 
Name-Email: debian_developer_name@debian.org
Expire-Date: 365d
%commit
EOT


#
# gpg --output buildd_key_pub.gpg --armor --export 2BCC55B8
#
# gpg --output buildd_key_sec.gpg --armor --export-secret-keys 2BCC55B8
#

