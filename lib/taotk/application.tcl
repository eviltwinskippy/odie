###
# Define the application framework
# Other classes will refer to this object for the state
# of the "program" itself, as opposed to the "application"
# (which can change)
###

###
# topic: 60613ded-64ab-1af0-996c-c7f40bd3d609
# description:
#    Define the application framework
#    Other classes will refer to this object for the state
#    of the "program" itself, as opposed to the "application"
#    (which can change)
###
tao::class taotk::application {
  superclass taotk::meta::megawidget
  
  property appname odie

  constructor {} {
    my InitializePublic
    my BuildDynamicMethods
    my initialize
  }

  constructor args {
    my InitializePublic
    my graft master [self]
    my configurelist [::tao::args_to_options {*}$args]  
    my init_stack
    my initialize
    my BuildDynamicMethods
  }

  ###
  # topic: 7853fe08-b09d-2710-c568-dd5198233131
  ###
  method message::error {msg errorinfo} {
    destroy .error
    floatingWindow .error
    ::ttk::label .error.l -text "APPLICATION ERROR"
    grid .error.l -sticky ew
    ::ttk::notebook .error.tabs
    grid .error.tabs -sticky ew

    set f .error.tabs.summary
    ttk::frame $f
    ttk:::label $f.hi -text "The application encountered the following error:"
    set maxwid 20
    set rows 0
    ttk::label $f.short -wraplength 500 -text $msg
    
    ttk::label $f.report#l -text Description:
    text $f.report -font [::simconfig::get font-text] -width 40 -height 10
    ttk::label $f.report#status -text {}

    ttk::frame $f.buttons
    ::ttk::button $f.buttons.close -command {destroy .error} -text Close
    grid $f.buttons.close

    grid $f.hi
    grid $f.short
    grid $f.email_l
    grid $f.email
    grid $f.report#l
    grid $f.report
    grid $f.report#status
    grid $f.buttons
    
    .error.tabs add $f -text "Summary"
    
    set f .error.tabs.trace
    ttk::frame $f
    text $f.error -font [::simconfig::get font-text]
    $f.error insert end "$msg \n\n *** TRACE *** \n $errorinfo"
    #$f.error configure -state disabled
    grid $f.error
    .error.tabs add $f -text "Stack Trace"

    halt_simulation
    set fout [open ~/irm/last_error.txt w]
    puts $fout $msg
    close $fout
  }

  ###
  # topic: 796eb2e2-77d9-50e9-d463-e4bc1cb02ab9
  ###
  method message::notice msg {
    odieMessageBox -parent [my organ topframe] -icon info -message $msg -type ok
  }
}

