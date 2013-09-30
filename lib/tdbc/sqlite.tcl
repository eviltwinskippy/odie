###
# Sqlite Wrapper for Tip 308
###

package provide odiedbc-sqlite3 0.1
package require sqlite3
package require odiedbc

namespace eval ::tdbc {
    oo::class create ::tdbc::sqlite {
        superclass connector
        
        ###
        # Startup the system
        #
        # Note: This calls are used by the emulator
        #       they are not part of the 308 Spec
        ###
        
        method wake {} {
            variable configdict
            variable channel
            set channel [self]/native
            if { [info command $channel] != {} } {
                return
            }
            set dbfile [dict get $configdict db_file]
            if { $dbfile == {} } {
                error "No db_file specified for [self]"
            }
            puts [list ::sqlite $channel $dbfile]
            ::sqlite $channel $dbfile
        }
        
        method native stmt {
            eval [self]/native $stmt
        }
        
        method sleep {} {
            [self]/native close
        }
        
        
        ###
        # Begin formal implementation of 308 methods here
        ###
        
        method close {} {
            sleep
            next
        }
        
        method starttransaction {} {
            [self]/native eval BEGIN
        }
        method commit {} {
            [self]/native eval COMMIT  
        }
        method rollback {} {
            [self]/native eval ROLLBACK
        }

        method tables {{pattern {}}} {
            if { $pattern == {} } {
                set tables [[self]/native eval {select name from sqlite_master where type='table'}]
            } else {
                set tables [[self]/native eval {select name from sqlite_master where type='table' and name glob $pattern}]
            }
            return $tables
        }
        
        ###
        # Note: Match Patterns are not implemented (yet)
        #
        # They would have to be done in the loop
        ###
        method columns {tablename {pattern {}}} {
            set result {}
            set data [[self]/native eval "PRAGMA table_info('$tablename')"]
            foreach {id name type nullable default extra} $data {
                if { $nullable == "99" } {
                    set nullable 0
                } else {
                    set nullable 1
                }
                dict set result $name [list name $name type $type nullable $nullable default $default extra $extra scale {} precision {}]
            }
            return $result
        }
        
  

    method sqlfix data {
        set map {}
        lappend map \r\n \n \r\r \n ' ''
        set data [string map $map $data]
	#regsub -all "\r\n" $data "\n" data
	#regsub -all "\r\r" $data "\n" data
	#regsub -all "\r" $data "\n" data
	#regsub -all "\'" $data {''} data
	return $data
    }
  
        
        ###
        # Backward Compadibility methods for TAO's old database layer
        # To be removed later
        #
        # For now I'm leaving them in to keep some old code running
        # and they are pretty damn handy
        ###
        method eval args {
            uplevel 1 "[self]/native eval $args"
        }
    
        method query stmt {
            set result {}
            [self]/native eval $stmt values {
                set cols $values(*)
                set row {}
                foreach col $cols {
                    lappend row $values($col)
                }
                lappend result $row
            }
            return $result
        }

        method query_flat stmt {
            #regsub -all ` $stmt {} stmt
            if [catch {
                [self]/native eval $stmt
            } result] {
                puts "***
[self] ERR: $result
***
STMT: $stmt
***"
                error $result
            }
            return $result
        }

        method cmnd stmt {
            #regsub -all ` $stmt {} stmt
            if [catch {
                [self]/native eval $stmt
            } result] {
                puts "***
[self] ERR: $result
***
STMT: $stmt
***"
                error $result
            }
            return $result
        }
    }
}