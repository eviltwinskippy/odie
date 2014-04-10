package require llama
package require http

::namespace eval ::llama::wiki {}

::namespace eval ::wiki {}

###
# topic: 04858067-e9b3-f868-dc51-5408be0a61c1
# description:
###
proc ::llama::wiki::/sql {} {
  return ::sqldb
}

###
# topic: 4b286013-b00f-99a2-260f-81b40a9b493c
###
proc ::wiki::/sql {} {return ::sqldb}

###
# topic: e72e6923-2a54-0159-ce8a-44b3b1888634
###
proc ::wiki::create_button info {
  set title {}
  set type  static
  dict with info {}
  set result {}
  set missing {title type}
  if {[catch {::community::AnonymousUser 1} page]} {
    return {}
  }
  append result {<form action=/home/create>}
  if {[dict exists $info title] && [dict exists $info type]} {
    foreach {var val} $info {
      append result "<input type=hidden name=\"$var\" value=\"$val\">"
      logicset remove missing $var
    }
  }
  if {[llength $missing]} {
    append result {<table><tr><th colspan=2>Create a page</th></td>}
  }
  if {"type" in $missing } {
    append result {<tr><th>Type</th><td>}
    set types [db eval {select distinct type from community order by class}]
    logicset add types index metaindex static
    append result [::html-style::select-combo type static [lsort -unique -dictionary $types]]
    append result </td></tr>
  }
  if {"title" in $missing} {
    append result {<tr><th>Title</th><td><input name=title></td></tr>}
  }
  if {[llength $missing]} {
    append result {<tr><td colspan=2 align=center><input type=submit value="Create"></td></tr></table>}
  } else {
    append result "<input type=submit value=\"Create $title\">"
  }
  append result </form>
  return $result
}

###
# topic: 65f25135-4742-8c21-b7c1-74867419d650
###
proc ::wiki::defaultMethod {} {
  return display
}

###
# topic: 27fd1b05-7a90-7e5c-67fe-8a79562ed382
###
proc ::wiki::expand args {
  return [::llama::wiki::expand {*}$args]
}

###
# topic: 1ced53fa-2e6f-f018-a37b-2159eaf21059
###
proc ::wiki::FindTopic {topicTitle {text {}}} {
  set row [db eval {select node_id,title from community where node_id=$topicTitle or title=$topicTitle limit 1}]
  if { $row == {} } {
      return [list {} $topicTitle $text]
  }
  if { $text != {} } {
      return [list [lindex $row 0] [lindex $row 1] $text]
  } else {
      return [list [lindex $row 0] [lindex $row 1] [lindex $row 1]]
  }
}

###
# topic: 8276a9c1-6263-451a-8b6a-8674ff299899
###
proc ::wiki::html {node {query {}}} {
  if { $node == {} } {
    return [community homepage]
  }
  return [html/node $node]
}

###
# topic: 969af7cf-383c-5e0f-17eb-2af43fe5d5f9
###
proc ::wiki::html/admin query {
  set layout {}
  if [catch {::community urlPrelim} result] {
    return $result
  }
  if {[catch {::community::AnonymousUser 1} page]} {
    return $page
  }
  set content {</form>}
  append content [create_button {}]
  append content "<li>[url /wiki/2/edit {Edit home page}]"
  foreach {node desc} {
    stylesheet {Site Style Sheet}
    contact-info {Contact Info Block}
    logo-bar {Logo on the top of the screen}
    ad-block {Google Ads Block}
    top-menu {Top Menu}
    block-menu {Block Menu}
    page {Page Layout Template}
  } {
    set row [FindTopic $node]
    set topic_id [lindex $row 0] 
    set title    [lindex $row 1]
    set text     [lindex $row 2]
    if {[llength $topic_id]} {
      append content "<li>$desc [url /wiki/$topic_id/edit Edit]"
    } else {
      append content "<li>$desc [create_button [list title $node type template]]"
    }
  }
  append content "<li>[topic contact-info {Contact Info Block} Edit]"
  page content $content
  set result [subst [::html-style::template [::page layout]]]
  ::community urlPostlim
  return $result
}

###
# topic: 849b63c1-9fb5-d6e5-1885-8d91eda71dc2
###
proc ::wiki::html/create query {
  if [catch {::community urlPrelim} result] {
    return $result
  }
  if {[catch {::community::AnonymousUser 1} page]} {
    return $page
  }
  ###
  # Clean up values
  ###

  set title [dict get $query title]
  set node_id [newnode]
  set created 1
  #puts stderr "$title $node_id"

  if { [string trim $title] != {} } {
    set tnode [db one {select node_id from community where title=$title}]
    set title "Topic $node_id"
    if { $tnode != {} } {
      set node_id $tnode
      set created 0
    }
  }
  if { $created } {
    db eval {insert into community (node_id,title) VALUES ($node_id,$title)}
  }
  dict set record title $title
  return [html/node/edit $node_id $query]
}

