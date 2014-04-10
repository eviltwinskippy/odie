#
# Library Routines for a Calendar System
#
package provide odie-calendar 1.1

package require calendar 0.2

::namespace eval ::calendar {}

###
# topic: 2574e95d-6de4-cac3-29e2-277515f5c726
# description:
#    Swiped from Practical Astronomy with your calculator
#    (Who swiped it from Nature, who swiped it from ...)
###
proc ::calendar::date_of_easter year {
	if { $year < 1583 } { 
	    return {}
	}
        set a [expr $year % 19]
        set b [expr $year / 100]
        set c [expr $year % 100]
        set d [expr $b / 4]
        set e [expr $b % 4]
        set f [expr ($b + 8) / 25]
        set g [expr ($b - $f + 1)/3]
        set h [expr (19 * $a + $b - $d - $g + 15) % 30]
        set i [expr $c / 4]
        set k [expr $c % 4]
        set l [expr (32 + 2 * $e + 2 * $i - $h - $k) % 7]
        set m [expr ($a + 11 * $h + 22 * $l) / 451]

	set month [expr ($h + $l - 7 * $m + 114)/31]
	# [3=March, 4=April]
	set p  [expr ($h + $l - 7 * $m + 114) % 31]
        #Easter Date=p+1     (date in Easter Month)
	set day [expr $p + 1]
	return [list $month $day]
    }

###
# topic: 42c62bc6-8f06-3251-2ebc-da22e733f5a4
###
proc ::calendar::date_to_days {{datestamp now}} {
return [gregorian_to_julian $datestamp]
}

###
# topic: 29eeaf34-eabb-9e39-b623-f8522fdd23b4
###
proc ::calendar::date_toint date {
return [gregorian_to_julian $date]
}

###
# topic: a3e2835c-a1c8-7201-432b-344686665db7
###
proc ::calendar::dateStamp {{time now}} {
    if { $time == "now" } {
       set time [clock seconds]
    } elseif ![string is integer $time] {
       set time [clock scan $time]
    }
    return [clock format $time -format "%Y-%m-%d %H:%M"]
}

###
# topic: d96aa468-6f6c-1761-4496-37686fdb9a91
###
proc ::calendar::detect_date rawstring {
	if { $rawstring == {} } {
	    return {}
	}

	if ![catch {clock scan $rawstring} time] {
	    return [clock format $time -format "%Y-%m-%d"]
	}

	if [string is integer rawstring] {
	    return [clock format $rawstring -format "%Y-%m-%d"]
	}
	
	###
	#  Detect date as YYYY/MM/DD or MM/DD/YYYY
	###
	regsub -all {\,} $rawstring " " rawstring 
	set result {}
	set era 0
	foreach item $rawstring {
	    if { [lsearch {bc bce b.c. b.c.e.} [string tolower $item]] >= 0 } { 
		set era 1
	    }
	    if [regexp / $item] {
		set result [detect_date_fixed [split $item /]]
	    }
	    if [regexp -- - $item] {
		set result [detect_date_fixed [split $item -]]
	    }
	}
	if { $result != {} } { 
	    if $era {
		return "bce $result"
	    }
	    return $result
	}
	return [detect_date_fixed $rawstring]
    }

###
# topic: 18787676-3815-bc63-f6ee-ac2d9ab5924a
###
proc ::calendar::detect_date_fixed datelist {

	set ydx {}
	set era   0
	set year  {}
	set month {}
        set day   {}
	set idx -1

	foreach item $datelist {
	    incr idx
	    if [string is integer $item] {
		if { [string length $item] == 4 } { 
		    set ydx $idx
		    set year $item
		} else {
		    if { $item > 31 } { 
			set ydx $idx
			set year $item
		    } elseif { $item > 12 && $item < 32 } {
			set ddx $idx
			set day $item
		    }
		}
	    } else {
		if { [set n [month_toint $item]] != {} } { 
		    set mdx $idx
		    set month $n	    
		}
		if { [lsearch {bc b.c. bce b.c.e} [string tolower $item]] >= 0 } {
		    set era 1
		}
	    }
	}

	if { $ydx == {} } { 
	    error "Could not detect a year in date."
	}

	if { $month == {} } {
	    if { $day == {} } {
		switch $ydx {
		    0 {
			set mdx   1
			set month [lindex $datelist 1]
			set day   [lindex $datelist 2]
		    }
		    2 { 
			set mdx   0
			set month [lindex $datelist 0]
			set day   [lindex $datelist 1]
		    }
		    default {
			error "Could not understand date"
		    }
		}
	    } else {
		set pos {0 1 2}
		# Eliminiate the year and day
		# Whatever is left is the month
		logicset remove pos $ddx
		logicset remove pos $ydx
		set month [lindex $datelist $pos]
	    }
	}

	if ![string is integer $month] {
	    set month [month_toint $month]
	}
	if { $month > 12 && $month < 1 } { 
	    error "Bad Month"
	}

	if { $day == {} } {
	    set pos {0 1 2}
	    logicset remove pos $mdx
	    logicset remove pos $ydx
	    set day [lindex $datelist $pos]
	}
	if $era {
	    return "bce $year-$month-$day"
	} else {
	    return "$year-$month-$day"
	}
    }

