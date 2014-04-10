###
# Script to synthesize the build environment for IRM
# Tested to work on the following operating systems:
# OSX: 10.5, 10.6
# Windows: XP
# Linux: Ubuntu 8.4, 9.4
###

set defaultsfile [file join [file dirname [info script]] .. build.default]
source $defaultsfile

###
# Each build knows what ActiveState release it is targeting
###

###
# Provide meaningful defaults
###
switch $HOST {
  Linux {
    set ActiveBase [file join $developer_root]
    set TclSh [file join $developer_root build tcl tclsh$tcl_major_version.$tcl_minor_version]
  }
  Darwin {
    set ActiveBase [file join $developer_root]
    set TclSh [file join $developer_root build tcl tclsh$tcl_major_version.$tcl_minor_version]
  }
  Windows {
    set ActiveBase [file join $developer_root]
    set TclSh [file join $developer_root build tcl tclsh${tcl_major_version}${tcl_minor_version}.exe]
  }
}


set doTeaCup 0
foreach {k v} $argv {
  switch -- $k {
    -target {
	set TARGET $v
    }
    -developer_root {
        puts "ACTIVE BASE $v"
      set ActiveBase $v
    }
    -help -
    --help {
      puts "Valid args are:"
      puts "-developer_root Base for compiling code. DFLT: $ActiveBase"
      puts "-target Build for another platform (Linux, Windows, Darwin)"
      exit -1
    }
  }
}
###
# Configure the build environment
###
file mkdir $baseKitPath

switch $HOST {
    Linux {
        set p ${ActiveBase}/bin/tclsh$tcl_major_version.$tcl_minor_version

        # On Linux, our path can be affected by the ActiveState version
        if {![file exists $p] && ($HOST eq $TARGET)} {
          puts "There is no revision $tcl_major_version.$tcl_minor_version Tcl installed in $ActiveBase"
          puts "Try using -activebase flag:"
          puts "-activebase Base for ActiveTcl installation. DFLT: ${ActiveBase}"
          exit -1
        }
        set activePath [file dirname $p]
        set teaCupPath [file dirname ${activePath}]/lib/teapot/
        set odie-tclsh $p
    }
    Darwin {
        set p /usr/local/bin/tclsh$tcl_major_version.$tcl_minor_version
        # On Linux, our path can be affected by the ActiveState version
        if {![file exists $p] &&  ($HOST eq $TARGET)} {
          puts "There is no revision $tcl_major_version.$tcl_minor_version Tcl installed in ${ActiveBase}"
          puts "Is the right version of ActiveTcl installed?"
          exit -1
        }
        set activePath /usr/local/bin
        set teaCupPath /Library/Tcl/teapot
        set odie-tclsh $p        
	
    }
    Windows {
        set activePath [file nativename [file join $ActiveBase bin]]
        set p [file join ${activePath} tclsh${tcl_major_version}${tcl_minor_version}.exe]
        # On Linux, our path can be affected by the ActiveState version
        if {![file exists $p]} {
          puts "There is no revision $tcl_major_version.$tcl_minor_version Tcl installed in $activePath"
          puts "Is the right version of ActiveTcl installed?"
          exit -1
        }
        set teaCupPath [file join [file dirname $activePath] lib teapot]
        set odie-tclsh $p
    }
}
###
# Configure the target
###
switch $HOST {
    Linux {
        set odiehost linux-glibc2.3-ix86

    }
    macosx-universal {
        set odiehost macosx-universal
    }
    Darwin {
        set odiehost macosx10.5-i386-x86_64
    }
    Windows {
        set odiehost win32-ix86
    }
}

switch $TARGET {
    Linux {
        set odietarget linux-glibc2.3-ix86

    }
    macosx-universal {
        set odietarget macosx-universal
    }
    Darwin {
        set odietarget macosx10.5-i386-x86_64
    }
    Windows {
        set odietarget win32-ix86
    }
}
if { $HOST ne "Windows" } {
  foreach file [glob [file join [file dirname [info script]] *]] {
	file attributes $file -permissions +x
  }
}
set hostkit $baseKitPath/base-tk-thread-$tcl_major_version.$tcl_minor_version-${odiehost}.kit
set tkkit $baseKitPath/base-tk-thread-$tcl_major_version.$tcl_minor_version-${odietarget}.kit

set of [open build.rc w]

set template {}
set hostflag {}
puts $of "export odie-version=$ODIEVERSION"

