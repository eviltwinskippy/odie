###
# SBIR DATA RIGHTS
# Contract No.: N00024-11-C-4120
# Contractor Name: Test & Evaluation Solutions, LLC
# Contractor Address: 400 Holiday CT, STE 204, Warrenton, VA 20186
#
# Expiration of SBIR Data Rights Period: 22 May 2017
#   The Government's rights to use, modify, reproduce, release, perform,
#   display, or disclose technical data or computer software marked with
#   this legend are restricted during the period shown as provided in
#   paragraph (b)(4) of the Rights in Noncommercial Technical Data and
#   Computer Software--Small Business Innovative Research (SBIR) Program
#   clause contained in the above identified contract. No restrictions
#   apply after the expiration date shown above. Any reproduction of
#   technical data, computer software, or portions thereof marked with
#   this legend must also reproduce the markings.
#
# Distribution Statement B: Distribution authorized to U.S. Government
# agencies only; (DFARS - SBIR Data Rights); 22 November 2010. Other
# requests for this document shall be referred to Naval Sea Systems
# Command ATTN: Small Business Innovation Research Program Office
# SEA05T1R, 1333 Isaac Hull Ave SE, Washington Navy Yard, DC 20376.
###

set scriptpath [file dirname [file normalize [info script]]]
set tclsh [info nameofexecutable]
set list [exec find . -iname *.tcl.new]

   button .keep -text "Keep Change" -command {set action keep}
   button .trash -text "Trash Change" -command {set action trash}
   button .skip -text "Skip" -command {set action skip}
   grid .keep .trash .skip

foreach item $list {
   set oldfile [file rootname $item]
   set newfile $item
   catch {exec $tclsh $scriptpath/tkdiff.tcl [file rootname $item] $item &} pid
   vwait action
   exec kill $pid
   switch $action {
     keep {
       file rename -force $newfile $oldfile
     }
     trash {
       file delete $newfile
     }
     skip {}
   }
}
exit 0
