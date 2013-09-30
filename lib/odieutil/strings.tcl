### BEGIN COPYRIGHT BLURB
#   
#   TAO - Tcl Architecture of Objects
#   Copyright (C) 2003 Sean Woods
#   
#   See the file "license.terms" for information on usage and redistribution
#   of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#   
### END COPYRIGHT BLURB

package provide odie-strings 1.1
package require odie-calendar

::namespace eval ::ostring {}

###
# topic: 69e9f55e-a7bf-b874-3991-415d33de5db1
###
proc ::ostring::address_type string {
set addrtype hostname
if { [string index $string end] == . } {
    return $hostname
}
if { [llength [set ipl [split $string .]]] == 4 } { 
    set ip 1
    foreach i $ipl {
    if { ![string is integer $i] } {
        set ip 0
        break
    }
    }
    if { $ip } { 
    return ip
    }
}
if { [llength [split $string :]] == 6 } {
    return mac
}
if { [llength [split $string -]] == 6 } {
    return mac
}
return hostname
}

###
# topic: 42f65de7-45b0-b130-2cb1-cf22e47951a6
###
proc ::ostring::cache {entry {newvalue {}}} {
    variable cache
    if { $newvalue == "NULL" } {
        array unset cache $entry
        return
    }
    if { $newvalue != {} } {
        set cache($entry) $newvalue
        return
    }
    if [info exists cache($entry)] {
        return $cache($entry)
    }
    return {}
}

###
# topic: f70dfd63-113a-e63b-dad0-3494df58e244
# description:
#    stem::cvform
#    
#    convert the word to CV form as required by porter
# arguments: word   -- a word
###
proc ::ostring::cvform word {
    ##
    ## consonant % = a letter other than AEIOU or Y preceeded by consonant
    ## vowel @ = not a consonant

    regsub -all -- {([^AEIOU])Y} $word {\1@} cvstring
    regsub -all -- {[AEIOU]} $cvstring {@} cvstring
    regsub -all -- {[^@]} $cvstring {%} cvstring

    # now convert sequences of . to C and sequences of | to V

    regsub -all {%+} $cvstring {C} cvstring
    regsub -all {@+} $cvstring {V} cvstring

    return $cvstring
}

###
# topic: adc8d9a3-d565-d9d8-51f9-b58655f99c61
###
proc ::ostring::detect_addr host {
if { [string index $host end] == "." } {
    return 1
}
return 0
}

###
# topic: 79ee26e8-8b8a-44c1-6cc7-beda0645e16d
###
proc ::ostring::detect_date rawstring {
return [::calendar::detect_date $rawstring]
}

###
# topic: b8134043-3960-2193-f757-fb74d9d262c5
###
proc ::ostring::detect_ip rawline {
# Remove any trailing garbage from a mac address
set rawlist {}
foreach item $rawline {
    if [regexp {\.} $item] {
    lappend rawlist $item
    }
}

foreach ip $rawlist {
    set iplist [split $ip .]
    
    if { [llength $iplist] != 4 } continue
    
    set badaddr 0
    foreach item $iplist {
    if ![string is integer $item] {
        set badaddr 1
        break
    }
    if { $item > 255 } {
        set badaddr 1
        break
    }
    if { $item < 0 } {
        set badaddr 1
        break
    }
    }
    if !$badaddr {
    return [join [lrange $iplist 0 3] .]
    }
}
return {}
}

###
# topic: 89eeac25-0edb-5911-684a-de4b4c653885
###
proc ::ostring::detect_mac rawline {
# Remove any trailing garbage from a mac address
set rawlist {}
foreach item $rawline {
    if [regexp ":" $item] {
    lappend rawlist $item
    }
}

foreach mac $rawlist {
    set maclist [split $mac :]

    set badaddr 0
    if { [llength $maclist] != 6 } continue
    ###
    # Mac sure all parts of the mac number are
    # in fact hex digits
    ###
    foreach item $maclist {
    if ![string is xdigit $item] {
        set badaddr 1
        break
    }
    }
    if !$badaddr {
    return [join [lrange $maclist 0 5] :]
    }
}
return {}
}

###
# topic: 50e6f472-d7c7-fc87-54f6-12fca9b11656
###
proc ::ostring::detect_time rawstring {
return [::calendar::detect_time $rawstring]
}

