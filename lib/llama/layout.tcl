###
# Low Level Layout Language
# Macros for generating tables
#
###

::namespace eval ::llama {}

::namespace eval ::llama::latex {}

::namespace eval ::llama::wiki {}

###
# topic: 9b528d28-65e1-3580-b72e-e5772374e6d8
###
proc ::llama::colObj_row {colObj value} { 
  return "\[row\]\[col [list [$colObj Label]]\]\[col [list [$colObj Display $value]]\]\[/row\]"
}

###
# topic: cbc140a8-1bd1-c1a8-b571-96be784ffde6
###
proc ::llama::expand {nspace buffer {state {}}} {
  if { [info command unknown_save] == {} } {
    rename unknown unknown_save
  }
  proc unknown {cmnd args} {
      
  }
  
  if [catch {
    namespace eval ::${nspace} [list subst $buffer]
  } result] {
    return $buffer
  }
  return $result
}

###
# topic: 973cd03c-1bef-87fe-0681-eefec42de9c5
###
proc ::llama::imageObj {image_id {size web}} {
    set location {}
    set title    {}

    set docObj [::tao::node_container document] 
    if [string is integer $image_id] {
      return [$docObj /node $image_id]
    }

    set table [$docObj cget table]
    set key   [$docObj cget primary_key]

    set row [lindex [$docObj db query_flat [$docObj db stmt_select [list title $image_id] $key $table]] 0]

    if { $row != {} } {
      return [$docObj /node $row]
    }
    return {}
  }

###
# topic: a80ccd88-8fc2-3292-eaf2-282d5a14f532
###
proc ::llama::latex::expand {buffer {state {}}} {
  dict with state {}
    if [cath {
        eval subst $buffer
    } result] {
        return $buffer
    }
    return $result
}

###
# topic: 9d35ceeb-27d1-1312-cc7e-54fc92896fa9
###
proc ::llama::latex::latex_packages {} { 
    return {
        \usepackage{supertabular}
        \usepackage{hyperref}
        \usepackage[usenames]{color}
    }
}

###
# topic: d9ac1163-7a8d-6c6b-75c8-552c48624843
###
proc ::llama::latex::latex_subst value {
    foreach {char sub} {
        # {\\#}  
        _ {\\_}  
        ~ {\\~} 
        \r {} 
        \" {}
        {\\$} dollar    
        & {\\&}
        {\(} {\\(}
        {\)} {\\)}
    } {    
        regsub -all $char $value $sub value
    }
    return $value
}

###
# topic: 0a75af3e-3a1f-0d5e-f657-40fe91fd337a
###
proc ::llama::latex::what_row {} { 
    variable row_stack
    set table [what_table]
    set row $table.[peek row_stack($table)]
}

###
# topic: 1976da06-0fba-e188-2d02-ca2025ce422c
###
proc ::llama::latex::what_table {} { 
    variable table_stack
    return [peek table_stack]
}

###
# topic: 45a2543d-b2d7-a307-0f0a-20a2f0f04502
###
proc ::llama::qrow {cols args} {
  append result {[row]}
  foreach col $cols {
    append result "\[col $col $args\]"
  }
  append result {[/row]}
  return $result
}

###
# topic: 3f216693-bf46-b49d-ad52-7eecc529ef31
###
proc ::llama::qtable rows {
  set result {[table]}
  foreach row $rows {
    append result "[qrow $row]"
  }
  append result {[/table]}
  return $result
}

###
# topic: eb33cf0d-76f8-002d-037a-70f79a0c14d8
###
proc ::llama::qtablist elements {
  set result {[table]}
  foreach element $elements {
    append result "\[row\]\[col $element\]\[/row\]"
  }
  append result {[/table]}
  return $result
}

###
# topic: 6079915f-a9bc-fdf4-df33-a48b80b1be9a
###
proc ::llama::tag {namelist arglist bodies} {

    foreach tag $namelist {
      foreach {namespace body} $bodies {
        if { $arglist == "string" } {
          set barglist args
          set bbody {
if { [llength $args] < 2 } { 
set string [lindex $args 0]
} else {
set string $args
}
}
          append bbody $body
        } else {
          set barglist $arglist
          set bbody $body
        }
        namespace eval ::${namespace} [list proc $tag $barglist $bbody]
      }
    }
  }

