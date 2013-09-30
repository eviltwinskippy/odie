package provide vhost::dictionary 0.1

::namespace eval ::dictionary {}

###
# topic: 0ba078cf-0976-bee2-c1b5-a8d417fb881c
###
proc ::dictionary::root spell_check {
  
    append result "
    <html>
    <head><STYLE>
    <!--
    .bgred {background: red; color: white}
    -->
    </STYLE>
    <title>Spell-Checker</title>
    </head>
    <body>
    <!--- Focus the window in case it was open already, in which case any JavaScript opening the window wouldn't ordinarily bring the window to the front again. --->
    <script>self.focus()</script>
    <font face=\"Arial, Verdana, Helvetica\" size=2>
    <a href=\"javascript: self.close()\">Close Spell-Checker</a>
    <BR><BR>
    "
  
    foreach word $spell_check {
      regsub -all "::RET::" $word " <BR>" word
      
      foreach wrd $word {
        if {[spell_check $wrd]} { append result "$wrd "
        } else { 
          append result "<a href=\"http://www.dictionary.com/search?q=$wrd\" target=_new><font class=\"bgred\">$wrd</font></a> " 
        }
      }
    }		
    return $result
  }

###
# topic: 42602bd6-c48d-2ecb-5936-09a13c036c96
###
proc ::dictionary::spell_check word {
    regsub -all {<BR>} $word {} word
    regsub -all {[^a-zA-Z\-]} $word {} word
    if {![regexp {[a-zA-Z]} $word]} { return 1 }
  
    # Hyphenated words should be split into individual words. If a single word is
    # invalid, 0 will be returned for the entire word. If there aren't any hyphens,
    # [split $word -] will return the original word anyway, so normal words don't
    # need to be handled any differently.
  
    foreach subword [split $word -] {
      set answer {}
      set stmt "select word from tfi.dictionary where word = '$subword'"
      set answer [sql::query $stmt]
      if {$answer == {}} { return 0 }
    }
  
    # If the procedure hasn't returned 0 by now, the word is valid, and 1 can be 
    # returned.
    return 1
  
  }

###
# topic: e06c0ab5-fc3b-ed42-ac34-f6f6f3bb0704
# description: Dictionary/spell-check tools
###
namespace eval ::dictionary {
# Accepts data which is checked word-by-word for words that are not contained in tfi.dictionary
  # Currently links bad words to dictionary.com, but in the future the script should get the HTML
  # output from dictionary.com and strip out everything except for the spelling suggestions.
  # Generates HTML code intended for a pop-up window.

  # Accepts a single word and checks for its existence in tfi.dictionary. Returns 1 if
  # word is valid, 0 if not. Can be used as all-purpose spell-check in other scripts.
  # The procedure also strips out all characters other than alphanumeric and -, and 
  # returns 1 automatically if the word contains no letters (i.e. is a number)
}

# Links /apps/dictionary on website to root procedure so that scripts link to spell-checker with 
# Javascript -- e.g. a link with an onClick action that pulls the value from a textarea box and
# generates a pop-up window to load /apps/dictionary with the textarea's contents as an argument.
#
# Note that newlines in a textarea should be replaced in the Javascript with ::RET::  -- I 
# couldn't think of a better way of doing it. There is probably a much better way of doing it, as
# the way I'm doing it now also produces an ugly CSS-based artifact. An invalid word that  
# immediately follows a blank newline will turn the newline (a block-shape at the beginning of the
# blank line) red too.

::httpd::dynamic_url /apps/dictionary ::dictionary::root

