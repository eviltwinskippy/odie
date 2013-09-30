::namespace eval ::document {}

::namespace eval ::wiki {}

###
# topic: 4cc1c09b-b3e2-13ba-cf31-1301388490a2
###
proc ::document::buildIndex {} {
    set count 0
variable baseDir
    foreach file [glob -nocomplain [baseDir] root *] { 
        fileCatalogue $file
    }
}

###
# topic: bf3e6757-f905-5ccf-976f-c4fc613549bd
###
proc ::document::file_fullpath path {
  return [file join [baseDir] root [string trimleft $path /]]
}

###
# topic: cd247853-08f3-6ce3-3537-ec6bf970ecce
###
proc ::document::file_url path {
  return "[baseUrl]/direct/[string trimleft $path /]"
}

###
# topic: 53500396-0460-a269-ec7b-10c16ba36c38
###
proc ::document::fileCatalogue file {
variable baseDir
    set path [::fileutil::relative [file join [baseDir] root] $file]
    #puts [list cat $path]
    set mtime [file mtime $file]
    set uuid [fileUUID $path]
    if { $uuid == {} } {
        set uuid [::uuid::uuid generate]
        fileIndex $uuid $path
    }
    if [file isdirectory $file] {
        foreach file [glob -nocomplain $file/*] {
            fileCatalogue $file
        }
    }
return $uuid
}

###
# topic: f0c9a0ab-41c4-28e5-5d66-37812df988b0
###
proc ::document::fileIndex {uuid path} {
    variable fileUUIDIndex
    dict set fileUUIDIndex $path $uuid
    variable filePATHIndex
    dict set filePATHIndex $uuid $path
}

###
# topic: 9a9f2edd-a499-74dc-c59e-2a8ad7b2fedf
###
proc ::document::fileUUID findpath {
    variable fileUUIDIndex
    if [dict exists $fileUUIDIndex $findpath] {
        return [dict get $fileUUIDIndex $findpath]
    }
    return {}
}

###
# topic: b7fba47a-c391-d0e5-a4c1-de2b1c693504
###
proc ::document::html uuid {
        variable baseUrl

	if { $uuid == {} } {
	    set uuid /
	}
	if [catch {::community urlPrelim} page] {
	    return $page
	}

        set path [uuidFILE $uuid]
        set plist {}
        set presult "<a href=[baseUrl]>top</a>"
        foreach part [split $path /] {
            lappend plist $part
            set puuid [fileUUID [join $plist /]]
            append presult "/<a href=[baseUrl]?uuid=$puuid>$part</a>"
        }
        append result "$presult" \n <P>
        set thisdir [pathinfo $uuid]

        append result "<table border=1 class=searchResult>"
        set count 0
        foreach type {parent directory file} {
            foreach {name info} [dict get $thisdir $type] {
                append result \n "<tr>[SearchResult $name [incr count] $info]</tr>"
            }
        }
        append result \n "</table>"
        if {![catch {::community::AnonymousUser 1} page]} {
          append result \n "<hr>"
          append result [upload_button $uuid]
          append result "<p><form method=post action=[baseUrl]/mkdir>Create Directory<input name=newdir><input type=hidden name=uuid value=$uuid><input type=submit name=method value=Create><form>"
        }
        return [pageout $result]
    }

###
# topic: 7d963845-1d47-5caa-d21b-041d39d0369b
###
proc ::document::html/delete uuid {
variable baseDir
    
if { $uuid == {} } {
        return [html]
}
if [catch {::community urlPrelim} page] {
    return $page
}
    if {[catch {::community::AnonymousUser 1} page]} {
      return $page
    }
if { $uuid == "/" } {
        return [html]
} else {
        set thisdir [file normalize [file join [baseDir] root [uuidFILE $uuid]]]
}
    if { $thisdir == [file join [baseDir] root] } {
        return [html]
    }
file delete -force $thisdir
    set puuid [fileUUID [file dirname [uuidFILE $uuid]]]
return [html $puuid]
}

###
# topic: 18467fd5-102c-b366-890f-4bd6deb5c968
###
proc ::document::html/mkdir {uuid newdir} {
	variable baseDir
	variable baseUrl

	if { $uuid == {} } {
	    set uuid /
	}
	if [catch {::community urlPrelim} page] {
	    return $page
	}
        if {[catch {::community::AnonymousUser 1} page]} {
          return $page
        }
	if { $uuid == "/" } {
	    set thisdir [file join [baseDir] root]
	} else {
            set thisdir [file join [baseDir] root [uuidFILE $uuid]]
	}
	file mkdir [file join $thisdir $newdir]
	return [html $uuid]
    }

###
# topic: db7d0179-c06f-66b3-dade-973ef1da6c1e
###
proc ::document::html_download {sock suffix} {
	variable baseDir
        puts [list $sock $suffix]
	if [catch {::community urlPrelim} page] {
	    Httpd_Error $sock 404
	    return
	}
	set uuid [file tail $suffix]
	if { $uuid == {} } {
	    return [html]
	}
	set fpath [uuidFILE $uuid]
        if { $fpath ne {} }
        puts [list DOWNLOAD]
	set fullpath [file_fullpath $suffix]
        puts [list $suffix $fullpath]

	if ![file exists $fullpath] {
	    Httpd_Error $sock 404
	    return
	}
	set mimetype [Mtype $fullpath]
	if { $mimetype == "text/plain" } { 
	    set mimetype application/octet-stream
	}
	#Httpd_AddHeaders $sock Content-disposition "file; filename=\"[file tail $fpath]\""
	if [catch {
	    Httpd_ReturnFile $sock $mimetype $fullpath
	} err]  {
	    Httpd_Error $sock 505
	}
    }

###
# topic: fe283a31-55fd-27e7-8aef-e30a3247c1b6
###
proc ::document::image {path geom {title {}}} {
  set cmd [::httpd config convert_cmd]
  set fullpath [::document::file_fullpath $path]
  set url [::document::file_url $path]
  set thumbpath [file rootname $path]_$geom.png
  if {[file exists [::document::file_fullpath $thumbpath]]} {
    return "<a href=\"$url\"><img src=\"[::document::file_url $thumbpath]\"></a>"
  }
  if { $cmd == {} } {
    return "<a href=\"$url\"><img src=\"$url\" width=[lindex [split $geom x] 0]></a>"
  }
  #puts [list convert $fullpath -> [::document::file_fullpath $thumbpath]]
  exec $cmd -resize $geom $fullpath [::document::file_fullpath $thumbpath]
  return "<a href=\"$url\"><img src=\"[::document::file_url $thumbpath]\"></a>"

  #puts $::errorInfo
}

###
# topic: e27a4c6e-a7c3-ed13-4e4b-baa27b28f49b
###
proc ::document::init {{config {}}} {
        package require uuid
        package require fileutil
        package require odie-strings
	package require httpd::upload
        variable fileUUIDIndex {}
        variable filePATHIndex {}
	variable saveName
        variable baseDir [file join [httpd cget siteRoot] files]
	variable baseUrl /files

        foreach {var val} $config {
          set $var $val
        }

        proc baseUrl {} [list return $baseUrl]
        proc baseDir {} [list return $baseDir]
        
        if ![file exists $baseDir] {
            file mkdir $baseDir
        }
        if ![file exists $baseDir/root] {
            file mkdir $baseDir/root
        }
        if ![file exists $baseDir/incoming] {
            file mkdir $baseDir/incoming
        }
        if [file exists [file join $baseDir $saveName]] {
            set fin [open [file join $baseDir $saveName]]
            while { [gets $fin line] >= 0 } {
                set uuid [lindex $line 0]
                set path [lindex $line 1]
                fileIndex $uuid $path
            }
            close $fin
        }
        ::httpd::static_root $baseUrl/direct        [file join $baseDir root]

	Upload_Url $baseUrl/upload $baseDir/incoming [namespace current]::UploadFinish
    	Url_PrefixInstall $baseUrl/download [namespace current]::html_download
    	::httpd::dynamic_url $baseUrl [namespace current]::html
    }

###
# topic: e47fc2f0-4c11-6874-7552-a24a92d73ddf
###
proc ::document::pageout data {
	::page object [namespace current]
	::page title "File Manager"
	::page layout wiki
	
	set menuCommand {}
	set menuNavigation {}

	page content $data

	set result [subst [::html-style::template page]]
	return $result
    }

###
# topic: 11fa37f5-4e61-e37d-7975-6e6e2f75bab8
###
proc ::document::pathinfo path {
	variable baseDir
	if { $path == "/" } {
	    set fullpath [baseDir]/root
	} else {
	    set fullpath [file join [baseDir]/root [uuidFILE $path]]
	}

	set result {parent {} directory {} file {}}

	if ![file isdirectory $fullpath] {
	    return $result
	}
	if { $fullpath != "[baseDir]/root" } {
	    set file [file dirname $fullpath]
	    file stat $file infoarray
	    set fileinfo [array get infoarray]
	    if { $file == "[baseDir]/root" } {
		set uuid /
	    } else {
		set uuid [fileCatalogue [file normalize $file]]
	    }
	    dict set fileinfo name ".."
	    dict set result parent $uuid $fileinfo	    
	}

	foreach file [lsort -dictionary [glob -nocomplain $fullpath/*]] {
	    file stat $file infoarray
	    set fileinfo [array get infoarray]
	    set rpath [file join $path [file tail $file]]
	    dict set fileinfo fullpath $file
	    dict set fileinfo path $rpath
	    dict set fileinfo name [file tail $file]
	    set type [dict get $fileinfo type]
	    set uuid [fileCatalogue [file normalize $file]]
	    dict set result $type $uuid $fileinfo
        }
	return $result
    }

###
# topic: b7ce3872-c0ce-7e3a-c4fa-7b7b6e13891d
###
proc ::document::SearchResult {name count info {proc {Display}} {print {}}} {
        variable baseUrl
	set colors  [list $::colors(rowcolor0) $::colors(rowcolor1)] 

	if {$print == {}} {
		set tdr "td class=\"searchResult[expr $count % 2]\" valign=\"left\""
	} else {
		set tdr "td valign=\"middle\""
	}

        if { $name == {} } { 
            return "<$tdr><A HREF=[baseUrl]>File Manager</a></td>"
        }
        
        switch [dict get $info type] {
            directory {
                return "<$tdr><A HREF=[baseUrl]?uuid=$name>[dict get $info name]/</a></td><$tdr></td><$tdr><tiny><a href=[baseUrl]/delete?uuid=$name>Delete</a></tiny></td>"
            }
	    file {
                return "<$tdr><A HREF=[baseUrl]/download/$name>[dict get $info name]</a></td><$tdr>[expr [dict get $info size] / 1024]kb</td><$tdr><tiny><a href=[baseUrl]/delete?uuid=$name>Delete</a></tiny></td>"
	    }
        }
        
	return $result
    }

###
# topic: 298411c5-cd5b-e86b-e769-3afbf8b00b2e
###
proc ::document::upload_button {{uuid /}} {
    variable baseUrl
    
append result "<form ENCtype=multipart/form-data action=[baseUrl]/upload method=post>\n"
append result "<input type=hidden name=uuid value=$uuid>"
append result "<table>"
append result "<tr><td>File:</td><td><input type=file name=the_file></td></tr>\n"
append result "<tr><td>Name<br>(Blank=filename):</td><td><input name=filename value=\"\"></td></tr>"
    append result "<tr><td colspan=2><input type=submit name=method value=Upload></td></tr>\n"
    append result "</table>"
append result "</form>\n"
}

###
# topic: 7b333017-6a07-041a-9120-a50b367ac440
###
proc ::document::UploadFinish args {
	foreach x $args {
	    foreach {var val} $x {
		dict set querydict $var $val
	    }
	}
	variable baseDir

	if [catch {::community urlPrelim} page] {
	    return $page
	}
        if {[catch {::community::AnonymousUser 1} page]} {
          return $page
        }
	if [dict exists $querydict uuid] {
	    set uuid [dict get $querydict uuid]
	    if { $uuid == "/" } {
		set fullpath [file join [baseDir] root]
	    } else { 
		set fullpath [file join [baseDir] root [uuidFILE $uuid]]
	    }
	} else {
	    set uuid /
	    set fullpath [file join [baseDir] root]
	}
	set filename [dict get $querydict the_file]
        set sfile [file tail $filename]
	if [dict exists $querydict filename] {
          set dfile [string map {{ } _ / -} [dict get $querydict filename]]
          if {[file extension $dfile] eq {} } {
            append dfile [file extension $sfile]
          }
        } else {
          set dfile $sfile
        }
	file rename -force [file join [baseDir] incoming $sfile] [file join $fullpath $dfile]
	return [html $uuid]
    }

###
# topic: 97e48d35-8a34-0c0f-0675-532676300f2f
###
proc ::document::uuidFILE findpath {
    variable filePATHIndex
    if [dict exists $filePATHIndex $findpath] {
        return [dict get $filePATHIndex $findpath]
    }
    variable fileUUIDIndex
    if [dict exists $fileUUIDIndex $findpath] {
      return $findpath
    }
    return {}
}

###
# topic: 9d87e01f-6f28-f3cb-f32c-e0ee1e079fc9
###
proc ::document::writeDb {} {
    variable baseDir
    variable saveName
    set fout [open [file join [baseDir] $saveName] w]
    variable fileUUIDIndex
    foreach {uuid path} $fileUUIDIndex {
        puts $fout [list $uuid $path]
    }
    close $fout
}

###
# topic: 3bf844a8-2dda-d2f3-914b-bcd8815df490
###
namespace eval ::document {
    variable saveName index.rc
    

    


    
    
    
    

    ###
    # Root directory
    ###
    

    
    
    
    
    




    
   
}

###
# topic: 3bf844a8-2dda-d2f3-914b-bcd8815df490
###
namespace eval ::document {
  namespace export *
  namespace ensemble create
}

