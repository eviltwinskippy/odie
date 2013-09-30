package provide bork 1.0

::namespace eval ::book {}

::namespace eval ::bork {}

###
# topic: a046a48e-8fcd-f4a9-2f4e-cada0f301e9e
###
proc ::book::convert buffer {
  
  variable patterns
  foreach {idx pat rep} $patterns {
     regsub -all $pat $buffer "C${idx}C" buffer
  } 
  foreach {idx pat rep} $patterns {
     regsub -all "C${idx}C" $buffer $rep buffer
  } 

  return $buffer

}

###
# topic: 38f1663a-2a04-024d-691e-bb872b06d49c
###
proc ::bork::bork buffer {
  set result {}
  set temp $buffer
  while 1 {
      set i [string first < $temp]
      if { $i < 0 } { 
          append result [convert $temp]
          return $result
      }
      set t [string range $temp 0 [expr $i - 1]]
      append result [convert $t]
      set temp [string range $temp $i end]
      set i [string first > $temp]
      if { $i < 0 } { 
          append result $temp
          return $result
      }
      append result [string range $temp 0 $i]
      set temp [string range $temp [expr $i + 1] end]
      if { $temp == {} } { 
          return $result
      }
  }
  return $result
}

###
# topic: e7095842-39bc-7ce9-1458-b69197857fab
###
namespace eval ::bork {
    variable patterns
    set patterns {
	19 the	zee
	20 The	Zee
	21 th	t
	22 tion	shun

	1  o	oo
	2  O	oo
	3  u	oo 
	4  o	u

	5  an	un
	6  An	Un
	7  e	e-a
	8  a	e
	9  A	E
	10 en	ee
	11 ew	oo
	12 E	I
	13 f	ff
	14 ir	ur
	15 i	ee
	16 ow	oo
	17 au	oo
	18 Au	Oo
	23 U	Oo
	24 v	f
	25 V	F
	26 w	v
	27 W	V

    }
}

