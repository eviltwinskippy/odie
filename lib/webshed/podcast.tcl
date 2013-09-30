package provide taourl-podcast 0.1

::namespace eval ::podcast {}

###
# topic: a946d317-b6d9-d8d5-d957-997c08584f93
###
proc ::podcast::baseUrl {} {return /podcast}

###
# topic: 2def186f-4b71-69df-4d28-8a283c23795d
###
proc ::podcast::dateStamp time {
   if { $time == {} } { 
	set time now
   }
   if {![string is integer $time]} {
	set time [clock scan $time]
   }  
   set result 	[clock format $time -format "%a, %d %b %Y %T GMT" -gmt 1]
   return $result
}

###
# topic: bb82d4ee-9a8c-c26c-2efb-4c7a45e7293a
###
proc ::podcast::html {} {
  return {The Etoyoc.com podcast RSS feed generator}
}

###
# topic: 0f5571d9-e80b-0256-d24d-6984e83b0bb0
###
proc ::podcast::html/debug {} {
  set result {
<HTML>
<BODY>
<CODE>
  }
  append result "<textarea>[html/rss]</textarea>"
  append result {</CODE></BODY></HTML>}
  return $result
}

###
# topic: 40645e34-7591-fe25-3776-53395d9c4af8
###
proc ::podcast::html/rss {} {
  set blank {
    title {A show about everything}
    language en-us
    copyright {John Doe}
    subtitle {A show about everything}
    author {John Doe}
    categories {}
    summary {}
    owner_name {John Doe}
    owner_email {john.doe@example.com}
    image {}
  }
  dict with blank {}
  set link http://[httpd cget host]:[httpd cget port]/[baseUrl]
  variable config
  dict with config {}

  set result [subst {<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">

<channel>
<title>$title</title>
<link>$link</link>
<language>en-us</language>
<copyright>&#xA9; [clock format [clock seconds] -format %Y] $copyright</copyright>

<itunes:subtitle>$subtitle</itunes:subtitle>
<itunes:author>$author</itunes:author>

<itunes:summary>$summary</itunes:summary>
<description>$summary</description>

<itunes:owner>
<itunes:name>$owner_name</itunes:name>
<itunes:email>$owner_email</itunes:email>
</itunes:owner>

<itunes:image href="$image" />
  }]
  foreach cat $categories {
    append result "<itunes:category text=\"$cat\">" \n
  }
  append result [podcast_items]
append result {
</channel>
</rss>}
  return $result
}

###
# topic: 83f8bf8f-1b58-1a32-c252-332e45afa180
###
proc ::podcast::init newconfig {
  variable config
  if {![info exists config]} {
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
  ::httpd::dynamic_url [baseUrl] [namespace current]::html 
}

###
# topic: b43727a6-19b0-5175-b674-413381ca9e7b
###
proc ::podcast::nodeToEntry nodeid {
  set blank {
    title    {}
    author   {}
    subtitle {}
    summary  {}
    imageurl {}
    filename {}
    ctime    {}
    duration {}
    keywords {}
  }
  dict with blank {}
  set dat [wiki nodeGet $nodeid]
  dict with dat {}
  return [subst {
<item>
<title>$title</title>
<itunes:author>$author</itunes:author>
<itunes:subtitle>$subtitle</itunes:subtitle>
<itunes:summary>[::wiki::expand $entry]</itunes:summary>
<itunes:image href="$imageurl" />
[podcast_link $filename]
<pubDate>[dateStamp $ctime]</pubDate>
<itunes:duration>$duration</itunes:duration>
<itunes:keywords>[join $keywords ,]</itunes:keywords>
</item>
  }]
}

###
# topic: 5ef4635d-9a64-ba36-a53d-eeb9108625dd
###
proc ::podcast::podcast_items {} {
  ::db eval {update community set ctime=mtime where ctime is null or ctime='' or ctime=0}
  ::db eval {select node_id from community 
where type='podcast'
order by node_id desc limit 50} {
    append result [nodeToEntry $node_id]
  }
  return $result
}

###
# topic: abf33707-29bc-85dd-f0fa-2a59298c5638
###
proc ::podcast::podcast_link filename {
  if { $filename eq {} } {
    return {}
  }
  set urlpath  [::fileutil::relative [file join [::document::baseDir] root] $filename]
  set url http://[httpd cget host][::documents::baseUrl]/direct/$path
  set type text/html
  set types {
    .mp3	audio/mpeg
    .m4a	audio/x-m4a
    .mp4	video/mp4
    .m4v	video/x-m4v
    .mov	video/quicktime
    .pdf	application/pdf
    .epub	document/x-epub
  }
  set ext [file extension $filename] 
  if {[dict exists $types $ext]} {
    set type [dict get $types $ext]
  }
  set size [file size $filename]
  return "<enclosure url=\"$urlpath\" length=\"$size\" type=\"$type\" />"
}

