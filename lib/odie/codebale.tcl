###
# codebale.tcl
#
# This file defines routines used to bundle and manage Tcl and C
# code repositories
#
# Copyright (c) 2014 Sean Woods
#
# See the file "license.terms" for information on usage and redistribution of
# this file, and for a DISCLAIMER OF ALL WARRANTIES.
###

::namespace eval ::codebale {}

::namespace eval ::codebale::parse {}

###
# topic: a5992c7f-8340-ba02-d40e-386aac95b1b8
# description: Records an alias for a Tcl keyword
###
proc ::codebale::alias {alias cname} {
  variable cnames
  set cnames($alias) $cname
}

###
# topic: 0e883f35-83c0-ccd3-eddc-6b297ac2ea77
###
proc ::codebale::buffer_append {varname args} {
  upvar 1 $varname result
  if {![info exists result]} {
    set result {}    
  }
  if {[string length $result]} {
    set result [string trimright $result \n]
    append result \n
  }
  set priorarg {}
  foreach arg $args {
    if {[string length [string trim $arg]]==0} continue
    #if {[string match $arg $priorarg]} continue
    set priorarg $arg
    append result \n [string trim $arg \n] \n
  }
  set result [string trim $result \n]
  append result \n
  return $result
}

###
# topic: 926c564a-a678-8498-6f74-89f37da3fb32
###
proc ::codebale::buffer_merge args {
  set result {}
  set priorarg {}
  foreach arg $args {
    if {[string length [string trim $arg]]==0} continue
    if {[string match $arg $priorarg]} continue
    set priorarg $arg
    append result [string trim $arg \n] \n
  }
  set result [string trim $result \n]
  return $result
}

###
# topic: c1e66f4a-20e3-97a5-d254-1714575c165f
###
proc ::codebale::buffer_puts {varname args} {
  upvar 1 $varname result
  if {![info exists result]} {
    set result {}    
  }
  set result [string trimright $result \n]
  #if {[string length $result]} {
  #  set result [string trimright $result \n]
  #}
  set priorarg {}
  foreach arg $args {
    #if {[string length [string trim $arg]]==0} continue
    #if {[string match $arg $priorarg]} continue
    #set priorarg $arg
    append result \n $arg
    #[string trim $arg \n]
  }
  #set result [string trim $result \n]
  #append result \n
  return $result
}

###
# topic: 951f31f2-cb24-992f-34d9-7e3deb16b43f
# description: Reports back the canonical name of a tcl keyword
###
proc ::codebale::canonical alias {
  variable cnames
  if {[info exists cnames($alias)]} {
    return $cnames($alias)
  }
  return $alias
}



set col 0
proc ::codebale::cases_put {f x} {
  global col
  if {$col==0} {puts -nonewline $f "   "}
  if {$col<2} {
    puts -nonewline $f [format " %-21s" $x]
    incr col
  } else {
    puts $f $x
    set col 0
  }
}

proc ::codebale::cases_finalize {f} {
  global col
  if {$col>0} {puts $f {}}
  set col 0
}

