#
#
#

::namespace eval ::crash {}

###
# topic: 91940b46-1ec2-6a13-3445-f1a4b62752ac
###
proc ::crash::bug_report error {
	set body "
Session: [get ::session(session_id)]
Page: [::taourl::request_get referer]
User: [get ::session(username)] / [get ::session(userid)]
Error: $error

------------------------------------------
Stack Trace: 
"
        foreach line [split [get ::errorInfo] \n] {
            if [regexp DirectRespond $line] {
                # Don't get into the innerds of the webserver
                break
            }
            append body "$line\n"
        }
        append body "...(And into the server)...\n"
	sql::cmnd "insert into tfi.workorder_observations set
report_entity='840',
report_user='[get ::session(userid)]',
report_time=now(),
report_memo='WebSite Error',
report_body='[sql::fix $body]'"

    }

###
# topic: 0fdc079d-3602-1ad4-ef59-89743d2827dc
###
proc ::crash::root {} {
	variable home
	append result "<HTML><HEAD>Crash the Server</HEAD><BODY>
<H1>Deliberately Crash the Server</H1>
<LI><A HREF=$home/submit>Test Submission of Work Order</a>
<LI><A HREF=$home/crash>Generate an Internal error, then submit work order</a>"
	return $result
    }

###
# topic: 6beb4ea5-3ced-1294-4d4d-8eacd2907052
###
proc ::crash::root/crash {} { 
	set result "<HTML><HEAD></HEAD><BODY>"
	error "Your Mother was a Hampster and your father stank of ELDERBERRIES!"
    }

###
# topic: 7aaa479d-e16e-6fc4-662d-99b50069ff79
###
proc ::crash::root/submit {} { 
	set result "<HTML><HEAD></HEAD><BODY>"
	bug_report TEST
	append result "<H1>Only Kidding</H1>"
	append result "Bug added as [sql::last_insert_id]"
	append result "</BODY></HTML>"
    }

###
# topic: ea011ebe-6481-87fd-79d0-e1b663755c93
###
namespace eval ::crash {
variable home /crash
  ::httpd::dynamic_url /crash ::crash::root
}

