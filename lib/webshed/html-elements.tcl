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
# Primative HTML Elements
#

package provide html-style 1.4

::namespace eval ::html-style {}

###
# topic: 4a275189-5af4-ebcd-5eb0-d6507ea07e7b
###
proc ::html-style::/script {} { 
	return {
-->
</script>
}
    }

###
# topic: 6c3a30cb-3a35-e185-d705-15792575e3c7
###
proc ::html-style::button {text link {image {}}} { 
	if { $image == {} } { 
return "<button type=submit onclick=\"window.location=\'${link}\'\">${text}</button>"
} else {
return "<a href=\"${link}\" alt=\"${text}\"><img src=\"$image\" /></a>"
}
    }

###
# topic: 35cfaac1-2de2-5f3f-d301-fbd6c912c1cd
###
proc ::html-style::checkbox {element value {optionlist true}} {
  set trueopt true
  foreach option $optionlist {
    if [string is true $option] {
      set trueopt $option
    }
  }
  append result "<input type=checkbox name=$element value=\"$trueopt\""
  if [string is true $value] {
      append result " checked "
  }
  append result ">"
  return $result   
}

###
# topic: c58b9ee0-8154-3fec-0e23-7efb93e9017c
###
proc ::html-style::checkboxlist {element valuelist optionlist} {
	::foreach option $optionlist {
	    append result "\n<input type=checkbox name=$element value=\"$option\" "
	    if { [lsearch $valuelist $option] >= 0 } { 
	 	append result " checked "
	    }
	    append result ">$option<BR>"
	}
	return $result
    }

###
# topic: c2cd97f4-dece-43f5-d21b-4e50858e9b2b
# description: Build a selection box
###
proc ::html-style::droparray {element value optionlist {SelectJS {}}} {	
        if { $SelectJS == {} } { 
             set SelectJS [selectjs $element]
        }
	variable html
	set form_name   [formname]  
	
 	append result "<table><tr><td><SELECT name=${element}_list $SelectJS>"
	append result "<option value=\"\"></option>\n"

	foreach option $optionlist {
	    append result "\n<option value=\"[lindex $option 0]\" "
	    append result ">[lrange $option 1 end]</option>"
	}

	append result "</select>
        </td></tr><tr><td><input name=\"$element\" value=\"$value\">
</td></tr></table>
"

	return $result   
    }

###
# topic: aae3d861-0dcf-1d3c-bcac-c357219f3a25
###
proc ::html-style::dropmenu menudat {
	set result {}
	set rootitem 0
        set total    0
        append result {<ul id="nav">} \n
	foreach {text link subitems} $menudat {
            append result "<li><a href=\"$link\">$text <img src=/llama/rightarrow.gif border=0></a>"
	    append result [dropmenu_submenu $subitems] </li> \n
	    
	}
        append result {</ul>}
	return $result
    }

###
# topic: bbb63455-9646-1ec9-b977-d3217330c65e
###
proc ::html-style::dropmenu_submenu items {
	set linklist {}

	set result {} 
	if { $items == {} } { 
	    return {}
	}
	set iteml {}
        append result {<ul>} \n
	foreach {text link subitems} $items {
	    if {[lsearch $linklist $link] >= 0 } { 
		continue
	    }
            lappend linklist $link
	    if { $subitems != {} }  {
                append result {<li>} "<a href=\"$link\" class=\"parent\">$text</a>" \n
		append result [dropmenu_submenu $subitems] \n  {</li>} \n
	    } else {
                append result {<li>} "<a href=\"$link\">$text</a>" {</li>} \n
            }
	}
        append result {</ul>} \n
	return $result
    }