###
# topic: 2f87199e-5d58-3cce-3e55-dd15e676d371
###
proc ::llama::tkIcon name {
  if { [info commands ::img::llama${name}] == {} } { 
    image create photo ::img::llama${name} -file [file join $::taourl(llamapath) javascript buttons $name-trans.gif]        
  }
  return ::img::llama${name}
}

###
# topic: 455fc354-f585-9a0b-65cf-1e41df882ad6
###
proc ::llama::wiki::expand {buffer {state {}}} {
  dict with state {}
  if [catch {subst $buffer} result] {
     puts "ERROR: $result\n$buffer\nState [list $state]"
     return $buffer
  }
  return $result
}

###
# topic: 39ae1ec9-ef50-87c6-43f3-bc0c2488bce0
###
proc ::llama::wiki::topicUnknown args {
  #puts "Unknown - $args"
  return [::wiki::topic {*}$args]
}

###
# topic: 554af958-bdd8-2188-98fa-bfa702f1e695
###
namespace eval ::llama {
  namespace export *
}

###
# topic: 554af958-bdd8-2188-98fa-bfa702f1e695
###
namespace eval ::llama {
  tag titleText {title {desc {}}} {

      wiki {
              if {$title == {}} { return {} }

              set text "<p class=\"sectionHeader\">$title</p>"
              if {$desc != {}} {
                      append text "<p>$desc</p>"
              } 
              append text "<div class=\"bgdivider\"></div>"
              return $text
      }
      latex {
              if {$title == {}} { return {} }

          return "\\Large\{$title\} \\normalsize "
      }
  }


  tag big_text string {
      wiki {
          return "<b><font size=+2>$string</font></b>"
      }
      latex {
          return "$string"
      }
  }


  tag white_text string {
      wiki {
          return "<b><font color=\#FFFFFF>$string</font></b>"
      }
      latex {
          return "\{\\color\{White\}$string\}"
      }
  }

  tag p {} { 
      wiki {
          return "<p>"
      }
      latex {
          return {\par}
      }
  }

  tag br {} { 
      wiki {
          return "<br>"
      }
      latex {
          return {\newline}
      }
  }

  tag bold string {
      wiki {
          return "<b>$string</b>"
      }
      latex {
          return " \\bf\{$string\} "
      }
  }
  
  tag emph string {
      wiki {
          return "<i>$string</i>"
      }
      latex {
          return " \\emph\{$string\} "
      }
  }

  tag i string {
      wiki {
          return "<i>$string</i>"
      }
      latex {
          return " \\it\{$string\} "
      }
  }

  tag typewriter string {
      wiki {
          return "<typewriter>$string</typewriter>"
      }
      latex {
          return " \\monospace\{$string\} "
      }
  }

  tag verbatim {} {
      wiki {
          return "<pre>"
      }
      latex {
          return { \begin{verbatim} }
      }
  }

  tag /verbatim {} {
      wiki {
          return "</pre>"
      }
      latex {
          returm { \end{verbatim} }
      }
  }

  tag rule {} { 
      wiki { return <hr> }
      latex { return { \hrule } }
  }



  tag wiki-template {title {text {}}} {
      wiki {
          variable container
          variable object

          set row [::wiki::FindTopic $title $text]
          set topic_id [lindex $row 0] 
          set title    [lindex $row 1]
          set text     [lindex $row 2]
          
          if { $topic_id == {} } { 
              set url /wiki/create?
              append url [::http::formatQuery title $title]
              return "$title<a href=\"$url\">*</a>."
          }
          set data [::wiki::nodeGetField $topic_id entry]
          return [expand $data]
      }
      latex {
          variable container
          variable object
          
          set row [::wiki::FindTopic $title]
          set topic_id [lindex $row 0] 
          set title    [lindex $row 1]
          
          if { $text == {} } {
              set text $title 
          }
          if { $topic_id == {} } { 
              return $text
          }
          set data [::wiki::nodeGetField $topic_id entry]
          return [expand $data]
      }
  }

