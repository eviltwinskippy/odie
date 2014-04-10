#!/usr/bin/tclsh

###
# Fossil repository index
###
set fossil_root /opt/fossil
set www_root /var/www

set fout [open $www_root/fossil/index.html w]
puts $fout "<HTML><HEAD>Fossil projects hosted at fossi.etoyoc.com<HEAD>
<BODY>
For more details about where these packages were obtained, and how they
are mirrored from other sites, see <a href=\"/fossil/odie/wiki?name=Packages\">The odie package manifest</a>
<p>
"

foreach file [lsort -dictionary [glob $fossil_root/*.fos*]] {
  set rname [file rootname $file]
  set repo [file tail $rname]
  if {![file exists $www_root/fossil/$repo]} {
    set cgiout [open $www_root/fossil/$repo w]
    puts $cgiout "#!/usr/bin/fossil"
    puts $cgiout "repository: $file"
    close $cgiout
  }
  set url "/fossil/$repo"
  puts $fout "<LI><a href=\"$url\">$repo</a></LI>"

  puts stdout [string map "@REPO@ $repo" {
$HTTP["url"] =~ "^/fossil/@REPO@" {
  alias.url += ( "^/@REPO@/" => "/fossil/@REPO@" )
  cgi.assign = ( "" => "/usr/bin/fossil" )
}
}]
}
puts $fout "</BODY></HTML>"
close $fout

