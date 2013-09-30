# Namespace stem --
#
#   Find English word stems via Porter's Algorithm
#
#   Copyright (c) 2001, Steve Cassidy  <Steve.Cassidy@mq.edu.au>
# 
# This program is made available under the same license terms as Tcl
# 
# See http://www.shlrc.mq.edu.au/~steve/tcl for updates.
# 

package provide stem 1.0

namespace eval stem {;
    namespace export -clear stem stem_text stem_file
    
    variable cache

}; # end of nameespace stem


# stem::stem --
#
#   find the stem of a word
#
# Arguments:
#   word     -- a word to stem
# Results:
#   Returns the word stem
#
proc stem::stem {word} {

    variable cache

    ## remove any nonword chars from word
    regsub -all -- {\W} $word {} word

    ## uppercase the word
    set word [string toupper $word]

    ## look in the cache to save work
    if [info exists cache($word)] {
	return $cache($word)
    }
    ## remember what we started with
    set initialword $word

    # step 1a

    tryrules word {
	{   SSES$ SS}
	{   IES$   I}
	{   SS$   SS}
	{   S$    {}}
    }

    # step 1b
    
    set cont_1b 0
    if {[regexp {(.*)EED$} $word => stem] && [measure $stem]>0 } {
	# should work for agreed => agree but gives agre
	set word [join [list $stem E] {}]
    } elseif [regexp {(.*)ED$} $word => stem] {
	if [regexp {V} [cvform $stem]] {
	    set word $stem
	    set cont_1b 1
	}
    } elseif [regexp {(.*)ING$} $word => stem] {
	if [regexp {V} [cvform $stem]] {
	    set word $stem
	    set cont_1b 1
	}
    }

    if {$cont_1b} {
	## added an IS -> ISE rule here for british english
	tryrules word {
	    {AT ATE}
	    {BL BLE}
	    {IZ IZE}
	    {IS ISE}
	}

	if { [string equal [string index $word end] [string index $word end-1]] \
	    && ![string match {*[LSZ]} $word]} {
	    # replace doubled letter with a single one
	    set word [string range $word 0 end-1]
	} else {
	    if {[measure $word] == 1 && [star_o $word]} {
		# add an E
		set word [join [list $word E] {}]
	    }
	}
    }
    
    ## step 1c 
    
    ## (*v*) Y -> I
    if { [regexp {.*Y$} $word => stem] && [regexp {V} [cvform $stem]] } {
	regsub {Y$} $word {I} word
    }


    ## step 2

    tryrules_if_m 0 word {
	{ATIONAL   ATE    }
	{TIONAL    TION   }
	{ENCI      ENCE   }
	{ANCI      ANCE   }
	{IZER      IZE    }
	{ABLI      ABLE   }
	{ALLI      AL     }
	{ENTLI     ENT    }
	{ELI       E      }
	{OUSLI     OUS    }
	{IZATION   IZE    }
	{ATION     ATE    }
	{ATOR      ATE    }
	{ALISM     AL     }
	{IVENESS   IVE    }
	{FULNESS   FUL    }
	{OUSNESS   OUS    }
	{ALITI     AL     }
	{IVITI     IVE    }
	{BILITI    BLE    }
    }

    # step 3

    tryrules_if_m 0 word {
	{ICATE IC}
	{ATIVE {}}
	{ALIZE AL}
	{ICITI IC}
	{ICAL  IC}
	{FUL   {}}
	{NESS  {}}
    }

    # step 4

    tryrules_if_m 1 word {
	{AL   }
	{ANCE }
	{ENCE }
	{ER   }
	{IC   }
	{ABLE }
	{IBLE }
	{ANT  }
	{EMENT}
	{MENT }
	{ENT  }
	{OU   }
	{ISM  }
	{ATE  }
	{ITI  }
	{OUS  }
	{IVE  }
	{IZE  }
    }

    if {[regexp "(.*\[ST\])ION\$" $word => stem] && [measure $stem]>1} {
	    set word $stem
    }

    # step 5a
    ## these two seem to cause errors (cease -> ceas) and not result in 
    ## any correct stems

     # (m>1) E     ->                 
#      if {[regexp {(.*)E$} $word => stem] && [measure $stem]>1} {
# 	 puts "Removing E from $word"
#  	set word $stem
#      }

    # (m=1 and not *o) E ->
#     if {[regexp {(.*)E$} $word => stem] &&\
# 	    [measure $stem]==1 &&\
# 	    ![star_o $stem]} {
# 	set word $stem
#     }

    # step 5b
    # (m > 1 and *d and *L) -> single letter
    if {[string match *L $word] \
	    && [string equal [string index $word end] [string index $word end-1]]\
	    && [measure $word] > 1} {
	regsub {(.).$} $word {\1} word 
    }

    set cache($initialword) $word
    return $word

}