  tag topic {topicTitle {text {}} {method {}}} {
      wiki {
          variable container
          variable object

          set row [::wiki::FindTopic $topicTitle $text]
          set topic_id [lindex $row 0] 
          set title    [lindex $row 1]
          set text     [lindex $row 2]
          
          if { $topic_id == {} } { 
              set url [::wiki::ModuleUrl]/create?
              append url [::http::formatQuery title $topicTitle]
              return "$topicTitle<a href=\"$url\">*</a>."
          }
          return [url [::wiki::nodeUrl $topic_id $method] $text]
      }
      latex {
          variable container
          variable object
          
          set row [::wiki:: FindTopic $title]
          set topic_id [lindex $row 0] 
          set title    [lindex $row 1]
          
          if { $text == {} } {
              set text $title 
          }
          if { $topic_id == {} } { 
              return $text
          }
          return "[url [::wiki:: nodeUrl $topic_id] $text]"
      }
  }

  tag url {url {text {}}} {
      wiki {
          if { $text == {} } { 
              set text $url
          }
          return "<a href=$url>$text</a>"
      }
      latex {
          if { $text == {} } { 
              set text $url
          }
          return " \\href\{$url\}\{$text\} "
      }
  }

  tag email {url {text {}}} {
      wiki {
          if { $text == {} } { 
              set text $url
          }
          return "<a href=\"mailto:$url\">$text</a>"
      }
      latex {
          if { $text == {} } { 
              set text $url
          }
          return " \\href\{mailto:$url\}\{$text\} "
      }	
  }

  tag center {} { 
      wiki {
          return "<center>"
      }
      latex {
          return { \begin{center} }
      }
  }
  tag /center {} { 
      wiki {
          return "</center>"
      }
      latex {
          return { \end{center} }
      }
  }

  tag brackets string {
      wiki {
          return "\[$string\]"
      }
      latex {
          return "\[$string\]"
      }
  }

  tag quote string {
      wiki {
          return "<tt>$string</tt>"
      }
      latex {
          return "\\quote\{$string\}"
      }
  }

  tag quotation string {
      wiki {
          return "<tt>$string</tt>"
      }
      latex {
          return "\\quotation\{$string\}"
      }
  }

  tag sic {} {
      wiki {
          return "\[sic\]"
      }
      latex {
          return "\[sic\]"
      }
  }

  tag dollar {{string {}}} {
      wiki {
          return "\$$string"
      }
      latex {
          return "\$$string"
      }
  }

  tag ulist rows {
      wiki {
          append result "<ul>"
          append result [join $rows "<li>"]
          append result "</ul>"
          return $result
      }
      latex {
          append result {\begin{itemize} \item } 
          append result [join $rows " \\item "]
          append result { \end{itemize} }
          return $result
      }
  }

  tag img {url {alt {}}} {
      wiki {
          return "<img src=\"$url\" alt=\"$alt\">"
      }
      latex {
          return "\hyperimage\{$url\}"
      }
  }

  tag image {image_id {size {}}} { 

      wiki {
          if { $size == {} } { 
              set size web
          }
          set node [imageObj $image_id $size]
          if { $node == {} } {
              return "[img /images/unknown.gif $image_id]"
          }
          if [catch {
              set result [$node Preview $size]
          } err] {
              return "ERROR LOADING IMAGE: $err"
          }
          return [url [$node UrlTo] [img [$node PreviewImage $size] [$node Get title]]]
      }

      latex {
          if { $size == {} } { 
              set size web
          }
          set node [imageObj $image_id $size]
          if { $node == {} } {
              return "[img /images/unknown.gif $image_id]" 
          }
          if [catch {
              set result [$node PreviewImage $size]
          } err] {
              return "ERROR LOADING IMAGE: $err"
          }
          return [url [$node UrlTo] [img [$node PreviewImage $size] [$node Get title]]]
      }
  }

  tag page_title {} {
      latex { return [::page title] }
      wiki { return [::page title] }
  }

  tag icon {file {alt {}}} {
      wiki {
          if { [file extension $file] == {} } { 
              append file .gif
          }
          return "<img src=\"/icons/$file\" alt=\"$alt\">"
      }
      latex {
          if { [file extension $file] == {} } { 
              append file .gif
          }
          return "\\hyperimage{\"/icons/$file\"}"
      }
  }

