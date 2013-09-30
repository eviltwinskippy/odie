###
# topic: 4f50f575-6c05-f806-b59c-63d4fa2b29c2
# description:
#    Facilities expected of any object
#    that is marked as a master to a dynamic object
###
tao::class taotk::meta::widget.stylesheet {
  superclass taotk::meta::page.options taotk::meta::megawidget
  
  property style_prefix {Tao}
  variable Rowcount 0
  
  if {[info command wm] eq {} } {
    set bgcolor grey
  } else {
    set bgcolor [::ttk::style lookup . -background]
  }
  
  option initial-filepath [list tab general widget pathname default [pwd] description {Path where file dialogs open by default}]
  
  option color-background "
    signal stylesheet
    usage gui
    tab colors
    widget color
    default $bgcolor
    description {Default background color for windows}
  "

  option color-row-even {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #BBF
    description {Color of even numbered rows in the display}
  }
  option color-row-odd {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default-command {my cget color-background}
    description {Color of even numbered rows in the display}
  }
  option color-red-even {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #F44
    description {Color of even numbered red rows in the display (with error)}
  }
  option color-red-odd {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #F00
    description {Color of even numbered red rows in the display (with error)}
  }

  option color-blue-even {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #44F
    description {Color of even numbered red rows in the display (with error)}
  }
  option color-blue-odd {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #00F
    description {Color of even numbered red rows in the display (with error)}
  }

  option color-green-even {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #4F4
    description {Color of even numbered red rows in the display (with error)}
  }
  option color-green-odd {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #0F0
    description {Color of even numbered red rows in the display (with error)}
  }

  option color-grey-even {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #a0a0a0
    description {Color of even numbered grey rows in the display (with disabled/greyed)}
  }
  option color-grey-odd {
    signal stylesheet
    usage gui
    tab colors
    widget color
    default #888
    description {Color of even numbered grey rows in the display (with disabled/greyed)}
  }
  
  option font-button {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default TkDefaultFont
    description {Font used on standard buttons}
  }
  option font-button-bold {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Font used on bold buttons}
  }
  option font-button-small {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Font used on small buttons}
  }
  option font-button-fixed {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Font used on fixed font buttons}
  }
  option font-canvas {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Font used on canvas elements}
  }
  option font-console {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default {fixed 10}
    description {Font used on console widgets}
  }
  option font-editor {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default {fixed 10}
    description {Font used on editable text widgets}
  }
  option font-entry {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default TkDefaultFont
    description {Font used on standard entry boxes}
  }
  option font-fixed {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Standard fixed space font}
  }
  option font-label {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default TkDefaultFont
    description {Font used on standard labels}
  }
  option font-normal {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default {helvetica 10}
    description {Standard proportional font}
  }
  option font-popups {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default-command {my Option_font_default %field%}
    description {Font used on popups}
  }
  option font-text {
    signal stylesheet
    widget font
    tab fonts
    usage gui
    default {fixed 10}
    description {Font used on normal text widgets}
  }
  
  option style_background {
    widget color
    tab general
    signal stylesheet
    default grey
  }
  
  option visual-theme [subst {
    signal stylesheet
    usage gui
    tab general
    widget select
    values-command {ttk::style theme names}
    default [if {$::tao::platform=="windows"} {return xpnative} else {return clam}]
    description {Theme for visual elements}
    signal style
  }]
  
  signal style {
    action {my apply_styles}
  }
  
  constructor args {
    my InitializePublic
    my configurelist [::tao::args_to_options {*}$args]
    my BuildDynamicMethods
    my apply_styles {}
  }

  ###
  # topic: 6c0dd511-13c1-da10-d3b6-520f03e1e28d
  ###
  method apply_styles stylelist {
    ::option add *tearOff 0
    logicset add stylelist [my property style_prefix]
    
    set theme  [my cget visual-theme]
    switch $::tao::platform {
      unix {
        option add *Scrollbar.borderWidth 1 
        option add *Scrollbar.highlightThickness 1
        if { $theme eq "default" } {
          set theme clam
        }
      }
      windows {
        if { $theme eq "default" } {
          set theme xpnative
        }
      }
      macosx {
        if { $theme eq "default" } {
          set theme clam
        }
      }
    }
    ::ttk::style theme use $theme
  
    ::ttk::style configure "TButton" -font [my cget font-button] -width 0
    ::ttk::style configure "TLabel" -font  [my cget font-label] -width 0
    ::ttk::style configure "TEntry" -font  [my cget font-entry] -width 0
    
    foreach prefix $stylelist {
      ::ttk::style configure "${prefix}.TButton"      -font [my cget font-button] -width 0
      ::ttk::style configure "${prefix}Fixed.TButton" -font [my cget font-button-fixed] -width -1
      ::ttk::style configure "${prefix}Small.TButton" -font [my cget font-button-small] -width -1
      ::ttk::style configure "${prefix}.TLabel"       -font [my cget font-button] -width 0
      ::ttk::style configure "${prefix}Fixed.TLabel" -font [my cget font-button-fixed] -width -1
      ::ttk::style configure "${prefix}Bold.TLabel"   -font [my cget font-button-bold] -width 0
      ::ttk::style configure "${prefix}Small.TLabel"  -font [my cget font-button-small] -width 0
    
      ::ttk::style configure "${prefix}.TEntry"       -font [my cget font-entry] -width 0
      ::ttk::style configure "${prefix}Fixed.TEntry"  -font [my cget font-button-fixed] -width -1
      ::ttk::style configure "${prefix}Small.TEntry"  -font [my cget font-button-small] -width -1
      
      dict set stylecolors ${prefix}Red red
      dict set stylecolors ${prefix}Green green
      dict set stylecolors ${prefix}Blue  blue
      dict set stylecolors ${prefix}Grey  grey

      dict set stylecolors ${prefix}NormalBar0 [my cget color-row-even]
      dict set stylecolors ${prefix}NormalBar1 [my cget color-row-odd]
      dict set stylecolors ${prefix}GreenBar0 [my cget color-green-even]
      dict set stylecolors ${prefix}GreenBar1 [my cget color-green-odd]
      dict set stylecolors ${prefix}RedBar0   [my cget color-red-even]
      dict set stylecolors ${prefix}RedBar1   [my cget color-red-odd]
      dict set stylecolors ${prefix}GreyBar0   [my cget color-grey-even]
      dict set stylecolors ${prefix}GreyBar1   [my cget color-grey-odd]      
      dict set stylecolors ${prefix}BlueBar0   [my cget color-blue-even]
      dict set stylecolors ${prefix}BlueBar1   [my cget color-blue-odd]
      
      ::ttk::style configure "${prefix}Grey" -background white
      ::ttk::style configure "${prefix}Grey.Treeview" -background grey
      ::ttk::style configure "${prefix}.Treeview" -background white
      ::ttk::style configure "${prefix}.TButton" -font [my cget font-button] -width 0
    }
    foreach {style color} $stylecolors {
      ::ttk::style configure "$style"                 -background $color
      ::ttk::style configure "$style.TFrame"          -background $color
      ::ttk::style configure "$style.TButton"         -background $color  -font [my cget font-button] -width 0
      ::ttk::style configure "${style}Small.TButton"  -background $color  -font [my cget font-button] -width 0
      ::ttk::style configure "${style}Fixed.TButton"  -background $color  -font [my cget font-button-fixed] -width -1
      ::ttk::style configure "${style}.TLabel"        -background $color  -font [my cget font-button] -width 0
      ::ttk::style configure "${style}.TEntry"        -background $color  -font [my cget font-button] -width 0
      ::ttk::style configure "${style}Bold.TLabel"    -background $color  -font [my cget font-button-bold] -width 0
      ::ttk::style configure "${style}Small.TLabel"   -background $color  -font [my cget font-button-small] -width 0
      ::ttk::style configure "${style}.TLabel"        -background $color  -font [my cget font-label] -width 0
      ::ttk::style configure "${style}.TToolbutton"   -background $color  -font [my cget font-button] -width 0
      ::ttk::style configure "${style}.TCheckbutton"  -background $color  -font [my cget font-button] -width 0    
      ::ttk::style configure "${style}.TSeparator"    -background $color
    }
  }

  ###
  # topic: bd75bfaf-7a28-4222-4846-b7c46ca47804
  ###
  method BuildDynamicMethods {} {
  }

  ###
  # topic: 1b6ca5ad-a9a3-8b8f-3ab3-5a9bac2932e6
  ###
  method Option_font_default field {

    switch $::tao::platform {
      macosx {
        # Font defaults of OSX
        switch $field {
          font-fixed        {return {system 10}}
          font-button-fixed {return {system 12}}
          font-button-small {return {system 8}}
          font-button-bold  {return {system 12 bold}}
          font-canvas       {return {system 10}}
          font-popups       {return {system 8}}
        }
      }
      windows {
        # Font defaults for Windows
        switch $field {
          font-fixed        {return {systemfixed 9}}
          font-button-fixed {return {systemfixed 12}}
          font-button-small {return {courier 8}}
          font-button-bold  {return {systemfixed 9 bold}}
          font-canvas       {return {courier 9}}
          font-popups       {return {courier 8}}
        }
      }
      default {
        # Font defaults for generic unix
        switch $field {
          font-fixed        {return {fixed 10}}
          font-button-fixed {return {fixed 12}}
          font-button-small {return {fixed 6}}
          font-button-bold  {return {fixed 12 bold}}
          font-canvas       {return {fixed 10}}
          font-popups       {return {fixed 8}}
        }
      }
    }
  }

  ###
  # topic: 5741a9af-c1d9-cf80-687f-13aa6c33f380
  ###
  method preferences {} {
    taotk::preference_panel.stylesheet .prefs object [self]
  }

  ###
  # topic: c456a442-11c5-4c96-d148-74a8a7039473
  ###
  method row_color {{row {}} {substyle {}}} {
    if { $row eq {} } {
      my variable Rowcount
      set row $Rowcount
    }
    switch $substyle {
      green {
        if {[expr {$row % 2}]} {
          return [my cget color-green-odd]
        } else {
          return [my cget color-green-even]
        }        
      }
      blue {
        if {[expr {$row % 2}]} {
          return [my cget color-blue-odd]
        } else {
          return [my cget color-blue-even]
        }        
      }
      grey -
      missing {
        if {[expr {$row % 2}]} {
          return [my cget color-grey-odd]
        } else {
          return [my cget color-grey-even]
        }
      }
      red -
      error {
        if {[expr {$row % 2}]} {
          return [my cget color-red-odd]
        } else {
          return [my cget color-red-even]
        }
      }
      default {
        if {[expr {$row % 2}]} {
          return [my cget color-row-odd]
        } else {
          return [my cget color-row-even]
        }
      }
    }
  }

  ###
  # topic: 3066b551-9ee1-2d62-7fd6-87d2db5eebfc
  ###
  method widget_newpage {} {
    my variable Rowcount
    set Rowcount 0
  }

  ###
  # topic: 46754a17-c102-304d-96f5-196784f3a3b5
  ###
  method widget_newrow {} {
    my variable Rowcount
    return [incr Rowcount]
  }

  ###
  # topic: 77418584-3b5d-386c-f90b-8feeafc232a7
  ###
  method widget_style {prim {substyle {}} {row {}}} {
    set prefix [my property style_prefix]
    if { $row eq {} } {
      switch $prim {
        button {
          switch $substyle {
            fixed {
              return ${prefix}Fixed.TButton
            }
            small {
              return ${prefix}Small.TButton
            }
            default {
              return ${prefix}.TButton
            }
          }   
        }
        entry {
          switch $substyle {
            fixed {
              return ${prefix}Fixed.TEntry
            }
            small {
              return ${prefix}Small.TEntry
            }
            default {
              return ${prefix}.TEntry
            }
          } 
        }
        label {
          switch $substyle {
            fixed {
              return ${prefix}Fixed.TLabel
            }
            small {
              return ${prefix}Small.TLabel
            }
            bold {
              return ${prefix}Bold.TLabel
            }
            default {
              return ${prefix}.TLabel
            }
          }
        }
        default {
          return ${prefix}.T[string totitle $prim]
        }
      }
    }
    switch $substyle {
      blue {
        return ${prefix}BlueBar[expr {$row % 2}].T[string totitle $prim]
      }
      grey -
      missing {
        return ${prefix}GreyBar[expr {$row % 2}].T[string totitle $prim]
      }
      green {
        return ${prefix}GreenBar[expr {$row % 2}].T[string totitle $prim]
      }
      red -
      error {
        return ${prefix}RedBar[expr {$row % 2}].T[string totitle $prim]
      }
      default {
        return ${prefix}NormalBar[expr {$row % 2}].T[string totitle $prim]
      }
    } 
  }

  ###
  # topic: 7709d504-e939-5594-8a4f-9e0443d505ca
  ###
  method widget_style_error {prim {row {}}} {
    set prefix [my property style_prefix]
    if { $row eq {} } {
      my variable Rowcount
      set row $Rowcount
    }
    return ${prefix}RedBar[expr {$row % 2}].T[string totitle $prim]
  }
}

