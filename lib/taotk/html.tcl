###
# HTML browser widget
###
image create photo image-missing -data {
    R0lGODlhCQAJAPAAAP///9sAACH5BAEAAAAALAAAAAAJAAkAAAISTIB5pofMEjBOUjmXdTE+
    jRkFADv/
}

###
# topic: 70782f00-840b-e001-6fea-022e332dabe3
###
proc ::htmlbox {title text {wwidth 80}} {
  set w .htmlbox
  if {![winfo exists $w]} {
    taotk::htmloutput .htmlbox
  }
  wm title .htmlbox $title
  .htmlbox render_html $text
}

###
# topic: cb43044f-eace-959e-2bda-58626286f124
# description: An IRM standard html megawidget
###
tao::class taotk::meta::html {
  superclass taotk::meta::widget

  ###
  # topic: 385ccfd8-377a-4495-0ca3-588aa3012535
  ###
  method action::back {} {
    my variable history url
    if {![info exists history]} return
    set info [lindex $history end-1]
    set history [lrange $history 0 end-2]
    dict with info {}
    set url [dictGet $info url]
    if {$url eq {}} {
      my render_html [my page blank]
    } else {
      my $handler $content
    }
  }

  ###
  # topic: a22ba84c-8114-dd71-0c41-5eae5fbc4288
  ###
  method action::goto {} {
    my build_content
  }

  ###
  # topic: 29d349fb-be12-d363-0405-2bb8930457d7
  ###
  method action::image_zoom {
    dict with dictargs {}
    $frame configure -image $image
  }

  ###
  # topic: bc393f1d-04b4-dc46-8bbe-b6110b8385c7
  ###
  method binding_href {x y} {
    set nodelist [lindex [my htmlframe node $x $y] 0]
    set url NULL
    foreach node $nodelist {
      set url [$node attribute -default NULL href]
      if { $url eq "NULL" } {
        set url [[$node parent] attribute -default NULL href]
      }
      if { $url eq "NULL" } {
        foreach child [$node children] {
          set turl [$child attribute -default NULL href]
          if {$turl ne "NULL"} {
            set url $turl
            break
          }
        }
      }
      if { $url ne "NULL"} break
    }
    if { $url ne "NULL" } {
      my browse [my url_fix $url]

    }
    return
  }

  ###
  # topic: c8eb113f-f760-aead-ccaf-a5c7e4a9ca58
  ###
  method browse url_goto {
    my variable history url
    set url $url_goto

    if { $url eq {} } {
      my render_html [my page blank]
      return
    }
    if {[string first : $url] < 0} {
      set url http://$url
    }
    set info [::uri::split $url]
        
    set content {}
    set directory 0
    set path [dict get $info path]
    set handler [my detect_content_type $url]
    if { $handler in {render_image} } {
      set binary 1
    } else {
      set binary 0
    }
    set tmpchan [my url_get $url $binary]
    set content [read $tmpchan]
    close $tmpchan
    ###
    # Guess the content type
    ###
    if { $handler eq "render_html" } {
      my history_add $url $handler $content
    }
    my $handler $content
      
  }

  ###
  # topic: 85be1790-8e85-f6e7-06ac-6a571fbe0f14
  ###
  method build_content {} {
    my variable url
    if {![info exists url]} {
      return
    }
    my browse [my url_fix $url]
  }

  ###
  # topic: aa4a0534-e7f4-31be-6554-9c6555130bf9
  ###
  method Build_controls w {
    ttk::entry $w.url -textvariable [my varname url] -width 60
    ttk::button $w.back -text "<" -command [namespace code {my action back}]
    ttk::button $w.go -text "Go" -command [namespace code {my action goto}]
    pack $w.back -side left
    pack $w.go -side right
    pack $w.url -side left -fill y
  }

  ###
  # topic: 8b7d13fd-be29-8717-cd27-d036cc350585
  ###
  method build_widget window {
    package require Tkhtml

    set w $window.url
    ttk::frame $w
    my Build_controls $w
    grid $w -columnspan 2

    label $window.image
    text $window.text  -yscrollcommand "$window.tsb set"
    html $window.html -yscrollcommand "$window.hsb set"
    scrollbar $window.tsb -orient vertical -command [list $window.text yview]
    scrollbar $window.hsb -orient vertical -command [list $window.html yview]

    my graft topframe $window
    my graft imageframe $window.image
    my graft textframe $window.text
    my graft htmlframe $window.html    
  }

  ###
  # topic: fcc6634a-8b5e-2cb8-30d0-7ae4b2ac5ed3
  ###
  method clear_content {} {
    my variable url images stylecount history
    foreach id [get images] {
      catch {image delete $id}
    }
    set images {}
    set stylecount 0
    my textframe delete 0.0 end
    my imageframe configure -image {}
    my htmlframe reset
    my htmlframe handler script style  [namespace code {my html_script_handler}]
    my htmlframe handler node   script [namespace code {my html_null_handler}]
    my htmlframe handler node link     [namespace code {my html_link_handler}]
    my htmlframe handler node a        [namespace code {my html_ahref_handler}]
    my htmlframe configure -imagecmd   [namespace code {my get_image}]
    set window [my organ topframe]
    grid forget $window.image
    grid forget $window.text
    grid forget $window.html
    grid forget $window.hsb
    grid forget $window.tsb
  }

  ###
  # topic: 439e2c8f-9a6c-c98d-9106-c98cffdbfa52
  ###
  method detect_content_type url {
    set info [::uri::split $url]
    set ext [string tolower [file extension [dict get $info path]]]
    set handler render_html
    foreach {patlist pathandler} {
      ".html .htm" render_html
      {.jpg .png .gif .jpeg .tiff} render_image
      {.txt .csv} render_text
    } {
      if {$ext in $patlist } {
        set handler $pathandler
      }
    }
    return $handler
  }

  ###
  # topic: 29de121b-e2f2-efda-7f3a-6229a68a4b87
  ###
  method directory_index path {
    set content "<HTML><HEAD><TITLE>$path</TITLE></HEAD><BODY>"
    append content \n "<LI><a href=\"file://[file dirname $path]>..</a>"
    set files [glob -nocomplain [file join $path *.jpg]]
    if {[llength $files]} {
      append content "<TABLE><TR>"
      set cells 0
      foreach file [lsort -dictionary $files] {
        append content \n "<TD><a href=\"file://$file\"><img src=\"file://$file\" width=120 height=120></TD>"
        if {[incr cells]%5==0} {
          append content \n "</TR><TR>"
        }
      }
      append content "</TR></TABLE>"
    }
    append content "</BODY></HTML>"
  }

  ###
  # topic: bd7dfe19-cbe0-90fa-fc39-9c8b14752b14
  ###
  method get_image imgurl {
    my variable images
    package require img::gif
    package require img::png
    package require img::jpeg
    set imgurl [my url_fix $imgurl]
    set id image#[llength $images]
    lappend images $id
    set tmpchan [my url_get $imgurl 1]
    if [catch {
      image create photo $id -data [read $tmpchan]
    } err] {
      image create photo $id -data [image-missing data -format png]
      puts "Error loading $imgurl: $err"
    }
    close $tmpchan
    return $id
  }

  ###
  # topic: 42ac6c31-1126-a7f7-b4a4-1395bb239b1d
  ###
  method history_add {url handler content} {
    my variable history
    if {[info exists history]} {
      set history [lrange $history end-20 end]
    }
    lappend history [list url $url handler $handler content $content]
  }

  ###
  # topic: 05c37cd4-fd45-b55c-b653-427f8dde5411
  ###
  method html_ahref_handler node {
    $node attribute color blue
    #puts [list $node [$node attr href]]
  }

  ###
  # topic: c178d284-3c91-51f4-61de-a7e40e03d6eb
  ###
  method html_link_handler node {
    return
    if {[$node attr rel] == "stylesheet"} {
      set URI [$node attr href]
      set stylesheet [<LOAD URI CONTENTS>]

      my variable stylecount
      incr stylecount
      
      set id "author.[format %.4d $stylecount]"
      set handler [namespace code [list my import_handler $id]]
      my htmlframe style -id $id.9999 -importcmd $handler $stylesheet
    }
  }

  ###
  # topic: 9958a6d4-b4ee-580b-8f40-41a10841329e
  ###
  method html_null_handler node {
    $node replace {}
  }

  ###
  # topic: 101be347-8770-11e2-9b72-80f3ba7457eb
  ###
  method html_script_handler tagcontents {
    my variable stylecount
    incr stylecount
    set id "author.[format %.4d $stylecount]"
    set handler [namespace code [list my import_handler $id]]
    my htmlframe style -id $id.9999 -importcmd $handler $tagcontents
  }

  ###
  # topic: 8a277131-0b5c-bcac-8c1b-15a1cbcf3937
  # description: shrinking without transparency
  ###
  method image_shrink {Image coef} {
    my variable images
    set sample [expr {int(ceil(1.0/$coef))}]
    set id image#[llength $images]
    image create photo $id
    $id copy $Image -subsample $sample $sample -shrink
    lappend images $id
    return $id
  }

  ###
  # topic: e662ef7e-158d-b56e-c3a4-e9b38751cd97
  ###
  method import_handler {parentid URI} {
      set stylesheet [<LOAD URI CONTENTS>]
  
      my variable stylecount
      incr stylecount
      
      set id "$parentid.[format %.4d $stylecount]"
      set handler [namespace code [list my import_handler $id]]
      my htmlframe style -id $id.9999 -importcmd $handler $stylesheet
  }

  ###
  # topic: ed27e9b7-f7e0-f2ab-f2e0-63963eca7234
  ###
  method page::blank {
    return {
<html>
<body>
(This space intentionally blank)
</body>
</html>
    }
  }

  ###
  # topic: e7f9bb13-785f-fb6c-d3dd-8885b9be639e
  ###
  method page::default {
    return [my page notfound]
  }

  ###
  # topic: 67bfcfd8-9ccb-f44d-2ae3-a21be0628282
  ###
  method page::notfound {
    return [subst {
<html>
<body>
Page not found: $url
</body>
</html>
    }]
  }

  ###
  # topic: 54e2129c-0d28-1dfb-6978-415bf609023d
  ###
  method render_directory content {
    
  }

  ###
  # topic: 99fc11b6-07ca-80d8-32cb-018fd1894e3f
  ###
  method render_html content {
    my clear_content
    set window [my organ topframe]
    set f [my organ htmlframe]    
    grid $f $window.hsb -sticky news
    grid columnconfigure $window $f -weight 1
    grid rowconfigure $window $f -weight 1
    # After we remap the window, we need to allow
    # the event loop to run so we get an interaction
    # between the widget and the scrollbar
    update idletasks
    my htmlframe parse -final $content
    #my htmlframe refresh
    bind $f <1> {}
    bind $f <B1-Motion> {}
    bind $f <1> [namespace code {my binding_href %x %y}]
    #bind $f <B1-Motion> [my binding_href_selection %x %y]
  }

  ###
  # topic: c363b5f4-895b-2771-7786-8ff88fa28bcc
  ###
  method render_image content {
    my variable images

    my clear_content
    set window [my organ topframe]
    set f [my organ imageframe]    

    set id image#[llength $images]
    lappend images $id
    set w [winfo screenwidth $window]
    set h [winfo screenheight $window]
    image create photo $id -data $content
    ###
    # Size to fit
    ###
    set zoom 1.0
    if {[image width $id] > $w } {
      set zoom [expr $w.0/[image width $id]]
    }
    if {[image height $id] > $h} {
      set z [expr $h.0/[image height $id]]
      if { $z < $zoom } {
        set zoom $z
      }
    }
    if { $zoom < 0.9 } {
      set newimg [my image_shrink $id $zoom]
      bind [winfo toplevel $window] <Key-z> [namespace code [list my action image_zoom frame $f image $id]]
      my imageframe configure -image $newimg
    } else {
      bind [winfo toplevel $window] <Key-z> {}
      my imageframe configure -image $id
    }
    grid $f -sticky news
  }

  ###
  # topic: d8029aaa-33af-0177-5488-a43a1455886f
  ###
  method url_fix httpurl {
    package require uri
    set retrurl $httpurl
    if {[string range $httpurl 0 6] ni {"page://" "file://" "http://"}} {
      if {[file exists $httpurl]} {
        set httpurl file://$httpurl
      } else {
        set httpurl http://$httpurl
      }
    }
    if {![uri::isrelative $httpurl]} {
      return $httpurl
    }
    my variable url
    set baseurl [get url]
    set info [uri::split $baseurl]
    set host [dict get $info host]
    set port [dict get $info port]
    set scheme [dict get $info scheme]

    if { $port ne {} } {
      append host : $port
    }
    if {[string index $httpurl 0] eq "/" } {
      return [uri::canonicalize http://$host$httpurl]
    }
    
    set path    [dict get $info path]
    set dirname [file dirname $path]
    return [uri::canonicalize http://$host/$path/$httpurl]
  }

  ###
  # topic: 7a2a327d-3eac-99fc-0ae2-d11b7abe4794
  ###
  method url_get {httpurl {binary 1}} {
    set retrurl [my url_fix $httpurl]
    set info [::uri::split $retrurl]
    set scheme [dict get $info scheme]
    return [my url_get_$scheme $retrurl $binary]
    return $tmpchan
  }

  ###
  # topic: 820d8069-e71b-7c62-82d8-d5ef54daa40d
  ###
  method url_get_about {url binary} {
    set info [::uri::split $url]
    set path [dict get $info path]
    set content [my page $path url $url {*}$info]
    set tmpchan [file tempfile]
    puts $tmpchan $content
    close $tmpchan
    return $tmpchan    
  }

  ###
  # topic: 257225a2-abe3-e2d0-7ea2-a111e0d1dd54
  ###
  method url_get_file {url binary} {
    set info [::uri::split $url]
    set path [dict get $info path]
    if {[file isdirectory $path]} {
      if {[file exists [file join $path index.html]]} {
        set tmpchan [open [file join $path index.html] r]
      } else {
        set tmpchan [file tempfile]
        puts $tmpchan [my directory_index $path]
        seek $tmpchan 0
      }
    } else {
      set tmpchan [open $path r]
    }
    if {$binary} {
      fconfigure $tmpchan -translation binary
    }
    return $tmpchan
  }

  ###
  # topic: 1c0b0fd4-afdb-ae1b-3cc3-62dba90dafef
  ###
  method url_get_http {url binary} {
    package require http
    set tmpchan [file tempfile]
    if {$binary} {
      fconfigure $tmpchan -translation binary
    }
    set token [::http::geturl $url -channel $tmpchan]
    seek $tmpchan 0
    http::cleanup $token
    return $tmpchan
  }

  ###
  # topic: 9a3bd2a8-65e5-aa24-e996-20a3c3de8b72
  ###
  method url_get_page {url binary} {
    set info [::uri::split $url]
    set path [dict get $info path]
    set content [my page $path url $url {*}$info]
    set tmpchan [file tempfile]
    puts $tmpchan $content
    close $tmpchan
    return $tmpchan    
  }
}

###
# topic: b5255e9f-6998-1ef5-229a-92fa4a1a2420
# description: An IRM standard browser megawidget
###
tao::class taotk::browser {
  superclass taotk::meta::html taotk::toplevel

  ###
  # topic: f1a24d87-b8ec-d046-8a8f-2a01c5d39643
  # title: Place the title on the top
  ###
  method build_title {} {
    set tl [my organ toplevel]
    wm title $tl [my title]
    wm iconname $tl [my title]    
  }

  ###
  # topic: 03a1feef-ac36-1272-2441-9d9e51b66b13
  # description: Return the title of the window
  ###
  method title {} {
    my variable title
    return "Help: [get title]"
  }
}

###
# topic: bae15949-f0d0-6f69-432a-75d2b4ad0582
# description: An IRM standard HTML output displayer
###
tao::class taotk::htmloutput {
  superclass taotk::browser
  

  ###
  # topic: 330a9be7-1edc-0989-0dde-4dc5ab8398ce
  ###
  method Build_controls w {
    ttk::button $w.close -text "Close" -command [list destroy [my organ topframe]]
    ttk::button $w.save  -text "Save" -command  [namespace code {my save_output}]
    grid $w.close $w.save -sticky news
    grid $w -columnspan 2
  }

  ###
  # topic: 2b15f7da-1f6d-90d6-755d-9697d95430ee
  ###
  method render_html block {
    my variable current_content
    set current_content $block
    next $block
  }

  ###
  # topic: db04ff8e-8ef0-1d9a-0f3c-1c7af0dc1586
  ###
  method save_output {} {
    my variable current_content
    set types {{{Text Files} {.txt}} {{HTML Files} {.html}}  {{All Files} *}}
    set f [tk_getSaveFile -filetypes $types -defaultextension .html -parent [my organ topframe]]
    if {$f!=""} {
      if {[catch {
        set fd [open $f w]
        puts $fd $current_content
      } err]} {
        odieMessageBox-icon error -type ok -parent $w -message \
            "Unable to save the text to a file.\n\n$err"
      }
      catch {close $fd}
    }
  }
}

