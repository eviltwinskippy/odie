###
# Package to deliver fossil repositories on the web
# Piggybacks off of CGI handling, with some policies percular
# to fossil
###

package provide httpd::fossil 1.1

package require httpd::cgi

# Register a fossil directory.
# This causes the server to pass off httpd request to the fossil binaries

proc ::Fossil_Directory {virtual {directory {}}} {

    # Set up the URL-directory mapping so that DocAccessHook works right.

    if {[string length $directory] == 0} {
	set directory [Doc_Virtual {} {} $virtual]
    }
    Doc_RegisterRoot $virtual $directory

    # Register the domain - not in a thread becaused we'll use another process anyway.
    # The CGI module will also read the post data itself so TclHttpd doesn't buffer
    # it all in memory before passing it to the CGI process.

    Url_PrefixInstall $virtual [list Fossil_Domain $virtual $directory] \
	-thread 0 -readpost 0
}


# Fossil_Domain is called from Url_Dispatch for URLs inside fossil directories.

proc ::Fossil_Domain {virtual directory sock suffix} {
    global Fossil env

    # Check the path and then find the part beyond the program name.
    # The trimleft avoids a buildup of extra / after the domain prefix.

    if {[catch {Url_PathCheck [string trimleft $suffix /]} pathlist]} {
	Doc_NotFound $sock
	return
    }

    # url is the logical name as viewed by a browser
    # path is a physical file system name as viewd by the server

    set url [string trimright $virtual /]
    set repo {}
    set path $directory
    set i 0
    set which [lindex $pathlist 0]
    if { $which eq "index" } {
      ::Fossil_Index $virtual $directory $sock $suffix
      return
    }
    foreach component [lindex $pathlist 0] {
	incr i
	set path [file join $path $component]
	append url /$component
        set found 0
        foreach ext {{} .fos .fossil} {
          if {[file isfile $path$ext]} {
	    # Don't bother testing execute permission here,
	    # because it doens't test right on windows anyway.
            set repo  $path$ext
	    set extra [lrange $pathlist $i end]
            set found 1
	    break
          }
        }
	if {!$found} { 
	    Doc_NotFound $sock
	    return
	}
    }
    if {![info exists extra]} {
	# Didn't find an executable file
	Httpd_Error $sock 403
	return
    } elseif {[llength $extra]} {
	set extra /[join $extra /]
    }
    ###
    # Build a CGI script for fossil to boot through
    ###
    set cgiscript [file rootname $repo].cgi
    if {![file exists $cgiscript]} {
      set exe {}
      set fout [open $cgiscript w]
      foreach path {
	/usr/bin
	/usr/local/bin
	/opt/local/bin
	~/bin
      } {
	if {[file exists $path/fossil]}  {
	  set exe [file normalize $path]/fossil
        }
      }
      puts $fout "#!$exe"
      puts $fout "repository: $repo"
      puts $fout ""
      close $fout
      exec chmod +x $cgiscript
    }

    # The CGI needs the server-relative url of the script,
    # the extra part after the program name,
    # and the translated version of the whole pathname.

    Url_Handle [list CgiHandle $url $extra [list $cgiscript]] $sock
}

###
# Build an index of the fossil repositories here
###
proc ::Fossil_Index {virtual directory sock suffix} {
  set files [glob -nocomplain $directory/*]
  if { $files eq {} } {
    Httpd_ReturnData $sock text/html {
<HTML>
<BODY>
No fossil repos here.
</BODY>
</HTML>
    }
  }
  set result {
<HTML>
<BODY>
<UL>
  }
  foreach file [lsort -dictionary $files] {
    if {[file extension $file] ni {.fos .fossil}} continue
    set fname [file tail $file]  
    append result "<LI><a href=\"$virtual/[file rootname $fname]\">[file rootname $fname]</a></LI>"
  }
  append result {
</UL>
</BODY>
</HTML>
  }
  Httpd_ReturnData $sock text/html $result
}
