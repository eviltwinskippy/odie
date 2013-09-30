
tao::class image_window {
  superclass taotk::meta::html taotk::frame

  method action::reload {} {
    my variable history url
    if {![info exists history]} return
    set node [lindex $history end]
    if {[llength $node]} {
      set url [dict get $node url]
      my [dict get $node handler] [dict get $node content]
    }    
  }

  method action::back {} {
    my variable history url
    if {![info exists history]} return
    set node [lindex $history end-1]
    set history [lrange $history 0 end-2]
    if {[llength $node]} {
      set url [dict get $node url]
      my [dict get $node handler] [dict get $node content]
    }
  }

  method action::file_select {
    set path [tk_getOpenFile]
    if { $path ne {} } {
      my variable url
      set url $path
      my action goto
    }
  }
  
  method action::next {
    my variable url
    my variable gallery_images
    if {[llength $gallery_images] < 1} return
      
    set idx [lsearch [lsort -dictionary $gallery_images] $url]
    if { $idx < 0 } {
      set url [lindex [lsort -dictionary $gallery_images] 0]
      my action goto
    }
    incr idx
    set url [lindex [lsort -dictionary $gallery_images] $idx]
    if {$url eq {}} {
      set url [lindex [lsort -dictionary $gallery_images] 0]
    }
    my action goto
  }

  method action::previous {
    my variable url
    my variable gallery_images
    if {[llength $gallery_images] < 1} return
      
    set idx [lsearch [lsort -dictionary $gallery_images] $url]
    if { $idx < 0 } {
      set url [lindex [lsort -dictionary $gallery_images] end]
      my action goto
    }
    incr idx -1
    set url [lindex [lsort -dictionary $gallery_images] $idx]
    if {$url eq {}} {
      set url [lindex [lsort -dictionary $gallery_images] end]
    }
    my action goto
  }

  method Build_controls w {
    ttk::entry $w.url -textvariable [my varname url] -width 60
    ttk::button $w.back -text "Back" -command [namespace code {my action back}]
    ttk::button $w.go -text "Go" -command [namespace code {my action goto}]
    ttk::button $w.select -text "Select" -command [namespace code {my action file_select}]

    pack $w.back -side left
    pack $w.url -side left -fill y -expand 1
    pack $w.go -side left
    pack $w.select -side left
    
    ttk::button $w.next -text "Next" -command [namespace code {my action next}]
    ttk::button $w.prev -text "Prev" -command [namespace code {my action previous}]
    pack $w.next $w.prev -side right
  }
  
  method html_ahref_handler node {
    my variable gallery_images
    $node attribute color blue
    set dest [$node attr href]
    if {[string tolower [file extension $dest]] in {.jpg .jpeg}} {
      lappend gallery_images $dest
    }
  }
  method render_image content {
    next $content
    set window [my organ topframe]
    bind [winfo toplevel $window] <Key-n> [namespace code {my action next}]
    bind [winfo toplevel $window] <Key-p> [namespace code {my action previous}]
  }

  method render_html content {
    ###
    # Index the content
    ###
    my variable gallery_images
    set gallery_images {}
    next $content
    set window [my organ topframe]
    bind [winfo toplevel $window] <Key-z> {}
    bind [winfo toplevel $window] <Key-n> {}
    bind [winfo toplevel $window] <Key-p> {}
  }
}