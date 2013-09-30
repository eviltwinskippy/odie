
::llama::tag did_you_know {} { 
  wiki {
    set dat [[community /sql] query_flat "select title,entry from community where class='dyk' order by rand() limit 1"]
    append result "<div class=callout>"
    append result "[topic {Did you know...}]<p>"
    append result "<b>[lindex $dat 0]</b><p>[subst [lindex $dat 1]]</p>"
    append result "</div>"
  }
}

::llama::tag linklist {title list} { 
  wiki {
    set r {}
    append r "<div class=callout><b>$title</b><br><table><tr>"
    set count 0
    foreach {type topica desca} $list {
       switch $type {
          url {
              append r "<td>[url $topica $desca]</td>"
          }
          topic {
              append r "<td>[topic $topica $desca]</td>"
          }
      }
      if { [incr count] % 3 == 0 } {
          append r "</tr><tr>"
      }	
    }
    append r </tr>
    append r </table>
    append r </div>
  return $r
  }
}

::llama::tag headlines {title list} {
  wiki {
    set r {}
    append r "<div class=callout><b>$title</b><br><table>"
    foreach {type headline link desc} $list {
      append r "<tr><td>$headline</td><td>[$type $link $desc]</td></tr>"
    }
    append r </table>
    append r </div>
    return $r 
  }
}

