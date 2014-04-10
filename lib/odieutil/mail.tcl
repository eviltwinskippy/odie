### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB


package provide qdmailer 1.1

###
#  Quick and dirty mailing list transmitter
###

::namespace eval ::smtp {}

###
# topic: 0f3ea895-9202-e0f3-171f-576fd11065f9
###
proc ::smtp::init smtphost {
variable host $smtphost
}

###
# topic: 2e00b054-ca86-b488-5f78-2db500cb416f
###
proc ::smtp::send {tolist sender body} {
      variable host
      set result {}

      set hostname [lindex [split $host :] 0]
      set port [lindex [split $host :] 1]
      if { $port eq {} } {
        set port smtp
      }
      set sock [socket $hostname $port]
    fconfigure $sock -blocking 1 -buffering line
    smtp_send_line $sock "HELO [info hostname]"
    smtp_send_line $sock "MAIL FROM: <$sender>"
    foreach person $tolist {
	if [catch {
	    smtp_send_line $sock "RCPT TO: <$person>"
	    append result "\nAccepted: $person"

	} err] {
	    append result "\nBad Recipient: $person ($err)"
	}
    }
    smtp_send_line $sock "DATA"
    puts $sock $body
    flush $sock
    smtp_send_line $sock .
    smtp_send_line $sock QUIT
    close $sock
    return $result
    }

###
# topic: 5f983346-efe2-4aff-d7ce-8a6d3d2810a0
###
proc ::smtp::smtp_send_line {chan line} {
   upvar 1 result result

   puts $chan $line
   set reply [gets $chan]
   if { [lindex $line 0] == "HELO" } {
	 append reply [gets $chan]
   }
   append result "> $line\n"
   append result "< $reply\n"
   if { [string index $reply 0] == "5" } {
       # Let calling programs debug what's going on
       set ::smtp_buffer $result
       # Give up my toys and close the channel
       catch {puts $chan "QUIT"}
       catch {puts $chan "QUIT"}
       catch {close $chan}
       # Throw an error
       error "$line\n$reply"
   }
}

###
# topic: 4b02efaa-b3ea-9dd4-c1da-0d432168e77d
###
namespace eval ::smtp {
   ###
   # Transmit an email to a distribution list.
   # Body should include any headers you wish to send
   ###


    ###
    #  Used internally to process SMTP response codes
    ###
}

