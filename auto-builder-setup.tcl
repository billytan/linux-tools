#
# auto-builder-setup.tcl
#
# supposed to be involed in a shell script
#

source common.tcl

source DebianAutoBuilder.tcl

set ACTION		[lindex $argv 0]
if { $ACTION == "" } exit


#
# auto-builder-setup.tcl initialize $topdir $args
#
if { $ACTION == "initialize" } {

	set top_dir			[lindex $argv 1]
	
	set builder			[eval [list DebianAutoBuilder new $top_dir] $args ]
	
	$builder install_required_packages

	$builder create_chroot_image
}


if { $ACTION == "keygen" } {




}