  tag new {} {
      wiki {
          return "<img border=0 src=/icons/new2.gif alt=\"NEW!\">"
      }
      latex {
          return "\\hyperimage\{/icons/new2.gif\}"
      }
  }

  tag {small smalltext} string {
      wiki {
          return "<font size=-2>$string</font>"
      }
      latex {
          return "\\small\{$string\}"
      }
  }

  tag table {{column_alignment {}} args} {
      wiki {
          return "\n<table>"
      }
      latex {
              variable rows 
          variable tables
          variable table_stack
          variable table_rows
          variable table_result
          incr tables
          
          
          set this_table $tables

          set rowstack($this_table) {}
          set table_rows($this_table) 0
          
          push table_stack $this_table
          
          set result {
\begin{supertabular}}
          if { $column_alignment != {} } { 
              append result "\{$column_alignment\}"
          }
          append result \n
          set table_result($this_table) $result
          return {}
      }
  }
  
  tag /table {} { 
      wiki {
          return "</table>"
      }
      latex {
          variable table_stack
          variable table_result
          variable rowstack
          variable row_result
          
          set table [pop table_stack]
          append table_result($table) {
              \end{supertabular}
          }
          set result $table_result($table)
          array unset table_result $table
          array unset rowstack $table
          array unset row_result $table.*
          return $result
      }
  }


  tag row {} { 
      wiki {
          return <tr>
      }
      latex {
          variable table_rows
          variable row_stack
          variable row_result
          
          set table [what_table]
          set row   [incr table_rows($table)]
          push row_stack($table) $row
          set row_result($table.$row) {}
          return {}
      }
  }

  tag /row {} {
      wiki {
          return "</tr>"
      }
      latex {
          variable row_result
          variable table_result
          variable row_stack 
          
          set table [what_table]
          set row   [pop row_stack($table)]
          
          set thisrow $row_result($table.$row)
          array unset row_result $table.$row
          
          set result {}
          append result [join $thisrow " & "]
          append result " \\\\\n" 
          
          append table_result($table) $result

          return {}
      }
  }

  tag col {data args} { 
      
      wiki {
          set tag {}
          array set info $args
          foreach {var attribute} {
              colspan colspan
              color   bgcolor
          } {
              if { [set value [get info($var)]] != {} } { 
                  append tag " $attribute=\"$value\" "
              }
          }
          if { [string is true -strict [get info(bold)]] } {
              return "<th $tag>$data</th>"
          } else {
              return "<td $tag>$data</td>"
          }
      }
      latex {
          set row [what_row]
          variable row_result
          
          set data [latex_subst $data]

          array set info $args
          if [string is true -strict [get info(bold)]] {
              set data [bold $data]
          }
          
          if { [get info(colspan)] != {} } { 
              set data " \\multicolumn\{$info(colspan)\}\{c\}\{$data\} "
          }
          
          lappend row_result($row) $data
          return {}
      }
  }

  tag label_row {elements args} { 
      wiki {
          return "<tr><th>[join $elements </th><th>]</th></tr>"
      }
      latex {
          variable table_result
          set table [what_table]
          append table_result($table "
\\tablefirsthead\{
[join $elements " & "] \\\\
  \\hline 
\}
\\tablehead\{
[join $elements " & "] \\\\
  \\hline 
\}
"

         return {}
      }
  }

  tag table_rule {{span 10}} { 
      wiki {
          return "<tr><td colspan=$span><hr></td></tr>"             
      }
      latex {
          variable table_result
          set table [what_table]
          append table_result($table) { \hline \\ }
          return {}
      }
  }
}

###
# topic: 9cfeb130-8671-1933-63e1-7f9f28bec74d
###
namespace eval ::wiki {
  namespace export *
}

###
# topic: d1a84df6-5199-39f0-77dd-b7c2fd710f50
###
namespace eval ::llama::wiki {
  variable container wiki
  namespace import ::wiki::*
  namespace unknown topicUnknown
}

###
# topic: 9609883b-2991-a493-6af0-4e32ef2c11fa
###
namespace eval ::llama::latex {
  variable container wiki
  namespace import ::llama::*

  ###
  #  Replicate ::wiki tags for latex
  ###
  variable rows 
  variable tables 0
  variable table_stack
  variable table_rows
  variable table_result

  variable rowstack
  variable row_result 

  variable mycolors
}

