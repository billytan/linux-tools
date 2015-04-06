#
# DebianAutoBuilder-tests.tcl
#

source common.tcl

source DebianAutoBuilder.tcl

set base_dir			[file normalize [file dirname [info script]]]

set builder		[DebianAutoBuilder new $base_dir --arch amd64 ]

if 1 {

	# $builder install_required_packages
	$builder initialize
}

if 0 {

	$builder create_chroot_image

}

if 0 { 

	$builder keygen "no_such_name@noip.com"
}