###
# topic: af2e4b89-14f2-c212-7afa-94ec03a69f8d
###
proc ::wiki::html/node {node {query {}}} {
  set ::post_exec {}
  set ::post_exec_force {}
  set layout {}
  if [catch {::community urlPrelim} result] {
    return $result
  }
  set node [nodeAlias $node]
  if { $node eq {} } {
    error "Unknown node"
  }
  set data [nodeGet $node]
  dict with data {
    ::page title $title
    if { $layout eq {} } {
      set layout record/wiki
    }
    ::page layout $layout
    ::page links {}
  }
  #puts stderr [list data $data]
  set raw [::llama::wiki::expand $entry $data]
  #dict with $data
  #if {[catch {subst $raw} content]} {
    #puts "ERror $content"
  #  set content $raw
  #}
  page content $raw
  #::page selectform     {}
  #::page menuNavigation  [menuNavigation $node]
  #::page menuCommand     [menuCommand $node]
   #::page menuSearch      [menuSearch $container $node]
  set result [subst [::html-style::template [::page layout]]]
  ::community urlPostlim
  return $result
}

###
# topic: 3ff5d567-67be-9e3e-d22c-135fae035211
###
proc ::wiki::html/node/edit {node {query {}}} {
  set layout {}
  if [catch {::community urlPrelim} result] {
    return $result
  }
  if {[catch {::community::AnonymousUser 1} page]} {
    return $page
  }
  set content {</form>}

  set node [nodeAlias $node]
  if { $node eq {} } {
    error "Unknown"
  }
  set action [dictGet $query action]
  set mode [dictGet $query mode]

  if {$query != {}} {
    switch $action {
      save {
        nodePut $node $query
      }
      copy {
        set node [nodeCreate $query]
      }
      html {
        set mode html
      }
      wysiwig {
        set mode wysiwyg
      }
    }
  }
  set data [nodeGet $node]

  if { $action eq "preview" || $action eq "save" } {
    foreach {var val} $query {  
      dict set data $var $val
    }
  }

  dict with data {
    ::page title $title
    if { $layout eq {} } {
      set layout record/wiki
    }
    ::page layout $layout
    ::page links {}
  }
  append content "<hr>[dictGet $data entry]<hr>"
  append content "<form action=/wiki/$node/edit method=post>"
  #append content "<input type=hidden name=node value=\"$node\">"
  append content "<table><tr><th>Title:</th><td>"
  append content "<input name=title value=\"[dict get $data title]\" width=60>"
  append content "</td></tr>"
  append content "<tr><th>Page Type:</th><td>"
  set types [db eval {select distinct type from community order by class}]
  logicset add types index metaindex static
  append content [::html-style::select-combo type [dict get $data type] [lsort -unique -dictionary $types]]
  append content "</td></tr>"
  append content "<tr><td>Preview</td><td><input name=preview value=\"[dictGet $data preview]\"></tr>"
  append content "<tr><td colspan=2>"
  if { $mode eq "wysiwyg" } {
    append content [::html-style::htmlentry entry $entry { style="height: 800px; width: 600px;"}]
  } else {
    append content "<textarea rows=30 cols=80 name=\"entry\">[dict get $data entry]</textarea>"
  }
  append content "</td></tr>"
  append content "</table>"
  append content "<input type=hidden name=mode value=\"$mode\">"
  if { $mode eq "wysiwyg" } {
    append content "<input type=submit name=action value=html>"
  } else {
    append content "<input type=submit name=action value=wysiwyg>"
  }
  append content "<input type=submit name=action value=preview>"

  append content "<input type=submit name=action value=save>"
  append content "<input type=submit name=action value=copy>"
  append content {</form>}

  page content $content
  #::page selectform     {}
  #::page menuNavigation  [menuNavigation $node]
  #::page menuCommand     [menuCommand $node]
   #::page menuSearch      [menuSearch $container $node]
  set result [subst [::html-style::template [::page layout]]]
  ::community urlPostlim
  return $result
}

###
# topic: 3dc01d74-5310-ae1b-cb59-422b6d8293b0
###
proc ::wiki::html/node/raw {node {query {}}} {
  set ::post_exec {}
  set ::post_exec_force {}
  set layout {}
  if [catch {::community urlPrelim} result] {
    return $result
  }
  set node [nodeAlias $node]
  if { $node eq {} } {
    error "Unknown"
  }
  set data [db eval {select 'node_id',node_id,'class',class,'title',title,'entry',entry from community where node_id=$node}]
  dict with data {
    ::page title $title
    if { $layout eq {} } {
      set layout record/wiki
    }
    ::page layout $layout
    ::page links {}
  }
  page content $entry
  #::page selectform     {}
  #::page menuNavigation  [menuNavigation $node]
  #::page menuCommand     [menuCommand $node]
   #::page menuSearch      [menuSearch $container $node]
  set result [subst [::html-style::template [::page layout]]]
  ::community urlPostlim
  return $result
}

