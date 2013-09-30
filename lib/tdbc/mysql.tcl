### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2008 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

package provide odiedbc-mysqltcl 0.1
package require mysqltcl 3.0
package require odiedbc

###
# MySqlTcl Wrapper for Tip 308
###

namespace eval ::tdbc {
    ::oo::class create ::tdbc::mysqltcl  {
        superclass ::tdbc::connector
    
        method tables {{pattern {}}} {
            set tables [::mysql::info [my wake] tables]
            if { $pattern == {} } {
                return $tables
            }
            set result {}
            foreach r $tables {
                if [regexp $pattern $r] {
                    lappend result $r
                }
            }
            return $result
        }
    
        method databases {} { 
            return [::mysql::info [my wake] databases]
        }
       
   
        method starttransaction {} {
            ::mysql::exec [my wake]  BEGIN
        }
        method commit {} {
            ::mysql::exec [my wake] COMMIT  
        }
        method rollback {} {
            ::mysql::exec [my wake] ROLLBACK
        }
        
        method wake {} {
            variable last_used
            variable cstate
            variable configdict
            variable cchannel
            if ![info exists cstate] {
                set cstate closed
            }
            if { $cstate != "open" } {
                set cchannel [::mysql::connect -host [dict get $configdict db_host] -user [dict get $configdict db_user] -password [dict get $configdict db_pass] -db [dict get $configdict database]]
            }
            set cstate open
            set last_used [clock seconds]
            return $cchannel
    
        }
    
        method sleep {} {
            variable cstate
            variable cchannel
            set cstate closed
            catch {
                ::mysql::close $cchannel
            }
        }
    
        method query stmt {
            return [::mysql::sel [my wake] $stmt -list]
        }
    
       method query_flat stmt {
           if [catch {::mysql::sel [my wake] $stmt -flatlist} err] {
               error "Error in statment: $err
    stmt: $stmt"
           }
           return $err
       }
    
        method cmnd stmt {
            ::mysql::exec [my wake] $stmt
        }
    
        method sqlfix data {
            ###
            # This package has a C-level handler 
            # for mysql escape sequences
            ####
            return [::mysql::escape $data]
        }
    
       method database {{newdb {}}} {
            variable configdict
            if { $newdb != {} } {
                dict set $configdict database $newdb
                ::mysql::use [my wake] $newdb
            }
            return [dict get $configdict database]
        }
    }
}
