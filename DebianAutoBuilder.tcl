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
			set suite			"jessie"
		}
		
		set base_dir			[file normalize [file dirname [info script]]]

		eval my __init $args
	}

	method __init { args } {

		if ![file exists "$topdir/logs" ] { file mkdir "$topdir/logs" }
		
		set chroot_dir		[file join $topdir "${suite}-${build_arch}-sbuild"]
		
		if ![file exists $chroot_dir] { file mkdir $chroot_dir }

		#
		# MUST RUN as root
		#
		catch { exec /usr/bin/id -u } user_id
		
		if { $user_id != 0 } { return -code error "root privilleges required" }
		
		my install_required_packages
	}
	
	method create_chroot_image { args } {
	
		catch {
			exec /usr/sbin/debootstrap --no-check-gpg --include="apt" --variant=buildd $suite $chroot_dir $mirror_url /usr/share/debootstrap/scripts/$suite
		} result
		
		@file $result >> $topdir/logs/deboostrap.log
		
		my chroot $base_dir/init-chroot.sh

	}

	method chroot { script_file args } {
	
	
	
	}
	
	
	method chroot_exec { script args } {
	
		set _name		[getopt $args "--name=%s"]
		if { $_name == "" } { set _name		"my-script.sh" }
		
		@file $script >> $chroot_dir/tmp/$_name
	
		exec /bin/chmod +x $chroot_dir/tmp/$_name
		
		#
		# setup chroot env
		#
		set _script	{
#!/bin/sh

		/bin/mount -t proc proc $chroot_dir/proc
		/bin/mount -t sysfs sysfs $chroot_dir/sys
		
		/bin/mount --bind /dev $chroot_dir/dev
		/bin/mount --bind /dev/pts $chroot_dir/dev/pts
		
		/usr/sbin/chroot $chroot_dir /tmp/$_name 
		
		/bin/umount $chroot_dir/dev/pts
		/bin/umount $chroot_dir/dev
		/bin/umount $chroot_dir/sys
		/bin/umount $chroot_dir/proc
		}
		
		set _script			[subst -nocommands -nobackslashes $_script]
		
		@file $_script >> $topdir/chroot_exec.sh
		
		catch {
			exec /bin/sh $topdir/chroot_exec.sh
		} result
		
		return $result
	}
	
	
	#
	# debootstrap, sbuild, and others
	#
	method install_required_packages { args } {



	}
}