###
# topic: eec14747-b1cf-8180-492f-66d0e9361b28
# description: Returns time
###
proc ::calendar::detect_time rawstring {
	if { $rawstring == {} } {
	    return {}
	}

	if ![catch {clock scan $rawstring} time] {
	    return [clock format $time -format "%H:%M:%S"]
	}

	set fix  0
	set hour {}
	set min  {}
	set sec  {}
	set prev {}

	foreach item $rawstring {
	    if [regexp : $item] { 
		set time [split $item :]
		set hour [lindex $time 0]
		set min  [lindex $time 1]
		set sec  [lindex $time 2]
	    }
	    if {[lsearch {am a.m.} [string tolower $item]] >= 0} {
		set fix -12
	    }
	    if {[lsearch {pm p.m.} [string tolower $item]] >= 0} {
		set fix 12
	    }
	    if [regexp -nocase clock $item] {
		set hour $prev
		set min 0
		set sec 0
	    }
	    set prev $item
	}

	if { $hour == {} } { 
	    error "Could not understand time string: $time"
	}

	if { $hour < 12 && $fix > 0} { 
	    incr hour 12
	} elseif { $hour == 12 && $fix < 0 } { 
	    set hour 0
	}


	set hour [two_digit $hour]
	set min  [two_digit $min]
	set sec  [two_digit $sec]

	return [join [list $hour $min $sec] :]
    }

###
# topic: 51f79c49-3723-51c7-1fc0-8309579afd0c
###
proc ::calendar::display_gregorian date {
	variable month_names

	if [string is integer $date] {
	    set date [julian_to_gregorian $date]
	}
	set parts [split $date -]
	set month [lindex $parts 1]
	set month [string trimleft $month 0]
	set aliases $month_names($month)

	set month [lindex $aliases 0]
	set day   [lindex $parts 2]
	if { $day < 10 } { 
	    set day "0$day"
	}
	return [join [list \
	    [lindex $parts 0] \
	    $month \
	    $day] -]
    }

###
# topic: d3ef00e8-e71b-2384-8344-f5d7a2ee0fc9
###
proc ::calendar::display_gregorian_short date {
	variable month_names

	if [string is integer $date] {
	    set dow  [julian_dayOfWeek $date]
	    set date [julian_to_gregorian $date]
	} else {
	    set jdate [gregorian_to_julian $date]
	    set dow  [julian_dayOfWeek $jdate]
	}

	set parts [split $date -]
	set weekday [lindex {Sun Mon Tue Wed Thu Fri Sat Sun} $dow]

	set month [lindex $parts 1]
	set month [string trimleft $month 0]
	set aliases $month_names($month)

	set month [lindex $aliases 0]
	set day   [lindex $parts 2]
	if { $day < 10 } { 
	    set day "0$day"
	}
	return [join [list \
	    $weekday \
	    $month \
	    $day] -]
    }

###
# topic: 0e6f6f1e-ec6d-0bfc-8fbf-a6deb0bcfd3b
###
proc ::calendar::display_moon_phase phase {
return [lindex {
    {new moon}
    {waxing crescent} 
    {first quarter}
    {waxing gibbous}
    {full moon}
    {waning gibbous}
    {last quarter}
    {waning crescent}
} $phase]
}

###
# topic: 6c17a0dc-da05-14c1-6c0d-79509a4c7ca2
###
proc ::calendar::fix_octal args {
foreach v $args {
    upvar 1 $v $v
    set $v [string trimleft [set $v] 0]
    if { [set $v] == {} } { 
    set $v 0
    }
}
}

