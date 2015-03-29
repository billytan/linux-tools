#
# compare-dir-tree.tcl
#
# only find out newly added files or directories;
#
# Usage:
#	compare-dir-tree.tcl <src-dir> <target-dir>
#



proc compare_dir_tree { src_dir dest_dir } {

	# puts "$src_dir"

	#
	# first, check if any new or updated files in $src_dir
	#
	foreach old_file [glob -dir $src_dir -types {f} -nocomplain "*"] {

		set _fname			[file tail $old_file]
		
		set pathname		[file join $dest_dir $_fname]
		
		if ![file exists $pathname] {
			show_info $old_file removed
			
			continue
		}
		
		#
		# we want to find out which files are copied and modified in the new code base ...
		#
		if { [file size $pathname] != [file size $old_file] } {
			show_info $old_file changed -path $pathname
			
			do_diff_file $pathname $old_file
			continue
		}
	}
	
	#
	# check for newly- added files
	#
	foreach fname [glob -dir $dest_dir -tails -types {f} -nocomplain "*"] {

		set pathname		[file join $src_dir $fname]
		
		if [file exists $pathname] continue
		
		show_info $pathname added -path [file join $dest_dir $fname]
	}
	
	#
	# check the sub-directories recursively
	#
	foreach dirname [glob -dir $src_dir -types {d} -tails -nocomplain "*"] {
	
		#
		# check if this is newly created 
		#
		set _dir2			[file join $dest_dir $dirname]
		
		if ![file exists $_dir2] {
			show_info $_dir2 removed
			
			continue
		}
		
		compare_dir_tree [file join $src_dir $dirname] $_dir2
	}
	
	#
	# check for newly-added directory
	#
	foreach dirname [glob -dir $dest_dir -types {d} -tails -nocomplain "*"] {	

		set _dir2			[file join $src_dir $dirname]	
	
		if [file exists $_dir2] continue
		
		show_info $_dir2 added -path [file join $dest_dir $dirname]
	}
}


proc show_info { old_file action args } {

	array set _args $args

	set j		[string length $::G(base,dir)]
	incr j
	
	set rel_path		[string range $old_file $j end]

	if {$action == "removed"} {
	
		#
		# for source code files ...
		#
		if [file isdirectory $old_file] {
			puts "--- $rel_path"
			return
		}
		
		set _n		[get_line_count $old_file]
	
		if {$_n < 0 } {
			puts [format "---             %s" $rel_path]
		} else {
			puts [format "--- +%-4d       %s" $_n $rel_path]		
			incr ::G(lines,del)	$_n
		}
		
		return
	}
	
	if {$action == "added"} {
	
		if [file isdirectory $_args(-path)] {
		
			puts "++D $rel_path"
			return
		}
		
		set _n		[get_line_count $_args(-path)]
		
		if {$_n < 0} {
			puts [format "+++             %s" $rel_path]
		} else {
			puts [format "+++ +%-4d       %s" $_n $rel_path]
			
			incr ::G(lines,add)		$_n
		}
	}
}

proc get_line_count { pathname } {

	set _ext			[file extension $pathname]

	if { [lsearch {.c .h .l} $_ext ] < 0 } {
		return -1
	}
	
	catch {
		exec /usr/bin/wc -l $pathname
	} result
	
	if [regexp {^(\d+)\s} $result _x _n] {
		return $_n
	}
	
	puts $result
	return -1
}


#
# if this one is source code, show the number of lines added or removed ...
#
proc do_diff_file { new_file old_file } {

	set _ext			[file extension $new_file]

	if { [lsearch {.c .h .l} $_ext ] < 0 } return
	
	catch {
		exec /usr/bin/diff -c --ignore-tab-expansion --ignore-all-space $old_file $new_file
	} result
	
	set lines_add			0
	set lines_del			0
	
	foreach _line [split $result "\n"] {
	
		if [regexp {^\+\s} $_line x ] {
			incr lines_add
		}
		
		if [regexp {^\-\s} $_line x ] {
			incr lines_del
		}
	}
	
	if { ($lines_add == 0) && ($lines_del == 0) } return
	
	set j		[string length $::G(base,dir)]
	incr j
	
	set rel_path		[string range $old_file $j end]
	
	#
	# just show the line ...
	#
	puts [format "... +%-4d -%-4d %s" $lines_add $lines_del $rel_path]
	
	incr ::G(lines,add)		$lines_add
	incr ::G(lines,del)		$lines_del
	
	return [list $rel_path $lines_add $lines_del]
}


foreach { src_dir target_dir } $argv break

set ::G(base,dir)		[file normalize $src_dir]

set ::G(lines,add)		0
set ::G(lines,del)		0

compare_dir_tree $src_dir $target_dir

puts [format "TOTAL: +%-5d -%-5d" $::G(lines,add) $::G(lines,del) ]