###
# topic: 8ffaa6ea-6d4f-0b72-3b85-ff33268fa484
###
proc ::html-style::dropselect {element value optionlist} {
	variable html

	set form_name   [formname]   
	set col_field   [lindex [split $element .] end]

	append result {<table border=0 cellspacing=0 cellpadding=0><tr>}
	append result "<td><input name=\"$col_field\" value=\"$value\"></td>"
	###
	#  Detect if we have to spill
	###
	set spill 0
	set msize 0
	foreach opt $optionlist {
	    set s [string length $opt]
	    if { $s > $msize } { set msize $s }
	}
	if { $msize > 20 } { 
	    set spill 1
	}
	if { $spill } {
	    append result "</tr><tr>"
	}
	append result "<td>"
        append result "<SELECT name=${col_field}_list onChange=\"this.form\['${col_field}'\].value=this.options\[this.options.selectedIndex\].value\">"

	append result "<option value=\"\"></option>\n"

	foreach option $optionlist {
	    append result "\n<option value=\"$option\" "
	    append result ">$option</option>"
	}

	append result "</select></td></tr></table>"

	return $result   
    }

###
# topic: 75af4c0b-bf06-ef70-f785-7af01af9df23
###
proc ::html-style::formname {{newname {}}} {
	variable html
	if { $newname == {} } { 
	    set value [get html(form-name)]
	    if { $value == {} } {
		set html(form-name) thisform
		return thisform
	    }
	    return $value
	}
	if { $newname == "default" } { 
	    set html(form-name) thisform
	    return thisform
	}
	set html(form-name) $newname
	return $newname
    }

###
# topic: 2a3f42fa-0ece-8dd2-1b60-8b5501c092f0
###
proc ::html-style::htmlentry {field {data {}} {formatting {}}} {
	htmlentry_header
	if { $formatting == {} } { 
	    set formatting "style=\"height: 170px; width: 500px;\""
        }

	
	append result "
<textarea id=\"htmlentry${field}\" name=\"${field}\" $formatting>\n"
	append result $data \n "</textarea>"
	append result "
<script language=\"javascript1.2\">
  generate_wysiwyg('htmlentry${field}');
</script>\n"
	return $result
    }

###
# topic: cbbe084e-7a32-fee4-d522-68a1e40df846
###
proc ::html-style::htmlentry_header {} { 
	if ![regexp {/llama/wysiwyg.js} [::page javascript]] {
	    append ::page(javascript) {
<script language="JavaScript" type="text/javascript" src="/llama/wysiwyg.js">
</script>
}
	}
    }

###
# topic: 7a6a1ead-9b8c-bdb1-e756-983846f7d87d
###
proc ::html-style::keyselect {element value optionlist {js {}}} {
	
 	append result "<SELECT name=$element $js>"
	append result "<option value=\"\"></option>\n"

	foreach row $optionlist {
	    if { [llength $row] == 2 } { 
		set optionval  [lindex $row 0]
		set optiondesc [lindex $row 1]
	    } else {
		set optionval  [lindex $row 0]
		set optiondesc [lrange $row 1 end]
	    }
	    append result "\n<option value=\"$optionval\" "
	    if { [string tolower $optionval] == [string tolower $value] } {
	 	append result " selected "
	    }
	    append result ">$optiondesc</option>"
	}
	append result "</select>"
	return $result   
    }

