package provide taourl-mailman 0.1
package require httpd::cgi
package require httpd::doc

::namespace eval ::mailman {}

###
# topic: bfa72357-a1e8-57c0-7ccd-7d2987870131
###
proc ::mailman::init newconfig {
  variable config
  if {![info exists config]} {
    set config {
      cgi_url      /cgi-bin
      cgi_path     /usr/lib/cgi-bin
      baseUrl      /pipermail
      archive_path /var/lib/mailman/archives/public
    }
  }
  foreach {var val} $config {
    dict set config $var $val
  }
  dict with config {}
  ::httpd::cgi_directory $cgi_url $cgi_path
  ::httpd::static_root   $baseUrl $archive_path
}

