#
# DebianAutoBuilder.tcl
#

oo::class create DebianAutoBuilder {

	#
	# MUST be located in btrfs partition
	#
	variable	topdir
	
	variable	build_arch
	
	variable	chroot_dir
	variable	chroot_name
	
	variable	build_dir
		
	variable	mirror_url
	variable	suite
	
	#
	# where my scripts is located
	#
	variable	base_dir
	
	constructor { _dir args } {

		set topdir		$_dir
		
		set build_arch		[getopt $args "--arch=%s"]
		
		if { $build_arch == "" } {
			catch { exec /usr/bin/dpkg --print-architecture } build_arch
		}
		
		if { $build_arch == "ppc64" } {
		
			set mirror_url		"http://ftp.de.debian.org/debian-ports"
			set suite			"sid"
		}
		
		if { $build_arch == "amd64" } {
		
			set mirror_url		"http://ftp.cn.debian.org/debian"
			set mirror_url		"http://192.168.1.80/debian/"
			
			set suite			"jessie"
		}
		
		#
		# where package sources are downloaded and compiled ...
		#
		set build_dir			[file join $topdir "build_${suite}_${build_arch}"]
		
		if ![file exists $build_dir] { file mkdir $build_dir }
		
		set base_dir			[file normalize [file dirname [info script]]]

		if ![file exists "$topdir/logs" ] { file mkdir "$topdir/logs" }
	
		set chroot_name		"${suite}-${build_arch}-sbuild"
	
		set chroot_dir		[file join $topdir $chroot_name ]
		
		if ![file exists $chroot_dir] { file mkdir $chroot_dir }
	}

	method initialize { args } {

		#
		# MUST RUN as root
		#
		catch { exec /usr/bin/id -u } user_id
		
		if { $user_id != 0 } { return -code error "root privilleges required" }
		
		my install_required_packages
		
		#
		# re-configure sbuild
		#
		set config_file			"/etc/sbuild/sbuild.conf"
		
		file copy -force $base_dir/sbuild.conf $config_file
	
		set subst_list			[list %ARCH% $build_arch %SUITE% $suite %CHROOT% $chroot_name %BUILD_DIR% $build_dir %LOG_DIR% $topdir/logs ]
		
		#
		# why we need this ... 
		#
		lappend subst_list %PUB_KEY% $base_dir/builder_key_pub.gpg %SEC_KEY% $base_dir/builder_key_sec.gpg
		
		@ subst $config_file $subst_list

		#
		#  E: Local archive GPG signing key not found
		#
		# file copy -force $base_dir/builder_key_pub.gpg /var/lib/sbuild/apt-keys/sbuild-key.pub
		# file copy -force $base_dir/builder_key_sec.gpg /var/lib/sbuild/apt-keys/sbuild-key.sec
		
		#
		# schroot
		#
		set _text {[${chroot_name}]
type=directory
description= Debian Jessie chroot for ppc64

directory=$chroot_dir

users=sbuild
groups=root

root-users=root,sbuild
root-groups=sbuild

#
# use the pre-defined profile, rather than a customized one
#
profile=buildd

# empty line is not allowed !!!
}
	
		set _text			[subst -nocommands -nobackslashes $_text]
		
		@file $_text >> /etc/schroot/chroot.d/$chroot_name
	
		return
	}
	
	method create_chroot_image { args } {

		if ![file exists "$chroot_dir/bin/sh" ] {
		
			@ exec /usr/sbin/debootstrap --no-check-gpg --variant=buildd $suite $chroot_dir $mirror_url /usr/share/debootstrap/scripts/$suite
		}
	
		@file "deb $mirror_url $suite main" >> $chroot_dir/etc/apt/sources.list
		
		#
		# as required by "apt-get build-dep"
		#
		@file "deb-src $mirror_url $suite main" > $chroot_dir/etc/apt/sources.list

		my chroot $base_dir/init-chroot.sh

	}

	method chroot { script_file args } {
	
		set _dir		[getopt $args "--dir=%s"]

		if { $_dir == "" } { set _dir  "/tmp" }
		
		set _fname		[file tail $script_file]
		
		file copy -force $script_file [file join "${chroot_dir}$_dir" $_fname]
		
		set _script	{
#!/bin/sh

		/bin/mount -t proc proc $chroot_dir/proc
		/bin/mount -t sysfs sysfs $chroot_dir/sys
		
		/bin/mount --bind /dev $chroot_dir/dev
		/bin/mount --bind /dev/pts $chroot_dir/dev/pts
		
		#
		# just make sure to always umount
		#
		/usr/sbin/chroot $chroot_dir $_dir/$_fname || :
		
		/bin/umount $chroot_dir/dev/pts
		/bin/umount $chroot_dir/dev
		/bin/umount $chroot_dir/sys
		/bin/umount $chroot_dir/proc
		}
		
		set _script			[subst -nocommands -nobackslashes $_script]
		
		@file $_script >> $topdir/chroot_exec.sh
		

		@ exec /bin/sh $topdir/chroot_exec.sh

	}
	
	
	method chroot_exec { script args } {
	
		set _name		[getopt $args "--name=%s"]
		if { $_name == "" } { set _name		"my-script.sh" }
		
		@file $script >> $chroot_dir/tmp/$_name
	
		exec /bin/chmod +x $chroot_dir/tmp/$_name
	

		return [my chroot $chroot_dir/tmp/$_name --dir "/tmp"]
	}
	
	
	#
	# debootstrap, sbuild, and others
	#
	method install_required_packages { args } {

		@ exec /usr/bin/apt-get -y --no-install-recommends install debootstrap sbuild

	}
	
	#
	# FIXME
	#     not work yet ...
	#
	method keygen { admin_mail args } {
	
		file mkdir $topdir/.gnupg
		
		set log_file	"$topdir/logs/keygen.log"
		
		set chan		[open "| /usr/bin/gpg --homedir $topdir/.gnupg --batch --gen-key --cert-digest-algo SHA256 --status-fd 3 3>$log_file" "w"]
	
		fconfigure $chan -translation binary -encoding binary -buffering none
		
		puts $chan "%echo Generating key for Debian auto-builder box ..."
		puts $chan "Key-Type: RSA"
		puts $chan "Key-Usage: sign"
		puts $chan "Key-Length: 4096"
		puts $chan "Name-Real: auto-builder autosigning key"
		puts $chan "Name-Email: $admin_mail"
		puts $chan "Expire-Date: 365d"
		puts $chan "%commit"
		
		flush $chan
		
		for { set i 0 } { $i < 100 } { incr i } { 
			if [eof $chan] { close $chan; break } 
			
			after 1000
		}

		catch { close $chan }
	}
	
	
	method build { pkg_name args } {
	
	
	
	}
	
	
	method build_pkg { dsc_file args } {
	
	
	
	
	}
	
}