# stem::tryrules --
# stem::tryrules_if_m
#
#   try to match a set of rules of the form {lhs rhs} against a word
#   if lhs appears at the end of the word, replace it with rhs and return.
#   in the second form, we also check that the measure of the stem
#   is greater than the given n
#
# Arguments:
#   word   -- a variable name to look in and modify
#   rules  -- one or more {lhs rhs} pairs
# Results:
#   modifies word if a rule matches 
#
proc stem::tryrules {wordvar rules} {
    
    upvar word $wordvar

    foreach rule $rules {
	foreach {lhs rhs} $rule {}
	if [regsub -- "$lhs\$" $word $rhs word] {
	    return 
	}
    }
}

proc stem::tryrules_if_m {n wordvar rules} {
    
    upvar word $wordvar

    foreach rule $rules {
	foreach {lhs rhs} $rule {}
	if {[regexp "(.*)$lhs\$" $word => stem] && [measure $stem]>$n} {
	    set word [join [list $stem $rhs] {}]
	    return 
	}
    }
}





# stem::cvform --
#
#   convert the word to CV form as required by porter
#
# Arguments:
#   word   -- a word 
# Results:
#   Returns a string of Cs and Vs
#
proc stem::cvform {word} {
    ##
    ## consonant % = a letter other than AEIOU or Y preceeded by consonant
    ## vowel @ = not a consonant

    regsub -all -nocase -- {([^AEIOU])Y} $word {\1@} cvstring
    regsub -all -nocase -- {[AEIOU]} $cvstring {@} cvstring
    regsub -all -nocase -- {[^@]} $cvstring {%} cvstring

    # now convert sequences of . to C and sequences of | to V

    regsub -all {%+} $cvstring {C} cvstring
    regsub -all {@+} $cvstring {V} cvstring

    return $cvstring
}


# stem::measure --
#
#   find the `measure' of a word -- the value of m in [C](VC){m}[V]
#
# Arguments:
#   word
# Results:
#   Returns the measure, an integer > 0
#
proc stem::measure {word} {

    set cvstring [cvform $word]

    # strip inital C or final V if present:
    if {![regexp {C?((VC)*)V?} $cvstring => trimstring]} {
	set trimstring $cvstring
    }
    set m [expr [string length $trimstring]/2]

    if {$m < 0} {
	return 0
    } else {
	return $m
    }
}


# star_o --
#
#   tests porters *o condition: the stem ends cvc, where the second c is 
#        not W, X or Y (e.g. -WIL, -HOP).
#
# Arguments:
#   word
# Results:
#   Returns boolean
#
proc stem::star_o {word} {

    set len [string length $word]

    if {$len < 3} {
	return 0
    }
    set last3 [string range $word [expr $len-3] end]

    regsub -all -nocase -- {([^AEIOU])Y} $last3 {\1@} cvstring
    regsub -all -nocase -- {[AEIOU]} $cvstring {@} cvstring
    regsub -all -nocase -- {[^@]} $cvstring {%} cvstring

    # must have %@%
    if {![string equal $cvstring "%@%"]} {
	return 0
    } else {
	# last can't be WXY
	if [string match {*[WXY]} $word] {
	    return 0
	} else {
	    return 1
	}
    }
}



proc stem::stem_text {text} {
    set result {}
    foreach word $text {
	lappend result [stem $word]
    }
    return $result
}


proc stem::stem_file {in out} {
    if [catch {open $in} inh] {
	error "Can't open $in"
    }
    if [catch {open $out w} outh] {
	error "Can't open $out"
    }
    set text [read $inh]
    set result [stem_text $text]
    puts $outh [join $result \n]
}