###
# topic: 7929fd54-c1cb-472e-74e6-0735f3ae526e
###
proc ::calendar::gregorian_to_julian date {

	if [string is integer $date] { 
	    return $date
	}

	set era CE
	set date [detect_date $date]
	if { [lindex $date 0] == "bce" } {
	    set era BCE
	    set date [lindex $date 1]
	}
        
	set parts [split $date -] 

	set y [lindex $parts 0]
	set m [lindex $parts 1]
	set d [lindex $parts 2]

	fix_octal y m d

	array set dateArray [list ERA $era YEAR $y MONTH $m DAY_OF_MONTH $d]
	return [::calendar::GregorianCalendar::EYMDToJulianDay dateArray]
    }

###
# topic: a43732f2-19f6-8605-12c5-c400d74bf003
###
proc ::calendar::int_toWeekday int {
variable days_long
return [lindex $days_long $int]
}

###
# topic: d882165d-15ed-33de-f268-18b24d0bf3ce
###
proc ::calendar::julian_dayOfWeek j {
return [expr { ( $j + 1 ) % 7 }]
}

###
# topic: a3df368d-dbd1-05ce-b4fe-3463fd987f56
###
proc ::calendar::julian_format {date {format %Y-%m-%d}} {
if ![string is integer $date] {
    set date [gregorian_to_julian $date]
}
return [julian_to_gregorian $date $format]
}

###
# topic: e7ca4af3-6fc7-d005-0e36-188b8f0c48fc
###
proc ::calendar::julian_to_gregorian {julianday {format %Y-%m-%d}} {
	variable months_short
	variable months_long
	variable days_short
	variable days_long

	calendar::GregorianCalendar::JulianDayToEYMWD $julianday calendar_day
	
	set result $format
	#
	# Direct Conversions from calendar_day array
	#
	
	# Synthesize the week number

	set calendar_day(WEEK_OF_YEAR) [expr $calendar_day(DAY_OF_YEAR) / 7]
	###
	#  Patterns with leading zereos
	###
	foreach {pattern value} {
	    %m	MONTH
	    %d	DAY_OF_MONTH
	} {
	    set dat $calendar_day($value)
	    if { $dat < 10 } { 
		set dat 0
		append dat $calendar_day($value)
	    }
	    regsub -all $pattern $result $dat result
	}
	
	foreach {pattern value} {
	    %Y	YEAR
	    %e	DAY_OF_MONTH
	    %j      DAY_OF_YEAR
	    %w	DAY_OF_WEEK
	    %U      WEEK_OF_YEAR
	} {
	    regsub -all $pattern $result $calendar_day($value) result
	}
	#
	# Conversion requiring a lookup in a list
	foreach {pattern list value} {
	    %b months_short MONTH
	    %B months_long  MONTH
	    %A days_long    DAY_OF_WEEK
	    %a days_short   DAY_OF_WEEK
	} {
	    regsub -all $pattern $result [lindex [get $list] $calendar_day($value)] result
	}

	if { $calendar_day(ERA) == "BCE" } {
	    set result [list bce $result]
	}
	return $result
    }

###
# topic: 3f76971d-57b4-d029-dc17-03ff96248eb6
###
proc ::calendar::julian_toyear jdate {
set date [julian_to_gregorian $jdate]
return [string range $date 0 3]
}

###
# topic: 04dce75f-7b9e-402a-02d7-6e83c02fceda
# description: Inputs
# returns: Day of the week (1-7)
###
proc ::calendar::month_endday {year month} {
set length [month_length $year $month]
set j [gregorian_to_julian $year-$month-$length]
return [julian_dayOfWeek $j]
}

###
# topic: a761f321-9fad-f32b-cbf6-6eddd024a2d5
# description: Inputsr
# returns: Length of month, in days
###
proc ::calendar::month_length {year month} {
	if { [year_isleap $year] } {
	    set month_length $::calendar::CommonCalendar::daysInMonthInLeapYear
	} else {
	    set month_length $::calendar::CommonCalendar::daysInMonth
	}
	set days [lindex $month_length [expr $month - 1]]

	return $days
    }

###
# topic: 87838d08-d3ab-4a0c-2e66-ce2b0aaf9154
# description: Inputs
# returns: Day of the week (1-7)
###
proc ::calendar::month_startday {year month} {
set j [gregorian_to_julian $year-$month-01]
return [julian_dayOfWeek $j]
}

###
# topic: 154e972a-05c8-3a70-8a31-510e8188b58d
###
proc ::calendar::month_toint month {
	variable month_names

	if [string is integer $month] {
	    return $month
	}

	foreach {mdx aliases} [array get month_names] {
	    if { [lsearch $aliases $month] >= 0 } { 
		return $mdx
	    }
	}
	return {}
    }

