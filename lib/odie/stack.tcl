###
# queue.tcl
#
# This file defines the method needed for the tcl inplementation
# of stacks
#
# Copyright (c) 2012 Sean Woods
#
# See the file "license.terms" for information on usage and redistribution of
# this file, and for a DISCLAIMER OF ALL WARRANTIES.
###

::namespace eval ::stack {}

###
# topic: 31fdcfe6-70eb-f454-2963-201fa6d15d70
# type: ensemble_method
###
ensemble_method ::stack::head_insert {stackvar value} {
  upvar 1 $stackvar stack
  set stack [linsert $stack 0 $value]
}

###
# topic: dc304faa-b514-d4ba-c7a5-f14287c4a710
# type: ensemble_method
###
ensemble_method ::stack::peek stackvar {
  upvar 1 $stackvar stack
  if {[info exists stack]} {
    return [lindex $stack end]
  }
  return {}
}

###
# topic: 79827956-1a8b-edda-397c-f9d076b9d8a9
# type: ensemble_method
###
ensemble_method ::stack::pop {stackvar resultvar} {
  upvar 1 $stackvar stack 
  upvar 1 $resultvar result
  if { [set len [llength $stack]] == 0 } { 
       set result {}
       return 0
  }
  set result [lindex $stack end]
  if { $len == 1 } { 
       set stack {}
  } else {
    set stack [lrange $stack 0 end-1]
  }
  return 1 
}

###
# topic: de540806-071f-5e11-d270-34e040a4b46c
# type: ensemble_method
###
ensemble_method ::stack::push {stackvar args} {
  upvar 1 $stackvar stack
  lappend stack {*}$args
}

ensemble_build ::stack

