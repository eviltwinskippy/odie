::namespace eval ::rss {}

###
# topic: 4b0197bb-f2e6-f849-2db1-f92c6e1bddf1
###
proc ::nodeToEntry nodeid {
   set dat [wiki nodeGet $nodeid]
   set result "    <item>"
   dict with dat {
	append result \n "      <title>$title</title>"
	append result \n "      <link>http://blokes.etoyoc.com/home/$nodeid</link>"
	append result \n "      <guid>http://blokes.etoyoc.com/home/$nodeid</guid>"
	append result \n "      <description>$comment</description>"
#	append result \n "      <description>[string range $entry 0 100]</description>"
	append result \n "      <pubDate>[dateStamp $ctime]</pubDate>"
   }
   append result \n "    </item>" \n
   return $result
}

###
# topic: dfbd15ee-897f-a9d1-e927-a7fc0b39e47e
###
proc ::rss::dateStamp time {
   if { $time == {} } { 
	set time now
   }
   if {![string is integer $time]} {
	set time [clock scan $time]
   }  
   set result 	[clock format $time -format "%a, %d %b %Y %T GMT" -gmt 1]
   puts $result
   return $result
}

###
# topic: e55f9a2d-5ac5-3705-f555-d967794cefdd
###
proc ::rss::html {} {
  variable config
  dict with config {}
  append result [subst {
<?xml version="1.0"?>
<rss version="2.0">
  <channel>
  <title>$title</title>
  <link>$link</link>
  <description>$description</description>
  <language>en-us</language>
  <pubDate>[dateStamp now]</pubDate>
  <lastBuildDate>[dateStamp now]</lastBuildDate>
  <docs>http://[httpd cget host][baseUrl]</docs>
  <generator>Etoyoc.org RSS Feeder</generator>
  <managingEditor>$editor</managingEditor>
  <webMaster>[httpd cget webmaster]</webMaster>
}]
  ::db eval {update community set ctime=mtime where ctime is null or ctime='' or ctime=0}
  ::db eval {select node_id from community 
where type is not null and type != '' and type != 'index' and type != 'metaindex'
order by node_id desc limit 50} {
    append result [nodeToEntry $node]
}  
return $result]
    append result {
  </channel>
</rss>
}
  return $result
}

###
# topic: 02872f91-bc15-c60e-6332-fce5a5447699
###
proc ::rss::init newconfig {
  variable config
  if {![info exists $config]} {
    ###
    # Provide meaningful defaults
    ###
    set config {
title {This Website}
description {The RSS Feed for this website}
    }
    dict set config editor [httpd cget webmaster]
    dict set config link http://[httpd cget host]/wiki
  }
  foreach {var val} $newconfig {
    dict set config $var $val
  }
  ::taohttpd dynamic_url [baseUrl] [namespace current]/html 
}