proc ::codebale::cases_generate {prefix cases} {
  global col
  set col 0
  set f [open [file join $::project(path) build [string tolower ${prefix}_cases].h] w]
  puts $f $::project(standard_header)
  puts $f "  const static char *${prefix}_strs\[\] = \173"
  set lx [lsort -dictionary $cases]
  foreach item $lx {
    cases_put $f \"[string tolower $item]\",
  }
  cases_put $f 0
  cases_finalize $f
  puts $f "  \175;"
  puts $f "  enum ${prefix}_enum \173"
  foreach name $lx {
    regsub -all {@} $name {} name
    cases_put $f ${prefix}_[string toupper $name],
  }
  cases_finalize $f
  puts $f "  \175;"
  puts $f "\
  int index;
  if( objc<2 ){
    Tcl_WrongNumArgs(interp, 1, objv, \"METHOD ?ARG ...?\");
    return TCL_ERROR;
  }
  if( Tcl_GetIndexFromObj(interp, objv\[1\], ${prefix}_strs,\
            \"option\", 0, &index)){
    return TCL_ERROR;
  }
  switch( (enum ${prefix}_enum)index )"
  close $f
}

###
# topic: 547fa005-7139-46cd-8f2c-395a28f9353c
###
proc ::codebale::complete_ccomment string {
  set result {}
  set opened 0
  set closed 0
  set idx 0
  while {1} {
    set idx [string first "/*" $string $idx]
    if {$idx < 0} break
    incr idx 2
    incr opened
    
    set idx [string first "*/" $string $idx]
    if {$idx < 0} break
    incr idx 2
    incr closed
  }
  if {!$opened} {
    return 1
  }
  if { $opened != $closed } {
    return 0
  }
  return 1
}


###
# description:
# Needed because there are cases where a C line is complete and valid
# in ways that info complete will not detect
###
proc ::codebale::complete_cstatement {line {trace 0}} {
  set n [string length $line]
  set dquotes   0
  set squote   0

  set paren    0
  set bracket   0
  set j 0
    
  for {set i 0} {$i < $n} {incr i} {
    if {[string index $line [expr {$i-1}]] eq "\x5c"} continue
    switch [string index $line $i] {
      "/" {
        ###
        # Ignore the contents of comments and return incomplete
        # if a comment is started on this line but not terminated
        ###
        set next [string index $line [expr {$i+1}]]
        if {$next eq "*"} {
          set endcomment [string first "*/" $line $i]
          if { $endcomment >= 0 } {
            set i [expr {$endcomment+2}]
            continue
          } else {
            return 0
          }
        } elseif { $next eq "/"} {
          set endcomment [string first "\n" $line $i]
          if { $endcomment >= 0 } {
            set i [expr {$endcomment+2}]
            continue
          } else {
            break
          }
        }
      }
      \x27 {
        # Single quotes can't embed anything else
        # but they can have several encodings        
        set next [string first \x27 $line [expr {$i+1}]]
        if { $next < 0} {
          return 1
        }
        set i $next
      }
      \x22 {
        while 1 {
          set next [string first \x22 $line [expr {$i+1}]]
          if { $next < 0} {
            return 1
          }
          set i $next
          if {[string index $line [expr {$next-1}]] eq "\\"} {
            continue
          }
          break
          #incr dquotes
        }
      }
      \x28 {
        incr paren
      }
      \x29 {
        incr paren -1
      }
      \x7B {
        incr bracket
      }
      \x7D {
        incr bracket -1
      }
    }
  }
  if {$dquotes % 2 || $paren || $bracket} {
    if {$trace} {
      puts [list $dquotes $paren $bracket]
    }
    return 0
  }
  return 1
}

###
# topic: b1e5e6ca-f0bf-9e78-695f-995a35af7c2f
# description: Provide a keyword handler to the autodoc parser
###
proc ::codebale::define {name info} {
  global cmdref
  foreach {var val} $info {
      dict set cmdref($name) $var $val
  }
}

###
# topic: 9cca11ca-4447-43a3-21d3-ad5ac85538b1
# description:
#    A simpler implementation of digest_comment, this proc
#    takes in the raw buffer and returns a dict of the annotations
#    it found
###
proc ::codebale::digest_comment {buffer {properties {}}} {
  set result(description) {}
  set appendto description
  
  foreach line [split $buffer \n] {
    set line [string trimleft [string range $line [string first # $line] end] #]
    set line [string trimright [string trim $line] -]
    if [catch {lindex $line 0} token] {
      append result($appendto) $line \n
      #set result($appendto) [buffer_merge $result($appendto) $line]
      continue
    }
    if {[string index $token end] ne ":"} {
      append result($appendto) $line \n
      #buffer_puts result($appendto) $line
    } else {
      set field [string tolower [string trimright $token :]]
      switch $field {
        topic {
          set result(topic) [lrange $line 1 end]
          append result(description) \n
          set appendto description
        }
        comment -
        desc -
        description {
          #append result(description) [lrange $line 1 end] \n
          set result(description) [buffer_merge $result(description) [lrange $line 1 end]]
          append result(description) \n
          set appendto description
        }
        title -
        headline {
          set result(title) [lrange $line 1 end]
          append result(description) \n
          set appendto description          
        }
        ensemble_method {
          set result(type) proc
          append result(description) \n
          set appendto description
        }
        ensemble -
        nspace -
        namespace -
        class -
        agent_class -
        task -
        subtask -
        method -
        class_function -
        class_method -
        phase -
        function -
        action {
          set result(type) $field
          set result(arglist) [lrange $field 1 end]
          append result(description) \n
          set appendto description
         }
        default {
          set result($field) [lrange $line 1 end]
          append result($field) \n
          set appendto $field
        }
      }
    }
  }
  foreach {field} [array names result] {
    set result($field) [string trim $result($field)]
  }
  return [array get result]
}

proc ::codebale::digest_cstatement {thisline resultvar {trace 0}} {
  upvar 1 $resultvar result
  if { [string match "*const*Tcl_ObjType*=*" $thisline] } {
    set pline [string range $thisline 0 [string first "=" $thisline]-1]
    if { $trace } {puts "TCL OBJ TYPE DECLARED $pline "}
    dict lappend result objtypes_defined [lindex $pline end]
  }
  if { [string match "*const*Tk_PhotoImageFormat*=*" $thisline] } {
    set pline [string range $thisline 0 [string first "=" $thisline]-1]
    if { $trace } {puts "TCL PHOTO TYPE DECLARED $pline "}
    dict lappend result phototypes_defined [lindex $pline end]
  } 
}

###
# topic: 4971b1be-8596-2744-bfb3-869375d60357
###
proc ::codebale::digest_csource {dat {trace 0}} {
  set ::readinglinenumber 0
  set ::readingline {}
  set result {}  

  set priorline {}
  set thisline {}
  set rawblock {}
  set continueline 0
  set continue_stmt 0
  set isfunct 0
  set inparen 0

  set instatement 0
  set parseline {}
  set thisfunct {}
  
  ###
  # Remove comments
  ###
  set dat [strip_ccoments $dat]
  
  ###
  # Place to store code that surrounds the functions
  ###
  dict set result code {}
  set llines [split $dat \n]
  foreach rawline $llines {
    incr ::readinglinenumber
    set ::readingline $rawline
    append rawblock $rawline \n
    regsub -all \x7b $rawline \x20\x7b line
    if {[regexp {^ *case *([A-Z]+)_([A-Z0-9_]+):} $rawline all prefix label]} {
      lappend cases($prefix) $label
    }
    if { $trace } {puts "$continueline | $continue_stmt $line" ; update}
    if {[string trim $line ] eq {} } continue
    append thisline \n [string trim $line]
    
    ###
    # continue_stmt is on one the following states:
    # 0 - unknown
    # 1 - finish C statement/function
    # 2 - detect function
    ###

    ###
    # Handle incomplete lines
    ###
    switch $continue_stmt {
      1 {
        #if { $trace } {puts "$continueline | cs 1" ; update}

        if {![complete_cstatement $thisline $trace]} {
          incr continueline
          continue
        } 
        # Waiting for end of function body
        if { $trace } { puts "STATEMENT" }
        if { $thisfunct eq {} } {
          digest_cstatement $thisline result $trace
          #dict set result function $thisfunct body $rawblock
        }
        set thisfunct {}
        set rawblock {}
        set thisline {}
        set continue_stmt 0
        set continueline 0
        set isfunct 0
      }
      2 {
        if {[string first \x7B $thisline] < 0} {
          incr continueline
          continue
        }
        if {[complete_cstatement $thisline $trace]} {
          # Waiting for end of function body
          if { $trace } { puts "STATEMENT" }
          if { $thisfunct eq {} } {
            digest_cstatement $thisline result $trace
            #dict set result function $thisfunct body $rawblock
          }
          set rawblock {}
          set thisline {}
          set continue_stmt 0
          set continueline 0
          set isfunct 0
        } else {
          set continue_stmt 1
          incr continueline
          continue
        }
      }
      default {
        set parseline [string map [list \x7b \x20\x7b \n \x20] [string trim $thisline]]
        #regsub -all \x7b $parseline \x20\x7b parseline
        #regsub -all \x7b $parseline \x20\x7b parseline
        
        ###
        # NEEDED: A MORE ROBUST IMPLEMENTATION TO CATCH THE PASSING OF
        # FUNCTIONS, WITH THEIR OWN PROTOTYPES
        # EXAMPLES:
#void TreeInit(
#  Tree *tree,                                 /* Tree object to initialize */
#  int (*xCompare)(const void*, const void*),  /* Comparison function */
#  void *(*xCopy)(const void*),                /* Key copy function or NULL */
#  void (*xFree)(void*)                        /* Key delete function or NULL */
#){
#  tree->xCompare = xCompare;
#  tree->xCopy = xCopy;
#  tree->xFree = xFree;
#  tree->top = 0;
#}
        ###


        foreach regexp {
             {(.*) ([a-zA-Z_][a-zA-Z0-9_]*) *\((.*)\)}
             {(.*) (\x2a[a-zA-Z_][a-zA-Z0-9_]*) *\((.*)\)}
        } {
          set isfunct [regexp $regexp $parseline all keywords funcname arglist]

          if { $isfunct > 0} {
            if {[string index $parseline end] eq "\;"} {
              set isfunct 0
              break
            }
            ###
            # We can't rely on the above regexp to suss out the headers
            # because of cases where a function pointer is declared
            ###
            
            set all [string trim $all]
            set declargs {}
            foreach item [split $arglist ,] {
              lappend declargs [string trim $item]
            }
            if { $trace } { puts "FUNCTION $keywords $funcname\([join $declargs ", "]\) | $arglist" }
            set thisfunct $funcname
            dict set result function $thisfunct keywords $keywords
            dict set result function $thisfunct arglist $declargs
            break
          }
        }
        if { $isfunct } {
          # If we can't see a curly bracket, parse until we do
          if {[string first \x7B $thisline] < 0} {
            set continue_stmt 2
            incr continueline
            continue
          }
      
          if {![complete_cstatement $thisline $trace]} {
            set continue_stmt 1
            incr continueline
            continue
          }
          # Function was implemented in one line
          set rawblock {}
          set thisline {}
          set continue_stmt 0
          set continueline 0
          set isfunct 0
        } else {
          if {![complete_cstatement $thisline $trace]} {
            incr continueline
            continue
          }
          if {[string index $parseline end] eq "\;" } {
            set continue_stmt 0
            if { $trace } { puts "CSTATEMENT" }
            digest_cstatement $thisline $trace
            set rawblock {}
            set continue_stmt 0
            set isfunct 0
            set instatement 0
            set thisline {}
          }
        }
      }
    }
  }
  if { $continue_stmt } {
    error "Stopped waiting for end of function $thisfunct"
  }
  if {[info exists cases]} {
    dict set result cases [array get cases]
  }
  return $result
}

proc ::codebale::detect_cases cfile {
  set fin [open $cfile r]
  while {[gets $fin line] >= 0} {
    if {[regexp {^ *case *([A-Z]+)_([A-Z0-9_]+):} $line all prefix label]} {
      lappend cases($prefix) $label
    }
  }
  close $fin
  set result {}
  foreach item [array names cases] {
    lappend result [string tolower ${item}_cases.h]
  }
  return $result
}

###
# topic: c0304a04-9be6-f312-06a0-2d15813720ce
###
proc ::codebale::meta_output outfile {
  set fout [open $outfile w]
  puts "SAVING TO $outfile"
  
  #puts $fout "array set filemd5 \x7b"
  #array set temp [array get ::filemd5]
  #foreach {file md5} [lsort -dictionary [array names temp]] {
  #  set md5 $temp($file)
  #  puts $fout "    [list $file $md5]"
  #}
  #array unset temp
  #puts $fout "\x7d"
  puts $fout "helpdoc eval {begin transaction}"
  helpdoc eval {
    select handle,localpath from repository
  } {
    puts $fout [list ::helpdoc repository_restore $handle [list localpath $localpath]]
  }
  helpdoc eval {
    select hash,fileid from file
  } {
    puts $fout [helpdoc file_serialize $fileid]
  }
  puts $fout [helpdoc node_serialize 0]
  helpdoc eval {
    select entryid from entry
    where class='section'
    order by name
  } {
    puts $fout [helpdoc node_serialize $entryid]
  }
  helpdoc eval {
    select entryid from entry
    where class!='section'
    order by parent,class,name
  } {
    puts $fout [helpdoc node_serialize $entryid]
  }
  puts $fout "helpdoc eval {commit}"
  close $fout
}

###
# topic: cd6e815c-2e68-b751-656a-4c9bbe8918dd
# description: Filters extranous fields from meta data
###
proc ::codebale::meta_scrub {aliases info} {
  foreach {c alist} $aliases {
    foreach a $alist {
      set canonical($a) $c
    }
  }

  set outfo {}
  foreach {field val} $info {
    if {[info exists canonical($field)]} {
      set cname $canonical($field)
    } else {
      set cname $field
    }
    if {$cname eq {}} continue
    if {[string length [string trim $val]]} {
      dict set outfo $cname $val
    }
  }
  return $outfo
}

###
# topic: ead7e6fe-5660-70cc-79f0-eb2f5182465e
###
proc ::codebale::normalize_tabbing {rawblock {newspace 0}} {
  set result {}
  ###
  # clean up spaces
  ###
  set block [string map [list \t "    "] $rawblock]
  
  set spaces -1
  while {[string index $block [incr spaces]] eq " " } {}
  if { $spaces < 0} {
    return $rawblock
  }
  set count 0
  foreach line [split $block \n] {
    if {[string first " " $line] > 0} {
      set spaces -1
      break
    }
    incr count
    set i [string last " " $line]
    if { ($i+1) < $spaces } {
      set spaces [expr $i + 1]
    }
  }
  if {$spaces <= 0} {
    return $rawblock
  }
  set head [string repeat " " $newspace]
  foreach line [split $block \n] {
    append result $head [string range $line $spaces end] \n
  }
  return $result
}

###
# topic: a6ee7ffd-7430-c9cc-d666-9addf08fd039
# description:
#    Parses a script, namespace body, or class
#    definition.
###
proc ::codebale::parse_body {meta body modvar} {
  
  upvar 1 $modvar match
  set match 0
  set patterns [parser_patterns [dictGet $meta scope]]
  foreach {pat info} $patterns {
    if {[regexp $pat $body]} {
      set match 1
      break
    }      
  }

  ###
  # Pass through if we don't see any patterns to match
  ###
  if {!$match} {
    return [list body $body]
  }
  
  set thisline {}
  set thiscomment {}
  set incomment 0
  set linecount 0
  set inheader 1

  array set result {
    namespace {}
    header    {}
    body      {}
    command   {}
    comment   {}
  }
  dict set meta comment {}

  foreach line [split $body \n] {
    append thisline \n $line
    if {![info complete $thisline]} continue
    
    set parseline [string range $thisline 1 end]
    set thisline {}

    if { $incomment } {
      if {[string index [string trimleft $parseline] 0] ne "#"} {
        set incomment 0
        set thiscomment [string trimright $thiscomment \n]
      } else {
        append thiscomment $parseline \n
        continue
      }
    } elseif {[string index [string trimleft $parseline] 0] eq "#"} {
      set incomment 1
      if {$inheader} {
        if {[string length $thiscomment]} {
          append result(header) $thiscomment \n
        }
      } else {
        if {[string length $thiscomment]} {
          append result(body) $thiscomment \n
        }
      }
      set thiscomment {}
      append thiscomment $parseline \n
      continue     
    }
    
    set cmd [pattern_match $patterns $parseline]
    if {$cmd eq {}} {
      set var body
      if {$inheader} {
        set var header
      } else {
        set var body
      }    
      if {[string length $thiscomment]} {
        append result($var) [string trimright $thiscomment \n] \n
        set thiscomment {}
      }
      append result($var) $parseline \n
    } else {
      set inheader 0
      set info $meta
      dict set info comment [string trim $thiscomment]
      if {[catch {{*}$cmd $info $parseline} lresult]} {
        puts "Error: [list {*}$cmd $info $parseline]"
        puts "$lresult"
        puts $::errorInfo
        exit
        error DIE
      }
      foreach {type info} $lresult {
        switch $type {
          header - body {
            #append result($type) $info \n
            buffer_append result($type) $info
          }
          command {
            foreach {pname pinfo} $info {
              dict set result($type) $pname $pinfo           
            }
          }
          namespace {
            logicset add result(namespace) {*}$info
          }
          default {
            append result($type) $info \n
          }
        }
      }
    }
    set thiscomment {}
  }
  return [array get result]
}

###
# topic: a18c5371-2559-4150-a50c-0a21013ba712
# description:
#    Parses a namespace and redeclares any procs as
#    glob procs pointing to the current namespace
###
proc ::codebale::parse_namespace {meta def} {
  global cmdref base block fileinfo
  set nspace [lindex $def end-1]
  set body [lindex $def end]

  set nspace [string trim $nspace :]
  if { $nspace eq {} } {
    set Nspace Global
  } else {
    set Nspace $nspace
  }
  set thisline {}
  array set result {
    command {}
    body    {}
    header  {}
  }
  
  dict set aliases {} [list topic subtopic proc namespace nspace class arglist method]
  set info [digest_comment [dict get $meta comment] $meta]
  set info [meta_scrub $aliases $info]
  dict set info type namespace
  
  helpdoc node_define namespace $Nspace $info nodeid
  set result(meta) [helpdoc node_properties $nodeid]

  set comment         [rewrite_comment 0 $nodeid $result(meta)]

  array set result [parse_body [list {*}$meta namespace $nspace parent $nodeid] $body mod]
  buffer_append newbody [get result(header)] [get result(body)]
  set result(header) {}

  if {[string length [string trim $newbody]]} {
    set result(body) [buffer_merge $comment "[list namespace eval ::$nspace] \{\n$newbody\}"]
  } else {
    logicset add result(namespace) $nspace
    set result(body) {}
    #[dict get $meta comment]
  }
  set result(comment) $comment
  return [array get result]
}

###
# topic: bab541dc-7ab2-5960-b7b3-75553ef388aa
###
proc ::codebale::parse_ooclass {meta def} {
  set nspace [lindex $def end-1]
  set body   [lindex $def end]

  set nspace [string trim $nspace :]
  
  set thisline {}
  array set result {
    command {}
    body    {}
    header  {}
  }
  
  set info [digest_comment [dict get $meta comment] $meta]
  dict set aliases {} [list topic subtopic proc namespace nspace class arglist method]
  set info [meta_scrub $aliases $info]
  dict set info type class
  helpdoc node_define class $nspace $info nodeid
  set result(meta)    [helpdoc node_properties $nodeid]
  set comment         [rewrite_comment 0 $nodeid $result(meta)]
  
  ###
  # Write in the results
  ###
  array set result [parse_body [list {*}$meta class $nspace parent $nodeid scope ooclass] $body mod]
  buffer_append newbody [get result(header)] [get result(body)]
  set result(header) {}
  foreach {mname} [lsort -dictionary [dict keys $result(command)]] {
    buffer_append newbody [dict get $result(command) $mname]
  }
  unset result(command)

  set result(body) [buffer_merge $comment "[list {*}[lrange $def 0 end-1]] \{\n$newbody\}"]
  set result(comment) $comment
  return [array get result]
}

###
# topic: 16fbb45b-8e9a-a13b-0b89-2270fd7537ff
# description:
#    This procedure reads in the definition of a method,
#    marks it up in the help documentation, and seeds the
#    re-writer so that this method is creates in sorted order
###
proc ::codebale::parse_oomethod {meta def} {
  set token    [lindex $def 0]
  if {[string range $token 0 5]=="class_"} {
    set cmd "class_method"
    set class class_method
  } else {
    set cmd "method"
    set class method
  }
  set def "  [list $cmd {*}[lrange $def 1 end-1]] \{[lindex $def end]\}"
  set def [normalize_tabbing $def 2]

  set token    [lindex $def 0]
  set procname [string trim [lindex $def 1] :]
  set fullname [string trimleft $class :]::$procname
  if {[llength $def] < 4} {
    set arglist dictargs
    set darglist dictargs
    set body [lindex $def 3]
  } else {
    set arglist [lindex $def 2]
    set body [lindex $def 4]
    ###
    # Clean up args
    ###
    set darglist {}
    foreach n $arglist {
      if [catch {
      if {[llength $n] > 1} {
        lappend darglist "?[lindex $n 0]?"
      } else {
        lappend darglist [lindex $n 0]
      }
      } err] {
        lappend darglist $n
      }
    }
  }
  
  ###
  # Document
  ###
  set info [digest_comment [dict get $meta comment] $meta]
  set type [dictGet $info type]

  if {$type eq {}} {
    set type [string trim $token :]
    if { $type ne "method" } {
      dict set info type $type
    }
  }
  
  dict set aliases returns {return yields}
  dict set aliases {} [list topic subtopic proc namespace nspace class arglist method $type]
  set info [meta_scrub $aliases $info]
  dict set info type $type
  dict set info arglist $darglist
  helpdoc node_define_child [dictGet $meta parent] $class $procname $info nodeid
  set result(meta)    [helpdoc node_properties $nodeid]
  set result(comment) [rewrite_comment 2 $nodeid $result(meta)]

  set result(command) $def
  return [list command [list ${class}::${procname} [buffer_merge $result(comment) $result(command)]]]
}

###
# topic: 2e9b9100-a28c-1d6d-d421-95779706ad24
# description:
#    This procedure reads in the definition of a method,
#    marks it up the ancestors for this object
###
proc ::codebale::parse_oosuperclass {meta def} {
  set parentid [dictGet $meta parent]
  foreach class [lrange $def 1 end] {
    set ancestor [helpdoc node_id [list class $class] 1]
    helpdoc link_create $parentid $ancestor class_ancestor
  }
  return [list header $def]
}

###
# topic: 0360b378-6857-5d30-2ab6-f15e88365266
###
proc ::codebale::parse_path {info base args} {
  set rewrite 0
  set repo    source
  dict with info {}

  set pathlist $args
  if {[llength $pathlist]==0} {
    set pathlist $base
  }
  
  set stack {}
  foreach path $pathlist {
    stack push stack $path
  }
  set filelist {}
  while {[stack pop stack stackpath]} {
    lappend filelist {*}[sniffPath $stackpath stack]
  }
  set meta [list repo $repo rewrite $rewrite base $base]
  if {![helpdoc exists {select localpath from repository where handle=:repo}]} {
    helpdoc eval {insert into repository (handle,localpath) VALUES (:repo,:base);}
  } else {
    helpdoc eval {update repository set localpath=:base where handle=:repo;}
  }
  foreach {type file} $filelist {
    switch $type {
      parent_name -
      source {
        if { [file tail $file] in {version_info.tcl packages.tcl lutils.tcl}} continue
        if {[catch {
          parse_tclsourcefile $meta $file $rewrite
        } err]} {
          puts [list $file $err]
          puts $::errorInfo
          if {[file exists $file.new]} {
            puts "X $file.new"
            file delete $file.new
          }
        }
      }
      csource {
        if {[catch {
          read_csourcefile $file
          
        } err]} {
          puts [list $file $err]
        }
      }
      index {
        continue
      }
    }
  }
}

###
# topic: 70a6c102-860a-d996-77f3-c4f2021a5308
# description:
#    This procedure reads in the definition of a procedures,
#    marks it up in the help documentation, and seeds the
#    re-writer so that this procedure is defined from the
#    global namespace
###
proc ::codebale::parse_procedure {meta def} {
  set def [normalize_tabbing $def]

  foreach {token procname arglist body} $def break;
  set rawproc $procname
  set proc [namespace tail $procname]
  set nspace [string trimleft [proc_nspace $rawproc] :]
  if { $nspace eq {} } {
    set nspace [dictGet $meta namespace]
  }
  if {$nspace in {{} ::}} {
    set fullname [string trim $proc :]
  } else {
    set fullname ${nspace}::${proc}
  }
  set result(namespace) $nspace
  set result(command) [list $token ::$fullname $arglist]
  append result(command) " \{$body\}"

  ###
  # Document
  ###
  set type [string trim $token :]
  dict set aliases yields return
  dict set aliases {} [list topic subtopic proc namespace nspace class arglist $type]

  set info [digest_comment [dict get $meta comment] $meta]
  set info [meta_scrub $aliases $info]
  
  dict set info type $type
  ###
  # Clean up args
  ###
  set darglist {}
  foreach n $arglist {
    if {[llength $n] > 1} {
      lappend darglist "?[lindex $n 0]?"
    } else {
      lappend darglist [lindex $n 0]
    }
  }
  dict set info arglist $darglist

  helpdoc node_define proc $fullname $info nodeid
  set result(meta) [helpdoc node_properties $nodeid]
  set result(comment) [rewrite_comment 0 $nodeid $result(meta)]

  return [list command [list $fullname [buffer_merge $result(comment) $result(command)]] namespace $result(namespace)]
}

###
# topic: 7c9f9cea-7829-7eef-903b-3f711033a993
###
proc ::codebale::parse_tclsourcefile {meta file {rewrite 0}} {
  global classes block filename fileinfo
  variable parser_patterns
  array unset filestore
  
  dict with meta {}

  set i [string length $base]

  set fname [file rootname [file tail $file]]
  set dir [string trimleft [string range [file dirname $file] $i end] /]
  set fpath $dir/[file tail $file]
  set filename $dir/[file tail $file]

  set repomd5 [helpdoc file_hash [list $repo $fpath]]
  set md5 [::md5::md5 -hex -file $file]
  
  if {!$::force_check} {
    if { $md5 eq $repomd5} { return 0 }
  }
  
  set info {}
  dict set info mtime [file mtime $file]
  dict set info hash  $md5
  dict set info path  $fpath
  dict set info filename [file tail $file]
  dict set info repo  $repo
  helpdoc file_restore [list $repo $fpath] $info
  
  #set ::filemd5($fpath) $md5
  
  set fin [open $file r]
  set dat [read $fin]
  close $fin
  
  puts "<< $fpath"
  set fileinfo {}
  set result [parse_body [list namespace {} file $file] $dat patmatch]
  if {!$rewrite || !$patmatch} {
    return $patmatch
  }
  ###
  # Rewrite the tcl sourcefile
  ###
  set buffer {}

  set ndefined {}
  set header {}
  set body {}
  set command {}
  set namespace {}
  set buffer {}
  dict with result {}
  buffer_append buffer $header
  foreach ns [lsort -dictionary $namespace] {
    if { $ns ne {} } {
      append buffer \n [list ::namespace eval ::$ns {}] \n
    }
  }  
  if {[llength $command]} {
    foreach {nsproc} [lsort -dictionary [dict keys $command]] {
      buffer_append buffer [dict get $command $nsproc]
    }
  }
  buffer_append buffer $body

  set oldlines [split $dat \n]
  set newlines [split $buffer \n]
  set idx -1
  set identical 1
  foreach oldline $oldlines {
    set newline [lindex $newlines [incr idx]]
    if {[string trim $oldline] ne [string trim $newline]} {
      set identical 0
      break
    }
  }
  if {$identical} {
    if {[file exists $file.new]} {
      puts "~ $file.new"
      file delete $file.new
    }
    return $patmatch
  }
  puts ">> $fpath.new"
  set fout [open $file.new w]
  fconfigure $fout -translation crlf
  puts $fout $buffer
  close $fout
  return $patmatch
}

###
# topic: 233756d1-a3b7-6fa9-3023-ccae156e0ec5
###
proc ::codebale::parser_addpattern args {
  variable parser_patterns
  dict set parser_patterns {*}$args
}

###
# topic: d086f779-79bd-e4d7-f60d-41af050c529d
###
proc ::codebale::parser_patterns scope {
  variable parser_patterns
  set result {}
  foreach {pat info} [dictGet $parser_patterns $scope] {
    dict set result $pat $info
  }
  return $result
}

###
# topic: 6fd968f4-2730-f701-c0fa-3ca32b8f7785
###
proc ::codebale::pattern_match {patterns parseline} {
  set parseline [string trimleft $parseline :]
  foreach {pat patinfo} $patterns {
    set idx -1
    set match 1
    foreach a $pat {
      incr idx
      if [catch {lindex $parseline $idx} token] {
        set match 0
        break
      }
      if {![string match $token $a] } {
        set match 0
        break
      }
    }
    if { $match } {
      return $patinfo
    }
  }
  return {}
}

proc ::codebale::pkg_mkIndex base {
  set stack {}
  if {[file exists [file join $base pkgIndex.tcl]]} {
    return
    #file delete [file join $base pkgIndex.tcl]
  }
  set fout [open [file join $base pkgIndex.tcl.new] w]
  set result [::codebale::sniffPath $base stack]
  
  puts $fout {# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.
  }
  
  while {[llength $stack]} {
    set stackpath [lindex $stack 0]
    set stack [lrange $stack 1 end]
    foreach {type file} [::codebale::sniffPath $stackpath stack] { 
      lappend result $type $file
    }
  }
  set i [string length $base]
  foreach {type file} $result {
      switch $type {
          module {
              set fname [file rootname [file tail $file]]
              set package [lindex [split $fname -] 0]
              set version [lindex [split $fname -] 1]
              set dir [string trimleft [string range [file dirname $file] $i end] /]
              puts $fout "package ifneeded $package $version \[list source \[file join \$dir $dir [file tail $file]\]\]"
              #::codebale::read_tclsourcefile $file
          }
          source {
              if { $file == "$base/pkgIndex.tcl" } continue
              if { $file == "$base/packages.tcl" } continue
              if { $file == "$base/main.tcl" } continue
              if { [file tail $file] == "version_info.tcl" } continue
              set fin [open $file r]
              set dat [read $fin]
              close $fin
              if {[regexp "package provide" $dat]} {
                 set fname [file rootname [file tail $file]]
  
                 set dir [string trimleft [string range [file dirname $file] $i end] /]
              
                 foreach line [split $dat \n] {
                    set line [string trim $line]
                    
                    if { [string range $line 0 14] != "package provide" } continue
                    set package [lindex $line 2]
                    set version [lindex $line 3]
                    if { $dir eq {} } {
                      puts $fout "package ifneeded $package $version \[list source \[file join \$dir [file tail $file]\]\]"                      
                    } else {
                      puts $fout "package ifneeded $package $version \[list source \[file join \$dir $dir [file tail $file]\]\]"
                    }
                    break
                 }
              }
              #::codebale::read_tclsourcefile $file
          }
      }
  }
  close $fout
  file rename -force [file join $base pkgIndex.tcl.new] [file join $base pkgIndex.tcl]
}


###
# topic: 929629f0-ebaa-5547-10f6-6410dfa51f8a
###
proc ::codebale::pkgindex_path base {
  set stack {}
  set buffer {
set BASE [file dirname [file normalize [info script]]]
  }
  set base [file normalize $base]
  set i    [string length  $base]
  set result [::codebale::sniffPath $base stack]
  while {[llength $stack]} {
    set stackpath [lindex $stack 0]
    set stack [lrange $stack 1 end]
    lappend result {*}[::codebale::sniffPath $stackpath stack]
  }
  foreach {type file} $result {
    switch $type {
      parent_name {
        set file [file normalize $file]
        set fname [file rootname [file tail $file]]
        ###
        # Assume the package is correct in the filename
        ###
        set package [lindex [split $fname -] 0]
        set version [lindex [split $fname -] 1]
        set path [string trimleft [string range [file dirname $file] $i end] /]
        ###
        # Read the file, and override assumptions as needed
        ###
        set fin [open $file r]
        set dat [read $fin]
        close $fin
        foreach line [split $dat \n] {
          set line [string trim $line]
          if { [string range $line 0 9] != "# Package " } continue
          set package [lindex $line 2]
          set version [lindex $line 3]
          break
        }
        append buffer "package ifneeded $package $version \[list source \[file join \$BASE $path [file tail $file]\]\]"
        append buffer \n
      }
      source {
        set file [file normalize $file]
        if { $file == [file join $base tcl8.6 package.tcl] } continue
        if { $file == [file join $base packages.tcl] } continue
        if { $file == [file join $base main.tcl] } continue
        if { [file tail $file] == "version_info.tcl" } continue
        set fin [open $file r]
        set dat [read $fin]
        close $fin
        if {![regexp "package provide" $dat]} continue
        set fname [file rootname [file tail $file]]
        set dir [string trimleft [string range [file dirname $file] $i end] /]
        
        foreach line [split $dat \n] {
          set line [string trim $line]              
          if { [string range $line 0 14] != "package provide" } continue
          set package [lindex $line 2]
          set version [lindex $line 3]
          append buffer "package ifneeded $package $version \[list source \[file join \$BASE $dir [file tail $file]\]\]"
          append buffer \n
          break
        }
      }
      index {
        if {[file dirname $file] eq $base } continue
        set dir [string trimleft [string range [file dirname $file] $i end] /]
        append buffer "set dir \[file join \$BASE $dir\] \; source \[file join \$BASE $dir [file tail $file]\]"
        append buffer \n
      }
    }
  }
  return $buffer
}

###
# topic: f9b3ce3a-afc9-72b5-5e33-0ac9b62c31db
###
proc ::codebale::proc_nspace procname {
  set rawproc $procname
  set proc [namespace tail $procname]
  set n [string last $proc $rawproc]
  if { $n == 0 } {
    set nspace {}
  } else {
    set nspace [string range $rawproc 0 [expr {$n - 1}]]
    set nspace [string trimleft $nspace :]
    set nspace [string trimright $nspace :]
  }
  return $nspace
}

###
# topic: 27a7f169-8a00-fb29-4f2c-700a8d8acb7e
###
proc ::codebale::read_csourcefile file {
  global classes base filename
  ###
  # Skip huge files
  ###
  if {[file size $file] > 500000} {return 0}
  set i [string length $base]

  set fname [file rootname [file tail $file]]
  set dir [string trimleft [string range [file dirname $file] $i end] /]
  set fpath $dir/[file tail $file]
  set filename $dir/[file tail $file]
  set fin [open $file r]
  set dat [read $fin]
  close $fin
  set found 0

  set thisline {}
  set thiscomment {}
  set incomment 0
  set parentid tclcmd
  foreach line [split $dat \n] {
    set line [string trim $line]
    if {[string range $line 0 1] == "/*" } {
        set incomment 1
    }
    if { $incomment } {
      set pline [string trimleft $line "/"]
      set pline [string trimleft $pline "*"]
      set pline [string trimright $pline "/"]
      set pline [string trimright $pline "*"]
      append thiscomment $pline \n


      if {[string range $line end-1 end] eq "*/" } {
        set incomment 0

        set info [digest_comment $thiscomment [list file $fpath]]
        set thiscomment {}
        set nodeid {}
        set found 0
        foreach {var val} $info {
          switch $var {
            topic {
              set nodeid $val
              dict unset info $var
            }
            tclcmd -
            tclmod {
              if { $nodeid eq {} } {
                set nodeid   [helpdoc node_id [list tclcmd [lindex $val 0]] 1]
              }
              set parentid $nodeid
              helpdoc node_property_set $nodeid usage $val
              dict unset info $var
            }
            tclmethod -
            tclsubcmd {
              if { $nodeid eq {} } {
                set nodeid [helpdoc node_id [list tclcmd [lindex $val 0] method [lindex $val 1]] 1]
              }
              dict unset info $var
              helpdoc node_property_set $nodeid usage   $val              
              helpdoc node_property_set $nodeid arglist [lrange $val 2 end]
            }
          }
        }
        if { $nodeid ne {} } {
          #puts [list $nodeid $info]
          helpdoc node_property_set $nodeid file $fpath

          dict set info file $fpath
          foreach {var val} $info {
            switch $var {
              topic -
              tclcmd -
              tclmod -
              tclmethod -
              tclsubcmd {}
              default {
                helpdoc node_property_set $nodeid $var $val
              }
            }
          }
        }
      }
    }
  }
  return 1
}

###
# topic: 7958a706-b48a-9bc4-4cbb-ef73813e0fb2
###
proc ::codebale::rewrite_comment {spaces topic info} {
  set result {}
  set head [string repeat " " $spaces]
  set class [helpdoc one {select class from entry where entryid=:topic}]
  if { $class eq [dictGet $info type] } {
    dict unset info type
  }

  set order [dict keys $info]
  logicset remove order type description arguments returns yields title
  set order [linsert order 0 title type]
  lappend order description arguments returns yields
  foreach {field} $order {
    set val [dictGet $info $field]
    ###
    # Fields to drop for meta-data
    ###
    set dtext [split [string trim $val] \n]
    if {![llength $dtext]} {
      continue
    }
    if {[llength $dtext] == 1} {
      append result \n "${head}# ${field}: [string trim [lindex $dtext 0]]"
    } else {
      append result \n "${head}# ${field}:"
      foreach dline $dtext {
        append result \n "${head}#    [string trim $dline]"
      }
    }
  }

  set result [buffer_merge "${head}###" "${head}# topic: $topic" $result "${head}###"]
}

###
# topic: 003ce0c0-d69b-7407-6e84-33492deac920
# description:
#    Descends into a directory structure, returning
#    a list of items found in the form of:
#    type object
#    where type is one of: csource source parent_name
#    and object is the full path to the file
###
proc ::codebale::sniffPath {spath stackvar} {
  upvar 1 $stackvar stack    
  set result {}
  if { ![file isdirectory $spath] } {
    switch [file extension $spath] {
      .tm {
        return [list parent_name $spath]
      }
      .tcl {
        return [list source $spath]
      }
      .h {
        return [list cheader $spath]
      }
      .c {
        return [list csource $spath]
      }
    }    
    return
  }
  foreach f [glob -nocomplain $spath/*] {
    if {[file isdirectory $f]} {
      if {[file tail $f] in {CVS build} } continue
      if {[file extension $f] eq ".vfs" } continue
      set stack [linsert $stack 0 $f]
    }
  }
  set idx 0
  foreach idxtype {
    pkgIndex.tcl tclIndex
  } {
    if {[file exists [file join $spath $idxtype]]} {
      lappend result index [file join $spath $idxtype]
    }
  }
  if {[llength $result]} {
    return $result
  }
  foreach f [glob -nocomplain $spath/*] {
    if {![file isdirectory $f]} {
      set stack [linsert $stack 0 $f]
    }
  }
  return {}
}

###
# topic: 47266d90-061e-780e-234e-c3245d85c176
###
proc ::codebale::strip_ccoments buffer {
  
  ###
  # Strip C /* comments */
  ###
  set string $buffer
  set result {}
  set idx 0
  while {[set ndx [string first "/*" $string $idx]] >=0 } {
    append result [string range $string $idx [expr {$ndx-1}]]
    set idx [string first */ $string [expr {$ndx+2}]]
    if { $idx < 0 } {
      break
    }
    incr idx 2
  }
  append result [string range $string $idx end]

  ###
  # Strip C++ // comments
  ###
  set string $result
  set result {}
  set idx 0
  while {[set ndx [string first "//" $string $idx]] >=0 } {
    append result [string range $string $idx [expr {$ndx-1}]]
    set idx [expr {$ndx+1}]
    while 1 {
      set idx [string first "\n" $string $idx]
      if { $idx < 0 } {
        break
      }
      if {[string index $string [expr {$idx-1}]] == "\\"} {
        incr idx
        continue
      }
      break
    }
    incr idx
  }
  append result [string range $string $idx end]
  
  set string [split $result \n]
  set result {}
  set continueline 0
  foreach line $string {
    set line [string trim $line]
    if {$continueline} {
      if {[string index $line end] ne "\\"} {
        set continueline 0
      }
    } else {
      if {[string index $line 0] eq "#"} {
        if {[string index $line end] eq "\\"} {
          set continueline 1
        }
      } else {
        append result \n $line
      }
    }
  }
  return $result
}

proc ::codebale::first_autoconf_token line {
  set line [string trim $line]
  set idx [string first "(" $line]
  if { $idx < 0 } {
    return {}
  }
  return [string range $line 0 $idx-1]
}

proc ::codebale::rewrite_autoconf {} {
  ###
  # Update the AC_INIT line in configure.in
  ###
  set fout [open [file join $::project(path) configure.in.new] w]
  set fin  [open [file join $::project(path) configure.in] r]
  set wrote_sources 0
  
  while {[gets $fin line]>=0} {
    switch [first_autoconf_token $line] {
      "AC_INIT" {
        puts $fout "AC_INIT(\[$::project(pkgname)\], \[$::project(pkgvers)\])"        
      }
      "m4_include" -
      "TEA_ADD_HEADERS" -
      "TEA_ADD_SOURCES" {
        if { !$wrote_sources } {
puts $fout "TEA_ADD_HEADERS(\[generic/${::project(h_file)}\])"
#puts $fout "TEA_ADD_SOURCES(\[generic/${project(c_file)}\])"
set wrote_sources 1
        foreach file $::project(tcl_sources) {
          puts $fout "TEA_ADD_TCL_SOURCES(\[$file\])"
        }
        }
      }
      default {
        puts $fout $line
      }
    }
  }

  close $fin
  close $fout
  file rename -force [file join $::project(path) configure.in.new] [file join $::project(path) configure.in]
}

set ::force_check 0

###
# topic: c790d2a5-043a-5f76-a476-143db91bd729
###
namespace eval ::codebale {
  alias nspace namespace

  parser_addpattern {}  {namespace eval}   ::codebale::parse_namespace
  parser_addpattern {}  proc               ::codebale::parse_procedure
  parser_addpattern {}  ensemble_method    ::codebale::parse_procedure
  parser_addpattern {}  odie::class        ::codebale::parse_ooclass  
  parser_addpattern {}  tao::class        ::codebale::parse_ooclass  
  parser_addpattern {}  {oo::class create} ::codebale::parse_ooclass
  parser_addpattern ooclass method         ::codebale::parse_oomethod
  parser_addpattern ooclass proc           ::codebale::parse_oomethod
  parser_addpattern ooclass class_method   ::codebale::parse_oomethod
  parser_addpattern ooclass superclasses   ::codebale::parse_oosuperclass
}