switch $TARGET {
  Linux {
    set libPath [file join [file dirname $activePath] lib]
    puts $of "export odie-tcllibrary=[file join $libPath libtcl$tcl_major_version.$tcl_minor_version.a]"
    puts $of "export odie-tklibrary=[file join $libPath libtk$tcl_major_version.$tcl_minor_version.a]"
    puts $of "export odie-tcl-lib=$libPath"
    puts $of "export odie-tk-lib=$libPath"
    set odie-tcl-lib $libPath
    set odie-tk-lib $libPath
    puts $of "export odie-cflags = -O2 -march=i686 -DODIE_LINUX=1"
  }
  macosx-universal {
    puts $of "export odie-tcllibrary=/Library/Frameworks/Tcl.framework/libtcl$tcl_major_version.$tcl_minor_version.a"
    puts $of "export odie-tklibrary=/Library/Frameworks/Tk.framework/libtk$tcl_major_version.$tcl_minor_version.a"
    set odie-tcl-lib /Library/Frameworks/Tcl.framework
    set odie-tk-lib /Library/Frameworks/Tk.framework
    puts $of "export odie-tcl-lib=${odie-tcl-lib}"
    puts $of "export odie-tk-lib=${odie-tk-lib}"
    puts $of "export odie-cflags = -arch ppc -arch ppc64 -arch x86_64 -arch i386 -isysroot /Developer/SDKs/MacOSX10.6.sdk/ -DODIE_OSX=1 -m32" 
  }
  Darwin {
    puts $of "export odie-tcllibrary=/Library/Frameworks/Tcl.framework/libtcl$tcl_major_version.$tcl_minor_version.a"
    puts $of "export odie-tklibrary=/Library/Frameworks/Tk.framework/libtk$tcl_major_version.$tcl_minor_version.a"
    set odie-tcl-lib /Library/Frameworks/Tcl.framework
    set odie-tk-lib /Library/Frameworks/Tk.framework
    puts $of "export odie-tcl-lib=${odie-tcl-lib}"
    puts $of "export odie-tk-lib=${odie-tk-lib}"
    puts $of "export odie-cflags = -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.7.sdk/ -DODIE_OSX=1 -m32" 
  }
  Windows {
    if { $HOST eq "Darwin" } {
      set mingwpath {}
      foreach path [lsort -dictionary [glob -nocomplain /usr/local/*mingw32*]] {
        if { ![file exists $path/bin] } continue
        set mingwpath $path
      }
      if { $mingwpath == {} } {
        error "MinGW not detected"
      }
        append env(path) :$mingwpath/bin
	puts $of "
export CC=$mingwpath/bin/i386-mingw32-gcc
export AR=$mingwpath/bin/i386-mingw32-ar
export RANLIB=$mingwpath/bin/i386-mingw32-ranlib
export RC=$mingwpath/bin/i386-mingw32-windres
"
      set mingwhost   x86_64-apple-darwin10
      set mingwtarget i386-mingw32
    }
    if { $HOST eq "Linux" } {
	puts $of {
export CC=i586-mingw32msvc-gcc
export AR=i586-mingw32msvc-ar
export RANLIB=i586-mingw32msvc-ranlib
export RC=i586-mingw32msvc-windres
}
      set mingwhost   i486-linux-gnu
      set mingwtarget i586-mingw32msvc
    }
    set libPath [file join $ActiveBase lib]
    puts $of "export odie-tcllibrary=[file join $libPath libtcl$tcl_major_version.$tcl_minor_version.a]"
    puts $of "export odie-tklibrary=[file join $libPath libtk$tcl_major_version.$tcl_minor_version.a]"
    puts $of "export odie-tcl-lib=$libPath"
    puts $of "export odie-tk-lib=$libPath"
    set odie-tcl-lib $libPath
    set odie-tk-lib $libPath
      if { $HOST != "Windows" } {
	# Write out the info we need of mingw

        puts $of "export PREFIX=$ActiveBase"
        puts $of "export TCL_SRC_DIR=$ActiveBase/include"
        puts $of "export TK_SRC_DIR=$ActiveBase/include"
      }
      puts $of "export odie-cflags = -O2 -march=i686 -DODIE_WINDOWS=1 -I $ActiveBase/include" 
  }
}

###
# Activestate modified where the basekits are stored
# look in the old and new locations
###


###
# Set up common flags across platforms
###
set template {
export odie-tclsh=${TclSh}
export odiehost=${odiehost}
export odietarget=${odietarget}
export teacup-path=[file normalize [file join ${teaCupPath} package ${odietarget} lib]]
export hostkit=[file normalize ${hostkit}]
export tkkit=[file normalize ${tkkit}]
export odie-library=[file normalize [file join $env(HOME) odie lib]]
}
puts $of [subst $template]
close $of
exit
cd libodie
source deps.tcl
if { $HOST ne "Windows" && $TARGET eq "Windows"} {
    #file copy -force Makefile.windows Makefile
    ###
    # Change the line breaks so Unix doesn't puke
    ###
    foreach file {tclConfig.sh tkConfig.sh} {
        set fin [open $ActiveBase/lib/$file r]
        set dat [read $fin]
        close $fin
        
        ###
        # We also have to map hard-coded paths to their new location
        ###
        set dat [string map [list C:/Tcl $ActiveBase] $dat]
        file rename -force  $ActiveBase/lib/$file  $ActiveBase/lib/$file.bak
        set fout [open $ActiveBase/lib/$file w]
        puts $fout $dat
        close $fout
    }
    
    if {![file exists libodie/Makefile]} {
        set fin [open ../build.rc r]
        while {[gets $fin line] >= 0} {
            if { [lindex $line 0] ne "export" } continue
            foreach {field val} [split [lindex $line 1] =] {
                set env($field) $val
            }
        }
        close $fin
        exec sh configure --host=${mingwhost} --build=${mingwtarget} --with-tcl=${odie-tcl-lib} --with-tk=${odie-tk-lib} >&@ stdout
    }
} else {
    if {![file exists libodie/Makefile]} {
        set flags "--with-tcl=${odie-tcl-lib} --with-tk=${odie-tk-lib}"
        eval exec sh configure $flags >&@ stdout
    }
}

cd ../canvas3d
if { $HOST ne "Windows" && $TARGET eq "Windows"} {
    if {![file exists Makefile]} {
        set fin [open ../build.rc r]
        while {[gets $fin line] >= 0} {
            if { [lindex $line 0] ne "export" } continue
            foreach {field val} [split [lindex $line 1] =] {
                set env($field) $val
            }
        }
        close $fin
        exec sh configure --host=${mingwhost} --build=${mingwtarget} --with-tcl=${odie-tcl-lib} --with-tk=${odie-tk-lib} >&@ stdout
    }
} else {
    if {![file exists libodie/Makefile]} {
        set flags "--with-tcl=${odie-tcl-lib} --with-tk=${odie-tk-lib}"
        eval exec sh configure $flags >&@ stdout
    }
}