###
# topic: 21c4c37d-8e67-4896-4b8f-adbeb462fba0
###
proc ::html-style::keyselect_2d {element value optionlist varea vname} {
	set rows $optionlist
	
	foreach row $rows {
	    set i [lindex $row 0]
	    set a [lindex $row 1]
	    set n [lindex $row 2]
	    lappend matrix($a) [list $n $i] 
	}
	set varea {}
	set vname {}
	
	set form_name [formname]
	set row_field erow
	set col_field $element
	
	set data "<TABLE><TR><TD>Section:</TD><TD>
<select name=\"$row_field\" onchange=\"redirect(this.options.selectedIndex)\">"
	append data "\n<option value=\"\">--- Select Section ---</option>\n"
	foreach item [lsort [array names matrix]] {
	    append data "\n<option value=\"$item\""
	    if { $varea == $item } {
		append data " selected "
	    }
	    append data ">$item"
	}
	append data "\n</select>"
        append data "</TD></TR><TR><TD>Item</TD><TD>"
	append data "<select name=$col_field>"
	set row $varea
	if { $row != {} && [info exists matrix($row)] } {
	    foreach item $matrix($row) {
		append data "\n<option value=\"[lindex $item 1]\""
		if { $value == [lindex $item 1] } {
		    append data " selected "
		}
		append data ">[lindex $item 0]"
	    }
	} else {
	    append data "\n<option selected value=\"\">"
	}
	append data "\n</select>"
        append data "</TD></TR></TABLE>"
	set i 0
	set javaarray {}

	set lastgroup {}
	foreach row [lsort [array names matrix]] {
	    incr i
	    set j -1
	    append result "\n"
	    foreach {column} $matrix($row) {
		incr j
		append javaarray \
"\ngroupdesc\[$i\]\[$j\] = \"[::sql::fix [lindex $column 0]]\"
groupval\[$i\]\[$j\] = \"[lindex $column 1]\""
            }
	}
	# Use a boilerplate javascript

	set javascript {

	    var groups=document.FORMNAME.ROWNAME.options.length
	    var groupdesc=new Array(groups)
	    var groupval=new Array(groups)
	    for (i=0; i<groups; i++){
		groupdesc[i]=new Array()
		groupval[i]=new Array()
	    }
	    groupdesc[0][0] = "Please Select"
	    groupval[0][0] = ""
	    JAVAARRAY
	    
	    var temp=document.FORMNAME.COLUMNAME
	    
	    function redirect(x){
		for (m=document.FORMNAME.COLUMNAME.options.length-1;m>0;m--) {
		    document.FORMNAME.COLUMNAME.options[m]=null
		}
		document.FORMNAME.COLUMNAME.options[0]=new Option("----Select an Item----","")
		for (i=0;i<groupdesc[x].length;i++){
		    document.FORMNAME.COLUMNAME.options[i+1]=new
		    Option(groupdesc[x][i],groupval[x][i])
		}
		document.FORMNAME.COLUMNAME.options[0].selected=true
	    }
	}
	regsub -all FORMNAME  $javascript $form_name javascript
	regsub -all COLUMNAME $javascript $col_field  javascript
	regsub -all ROWNAME   $javascript $row_field javascript
	regsub -all JAVAARRAY $javascript $javaarray javascript

        append data [script]
        append data $javascript
        append data [/script]

	return $data
	
    }