###
# topic: becb62bc-4284-e63f-5278-7018b33d0f36
###
proc ::wiki::html/node/root {node {query {}}} {
  return [html/node 2]
}

###
# topic: f315394d-3810-eb66-0b4d-a7705a5a69c1
###
proc ::wiki::httpdMethodAlias {method node} {
  set method [string trimleft [string tolower $method] html]
  switch $node {
    new -
    create {
      return ::wiki::html/create
    }
    find -
    search {
      return ::wiki::html/search
    }
    admin {
      return ::wiki::html/admin
    }
  }
  if { $method in {display {}} } {
    return ::wiki::html/node
  } else {
    return ::wiki::html/node/$method
  }
}

###
# topic: 649354b0-2844-645d-599f-ca911a7364c4
###
proc ::wiki::MarshallArguments {prefix suffix input} {
  ###
  # Convert from wibble style dict
  ###
  set query {}
  foreach {var dict} $input {
    if {[dict exists $dict {}]} {
      dict set query $var [dict get $dict {}]
    }
  }


  if {[info command ::wiki::html$suffix] != {}} {
    return [list ::wiki::html$suffix $query]
  }
  set rdict {}
  set l [lrange [split $suffix /] 1 end]
  switch [llength $l] {
      0 {
          ##
          # Begin with sensible defaults
          # When in doubt, it's me and my root node
          ###
          dict set rdict node {}
          dict set rdict method {}                
      }
      1 {
        dict set rdict node [lindex $l 0]
        dict set rdict method [defaultMethod]
      }
      2 {
          dict set rdict node [lindex $l 0]
          dict set rdict method [lindex $l 1]
      }
      default {
          error "Invalid URL $suffix"
      }
  }
  ###
  # Start with data from CGI
  #
  # Multiple hits on an key are fed into a list
  #
  # Values will be overridden if part of the URL are fed in
  ###
  foreach {key value} $query {
      if { $key in {node method} } {
          dict set rdict $key $value
      } else {
          dict lappend rdict $key $value
      }
  }
  
  set rnode [dict get $rdict node]
  set rmethod [dict get $rdict method]



  if { $rmethod == {} } {
      set rmethod root
  }
  ###
  # Does the node exist?
  ###
  if { $rnode != {} } {
      if ![nodeExists $rnode] {
          # Signal "We aint got nuttin"
          return {}
      }
  }
  ###
  # Perform any normalizations and sanity checks
  # To convert a submitted method name into the proper
  # internal method name
  ###
  set rmethod [httpdMethodAlias $rmethod $rnode]
  if { $rmethod == {} } {
      # A blank is interpreted as "Not valid"
      return {}
  }
  ###
  # Some other sanity check...
  ###
  return [list $rmethod $rnode $query]
}

###
# topic: 27cbbad4-c734-65fd-f359-b9d9d20a85f5
###
proc ::wiki::menuMethods args {}

###
# topic: 00947abb-4d22-9ba9-6cc3-bc6e0212d548
###
proc ::wiki::menuNavigation args {}

###
# topic: 5c3f79fd-3cb1-a111-d022-fd116a0f3d5e
###
proc ::wiki::newnode {} {
  set node_id [db one {select max(node_id)+1 from community}]  
}

###
# topic: 632835df-7769-a3c4-acd0-f0d38f3099f5
###
proc ::wiki::nodeAlias node {
  return [db one {select node_id from community where node_id=$node or title=$node limit 1}]
}

###
# topic: 8308b84e-1508-c9e5-ac7e-7e040f48b24c
###
proc ::wiki::nodeCreate record {
  set node_id [newnode]
  set title "[dictGet $record title] $node_id"
  db eval {insert into community (node_id,title) VALUES ($node_id,$title)}
  dict set record title $title
  nodePut $node_id $record
  return $node_id
}

###
# topic: 01cbf8a1-f1c1-cff3-0770-be6fdec78996
###
proc ::wiki::nodeExists node {
  set row [db eval {select node_id,title from community where  node_id=$node or title=$node limit 1}]
  if { $row eq {} } {
    return 0
  }
  return 1
}

###
# topic: 5940a7e1-22b6-3be4-21a4-7b76aaece842
###
proc ::wiki::nodeGet node {
  db eval {select * from community where node_id=$node or title=$node limit 1} record {}
  set element "wiki-$node"
  db eval {select field,data from meta_data where element=$element} {
    set record($field) $data
  }
  return [array get record]
}

