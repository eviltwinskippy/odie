### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

package require listutil
package provide odie-osinfo-windows 1.0

if { $::tcl_platform(platform) == "windows" } { 
    
    ###
    # Operating System Info
    # Windows Platform
    ###

    package require registry

}

::namespace eval ::osinfo {}

###
# topic: 3fab72c9-0fd7-4e87-e6c9-443e5fcf1a2c
###
proc ::osinfo::identify_os {} {
    variable os_version
    set os_version(ostype) windows
    set os_version(release) windows
    
    if [info exists os_version(version)] {
    return
    }
    
    # Load operating System parameters
    array set os_version {
    kernel      {}
    serial      {}
    productkey  {}
    installtime {}
    vendor      Microsoft
    release.minor {}
    release.major {}
    ostype      windows
    }
    
    ###
    # 9x and NT+ store os info in 2 different spots in the 
    # registry. This routine will idenity which one.
    ###
    if [catch {
    registry get {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion} ProductId
    } os] {
    set regroot {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion}
    set osname Win9x
    } else {
    set regroot {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion}
    set osname WinNT
    }
    
    catch {
    foreach {var regval platform} {
        version     ProductName    {Win9x WinNT}
        serial          ProductId      {Win9x WinNT}
        productkey    ProductKey     {Win9x}
        kernel             VersionNumber  {Win9x}
        kernel            CurrentVersion {WinNT}
    } {
        if { [lsearch $platform $osname] >= 0 } {
        catch {set os_version($var) [registry get $regroot $regval]} err
        }
    }
    }
    
    if { [get os_version(version)] == {} } {
    # Windows NT 4.0 is missing a registry key
    set os_version(version) {Windows NT 4.0}
    }
    
    # Differentiate 2K and XP
    foreach {phrase maj min} {
    {Windows 95}   9x 95
    {Windows 98}   9x 98
    {Windows ME}   9x ME
    {Windows NT}   NT NT
    {Windows 2000} NT 2000
    {Windows XP}   NT XP
    } {
    if [regexp $phrase $os_version(version)] {
        set os_version(release.major) $maj
        set os_version(release.minor) $min
    }
    }
}

###
# topic: c943ba61-ac50-1021-e8ea-253861412f2d
# description:
#    Parse network configuration information
#    Windows NT/98/ME/2K/XP
###
proc ::osinfo::iplist.windows {} {
	    variable iplist {}
	    
	    # Load IP info
	    
	    catch {
		exec ipconfig /all
	    } data
	    
	    set buffer [split $data \n] 
	    
	    set mac_address {}
	    foreach line $buffer {
		if [regexp -nocase {Description} $line] {
		    set val [string trim [lindex [split $line :] end]]
		    lappend mac_addresses $val
		}
		if [regexp -nocase {Physical Address} $line] {
		    set val [string trim [lindex [split $line :] end]]
		    regsub -all {\-} $val : val
		    lappend mac_addresses [string tolower $val]
		}
		if [regexp -nocase {DHCP Enabled} $line] {
		    set val [string trim [lindex [split $line :] end]]
		    lappend mac_addresses [string tolower $val]		
		}

		if [regexp -nocase {IP Address} $line] {
		    set val [string trim [lindex [split $line :] end]]
		    lappend mac_addresses $val
		}
	    }

	    set devices -1
	    set ppp 0
	    foreach {desc mac dhcp ip} $mac_addresses {
		if [regexp desc "PPP"] {
		    set device ppp[incr ppp]
		}  else {
		    set device eth[incr devices]
		}
		lappend iplist [list $device [subnet $ip] $ip $mac $dhcp]
	    }
	}

###
# topic: 11041623-4189-9ca9-4209-8d12651c159b
###
proc ::osinfo::local_domain {} {
    set domain {}
    
    if [info exists ::env(USERDOMAIN)] {
    set domain $::env(USERDOMAIN)    
    } else {
    set domain {}
    }
    return $domain
}

###
# topic: 586b771d-294e-b4d0-08d9-5968e3bf406f
###
proc ::osinfo::local_user {} {
    set user {}
    
    set user [string tolower $::tcl_platform(user)]
    if { $user == {} } {
    # Occasionally, not there in 98
    catch {set user [registry get {HKEY_LOCAL_MACHINE\Network\Logon} username]}
    }
    return $user
}

###
# topic: 9ffa4766-81f0-c685-0018-0b35d19adadb
###
proc ::osinfo::reboot {} {
    go_offline
    exec rundll32.exe shell32.dll,SHExitWindowsEx 2 &
}

###
# topic: 27c661dc-3062-e2fc-5904-39f63b4b4d2f
###
proc ::osinfo::service {cmnd service} {
    tfirpc::log [get ::tfi(computer_id)] service "$service $cmnd"
    switch $cmnd {
    start {
        exec net start $service &
    }
    stop {
        exec net stop $service &
    }
    status {
        return 1
    }
    restart {
        exec net stop $service
        exec net start $service &
    }
    }
}

###
# topic: b4005889-d033-fc0f-7ddc-8cf8485b49fd
###
proc ::osinfo::shutdown {} {
    go_offline
    exec rundll32.exe shell32.dll,SHExitWindowsEx 5 &
}

###
# topic: 263d1a4a-4d73-2f5f-91a7-ea7c56689b52
###
namespace eval ::osinfo {
	
	
	
	
	##################

    
}

