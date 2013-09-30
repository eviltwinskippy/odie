
###
# Define a common framework class or TDBC connectors
###
package require listutil

namespace eval ::tdbc {
    
    namespace export *
    namespace ensemble create


    ###
    # Define column types
    ###

    ###
    # Define a Statement class
    ###
    oo::class create statement {
        constructor {connectorObj paramDict} {
            variable connector $connectorObj
            variable params
            foreach {key info} $paramDict {
                dict set params $key [::tdbc::combine {name {} type {} scale {} precision {} nullable 1} $info]
            }
        }
        method params {} {
            variable params
            return $params
        }
        
        method execute {{dictionary {}}} {
            error "Method Not implemented"
            
        }
        
        method close {} {
            destroy
        }
    }

    ###
    # Define a Result Set class
    ###
    oo::class create resultSet {
        constructor initstmt {
            variable stmt
            set stmt $initstmt
        }
        method rows {} {
            
        }
        method columns {} {
            
        }
        method nextrow args {
            set usageStr "Usage: nextrow ?-as lists|dicts? ?--? variableName"
            set mode dicts
            ###
            # Medieval, I know, but I'm on a code sprint
            ###
            switch [llength $args] {
                4 {
                    if { [lindex $args 0] == "-as"  && [lindex $args 2] = "--" } {
                        set mode [lindex $args 1]
                        set varname [lindex $args 3]
                    } else {
                        error $usageStr
                    }
                }
                3 {
                    if { [lindex $args 0] == "-as" } {
                        set mode [lindex $args 1]
                        set varname [lindex $args 2]
                    } else {
                        error $usageStr
                    }
                }
                1 {
                   set varname [lindex $args 0]
                }
                default {
                    error $usageStr
                }
            }
        }
        method close {} {
            destroy
        }
    }     

    ###
    # Define batch processing class
    ###
    
    ###
    # Define a generic template class for other systems to build on
    ###

    ::oo::class create connector {

        constructor args {
            variable configdict
            ###
            # Establish the TDBC Defaults
            ###
            foreach {var val} {
                encoding    default
                isolation   serializable
                timeout     default
                readonly    0
            } {
                dict set configdict $var $val
            }
            my wake
        }

        ###
        # Validate a configured encoding
        ###
        method configValidate.encoding newvalue {
            if { $newvalue != "default" } {
                error "No values for default are defined for this class"
            }
        }


        ###
        # Validate a configured isolation
        ###
        method configValidate.isolation newvalue {
            set validValues {readuncommitted readcommitted repeatableread serializable readonly}
            if { $val ni $validValues} {
                error "Bad value for -isolation. Valid values: $validValues"
            }
        }

        ###
        # Check that configuration input from
        # configure is valid before modifying
        ###
        method configValidate {newvaluedict} {
            variable configdict
            set result $configdict
            foreach {var val} $newvaluedict {
                set var [string trimleft $var -]
                switch $var {
                    encoding -
                    isolation {
                        configValidate.$var $val
                    }
                    default {
                    }
                }
                dict set result $var $val
            }
            return $result
        }

        method configure args {
            variable configdict
            set this [self]
            set vallist $args
            if { $vallist == {} } {
                return $configdict
            }
            if { [llength $vallist] == 1 } {
        	    return [dict get $configdict [string trimleft [lindex $vallist 0] -]]
            }
            set configdict [my configValidate $vallist]
        }

        method substLoop {bufferVar} {
            upvar 1 $bufferVar buffer
            set buffer [string trimleft $buffer]
            set i [string first : $buffer]
            if { $i < 0 } {
                return {}
            }
            set j [string first " " $buffer]
            if { $j < 0 } {
                set j end
            }
            set var [string range [expr $i + 1] $j]
            return $var
        }

        ###
        # TQL
        #
        # insert:
        # INSERT {
        #    table table
        #    values {key value ...}
        #}
        #
        # SELECT {
        #    table table1
        #    fields {field1 field2...}
        #    join {
        #       table table2
        #       on {table1field table2field}
        #       type {INNER/LEFT OUTER/RIGHT OUTER/FULL OUTER/CROSS}
        #    }
        #    wheresql {
        #       x='y' AND x like '%bar%' AND (z=foo OR z like '%bat%') 
        #    }
        # ----or----
        #    wheretql {
        #       and {{x eq y} {x like %bar%} {OR {z eq ?foo} {z like %bat%}}}
        #    }
        # ---or-----
        # -- 
        #    valuelist {
        #       x y z bar 
        #   }
        # }
        #
        # DELETE {
        #    table table1
        #
        #    wheresql {
        #       x='y' AND x like '%bar%' AND (z=foo OR z like '%bat%') 
        #    }
        # ----or----
        #    wheretql {
        #       and {{x eq y} {x like %bar%} {OR {z eq ?foo} {z like %bat%}}}
        #    }
        # ----or----
        #    delete all
        # }
        #
        # CREATE {
        #    table {}
        #}
        
        if 0 {

        method tqlstmt {
                        
        }
        method stmt_select {tablelist fieldlist conditions {sort {}} {limit {}}} {
            
        }
        method stmt_select_join_left {table1 table1 fieldlist conditions {sort {}} {limit {}}} {
            
        }
        method stmt_select_join_right {table1 table1 fieldlist conditions {sort {}} {limit {}}} {
            
        }
        method stmt_select_join_innter {table1 table2 fieldlist conditions {sort {}} {limit {}}} {
            
        }
        method stmt_delete {table conditions} {
        }
        
        method stmt_update {tablelist newvaluelist conditions {limit {}}} {
            
        }
        }
        method prepare sqlcode {
            # detect variable substitutions
            # I'm no good at regexp, so I do it the
            # hard way
            set varlist {}
            set buffer $sqlcode
            while {[set nextVar [my substLoop $buffer]] != {} } {
            }
            set stmt $sqlcode
            foreach var $varlist {
                upvar 1 $var $var
                regsub -all ":${var} " $buffer "[my sqlfix [set $var]] " stmt
            }
            
            
        }
        method preparecall sqlcode {
            
        }
        
        method statements {} {
            variable statements
            return $statements            
        }
        
        method resultsets {} {
            variable resultSets
            return $resultSets
        }
    }
        
    foreach {method arglist} {
            starttransaction {}
            commit {}
            rollback {}
            close {}
            tables {{matchpattern %}}
            columns {tablename {matchpattern %}}
            columnTypeMapSource {}
            columnTypeMapTDIF {}
    } {
        oo::define connector method $method $arglist {
            error "Method Not implemented"
        }
    }
    oo::define connector export *
}

namespace eval ::tcl {}

namespace eval ::tcl::db {
    
}