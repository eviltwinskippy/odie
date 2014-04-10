###
# logicset.tcl
#
# This file defines the method needed for the tcl inplementation
# of logical sets
#
# Copyright (c) 2012 Sean Woods
#
# See the file "license.terms" for information on usage and redistribution of
# this file, and for a DISCLAIMER OF ALL WARRANTIES.
###

::namespace eval ::logicset {}

###
# topic: 08efb87d-9c9b-36e8-64f5-0a05ff0811f5
# type: ensemble_method
###
ensemble_method ::logicset::add {setvar args} {
  upvar 1 $setvar result
  if {![info exists result]} {
    set result {}
  }
  foreach arg $args {
    if { $args ni $result } {
      lappend result $arg
    }
  }
  return $result
}

###
# topic: bd1fdea7-e32f-113f-6b4b-b1fe7455d5fd
# type: ensemble_method
###
ensemble_method ::logicset::cartesian_product {A B} {
  set result {}
  foreach alement [sort $A] {
    foreach blement [sort $B] {
      lappend result $alement $blement
    }
  }
  return $result
}

###
# topic: d3032d6a-b1d1-656e-afab-a99bb80e09a9
# type: ensemble_method
###
ensemble_method ::logicset::contains {setval args} {
  foreach arg $args {
    if { $arg ni $setval } {
      return 0
    }
  }
  return 1
}

###
# topic: d642d345-9294-81a0-cd88-38b825966629
# type: ensemble_method
###
ensemble_method ::logicset::empty setval {
  if {[llength $setval] == 0} {
    return 1
  }
  return 0
}

###
# topic: aaf46124-7085-3353-aba3-88d113cd0e78
# type: ensemble_method
###
ensemble_method ::logicset::intersection {A B} {
  set result {}
  foreach element $B {
    if { $element in $A } {
      add result $element
    }
  }
  return $result
}

###
# topic: 5ff774e0-3ce3-fd96-38e0-3c83a0c7b1a4
# type: ensemble_method
###
ensemble_method ::logicset::remove {setvar args} {
  upvar 1 $setvar result
  if {![info exists result]} {
    set result {}
  }
  foreach arg $args {
    while {[set idx [lsearch $result $arg]] >= 0} {
      set result [lreplace $result $idx $idx]
    }
  }
  return $result
}

###
# topic: ca1ffbc9-d3ff-fbc4-4a2e-d63ed823573d
# type: ensemble_method
###
ensemble_method ::logicset::set_difference {U A} {
  set result {}
  foreach element $A {
    if { $element ni $U } {
      add result $element
    }
  }
  return $result
}

###
# topic: ddb93085-3ab4-a3b3-61e1-fc2133a7c79a
# type: ensemble_method
###
ensemble_method ::logicset::sort A {
  return [lsort -dictionary -unique $A]
}

###
# topic: 13e4ecbf-7e85-e27f-c293-a4b42ad48c30
# type: ensemble_method
###
ensemble_method ::logicset::symmetric_difference {A B} {
  set result {}
  foreach element $A {
    if { $element ni $B } {
      add result $element
    }
  }
  foreach element $B {
    if { $element ni $A } {
      add result $element
    }
  }
  return $result
}

###
# topic: 49074428-2a40-261f-0d63-192290657d9b
# type: ensemble_method
###
ensemble_method ::logicset::union {A B} {
  set result {}
  add result {*}$A
  add result {*}$B
  return $result
}

ensemble_method ::logicset::permutation items {
  set l [llength $items]
  if {[llength $items] < 2} {
    return $items
  } else {
    for {set j 0} {$j < $l} {incr j} {
      foreach subcomb [permutation [lreplace $items $j $j]] {
        lappend res [concat [lindex $items $j] $subcomb]
      }
    }
    return $res
  }
}

ensemble_build ::logicset

