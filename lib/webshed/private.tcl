::namespace eval ::private {}

::namespace eval ::wiki {}

###
# topic: 4cdd8b22-8df4-3070-bbc9-feaffdde1ac2
###
proc ::private::init {{config {}}} {
        package require uuid
        package require fileutil
        package require odie-strings
	package require httpd::upload
        
	set saveName index.rc
        set baseDir [file join [httpd cget siteRoot] files]
	set baseUrl /files
        set nspace [namespace current]
        
        foreach {var val} $config {
          set $var $val
        }
        set nspace ::[string trimleft $nspace :]

        namespace eval $nspace {}
        proc ${nspace}::saveName {} [list return $saveName]
        proc ${nspace}::self {} [list return $nspace]
        proc ${nspace}::baseUrl {} [list return $baseUrl]
        proc ${nspace}::baseDir {} [list return $baseDir]
        
        if ![file exists $baseDir] {
            file mkdir $baseDir
        }
        if ![file exists $baseDir/root] {
            file mkdir $baseDir/root
        }
        if ![file exists $baseDir/incoming] {
            file mkdir $baseDir/incoming
        }
        ::httpd::static_root $baseUrl/direct        [file join $baseDir root]
	Upload_Url $baseUrl/upload $baseDir/incoming ${nspace}::UploadFinish
    	Url_PrefixInstall $baseUrl/download ${nspace}::html/download
    	::httpd::dynamic_url $baseUrl ${nspace}::html

namespace eval $nspace {

    proc SearchResult {name count info {proc {Display}} {print {}}} {
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
                return "<$tdr><A HREF=[baseUrl]?uuid=$name>[dict get $info name]/</a></td><$tdr></td><$tdr></td><$tdr><tiny><a href=[baseUrl]/delete?uuid=$name>Delete</a></tiny></td>"
            }
	    file {
                return "<$tdr><A HREF=[baseUrl]/download/$name>[dict get $info name]</a></td><$tdr>[clock format [dict get $info mtime] -format "%a %b-%d-%Y %H:%M"]</td><$tdr>[expr [dict get $info size] / 1024]kb</td><$tdr><tiny><a href=[baseUrl]/delete?uuid=$name>Delete</a></tiny></td>"
	    }
        }
        
	return $result
    }  

    proc writeDb {} {
        set saveName [saveName]
        set fout [open [file join [baseDir] $saveName] w]
        variable fileUUIDIndex
        foreach {uuid path} $fileUUIDIndex {
            puts $fout [list $uuid $path]
        }
        close $fout
    }
    
    proc uuidFILE {findpath} {
        variable filePATHIndex
        if {![info exists filePATHIndex]} {
          buildIndex
        }
        if [dict exists $filePATHIndex $findpath] {
            return [dict get $filePATHIndex $findpath]
        }
        return {}
    }
    
    proc fileUUID {findpath} {
        variable fileUUIDIndex
        if {![info exists fileUUIDIndex]} {
          buildIndex
        }
        if [dict exists $fileUUIDIndex $findpath] {
            return [dict get $fileUUIDIndex $findpath]
        }
        return {}
    }
    
    
    proc pathinfo path {
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
            dict set fileinfo mtime [file mtime $file]
	    set type [dict get $fileinfo type]
	    set uuid [fileCatalogue [file normalize $file]]
	    dict set result $type $uuid $fileinfo
        }
	return $result
    }

    ###
    # Root directory
    ###
    
    proc pageout data {
	::page object [self]
	::page title "File Manager"
	::page layout wiki
	
	set menuCommand {}
	set menuNavigation {}

	page content $data

	set result [subst [::html-style::template page]]
	return $result
    }

    proc html uuid {
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
    
    proc upload_button {{uuid /}} {        
	append result "<form ENCtype=multipart/form-data action=[baseUrl]/upload method=post>\n"
	append result "<input type=hidden name=uuid value=$uuid>"
	append result "<table>"
	append result "<tr><td>File:</td><td><input type=file name=the_file></td></tr>\n"
	append result "<tr><td>Name<br>(Blank=filename):</td><td><input name=filename value=\"same\"></td></tr>"
        append result "<tr><td colspan=2><input type=submit name=method value=Upload></td></tr>\n"
        append result "</table>"
	append result "</form>\n"
    }
    
    proc html/mkdir {uuid newdir} {

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
	    set thisdir [baseDir]/root
	} else {
            set thisdir [file join [baseDir]/root [uuidFILE $uuid]]
	}
	file mkdir [file join $thisdir $newdir]
	return [html $uuid]
    }
    
    proc html/delete {uuid} {        
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
            set thisdir [file normalize [file join [baseDir]/root [uuidFILE $uuid]]]
	}
        if { $thisdir == [file join [baseDir]/root] } {
            return [html]
        }
	file delete -force $thisdir
        set puuid [fileUUID [file dirname [uuidFILE $uuid]]]
	return [html $puuid]
    }
    
    proc UploadFinish {args} {
	foreach x $args {
	    foreach {var val} $x {
		dict set querydict $var $val
	    }
	}
	if [catch {::community urlPrelim} page] {
	    return $page
	}
        if {[catch {::community::AnonymousUser 1} page]} {
          return $page
        }
	if [dict exists $querydict uuid] {
	    set uuid [dict get $querydict uuid]
	    if { $uuid == "/" } {
		set fullpath [baseDir]/root
	    } else { 
		set fullpath [file join [baseDir]/root [uuidFILE $uuid]]
	    }
	} else {
	    set uuid /
	    set fullpath [baseDir]/root
	}
	set filename [dict get $querydict the_file]
        set sfile [file tail $filename]
	if {[string trim [dictGet $querydict filename]] ni {{} same}} {
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
    

    proc fileIndex {uuid path} {
        variable fileUUIDIndex
        dict set fileUUIDIndex $path $uuid
        variable filePATHIndex
        dict set filePATHIndex $uuid $path
    }

    proc file_link path {
      variable baseUrl
      variable baseDir
      set fullpath [file join [baseDir] root [string trimleft $path /]]
      # puts stderr [list file_link $fullpath]
      return [baseUrl]/download/[fileCatalogue $fullpath]
    }

    proc fileCatalogue file {
	variable baseDir
        set path [::fileutil::relative [baseDir]/root $file]
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


    proc buildIndex {} {
        variable fileUUIDIndex {}
        variable filePATHIndex {}
        set count 0
	variable baseDir
        foreach file [glob -nocomplain [baseDir]/root/*] { 
            fileCatalogue $file
        }
    }
    
    proc html/download {sock suffix} {
	variable baseDir
	if [catch {::community urlPrelim} page] {
	    Httpd_Error $sock 404
	    return
	}
	set uuid [file tail $suffix]
	if { $uuid == {} } {
	    return [html]
	}
	set fpath [uuidFILE $uuid]
	set fullpath [file join [baseDir]/root $fpath]
	if ![file exists $fullpath] {
	    Httpd_Error $sock 404
	    return
	}
	set mimetype [Mtype $fullpath]
	if { $mimetype == "text/plain" } { 
	    set mimetype application/octet-stream
	}
	Httpd_AddHeaders $sock Content-disposition "file; filename=\"[file tail $fpath]\""
	if [catch {
	    Httpd_ReturnFile $sock $mimetype $fullpath
	} err]  {
	    Httpd_Error $sock 505
	}
    }
  namespace export *
  namespace ensemble create
  buildIndex
}
        if [file exists [file join $baseDir $saveName]] {
            set fin [open [file join $baseDir $saveName]]
            while { [gets $fin line] >= 0 } {
                set uuid [lindex $line 0]
                set path [lindex $line 1]
                ${nspace}::fileIndex $uuid $path
            }
            close $fin
        }

}

###
# topic: cad89f85-a093-3761-6f83-29fa7b7bb534
###
namespace eval ::private {
    variable saveName index.rc
}

