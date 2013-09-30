package provide spawn 0.1

###
# topic: f73ebf2d-0932-fdff-953b-65f2637a30be
###
proc ::spawnProcess { code } {

    set uniqueid [ clock clicks -milliseconds ]
    
    set ::$uniqueid [ list ]
    
    ;## internal callback
    proc __freeMem__ { fid uniqueid } {
	if { [ catch {
	    set ::$uniqueid [ read $fid ]
	    close $fid
	} err ] } {
	    return -code error $err
	}
    }

    ;## handle return values (including return -codes)
    regsub -all {return .+} $code "puts {&}" code
    
    if { [ catch {
        set fid [ open |tclsh w+ ]
        fconfigure $fid -blocking off
        fconfigure $fid -buffering line
        puts $fid $code
        fileevent $fid readable "__freeMem__ $fid $uniqueid"
    } err ] } {
        catch { close $fid }
        return -code error $err
    }
    return ::$uniqueid
}

