		      A Stemming Package for Tcl

	      by Steve Cassidy <Steve.Cassidy@mq.edu.au>
				   
This is an implementation of Porter's algorithm which is described in
the file porter.txt included with this extension.  This algorithm does
a reasonable job of guessing the stem or base form of a word using a
set of heuristic rules.   On tests with a list of 724 words taken from
the Brown corpus it makes 196 or 27% errors. Some of these aren't
really errors (the correct list I'm using is idiosyncratic) and some
are unavoidable because they're proper names or irregular words.  

The package exports three functions:

package require stem 1.0

stem::stem word          -- returns the stem of a word
stem::stem_text wordlist -- returns the stems of all words in the list
stem::stem_file in out   -- stems all words in the file writing the
                            results to the output file one word per line

stems are returned in upper case.

My implementation misses out two parts of Porter's rule 5 since they
don't seem to contribute anything and in fact give more errors. 

I also include two demonstration programs, stemfile.tcl takes two
arguments and calls stem::stem_file on them.  evaluate.tcl takes a word
list (like the one included in testwords.tcl) containing words and
their stems and evaluates the algorithm printing out errors and a final
tally of errors made.

See http://www.shlrc.mq.edu.au/~steve/tcl for updates.

Copyright (c) 2001, Steve Cassidy  <Steve.Cassidy@mq.edu.au>