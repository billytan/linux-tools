#!/bin/sh

echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/force-unsafe-io"

install_pkg() {

	apt-get install -y --force-yes --no-install-recommends "$1"
}

apt-get update

install_pkg policyrcd-script-zg2


cat > "/usr/local/sbin/policy-rc.d" << 'EOF'
#!/bin/sh

# policy-rc.d script for chroots.
# Copyright (c) 2007 Peter Palfrader <peter@palfrader.org>

while true; do
    case "$1" in
        -*)      shift ;;
        makedev) exit 0;;
        *)
            echo "Not running services in chroot."
            exit 101
            ;;
    esac
done
EOF

chmod +x "/usr/local/sbin/policy-rc.d"

install_pkg locales-all
install_pkg build-essential
install_pkg zsh less vim fakeroot devscripts gdb


cat > /etc/apt/apt.conf.d/88localrepo <<EOF

APT::Get::AllowUnauthenticated "true";
Acquire::Check-Valid-Until "false";

APT::Install-Recommends 0;
Acquire::http::Pipeline-Depth "0";
Acquire::Languages "none";
Acquire::PDiffs "false";

EOF

