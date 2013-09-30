###
#  ITS User Manager
###

::namespace eval ::admin {}

###
# topic: 219c4a64-70d4-c9e0-e7dd-5edbbcae132e
# description: ::community::addModule {Manage Users} /admin/users
###
proc ::admin::root_users {} { 
if [catch {::security::urlPrelim {} useradmin} page] {
    return $page
}
set objresult {
    <ul>
    <li><a href=users/create>Create New User</a></li>
    <li><a href=users/edit?mode=delete>Disable Active User</a></li>
    <li><a href=users/edit>Edit Active Users</a></li>
    </ul>
}
return [subst $page]
}

###
# topic: e453f50d-1887-b7ae-5838-c43cda8982b7
###
proc ::admin::root_users/create {} {
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}
	set ::page(title) "Create User"
	set objresult {
	    <form action=create/check method=post>
	    <table>
	    <tr><td>New Username:</td><td><input name=username size=16></td></tr>
	    <tr><td>Last Name:</td><td><input name=namelast size=32></td></tr>
	    <tr><td>First Name:</td><td><input name=namefirst size=32></td></tr>
	    <tr><td>Account Type:</td><td><select name=type>
<option value="emailonly">Email Only</option>
<option value="staff" selected>Full Time Staff</option>
</select>
</td></tr>
	    </table>
<input type=submit name=confirm value="Next">
	    </form>
	}
	return [subst $page]
    }

###
# topic: aea32812-d8a0-7583-7534-9173df69a762
###
proc ::admin::root_users/create/check {username namelast namefirst type confirm} {
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}

	set ::page(title) "Confirm Name"
	set objresult {}
	if { $confirm == "cancel" } {
	    Doc_Redirect /admin/users/create
	}
	if { $confirm == "continue" } {
	    return [root_users/create/confirmed $username $namelast $namefirst $type]
	}
	
	# Check if username is in use
	set rows [maildb query_flat "select uid,username,name_last,name_first from user where username='$username' or fka='$username'"]
	if { $rows != {} } { 
	    set objresult "Username $username already exists for user: [lindex $rows 2], [lindex $rows 3]"
	    append objresult "<p>[[::tao::Container users] nodeUrlLink [lindex $rows 0]]"
	    return [subst $page]
	}
	append objresult "
Please confirm the name and username are spelled correctly.
<p>
<table>
<tr><td>Username</td><td>$username</td></tr>
<tr><td>Last Name</td><td>$namelast</td></tr>
<tr><td>Name First</td><td>$namefirst</td></tr>
</table>
"

	set rows [maildb query_flat "select uid,username,fka,name_last,name_first from user where soundex(username)=soundex('$username') or
soundex(fka)=soundex('$username') or
fka like '%${namelast}%' 
or (soundex(name_last)=soundex('$namelast') and soundex(name_first)=soundex('$namefirst'))
or (soundex(name_last)=soundex('$namefirst') and soundex(name_first)=soundex('$namelast'))"]
	if { $rows != {} && $confirm != "continue" } { 
	    set objresult "The new user entered sounds similar ot the following 
accounts that already exist. Please confirm this is not a duplicate:
<p>
<table>
<tr><th>UID</th><th>Username</th><th>Former Uname</th><th>Last Name</th><th>First Name</th></tr>"
            set cobj [::tao::Container users]
	    foreach {ruid rusername rfka rname_last rname_first} $rows {
		append objresult "<tr><td>$ruid</td><td>$rusername</td><td>$rfka</td><td>$rname_last</td><td>$rname_first</td><td>[$cobj nodeUrlLink $ruid]</td></tr>"
	    }
	    append objresult "</table>"
	}
	append objresult "<form method=post action=check>
<input type=hidden name=username value=\"$username\">
<input type=hidden name=namelast value=\"$namelast\">
<input type=hidden name=namefirst value=\"$namefirst\">
<input type=submit name=confirm value=\"continue\">
<input type=submit name=confirm value=\"cancel\">
</form>"
	return [subst $page]
    }

###
# topic: 66dc80a8-3418-4fbd-0f39-7ec10520b190
###
proc ::admin::root_users/create/confirmed {username namelast namefirst type} { 
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}
        set passresult [exec /usr/odie/scripts/newpass]
        set password [lindex $passresult 1]
        set display 0
        set domain  0
        if { $type == "staff" } { 
           set display 1
           set domain 1
        }
        set stmt "insert into user set username='$username',name_last='$namelast',name_first='$namefirst',cleartext='[maildb sqlfix $password]',email='${username}@fi.edu',display=$display,domain_enable=$domain,name='$namefirst $namelast'"

        if { $username == "testuser" } {
           append stmt ",uid='2814'"
        }
        maildb cmnd $stmt

        set ::page(title) "User Created"
        append objresult "User $username has been created with the password:
