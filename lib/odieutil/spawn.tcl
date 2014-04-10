package provide spawn 0.1

###
# topic: 3ac5759b-96ac-f7d4-3913-0940a42a4ad3
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