###
# topic: a90ad58c-94cb-77e9-c5a5-196881f91303
###
proc ::wiki::nodeGetField {topic_id field} {
  set record [nodeGet $topic_id]
  if {[dict exists $record $field]} {
    return [dict get $record $field]
  }
  return {}
}

###
# topic: bac86bec-a58d-9634-3b23-419f63a59147
###
proc ::wiki::nodePut {node record} {
  db eval {select * from community where node_id=$node or title=$node limit 1} oldrecord {}
  set stmtl {}
  set native {}
  db eval {select field,data from meta_data where element='wiki-$node'} {
    set meta($field) $data
  }
  set element "wiki-$node"
  foreach {field value} $record {
    if {[info exists oldrecord($field)]} {
      if { $value != $oldrecord($field) } {
        lappend stmtl "$field=\$$field"
      }
    } else {
      if { $field in {action type_dropdown} } continue
      if { $value eq {} } {
        db eval {delete from meta_data where element=$element and field=$field}
      } else {
        puts [list $element $field $value]
        db eval {insert or replace into meta_data (element,field,data) VALUES ($element,$field,$value)}
      }
    }
  }
  if { $stmtl != {} } {
      set stmt "update community set "
      append stmt [join $stmtl ,]
      append stmt { where node_id=$node}
      dict with record {
        db eval $stmt
      }
  }
  return $node
}

###
# topic: e653b6cf-f0cf-88d5-7941-acb924b2a215
###
proc ::wiki::nodeUrl {node {method {}}} {
  return "/wiki/$node"
}

###
# topic: 9a387653-558b-d7de-5b57-7e079924c941
###
proc ::wiki::SearchResult {nodeid {count 0} {showColumns {}} {method {}} {print {}}} {
    set colors  [list $::colors(rowcolor0) $::colors(rowcolor1)]
    set td { align=left valign=top }
    if {$print == {}} {
            set tdr "td $td class=\"searchResult[expr $count % 2]\" valign=\"middle\""
    } else {
            set tdr "td valign=\"middle\""
    }
    if { $nodeid == {} } { 
        return "<$tdr><A HREF=$urlPrefix>${globalName}</a></td>"
    }
    set data [nodeGet $nodeid]
    set cols title
    foreach col $showColumns {
      if { $col ni $cols } {
        lappend cols $col
      }
    }
    set class [dictGet $data type]
    dict with data {
      if { $method ne {} } {
        set result "<$tdr><a href=\"[nodeUrl $nodeid]/$method\">$title</td>"
      } else {
        set result "<$tdr><a href=\"[nodeUrl $nodeid]\">$title</td>"
      }
       foreach item [lrange $cols 1 end] { 
            if {![info exists $item]} continue
            if {$item eq "preview" } {
              if {[dictGet $data preview] ne {} } {
                if [catch {::document::image [dictGet $data preview] 250x200} preview] {
                  set preview &nbsp
                }
                append result "<$tdr>$preview</td>"
              }
              continue
            }
            if { $item in {ctime mtime} } {
                set value [set $item]
                if { $value == {} || $value == 0 } {
                    append result "<$tdr> - </td>"
                    continue
                } 
                if {![string is integer $value]} {
                    set value [clock scan $value]
                }  	
                append result "<$tdr>[clock format $value -format "%Y-%b-%d %H:%M"]</td>"
            } else {
               append result "<$tdr>[set $item]</tdr>"
            }	
       }
    }
    return $result
}

###
# topic: c2098ebe-892c-2111-d6c5-4c67d5a0cf60
###
proc ::wiki::template topicTitle {
  set entry [db one {select entry from community where node_id=$topicTitle or title=$topicTitle}]
  
  if { $entry == {} } { 
    set url /wiki/create?
    append url [::http::formatQuery title $topicTitle]
    return "$topicTitle<a href=\"$url\">*</a>."
  }
  return [::wiki::expand $entry]
}

###
# topic: e6c0c6f1-5922-07b0-4c3c-a2c751db2f90
###
proc ::wiki::topic {topicTitle {text {}} {method {}}} {
  set row [FindTopic $topicTitle $text]
  set topic_id [lindex $row 0] 
  set title    [lindex $row 1]
  set text     [lindex $row 2]
  
  if { $topic_id == {} } { 
      set url /wiki/create?
      append url [::http::formatQuery title $topicTitle]
      return "$topicTitle<a href=\"$url\">*</a>."
  }
  return [url [nodeUrl $topic_id $method] $text]
}

###
# topic: 9cfeb130-8671-1933-63e1-7f9f28bec74d
###
namespace eval ::wiki {
namespace export *
  namespace ensemble create
}

::httpd::dynamic_root /home ::wiki::html ::wiki::MarshallArguments
::httpd::dynamic_root /wiki ::wiki::html ::wiki::MarshallArguments