###
# topic: 35f09891-65af-a4be-7657-68c59887d75a
###
proc ::html-style::rawcode text {
        set result [string map {< &lt; > &gt; & &amp; \" &quot;} $text]
        return "<TT><PRE>$result</PRE></TT>"
    }

###
# topic: e15cb8d6-dac9-d6f1-4925-c95cccb6d6c4
###
proc ::html-style::script {} { 
	return {
<script language="JavaScript">
<! -- 
}
    }

###
# topic: 69acaf07-407d-c7e9-a6d7-64edf35b6211
###
proc ::html-style::select {element value optionlist {SelectJS {}}} {	
  append result "<SELECT name=$element $SelectJS>"
  append result "<option value=\"\"></option>\n"
  foreach option $optionlist {
    append result "\n<option value=\"$option\" "
    if { $option == $value } { 
      append result " selected "
    }
    append result ">$option</option>"
  }
  append result "</select>"
  return $result   
}

###
# topic: 7f29de96-1cd4-f809-5f60-aac436d5138b
###
proc ::html-style::select-combo {element value optionlist} {	
  append result "<input name=$element value=\"$value\">"
  append result "<SELECT name=${element}_dropdown [selectjs $element]>"
  append result "<option value=\"\"></option>\n"
  foreach option $optionlist {
    append result "\n<option value=\"$option\" "
    if { $option == $value } { 
      append result " selected "
    }
    append result ">$option</option>"
  }
  append result "</select>"
  return $result   
}

###
# topic: bca3d254-34b1-d1b1-ed8f-61f82a2cec0e
###
proc ::html-style::selectjs element {
  return "onChange=\"this.form.${element}.value=this.options\[this.options.selectedIndex\].value\""
}

###
# topic: 1a46e6ba-b69f-234c-d6bb-0c6802535e32
###
proc ::html-style::template template {
	set load 1
	if [::taourl::template $template info] {
	    set data  [lindex $info 0]
	    set check [lindex $info 1]
	    set mtime [lindex $info 2]
            set fname [lindex $info 3]
            if { ( [clock seconds] - $check ) < 60 } { 
                 return $data
            }
            if { $fname == ":wiki:"} {
                if { $mtime != {} } {
                    # For wikis that GIVE us the mtime
                    # only hit that DB on demand
                    if {([clock seconds] - $mtime) < 60 } {
                        return $data
                    }
                }
            } else {
                if [file exists $fname] {

                if { $mtime == [file mtime $fname] } { 
                    ::taourl::template_touch $template
                    return $data
                }
                }
            }
	}
        # See if we have one in the Wiki
        set row [::wiki FindTopic $template {}]
 	set topic_id [lindex $row 0]
        if { $topic_id != {} } {
            set dat [wiki nodeGet $topic_id]
            set buffer [dict get $dat entry]
            if [dict exists $dat mtime] {
                set mtime [dict get $dat mtime]
            } else {
                set mtime {}
            }
            ::taourl::template_put $template $buffer :wiki: $mtime
            return $buffer
        }
            
	###
	#  Only check the file once a minute
	###
	set fname [template_find $template]
	if { $fname == {} } { 
	    return {}
	}
	
	###
	#  Load the buffer from the file
	###
	set fin [open $fname r]
	set buffer [read $fin]
	close $fin
	::taourl::template_put $template $buffer $fname [file mtime $fname]
	return $buffer
    }

###
# topic: 1eeb5bfd-0691-896a-a37a-33c82eabde25
###
proc ::html-style::template_find template {
        set fname {}
                
	foreach path [list \
	   [file join [httpd cget siteRoot] templates] \
	   [file join $::webshed::root templates]] {
	    set fname [file join $path $template.tml]
            if [file exists $fname] {
	       return $fname
            }
	    set fname [file join $path $template]
            if [file exists $fname] {
	       return $fname
            }
	}
	return {}
    }

###
# topic: d3de84f1-cf63-2191-234d-f52fe11d3ae2
###
proc ::html-style::textblock value {
	regsub -all \r $value {} text
	regsub -all \n $text <BR> text
	
	foreach item [get ::session(highlight)] {
	    regsub -all $item $text "<font color=#30a72f>$item</font>" text
	}

	return $text
    }

###
# topic: 4f32f6f3-fb06-45a7-f3f4-71f030a13587
# description:
#    BEGIN COPYRIGHT BLURB
#    
#    TAO - Tcl Architecture of Objects
#    Copyright (C) 2003 Sean Woods
#    
#    See the file "license.terms" for information on usage and redistribution
#    of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#    
#    END COPYRIGHT BLURB
#    
#    Primative HTML Elements
###
namespace eval ::html-style {
variable html
    array set html {
	form-name thisform
    }
    # Generate a boolean checkbox
    #
    # Element refers to the name of the variable to be fed into the form
    # Value   is the default value selected
    # OptionList is the list of options to present

    # Generate a select dropdown box in HTML
    #
    # Element refers to the name of the variable to be fed into the form
    # Value   is the default value selected
    # OptionList is the list of options to present

    #
    # Build a selection box
    #

    #  Produce a list of checkbox elements to fill out for a variable.
    #
    #  Element refers to the name of the variable to be fed into the form
    #  ValueList are the default values selected
    #  OptionList is the list of options to present

    # A selectbox where the value selected is actually a code
    # for the text presented to the user.
    #
    # Element refers to the name of the variable to be fed into the form
    # Value   is the default value selected
    # OptionList is the list of options to present
    #   * the first element in each listitem is the code input
    #   * The remaining arguments are presented as the text of the selection

    ###
    #  Convert linebreaks to <br> tags to allow text
    #  to flow as originally formatted.
    #
    #  Looks pretter than a PRE tag.
    ###
}



    namespace import ::html-style::template*

###
# topic: 9cfeb130-8671-1933-63e1-7f9f28bec74d
###
namespace eval ::wiki {
namespace import ::html-style::*
}

::httpd::static_root /llama [file join $::webshed::root javascript]

