###
# queue.tcl
#
# This file defines the method needed for the tcl inplementation
# of queues
#
# Copyright (c) 2012 Sean Woods
#
# See the file "license.terms" for information on usage and redistribution of
# this file, and for a DISCLAIMER OF ALL WARRANTIES.
###

::namespace eval ::queue {}

###
# topic: faf2fff4-8cce-65a9-1aa9-aebbd88abb93
# type: ensemble_method
###
ensemble_method ::queue::add {queuevar value} {
  upvar 1 $queuevar queue
  lappend queue $value
}

###
# topic: efe3829e-7435-57ee-356a-2e454a035da1
# type: ensemble_method
###
ensemble_method ::queue::head_insert {queuevar value} {
  upvar 1 $queuevar queue
  set queue [linsert $queue 0 $value]
}

###
# topic: 19078eef-4bc4-b494-9b90-eabf7e88ac1d
# type: ensemble_method
###
ensemble_method ::queue::next {queuevar resultvar} {
  upvar 1 $queuevar queue 
  upvar 1 $resultvar result
  if { [set len [llength $queue]] == 0 } { 
       set result {}
       return 0
  }
  set result [lindex $queue 0]
  if { $len == 1 } { 
       set queue {}
  } else {
    set queue [lrange $queue 1 end]
  }
  return 1 
}

ensemble_build ::queue

