package provide preen-words 1.0	

global leet_codes 
array set leet_codes {
	0	{a @ e # i 1 o 0 u U s $ t + ck X}
	1	{a 8 e 3 i 1 o 0 u u s 4 t 7}
}

###
# topic: 2064031b-5cbe-5b10-8d94-2b74576db628
###
proc ::random_password {} {
     set found 0
     set word [random_word]
     set flip [expr rand()]
     if  { $flip > 0.5 } { 
	set code 0
     } else {
	set code 1
     }
     foreach {letter replacement} $::leet_codes($code) {
	regsub -all $letter $word $replacement word
     }
     return $word     
}

###
# topic: c71c945a-fe40-6368-67da-c2f8b6c369f6
###
proc ::random_word {} {

     set dict /usr/share/dict/words
     set size [file size $dict]
     set count [expr int(rand() * $size)]
     set fin [open /usr/share/dict/words r]

     seek $fin $count
     # Feed in garbage to eol
     gets $fin word
     gets $fin word     

     close $fin
     return $word
}

