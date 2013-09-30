###
# topic: 4d828e6f-3d34-e26b-b3ed-0e0a79134099
# description:
#    Open a console window for direct access to the
#    Tcl/Tk command interface to the IRM software suite
###
proc ::console:start {} {
  if {[winfo exists .console]} {
    wm deiconify .console
    update
    raise .console
  } else {
    set args [list -prompt {wish% } -title {Tcl/Tk Shell}]
    if {[info exists ::g(font-console)]} {
      lappend args -font $::g(font-console)
    }
    taotk::console .console {*}$args
  }
  
  catch {rename puts console:oldputs}
  proc puts args {
    if {![winfo exists .console]} {
      rename puts {}
      rename console:oldputs puts
      return [uplevel #0 puts $args]
    }
    switch -glob -- "[llength $args] $args" {
      {1 *} {
         set msg [lindex $args 0]\n
         set tag ok
      }
      {2 stdout *} {
         set msg [lindex $args 1]\n
         set tag ok
      }
      {2 stderr *} {
         set msg [lindex $args 1]\n
         set tag err
      }
      {2 green *} {
         set msg [lindex $args 1]\n
         set tag grn
      }
      {2 purple *} {
         set msg [lindex $args 1]\n
         set tag purple
      }
      {2 lightblue *} {
         set msg [lindex $args 1]\n
         set tag lblue
      }
      {2 orange *} {
         set msg [lindex $args 1]\n
         set tag orange
      }
      {2 -nonewline *} {
         set msg [lindex $args 1]
         set tag ok
      }
      {3 -nonewline stdout *} {
         set msg [lindex $args 2]
         set tag ok
      }
      {3 -nonewline stderr *} {
         set msg [lindex $args 2]
         set tag err
      }
      default {
        uplevel #0 console:oldputs $args
        return
      }
    }
    .console puts $msg $tag
  }
}

###
# topic: 8f8a761e-ba0a-7781-9c16-9facd26cba92
# description:
#    By the overt act of typing this comment, the author of this code
#    releases it into the public domain.  No claim of copyright is made.
#    In place of a legal notice, here is a blessing:
#    
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#    
#    
#    
#    This file contains code use to implement a simple command-line console
#    for Tcl/Tk.
###
tao::class taotk::meta::console {
  superclass taotk::meta::widget

  option title {
    default {}
  }  
  option prompt {
    default {wish% }
  }
  option font {
    default {fixed 10}
    widget font
  }

  constructor {window args} {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]  
    my initialize
    my BuildDynamicMethods
    my Build_topframe $window
    my build_widget $window
    my bind_widget $window
  }
  

  ###
  # topic: 39f1757e-4b60-d1d5-4282-ec73f8fd3717
  ###
  method addHistory line {
    my variable v
    if {$v(historycnt)>0} {
      set last [lindex $v(history) [expr $v(historycnt)-1]]
      if {[string compare $last $line]} {
        lappend v(history) $line
        incr v(historycnt)
      }
    } else {
      set v(history) [list $line]
      set v(historycnt) 1
    }
    set v(current) $v(historycnt)
  }

  ###
  # topic: 0fe4f765-7c4f-e2c6-7d3b-b393f4c4524e
  # description:
  #    Called whenever the mouse leaves the boundries of the widget
  #    while button 1 is held down.
  ###
  method B1Leave {x y} {
    my variable v
    set v(y) $y
    set v(x) $x
    my motor
  }

  ###
  # topic: 6e6433ac-020f-c2a2-b954-38949ca27ff1
  # description: Called whenever the mouse moves while button-1 is held down.
  ###
  method B1Motion {x y} {
    my variable v
    set v(y) $y
    set v(x) $x
    my SelectTo $x $y
  }

  ###
  # topic: 7c78e823-a093-405f-4eb3-75719d701787
  # description: Erase the character to the left of the cursor
  ###
  method Backspace {} {
    my variable v
    scan [my text index insert] %d.%d row col
    if {$col>$v(plength)} {
      my text delete {insert -1c}
    }
  }

  ###
  # topic: 429d0394-f005-1aba-c340-545873867e7a
  ###
  method build_buttons {} {
    set w [my organ topframe]
    my variable v
    ttk::frame $w.mb
    my graft buttonframe $w.mb
    pack $w.mb -side top -fill x
    menubutton $w.mb.file -text File -menu $w.mb.file.m
    menubutton $w.mb.edit -text Edit -menu $w.mb.edit.m
    menubutton $w.mb.tool -text Tools -menu $w.mb.tool.m
    pack $w.mb.file $w.mb.edit $w.mb.tool -side left -padx 8 -pady 1
    set m [menu $w.mb.file.m -tearoff 0]
    # $m add command -label {Source...} -command "console:SourceFile $w.t"
    # $m add command -label {Save As...} -command "console:SaveFile $w.t"
    # $m add separator
    $m add command -label {Close} -command [list destroy [my organ topframe]]
    $m add command -label {Exit} -command exit
    #$m add command -label {SQLite Console} -command \
    #   {::sqlitecon::create .sqlitecon {sqlite> } {SQLite Console} db}    

    set m [menu $w.mb.tool.m -tearoff 0]

    set editmenu $w.mb.edit.m
    set v(editmenu) $editmenu
    set m [menu $editmenu -tearoff 0]
    $m add command -label Cut -command [namespace code "my Cut"]
    $m add command -label Copy -command [namespace code "my Copy"]
    $m add command -label Paste -command [namespace code "my Paste"]
    $m add command -label {Clear Screen} -command [namespace code "my Clear"]
    $m add separator
    $m add command -label {Source...} -command [namespace code "my SourceFile"]
    $m add command -label {Save As...} -command [namespace code "my SaveFile"]
    catch {$editmenu config -postcommand [namespace code "my EnableEditMenu"]} 
  }

  ###
  # topic: 7431f491-3f8e-6bd8-97dd-d159e5b777d9
  ###
  method build_console {} {
    set w [my organ topframe]
    my variable v

    ttk::scrollbar $w.sb -orient vertical -command "$w.t yview"
    pack $w.sb -side right -fill y
    text $w.t -font [my cget font] -yscrollcommand "$w.sb set"
    pack $w.t -side right -fill both -expand 1

    my graft text $w.t
    set prompt [my cget prompt]
    
    set v(text) $w.t
    set v(history) 0
    set v(historycnt) 0
    set v(current) -1
    set v(prompt) $prompt
    set v(prior) {}
    set v(plength) [string length $v(prompt)]
    set v(x) 0
    set v(y) 0
    $w.t mark set insert end
    $w.t tag config ok -foreground blue
    $w.t tag config err -foreground red
    $w.t tag config grn -foreground #00a000
    $w.t tag config purple -foreground #c000c0
    $w.t tag config lblue -foreground #417a9b
    $w.t tag config orange -foreground #be9e4f
    $w.t insert end $v(prompt)
    $w.t mark set out 1.0
    
    after idle "focus $w.t"
    bindtags $w.t [list $w.t . all]

    bind $w.t <1>         [namespace code {my Button1 %x %y}]
    bind $w.t <B1-Motion> [namespace code {my B1Motion %x %y}]
    bind $w.t <B1-Leave>  [namespace code {my B1Leave %x %y}]
    bind $w.t <B1-Enter>  [namespace code {my cancelMotor}]
    bind $w.t <ButtonRelease-1> [namespace code {my cancelMotor}]
    bind $w.t <KeyPress>  [namespace code {my Insert %A}]
    bind $w.t <Left>      [namespace code {my Left}]
    bind $w.t <Control-b> [namespace code {my Left}]
    bind $w.t <Right>     [namespace code {my Right}]
    bind $w.t <Control-f> [namespace code {my Right}]
    bind $w.t <BackSpace> [namespace code {my Backspace}]
    bind $w.t <Control-h> [namespace code {my Backspace}]
    bind $w.t <Delete>    [namespace code {my Delete}]
    bind $w.t <Control-d> [namespace code {my Delete}]
    bind $w.t <Home>      [namespace code {my Home}]
    bind $w.t <Control-a> [namespace code {my Home}]
    bind $w.t <End>       [namespace code {my End}]
    bind $w.t <Control-e> [namespace code {my End}]
    bind $w.t <Return>    [namespace code {my Enter}]
    bind $w.t <KP_Enter>  [namespace code {my Enter}]
    bind $w.t <Up>        [namespace code {my Prior}]
    bind $w.t <Control-p> [namespace code {my Prior}]
    bind $w.t <Down>      [namespace code {my Next}]
    bind $w.t <Control-n> [namespace code {my Next}]
    bind $w.t <Control-k> [namespace code {my EraseEOL}]
    bind $w.t <<Cut>>     [namespace code {my Cut}]
    bind $w.t <<Copy>>    [namespace code {my Copy}]
    bind $w.t <<Paste>>   [namespace code {my Paste}]
    bind $w.t <<Clear>>   [namespace code {my Clear}]
  }

  ###
  # topic: 718a90a8-50eb-fa90-ed37-0a71d76c50f8
  ###
  method build_widget window {
    my build_buttons    
    my build_console
  }

  ###
  # topic: da2c0cbc-c9db-4e6c-7845-acd8126f3f9c
  # description:
  #    Called when the mouse button is pressed at position $x,$y on
  #    the console widget.
  ###
  method Button1 {x y} {
    global tkPriv
    set w [my organ text]
    my variable v
    set v(mouseMoved) 0
    set v(pressX) $x
    set p [my nearestBoundry $x $y]
    scan [my text index insert] %d.%d ix iy
    scan $p %d.%d px py
    if {$px==$ix} {
      my text mark set insert $p
    }
    my text mark set anchor $p
    focus $w
  }

  ###
  # topic: 16aab5a0-d905-f38b-c90b-bcbb6cf1b103
  # description: This routine cancels the scrolling motor if it is active
  ###
  method cancelMotor {} {
    my variable v
    if [info exists v(timer)] {
      catch {after cancel $v(timer)}
      catch {unset -nocomplain v(timer)}
    }
  }

  ###
  # topic: 0acebbb2-b043-5f64-d65f-628aa70094fc
  # description:
  #    Return 1 if the selection exists and is contained
  #    entirely on the input line.  Return 2 if the selection
  #    exists but is not entirely on the input line.  Return 0
  #    if the selection does not exist.
  ###
  method canCut {} {
    set r [catch {
      scan [my text index sel.first] %d.%d s1x s1y
      scan [my text index sel.last] %d.%d s2x s2y
      scan [my text index insert] %d.%d ix iy
    }]
    if {$r==1} {return 0}
    if {$s1x==$ix && $s2x==$ix} {return 1}
    return 2
  }

  ###
  # topic: 228bf7a9-8a5b-e4ba-ae06-f4267d973cad
  # description: Erase everything from the console above the insertion line.
  ###
  method Clear {} {
    my text delete 1.0 {insert linestart}
  }

  ###
  # topic: 93cbd31b-d15a-e06a-d679-fa580c0fd0c1
  # description: Do a Copy operation on the stuff currently selected.
  ###
  method Copy {} {
    set w [my organ text]
    if {![catch {set text [my text get sel.first sel.last]}]} {
       clipboard clear -displayof $w
       clipboard append -displayof $w $text
    }
  }

  ###
  # topic: fb18734a-1651-9500-4651-0ff183112069
  # description:
  #    Do a Cut operation if possible.  Cuts are only allowed
  #    if the current selection is entirely contained on the
  #    current input line.
  ###
  method Cut {} {
    if {[my canCut]==1} {
      my Copy
      my text delete sel.first sel.last
    }
  }

  ###
  # topic: 5b4bb326-b741-0b42-4ffb-aa9df46950c0
  # description: Erase the character to the right of the cursor
  ###
  method Delete {} {
    my text delete insert
  }

  ###
  # topic: eb9028f1-8070-e4ee-4040-0161e508ab67
  ###
  method dialog_preferences {} {
    set pvar [my varname prefs]
    set f [my organ topframe]
    if {[winfo exists $f.prefs]} {
      destroy {*}[winfo children $f.prefs]
      wm deiconify $f.prefs
      raise $f.prefs
      $f.prefs signal build_content
    } else {
      ::taotk::preference_panel $f.prefs object [self]
    }
  }

  ###
  # topic: ee9ff93d-efb7-6b02-b503-9ee947540d19
  # description: Enable or disable entries in the Edit menu
  ###
  method EnableEditMenu {} {
    my variable v
    set m $v(editmenu)
    if {$m=="" || ![winfo exists $m]} return
    switch [my canCut] {
      0 {
        $m entryconf Copy -state disabled
        $m entryconf Cut -state disabled
      }
      1 {
        $m entryconf Copy -state normal
        $m entryconf Cut -state normal
      }
      2 {
        $m entryconf Copy -state normal
        $m entryconf Cut -state disabled
      }
    }
  }

  ###
  # topic: a26c92ac-378b-3d52-6f2b-78ffe8881646
  # description: Move the cursor to the end of the current line
  ###
  method End {} {
    my text mark set insert {insert lineend}
  }

  ###
  # topic: 2f2a366f-3cb5-d6c1-2558-ae3efba9d4e8
  # description:
  #    Called when "Enter" is pressed.  Do something with the line
  #    of text that was entered.
  ###
  method Enter {} {
    my variable v
    set w [my organ text]
    scan [my text index insert] %d.%d row col
    set start $row.$v(plength)
    set line [my text get $start "$start lineend"]
    my addHistory $line
    my text insert end \n
    my text mark set out end
    if {$v(prior)==""} {
      set cmd $line
    } else {
      set cmd $v(prior)\n$line
    }
    if {[info complete $cmd]} {
      set rc [catch {uplevel #0 $cmd} res]
      if {![winfo exists $w]} return
      if {$rc} {
        my text insert end $res\n err
      } elseif {[string length $res]>0} {
        my text insert end $res\n ok
      }
      set v(prior) {}
      my text insert end $v(prompt)
    } else {
      set v(prior) $cmd
      regsub -all {[^ ]} $v(prompt) . x
      my text insert end $x
    }
    my text mark set insert end
    my text mark set out {insert linestart}
    my text yview insert
  }

  ###
  # topic: 917e7ac8-e460-b9c6-9259-e4c382eabe76
  # description: Erase to the end of the line
  ###
  method EraseEOL {} {
    my variable v
    scan [my text index insert] %d.%d row col
    if {$col>=$v(plength)} {
      my text delete insert {insert lineend}
    }
  }

  ###
  # topic: 57cac72c-f3af-ae1f-c1e8-748acfcacbac
  # description: Move the cursor to the beginning of the current line
  ###
  method Home {} {
    my variable v
    scan [my text index insert] %d.%d row col
    my text mark set insert $row.$v(plength)
  }

  ###
  # topic: e4e282b0-c9a6-a966-16b9-d2bf08e7d526
  # description: Insert a single character at the insertion cursor
  ###
  method Insert a {
    my text insert insert $a
    my text yview insert
  }

  ###
  # topic: c0e84133-fa1f-bdca-fd76-c80ba72bc041
  ###
  method insert text {
    my insert $a
    my Enter
  }

  ###
  # topic: 2dc7b2e4-22c9-8624-ae39-ebc67b96c56e
  # description: Move the cursor one character to the left
  ###
  method Left {} {
    my variable v
    scan [my text index insert] %d.%d row col
    if {$col>$v(plength)} {
      my text mark set insert "insert -1c"
    }
  }

  ###
  # topic: b828129b-836b-d94a-57a8-547088d5e649
  # description:
  #    This routine is called to automatically scroll the window when
  #    the mouse drags offscreen.
  ###
  method motor {} {
    my variable v
    set w [my organ text]
    if {![winfo exists $w]} return
    if {$v(y)>=[winfo height $w]} {
      $w yview scroll 1 units
    } elseif {$v(y)<0} {
      $w yview scroll -1 units
    } else {
      return
    }
    my SelectTo $v(x) $v(y)
    set v(timer) [after 50 [namespace code {my motor}]]
  }

  ###
  # topic: 5af84eb6-076e-825e-04b6-a0a1ff5845e2
  # description:
  #    Find the boundry between characters that is nearest
  #    to $x,$y
  ###
  method nearestBoundry {x y} {
    my variable v
    set p [my text index @$x,$y]
    set bb [my text bbox $p]
    if {![string compare $bb ""]} {return $p}
    if {($x-[lindex $bb 0])<([lindex $bb 2]/2)} {return $p}
    my text index "$p + 1 char"
  }

  ###
  # topic: 98961608-87f6-69df-e4d1-6d54081a9031
  # description: Change the line to the next line
  ###
  method Next {} {
    my variable v
    if {$v(current)>=$v(historycnt)} return
    incr v(current) 1
    set line [lindex $v(history) $v(current)]
    my SetLine $line
  }

  ###
  # topic: d7667e5e-2aba-b7fe-3467-e6de81d8fb10
  # description: Do a paste opeation.
  ###
  method Paste {} {
    my variable v
    if {[my canCut]==1} {
      my text delete sel.first sel.last
    }
    set w [my organ text]
    if {[catch {selection get -displayof $w -selection CLIPBOARD} topaste]
      && [catch {selection get -displayof $w -selection PRIMARY} topaste]} {
      return
    }
    set prior 0
    foreach line [split $topaste \n] {
      if {$prior} {
        my Enter
        update
      }
      set prior 1
      my text insert insert $line
    }
  }

  ###
  # topic: 363fde4f-69a8-a62e-6258-ec766593c38e
  # description: Change the line to the previous line
  ###
  method Prior {} {
    my variable v
    if {$v(current)<=0} return
    incr v(current) -1
    set line [lindex $v(history) $v(current)]
    my SetLine $line
  }

  ###
  # topic: 69320162-4278-a9f2-befa-400769cd92fb
  # description:
  #    Insert test at the "out" mark.  The "out" mark is always
  #    before the input line.  New text appears on the line prior
  #    to the current input line.
  ###
  method puts {t tag} {
    set nc [string length $t]
    set endc [string index $t [expr $nc-1]]
    if {$endc=="\n"} {
      if {[my text index out]<[my text index {insert linestart}]} {
        my text insert out [string range $t 0 [expr $nc-2]] $tag
        my text mark set out {out linestart +1 lines}
      } else {
        my text insert out $t $tag
      }
    } else {
      if {[my text index out]<[my text index {insert linestart}]} {
        my text insert out $t $tag
      } else {
        my text insert out $t\n $tag
        my text mark set out {out -1 char}
      }
    }
    my text yview insert
  }

  ###
  # topic: 977890cd-ac7c-46a9-7ff3-bf750e6e2055
  # description: Move the cursor one character to the right
  ###
  method Right {} {
    my text mark set insert "insert +1c"
  }

  ###
  # topic: d3be45ea-0bab-e57a-7187-46aa2351de01
  # description:
  #    Prompt the user for the name of a writable file.  Then write the
  #    entire contents of the console screen to that file.
  ###
  method SaveFile {} {
    set types {
      {{Text Files}  {.txt}}
      {{All Files}    *}
    }
    set f [tk_getSaveFile -filetypes $types -title "Write Screen To..."]
    if {$f!=""} {
      if {[catch {open $f w} fd]} {
        odieMessageBox -type ok -icon error -message $fd
      } else {
        puts $fd [string trimright [my text get 1.0 end] \n]
        close $fd
      }
    }
  }

  ###
  # topic: 0016865c-23b7-8bfc-e8bf-8141e1aaaee8
  # description: This routine extends the selection to the point specified by {$x,$y}
  ###
  method SelectTo {x y} {
    my variable v
    set cur [my nearestBoundry $x $y]
    if {[catch {my text index anchor}]} {
      my text mark set anchor $cur
    }
    set anchor [my text index anchor]
    if {[my text compare $cur != $anchor] || (abs($v(pressX) - $x) >= 3)} {
      if {$v(mouseMoved)==0} {
        my text tag remove sel 0.0 end
      }
      set v(mouseMoved) 1
    }
    if {[my text compare $cur < anchor]} {
      set first $cur
      set last anchor
    } else {
      set first anchor
      set last $cur
    }
    if {$v(mouseMoved)} {
      my text tag remove sel 0.0 $first
      my text tag add sel $first $last
      my text tag remove sel $last end
      update idletasks
    }
  }

  ###
  # topic: 4dd8b3dd-4bb0-72cc-2ec8-cc64270e322a
  # description: Change the contents of the entry line
  ###
  method SetLine line {
    my variable v
    scan [my text index insert] %d.%d row col
    set start $row.$v(plength)
    my text delete $start end
    my text insert end $line
    my text mark set insert end
    my text yview insert
  }

  ###
  # topic: 900ce788-3b0b-6a5a-aad0-3e63d9b9305f
  # description: Prompt for the user to select an input file, the source that file.
  ###
  method SourceFile {} {
    set types {
      {{TCL Scripts}  {.tcl}}
      {{All Files}    *}
    }
    set f [tk_getOpenFile -filetypes $types -title "TCL Script To Source..."]
    if {$f!=""} {
      uplevel #0 source $f
    }
  }
}

###
# topic: 0bf0c5b1-e5b0-9291-b376-b8beb25b0404
# description:
#    By the overt act of typing this comment, the author of this code
#    releases it into the public domain.  No claim of copyright is made.
#    In place of a legal notice, here is a blessing:
#    
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#    
#    
#    
#    This file contains code use to implement a simple command-line console
#    for Tcl/Tk.
###
tao::class taotk::console {
  superclass taotk::meta::console taotk::toplevel

  ###
  # topic: 832b9fa2-4f5f-5849-70e2-0f943aa8e256
  ###
  method build_widget window {
    set w $window
    set prompt [my cget prompt]
    set title  [my cget title]
    upvar #0 $w.t v
    if {[info exists v]} {unset v}
    wm title $w $title
    wm iconname $w $title
    my graft topframe $w

    my build_buttons    
    my build_console
  }
}

# Start the console
#
# console:create {.@console} {% } {Tcl/Tk Console}