###
# topic: 5037315b-3ce3-6e90-53f7-a49ca373fbf9
###
proc ::calendar::month_tolong month {
	variable months_long
	if [string is integer $month] {	    
	    return [lindex $months_long $month]
	}

	foreach {mdx aliases} [array get month_names] {
	    if { [lsearch $aliases $month] >= 0 } { 
		return [lindex $months_long $mdx]
	    }
	}
	return {}
    }

###
# topic: cda83f6c-cbf5-3a26-4a72-a41e8f8f439b
###
proc ::calendar::month_toshort month {
	variable months_short
	if [string is integer $month] {	    
	    return [lindex $months_short $month]
	}

	foreach {mdx aliases} [array get month_names] {
	    if { [lsearch $aliases $month] >= 0 } { 
		return [lindex $months_short $mdx]
	    }
	}
	return {}
    }

###
# topic: bf254232-2742-4f76-3c6a-d8abf376decc
# description: Moon Phase
###
proc ::calendar::moon_phase julian_day {
set day [expr $julian_day -7].0
set moon_period 29.5305882
set quotient [expr int($day / $moon_period)]
set remainder [expr $day - ($moon_period * $quotient)]
return [expr int(8.0 * $remainder / $moon_period)]
}

###
# topic: 876eab34-84ad-f3ef-f31a-5addeb6212d5
# description:
#    Convert a time from HH::MM::SS
#    to number of seconds since midnight
###
proc ::calendar::time_toint string {
	if [string is integer $string] { 
	    return $string
	}

	set time [detect_time $string]
	set parts [split $time :]

	set hour  [string trimleft [lindex $parts 0] 0]
	if { $hour == {} } { 
	    set hour 0
	}
	set min  [string trimleft [lindex $parts 1] 0]
	if { $min == {} } { 
	    set min 0
	}
	set sec  [string trimleft [lindex $parts 2] 0]
	if { $sec == {} } { 
	    set sec 0
	}

	set result [expr $hour * 3600 + $min * 60 + $sec]
	return $result
    }

###
# topic: 0a552b03-cfe1-513f-cd3a-981e116c78b8
###
proc ::calendar::two_digit value {
if { $value == {} } { 
    return 00
}
if { $value < 10 } { 
    return 0${value}
}
return $value
}

###
# topic: b205238d-8368-f742-4755-20d4b59c26f3
# description:
#    Inputs
#    Year:2 Digit
###
proc ::calendar::year_4digit { year } {
if { $year > 40 } { 
    incr year 1900
} else {
    incr year 2000
}
return $year
}

###
# topic: 8119ea0b-3d18-95df-ae9c-30f419da61a2
# description: Inputs
# returns: 1 (true) 0 (false)
###
proc ::calendar::year_isleap { year } {
return [::calendar::GregorianCalendar::IsLeapYear $year]
}

###
# topic: eeec8d0b-8794-08ba-bbe6-ab1c1062b246
# description: Calculate the day of the week a year started on
###
proc ::calendar::year_start year {
set j [gregorian_to_julian $year-01-01]
return [julian_dayOfWeek $j]
}

###
# topic: 512f842b-0296-7212-6591-6ff5c1ebe0f8
###
namespace eval ::calendar {
    variable month_names 
    array set month_names {
	1 {Jan 01 January}
	2 {Feb 02 February}
	3 {Mar 03 March}
	4 {Apr 04 April}
	5 {May 05 May}
	6 {Jun 06 June}
	7 {Jul 07 July}
	8 {Aug 08 August}
	9 {Sep 09 September}
	10 {Oct 10 October}
	11 {Nov 11 November}
	12 {Dec 12 December}
    }

    variable days_long {Sunday Monday Tuesday Wednesday Thursday Friday Saturday}
    variable days_short {Sun Mon Tue Wed Thu Fri Sat}
    variable months_long {{} 
	January February March April May June 
	July August September October November December
    }
    variable months_short {{} 
	Jan Feb Mar Apr May Jun 
	Jul Aug Sep Oct Nov Dec
    }	
	




    
    
    
    
    
    













    ###
    #  Returns a date in YYYY-MM-DD form
    #
    #  Pull out something that resembes and date address from 
    #  the string given. Blank on failure. 
    #  
    #  Needed because clock only understands dates after 1970. 
    ###
    
}

