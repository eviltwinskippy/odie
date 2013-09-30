### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2007 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

package provide odie-thumbnail 0.1

set ::Config(MagicExec) {}
foreach path {
    /usr/bin /usr/local/bin /opt/local/bin
} {
    foreach exec {gm convert} {
        if [file exists [file join $path $exec]] {
            set ::Config(MagicExec) $exec
        }
    }
}
if { $::Config(MagicExec) == {} } {
    return
    error "Cannot findex executable to do thumbnails with (install ImageMagick or GraphicsMagic)"
}

###
#  Try to use TclMagick if available
###
# [catch {package require TclMagick}]    
if 1 {  
    proc thumbnail {format geom original thumbnail} {
        catch {
            exec $::Config(MagicExec) -format $format -interlace plane \
                -profile "*" -resize $geom \
                $original $thumbnail >& /tmp/convert.log
        } err   
    }
} else {
    proc thumbnail {format geom original thumbnail} {
       
        set wid [lindex [split $geom x] 0]
        set hgt [lindex [split $geom x] 1]

        set handle [magick create wand]
        
        $handle ReadImage $original
        set owid [$handle width]
        set ohgt [$handle height]
        
        set orat [expr $owid.0 / $ohgt.0]
        set rat  [expr $wid.0 / $hgt.0]
        set nwid $wid
        set nhgt $hgt

        if { $rat < $orat } { 
            set nwid [expr int($hgt * $orat)]
        } else {
            set nhgt [expr int($wid / $orat)]
        }
                
        $handle ResizeImage $nwid $nhgt lanczos 

        $handle WriteImage $thumbnail
        magick delete $handle
    }	
}
