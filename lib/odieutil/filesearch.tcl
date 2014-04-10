### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB



#
# Suite of tools for managing file systems
#
#package require odie-objects

package provide filemanager 1.1

::namespace eval ::filemanager {}

###
# topic: c02cb216-008c-fa76-c97f-1495f33d57cc
###
proc ::filemanager::backup_files {type item} {
  #
  # File extensions to preserve
  #

  if [isTemp $type $item] {
    return result
  }

  if [isOld $type $item] {
    return result
  }

  if { $type == "directory" } {
    return stack
  }
}

###
# topic: 937a5c45-f751-5e46-1985-c6a6e404d7da
###
proc ::filemanager::cache_files {type item} {
	#
	# File extensions to preserve
	#

	if [isTemp $type $item] {
	    return result
	}

	if { $type == "directory" } {
	    # Detect Cached Thumbnail Folders
	    set fname [file tail $item]
	    foreach pattern { 
		.mappedfiles CVS Cvs
	    } {
		if {$fname == $pattern} {
		    return result
		    break
		}
	    }
	    return stack
	}
    }

###
# topic: 6153e766-fa99-73b2-3283-d02971479926
###
proc ::filemanager::copy_code_files {type item} {
  #
  # File extensions to preserve
  #
  set result {}
  if [isIgnored $type $item] {
      return {}
  }
  if { $type == "directory" } {
      lappend result stack
  }
  lappend result result
  return $result
}

###
# topic: cd188b67-03d2-d4b5-bba2-c160e0459153
###
proc ::filemanager::copy_files {type item} {
  #
  # File extensions to preserve
  #
  set result {}
  if [isTemp $type $item] {
      return {}
  }
  if { $type == "directory" } {
      lappend result stack
  }
  lappend result result
  return $result
}

###
# topic: 664dd741-ee20-7c2d-64ce-18831cf29c30
###
proc ::filemanager::dead_links {type item} {
  #
  # File extensions to preserve
  #
  if { $type == "link" } { 
      if ![file exists $item] {
      return $result
      }
  }
  if { $type == "directory" } {
      return stack
  }
}

###
# topic: 1d117a4b-f34e-ec07-f2e7-61757d1b427c
###
proc ::filemanager::goofy_files {type item} {
  #
  # File extensions to preserve
  #

  if [isGoofy $type $item] {
    return result
  }

  if { $type == "directory" } {
    return stack
  }
}

###
# topic: 4f7c4ade-8dfc-7b76-8cfd-28c1dd1abae4
# description: Detect temporary file structures
###
proc ::filemanager::isGoofy {type file} {
  set istemp 0
  set fname [file tail $file]
  if {![string is ascii $fname]} { 
      return 1
  }
  return 0
}

###
# topic: ba52bb5b-761c-0104-5769-2d72a8c9e778
###
proc ::filemanager::isIgnored {type file} {
  if [isTemp $type $file] {
    return 1
  }
  set ignored 0
  set fname [file tail $file]
  switch $type {
    file {
      # Detect Temporary/Recovery files from programs
      foreach pattern { 
          *.old *.bak *.new log* *log
      } {
        if [string match $pattern $fname] {
          set ignored 1
          break
        }
      }
    }
    directory {
      #
      # Detect temporary filesystem folders
      #
      foreach pattern { 
          cvs archive entropy *.old var proc tmp temp
          .AppleDouble .AppleDesktop .nfs* backup*
          data docs *.old2 *.tar *.gz *.zip
          deprecated
      } {
          if [string match -nocase $pattern $fname] {
          set ignored 1
          break
          }
      }
    }
  }
  return $ignored
}

###
# topic: 18f33d6d-b2d6-62ec-1f5e-3fd1404d79e1
# description: Detect temporary file structures
###
proc ::filemanager::isOld {type file} {
  set istemp 0
  set fname [file tail $file]
  if { $type ne "file"} {
    return 0
  }
  # Detect Temporary/Recovery files from programs
  foreach pattern { 
      *.old *.bak
  } {
    if [string match $pattern $fname] {
      return 1
    }
  }
  return 0
}