<p>
<typewriter>$password</typewriter> (as in [lindex $passresult 0])
"

        if { $domain == 1 } { 
           append objresult "
<p>
The network login creation process is taking place in the background, and 
should be finished in a matter of minutes.
"
           exec ssh root@lachesis /usr/odie/scripts/pdc/adduser $uid $username $name_last $name_first $password &
       }
       append result "<p>
Edit user: [[::tao::Container users] nodeUrlLink [maildb query_flay "select uid from user where username='$username'"]]
"
       return [subst $page]
    }

###
# topic: 8ab77091-f10a-2948-a91f-ddaf4afd0af7
###
proc ::admin::root_users/delete uid { 
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}
        set ::page(title) "Delete/Disable User"
        append objresult "This action will disable access to the selected user account. 
It will optionally dispose of the files belonging to this user from the network and 
email system. You will also be asked how to redirect the email for this user."

        set objresult "Step 1: Confirmation"
        
 
    }

###
# topic: b5805a71-8b8d-0650-2bab-f71d6d6ce409
###
proc ::admin::root_users/edit mode {
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}
        if { $mode == "delete" } {
            set ::page(title) "Remove a user"
        } else {
	    set ::page(title) "Edit Userlist"
        }
        set colobj [[::tao::Container users] /column department]
	set objresult {
Enter either a username, part of the name, whatever you know.
<p>
If the system can't find the exact match it will check for soundalikes.
<p>
	    <form action=search method=get>

	    <table>
}
            append objresult "<input type=hidden name=mode value=${mode}>"
            append objresult {
	    <tr><td>Username:</td><td><input name=username size=16></td></tr>
            <tr><td colspan=2><hr></td></tr>
	    <tr><td>Last Name:</td><td><input name=namelast size=32></td></tr>
	    <tr><td>First Name:</td><td><input name=namefirst size=32></td></tr>
            <td><td colspan=2><hr></td></tr>
      	    <tr><td>Department:</td>
}
            append objresult "<td>[$colobj Entry {}]</td></tr>"
            append objresult {
	    </table>
<input type=submit name=confirm value="Next">
	    </form>
            }
        
  	return [subst $page]
    }

###
# topic: c2b4fdd5-85c8-fd82-1090-59c5f248308a
###
proc ::admin::root_users/search {username namelast namefirst department mode} {
	if [catch {::security::urlPrelim {} useradmin} page] {
	    return $page
	}
        set stmtl {}
        if { $username != {} } {
            lappend stmtl "(username like '%${username}%' or fka like '%${username}%)"
        }
       if { $namefirst != {} } {
            lappend stmtl "name_first like '%${namefirst}%'"
        }
        if { $namelast != {} } {
            lappend stmtl "(name_last like '%${namelast}%' or username like '%${namelast}%' or fka like '%${namelast}%')"
        }
        if { $department != {} } { 
            lappend stmtl "department=${department}"
        }
        set cobj [::tao::Container users]
        if { $mode == "delete" } { 
            set url /admin/users/delete?uid=
        } else {
            set url [$cobj ModuleUrl]?node=
        }
        if { $stmtl == {} } { 
            set objresult {<h1>No search criteria specified</h1>}
        } else {
            set rows [maildb query_flat "select uid,username,name_last,name_first,display,former_staff from user where [join $stmtl " AND "]"]
            if { $rows == {} } { 
               set objresult {<h1>No records matched search pattern</h1>}
            } else {
               append objresult {
<table>
<tr><th>UID</th><th>Username</th><th>Last Name</th><th>First Name</th><th>Status</th><th></th></tr>
}
               foreach {ruid rusername rname_last rname_first rdisplay rformerstaff} $rows {
set status ACTIVE
if { [string is false $rdisplay] } {
   set status HIDDEN
}
if { [string is true $rformerstaff] } {

    set status INACTIVE
}
append objresult "<tr><td>$ruid</td><td>$rusername</td><td>$rname_last</td><td>$status</td><td><a href=${url}${ruid}>Select</a></td></tr>"
}
append objresult \n "</table>"
            }
        }
	return [subst $page]
    }

#Direct_Url /admin/users ::admin::root_users 