###
# topic: 1138538e-faaa-488e-10f5-d049bce14364
###
proc ::ostring::dumpCache file {
    variable cache
    variable stopWords
    set fout [open $file w]
    foreach item stopWords {
        set cache($item) {}
    }
    foreach item [lsort -dictionary [array names cache]] {
        puts $fout [list $item $cache($item)]
    }
    close $fout
}

###
# topic: c64c5106-3a6b-fda7-00b3-295a4ebb3211
###
proc ::ostring::fix_addr host {
if { [string index $host end] == "." } {
    return $host
}
append host .
return $host

}

###
# topic: 7a6282b2-fe5d-c9aa-7dca-4fa1f268777e
# description:
#    stem::measure
#    
#    find the `measure' of a word -- the value of m in [C](VC){m}[V]
# arguments: word
###
proc ::ostring::measure word {

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

###
# topic: 11244288-663a-5470-5bb8-f85015a16378
###
proc ::ostring::metaphone { string } {
    variable metaphonePatterns
     foreach [ list pattern replacement ] $metaphonePatterns {
        regsub -all -nocase $pattern $string $replacement string
     }

     regsub -all {\s+} $string { } string
     return $string
}

###
# topic: c7ef5a36-d044-e72e-5ce4-3d9a36e3c46c
# description:
#    stem
#    
#    find the stem of a word
# arguments: word     -- a word to stem
###
proc ::ostring::porter word {
        variable cache
        variable steps
        if { [string length $word] < 5 } {
            return [string trimright $word S]
        }
    
        ## look in the cache to save work
        if { [set r [cache $word]] != {} } {
            return $r
        }
        ## remember what we started with
        set initialword $word
    
        # step 1a
        tryrules word [dict get $steps 1a]
    
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
            tryrules word [dict get $steps 1b]
            
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
    
    
        ## step 2.a
        tryrules_if_m 0 word [dict get $steps 2.a]
        ## step 2.b

        tryrules_if_m 0 word [dict get $steps 2.b]
    
        # step 3
        tryrules_if_m 0 word [dict get $steps 3]

        # step 4    
        tryrules_if_m 1 word [dict get $steps 4]
        
        if {[regexp "(.*\[ST\])ION\$" $word => stem] && [measure $stem]>1} {
                set word $stem
        }
    
        # step 5a
        ## these two seem to cause errors (cease -> ceas) and not result in 
        ## any correct stems
        # (not even included here...)    

        # step 5b
        # (m > 1 and *d and *L) -> single letter
        if {[string match *L $word] \
                && [string equal [string index $word end] [string index $word end-1]]\
                && [measure $word] > 1} {
            regsub {(.).$} $word {\1} word 
        }
      
        
        ### TOADY STEPS
        # Strip trailing E's I's and Y's
        # If it leads to an existing word
        ###
        if { [string index $word end] in {I E Y} } {
            set test [string range $word 0 end-1]
            if [info exists cache($test)] {
                set word $test
            }
        }
    
        cache $initialword $word
        return $word
    }

###
# topic: 47fdc572-cebb-58bc-f02f-d85e74ed7dc8
###
proc ::ostring::reduce {buffer {stemmer porter}} {
set result {}
variable stopWords
foreach item $buffer {
    if { $item in $stopWords } continue
    set stem [$stemmer $item]
    if { [string length $stem] > 1 } {
    lappend result $stem
    }
}
return $result
}

###
# topic: bd7594e7-49b3-6578-3d59-7c70ac33b7d3
###
proc ::ostring::soundex { TempIn } {
    variable soundexCodes
    set key ""
    
    if {[string length "$TempIn"] == 0} then {
        return "Z000"
    }
    set last "[string index $TempIn 0]" 
    set key "[string toupper $last]"
    set last [dict get $soundexCodes $last]

    #  Scan rest of string, stop at end of string or when the key is full
    set count 1
    set MaxIndex [string length $TempIn]
    for { set index 1} {(($count < 4) && ($index < $MaxIndex))} {incr index } {
        set chcode [dict get $soundexCodes [string index $TempIn $index]]
        # Fold together adjacent letters sharing the same code
        if { "$last" != "$chcode"} then {
            set last "$chcode"
            # Ignore code==0 letters except as separators
            if {"$last" != 0} then {
                set key "$key$last"
                incr count
            }
        }
    }
    return [string range "${key}0000" 0 3]
}

###
# topic: bee1c271-a090-6842-d32e-13c1861512dc
# description:
#    star_o
#    
#    tests porters *o condition: the stem ends cvc, where the second c is
#    not W, X or Y (e.g. -WIL, -HOP).
# arguments: word
###
proc ::ostring::star_o word {

    set len [string length $word]

    if {$len < 3} {
        return 0
    }
    set last3 [string range $word [expr $len-3] end]

    regsub -all -- {([^AEIOU])Y} $last3 {\1@} cvstring
    regsub -all -- {[AEIOU]} $cvstring {@} cvstring
    regsub -all -- {[^@]} $cvstring {%} cvstring

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

###
# topic: e665470b-e255-9464-8333-2b612e02977a
###
proc ::ostring::stemprep buffer {
   variable contractions
   set result [string toupper $buffer]
       #
       # Map bars and dashes as seperators between stems
       #
       
       # Insert whitespace implied by tags
       set result [string map {| { } - { } {<LI} { <LI} {<OL} { <OL} {<UL} { <UL} {<DIV} { <DIV} {,} { , } {<BR} { <BR} {<P} { <P} {<DT} { <DT} {<TD} { <TD}} $result]      

       regsub -all -- {<[^>]*>} $result {} result      
   set result [string map $contractions $result]
       regsub -all -- {[^A-Z]} $result { } result
       
   return $result
   }

###
# topic: 1730e193-c758-66fb-db05-3387ed8613ec
###
proc ::ostring::strip buffer {
variable contractions
    # Remove the leading/trailing white space punctuation etc.
    #set TempIn [string trim $word "\t\n\r .,'-"]

    # only use alphabetic characters, so strip out all others
    # also, soundex index uses only upper case chars, so force to upper

# Preserve contractions
#set buffer [string toupper $buffer]
#set buffer [string map $contractions $buffer]
    regsub -all {[^A-Z]} [string toupper $buffer] { } buffer
    
return $buffer
    ## remove any nonword chars from buffer
    #regsub -all -- {\W} $word { } word

    ## uppercase the word
}

###
# topic: 0ba656cd-27eb-e632-2e04-61e8eb155318
###
proc ::ostring::strip-html {html {ignore {}}} {
  set n [string first "<body" $html]
  if { $n < 0 } {
  set n [string first "<BODY" $html]
  }
  if { $n >= 0 } {
  set html [string range $html $n end]
  }
  set n [string first "</body" $html]
  if { $n < 0 } {
  set n [string first "</BODY" $html]
  }
  if { $n >= 0 } {
  set html [string range $html 0 [expr $n - 1]]
  }
    #regsub -all -- {<[^>]*>} $html "\[strip-html-ignore \[list &\] [list $ignore]\]" html
    regsub -all -- {<[^>]*>} $html {} result
  return $result
    #set html [subst $html]
    #return $html
}

###
# topic: 79db6c79-37f3-538d-7a63-8b510f492f5f
# description: Looted from the Tcl'ers Wiki
###
proc ::ostring::strip-html-ignore {text {ignore {}}} {
    set c 0
    foreach i $ignore {if {[regexp $i $text]} {return $text}}
    return ""
}

###
# topic: e6d3a219-4a97-462b-b516-48022c7c242d
# description:
#    stem::tryrules
#    stem::tryrules_if_m
#    
#    try to match a set of rules of the form {lhs rhs} against a word
#    if lhs appears at the end of the word, replace it with rhs and return.
#    in the second form, we also check that the measure of the stem
#    is greater than the given n
# arguments:
#    word   -- a variable name to look in and modify
#    rules  -- one or more {lhs rhs} pairs
###
proc ::ostring::tryrules {wordvar rules} {
    
    upvar word $wordvar

    foreach rule $rules {
        foreach {lhs rhs} $rule {}
        if [regsub -- "$lhs\$" $word $rhs word] {
            return 
        }
    }
}

###
# topic: 6701f7a8-becb-06b9-a6dd-cd001c1ffeb5
###
proc ::ostring::tryrules_if_m {n wordvar rules} {
    
    upvar word $wordvar

    foreach rule $rules {
        foreach {lhs rhs} $rule {}
        if {[regexp "(.*)$lhs\$" $word => stem] && [measure $stem]>$n} {
            set word [join [list $stem $rhs] {}]
            return 
        }
    }
}

###
# topic: 1f242e57-763a-90e2-f692-6b7a1634fdf3
###
proc ::ostring::verify_ip host {
if { [string index $host end] == "." } {
    return 0
}
set ip [split $host .]
if { [llength $ip] != 4 } {
    return 0
}
foreach item $ip {
    if ![string is integer $item] {
    return 0
    }
    if { $item < 0 || $item > 255 } { 
    return 0
    }
}
return 1
}

###
# topic: 1431f5cd-7315-05f8-ee86-85c82a003634
###
namespace eval ::ostring {
    
    ###
    # Find and IP address in a line
    #
    # Pull out something that resembes and IP address from 
    # the string given. Blank on failure.
    ###

    
    ###
    # Find a MAC address in a line
    # Pull out something that resembes and mac address from 
    # the string given. Blank on failure.
    ###






    
    
    
    

###
# Porter Stemmer
#
# Initial version based on the Porter stemmer, in particular
# Steve Cassidy's Tcl implementation Copywrite 2001 under
# the Tcl license.
#
# Thanks Steve!
###

###
# Knuth Soundex lifted from:
#   This implementation of the Soundex algorithm is released to the public
#   domain: anyone may use it for any purpose.  See if I care.
#
#   N. Dean Pentcheff 1/13/89 Dept. of Zoology University of California Berkeley,
#     CA  94720 dean@violet.berkeley.edu
#   TCL port by Evan Rempel 2/10/98 Dept Comp Services University of Victoria.
#     erempel@uvic.ca
####
    variable cache
    array unset cache

    ###
    # Useful data tables
    ###
    variable contractions {
        {'M} { AM}
        {'RE} { ARE}
        {'S} { IS}
        {N'T} { NOT}
        {'D} { WOULD}
        {'VE} { HAVE}
        {'LL} { WILL}
    }
    
    variable soundexCodes {
         A 0 B 1 C 2 D 3 E 0 F 1 G 2 H 0 I 0 J 2 K 2 L 4 M 5
         N 5 O 0 P 1 Q 2 R 6 S 2 T 3 U 0 V 1 W 0 X 2 Y 0 Z 2
      }
    
    #variable cache
    # Hard coded rules
    #array set cache {
    #    BASICALLY   BASIC BLESS BLESS LESS LESS NOVELTY NOVEL
    #    NUMERICALLY NUMBER NUMERO NUMER
    #}
 
    # Words the system should NOT
    # try to stem any further
    variable rootWords {
        AGE BIO BASIC ACCUSE ACCURATE ACHIEVE CKNOWLEGE ACOUSTIC ACTIVE ADMIRAL ADMINISTER ADHERE ADDITION ALIAS ALLUDE ALLES 
    }
 
    variable stopWords [string toupper {
        COM DE EN 

        ABOUT ANOTHER
        A  AN THE
        AS AT BY 
        FOR FROM HOW
        IN  LA 
        OF ON OR 
        THE  TO  
         WHEN WHERE
         WILL WITH
        UND  WWW
	VE
        I WE ME MY MYSELF
        YOU YOUR YOURS YOURSELF YOURSELVES
        HE HIM HIS HIMSELF
        SHE HER HERS HERSELF
        IT ITS IT'S ITSELF
        THEY THEM THEIR THEIRS THEMSELVES
        WHAT WHICH WHO WHOM THIS THAT THESE THOSE
        THEY 
        AND NOT OR
        COULD OUGHT
        SHOULD WOULD
        HAVE
        AM IS ARE WAS WERE
        BE BEEN BEING
        DO DOES DID DOING
        HAVE HAS HAD HAVING

i'm
you're
he's
she's
it's
we're
they're
i've
you've
we've
they've
i'd
you'd
he'd
she'd
we'd
they'd
i'll
you'll
he'll
she'll
we'll
they'll

isn't
aren't
wasn't
weren't
hasn't
haven't
hadn't
doesn't
don't
didn't


won't
wouldn't
shan't
shouldn't
can't
cannot
couldn't
mustn't
       
let's
that's
who's
what's
here's
there's
when's
where's
why's
how's

and
but
if
or
because
as
until
while

of
at
by
for
with
about
against
between
into
through
during
before
after
above
below
to
from
up
down
in
out
on
off
over
under

again
further
then
once

here
there
when
where
why
how

all
any
both
each
few
more
most
other
some
such

no
nor
not
only
own
same
so
than
too
very


    }]
    
    ###
    # Added my own mapping that removes "ology" from
    # the end of a word

    variable steps {
        1a {
            {   SSES$ SS}
            {   IES$   I}
            {   SS$   SS}
            {   S$    {}}
        }
        1b {
                {AT ATE}
                {BL BLE}
                {IZ IZE}
                {IS ISE}
        }
        2.a {
            {ATELY     ATE}
            {LESSLY    LESS}
            {ICALLY    IAL }
	    {LOGICAL   {}   }
	    {LOGY      {}   }
        }
        2.b {
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
        3 {
            {ICATE IC}
            {ATIVE {}}
            {ALIZE AL}
            {ICITI IC}
            {ICAL  IC}
            {FUL   {}}
            {NESS  {}}
        }
        4 {
            {LOGICAL }
            {LOGY }
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
    }

    variable metaphonePatterns {
        (OUGH|IGH|A|E|I|O|U|Y) {}
        (GTH) G
        (TH|T|TT) T
        (SCH|SH|SS|S) S
        (GHN|GN|NN) N
        (CH|ZH|GH|X|J) X
        (PH|FF|F) F
        (CK|KK|K) K
        (GG|GH) G
        (LL|LH) L
        (MM|MN) M
        (DD|DH) D
        (ZZ|SZ) Z
        (WH|W) {}
        RR R
        H {}      
    }
    

    if 0 {
proc porter {word} {

    variable cache

    ## remove any nonword chars from word
    #regsub -all -- {\W} $word {} word

    ## uppercase the word
    #set word [string toupper $word]
        if { [string length $word] < 5 } {
            return [string trimright $word S]
        }
    
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
      if {[regexp {(.*)E$} $word => stem] && [measure $stem]>1} {
# 	 puts "Removing E from $word"
  	set word $stem
      }

    # (m=1 and not *o) E ->
     if {[regexp {(.*)E$} $word => stem] &&\
 	    [measure $stem]==1 &&\
 	    ![star_o $stem]} {
 	set word $stem
     }

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
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    #   proc Soundex( string )
    
    #   Given as argument: a character string. Returns: a static string, 4 characters long
    #   This string is the Soundex key for the argument string.
    #   Side effects and limitations:
    #   Does not clobber the string passed in as the argument. No limit on
    #   argument string length. Assumes a character set with continuously
    #   ascending and contiguous letters within each case and within the digits
    #   (e.g. this works for ASCII and bombs in EBCDIC. But then, most things
    #   do.). Reference: Adapted from Knuth, D.E. (1973) The art of computer
    #   programming; Volume 3: Sorting and searching.  Addison-Wesley Publishing
    #   Company: Reading, Mass. Page 392.
    #   Special cases: Leading or embedded spaces, numerals, or punctuation are squeezed
    #   out before encoding begins.
    #   Null strings or those with no encodable letters return the code 'Z000'.
    #   Test data from Knuth (1973):
    #   Euler   Gauss   Hilbert Knuth   Lloyd   Lukasiewicz
    #   E460    G200    H416    K530    L300    L222
        
        
     ## ********************************************************
     ##
     ## Name: metaphone.tcl
     ##
     ## Description:
     ## A better soundex type algorithm
     ##
     ## Usage:
     ##
     ## Comments:
     ## The idea here is not to match some existing standard.
     ##
     ## The idea *is* to try to reduce *english* to a sound
     ## based structure while preserving readability.
     ##
     ## This results in output that *can* be used for the same
     ## purpose as soundex.
     ##
     ## Example:
     ## % metaphone "the quick brown fox jumped over the lazy dog"
     ## t qk brn fx xmpd vr t lz dg
    




    
    
    

    namespace export *
}