###
# topic: 6bf788c3-4f67-3e06-5c84-34565a620c2a
###
tao::class taotk::preference_panel.stylesheet {
  superclass taotk::meta::template.preferences
  

  ###
  # topic: ce352167-e327-4376-1fb5-c890e65920ca
  ###
  method action::apply {
    my variable record
    set data [my Option_Filter [array get record]]
    my <object> configurelist $data
    my <object> apply_styles {}
  }

  ###
  # topic: 5cbdd292-b56b-aa67-d543-b9485e396253
  ###
  method action::save {
    my variable record
    foreach {var val} [array get record] {
      my <object> prefdb write stylesheet $var $val
    }
    my action apply
  }

  ###
  # topic: 536a63af-afcb-0472-9293-0c6db735d9e7
  ###
  method Build_controls frame {
    ttk::button $frame.apply -text Apply -command [namespace code {my action apply}]
    ttk::button $frame.revert -text Revert -command [namespace code {my build_content}]
    ttk::button $frame.cancel -text Cancel -command [namespace code {my destroy}]
    pack $frame.cancel $frame.revert -side left
    pack $frame.apply -side right
    if {[my <object> organ prefdb] ne {}} {
      ttk::button $frame.save -text Save -command [namespace code {my action save}]
      pack $frame.save -side right
    }
  }
}