###
# topic: cb7a5170-fcba-b4d6-1dc1-ebda71523b65
###
proc ::filemanager::isTemp {type file} {
  set istemp 0
  set fname [file tail $file]
  switch $type {
    file {
      # Detect Unix Core Dumps
      if [string match core* $fname] {
          if { $fname == "core" } {
          set istemp 1
          }
          set ext [string range [file extension $fname] 1 end]
          if [string is integer $ext] {
          set istemp 1
          }
      }
      
      # Detect Temporary/Recovery files from programs
      foreach pattern { 
          *.rej *.save *.tmp *~ #* ~* *# .save-*
      } {
          if [string match $pattern $fname] {
          set istemp 1
          break
          }
      }
    }
    directory {
      #
      # Detect temporary filesystem folders
      #
      foreach pattern { 
          *~ #* ~* *#
      } {
          if [string match $pattern $fname] {
          set istemp 1
          break
          }
      }
      # Detect Cached Thumbnail Folders
      foreach pattern { 
          .mappedfiles
      } {
          if {$fname == $pattern} {
          set istemp 1
          break
          }
      }
    }
  }
  return $istemp
}

###
# topic: 83016aa9-a609-5aa5-2533-5ee91182569d
###
proc ::filemanager::search {seedpath cmnd resultvar {details {}}} {
  set stack $seedpath
  upvar 1 $resultvar result

  while 1 {
    set item    [pop stack]
    set donext  [llength $stack]
    
    if { $item == {} } break
    if ![file exists $item] {
      puts "$item doesn't exist?!?"
      continue
    }	 
    set type    [file type $item]
    set dispose [$cmnd $type $item]
    foreach scmnd $dispose {
      switch $scmnd {
        stack {
          set donext 1
          foreach sitem [lsort -dictionary -decreasing [glob -nocomplain -directory $item *]] {
            push stack $sitem
          }
          foreach sitem [lsort -dictionary -decreasing [glob -nocomplain -directory $item -types hidden *]] {
            if { [file tail $sitem] == "." } continue
            if { [file tail $sitem] == ".." } continue
            push stack $sitem
          }
        }
        result {
          set argl $type
          foreach detail $details {
            lappend argl [file $detail $item]
          }
          lappend result $item $argl
        }
      }
    }
  }
  return $result
}

###
# topic: 7f28b263-75d5-5306-70f9-a03c59a9ac7a
###
proc ::filemanager::tcl_files {type item} {
  #
  # File extensions to preserve
  #
  set result {}
  if [isTemp $type $item] {
    return {}
  }
  if { $type == "directory" } {
    if { [lsearch {test tests deprecated entropy} [file tail $item]] < 0 } {
      return stack
    } else {
      return {}
    }
  }

  if { [file tail $item] == "pkgIndex.tcl" }  {
    return {}
  }

  set ext [string tolower [file extension $item]]

  if { [string range [file tail $item] 0 1] == "._" } {
    return {}
  }

  if { [lsearch {.tcl .tk .itcl .itk} $ext] < 0 } {
    return {}
  }
  return result
}

###
# topic: 2e532220-901a-9857-17ea-cf1211340c15
###
proc ::filemanager::temp_files {type item} {
  #
  # File extensions to preserve
  #

  if [isTemp $type $item] {
    return result
  }

  if { $type == "directory" } {
    return stack
  }
}

###
# topic: 553d8a4d-6740-f9bb-ed25-199492f2d562
###
namespace eval ::filemanager {
    ## 
    ## Stock File System Tests
    ##

    ###
    #  Detect temporary file structures
    ###

    ###
    #  Detect parts of the file system to be
    #  ignored during syncronization of a code
    #  base
    #
    #  Test for invisible/ignored file patterns. Generally old, bak, CVS, etc
    ###


    ###
    # Recusively search a file system
    # And delete any temporary files
    ###

	
}

