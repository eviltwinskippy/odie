
package provide odie-ports 0.1
package require listutil 1.5

###
# Stub package that sets up Unix-Alikes to look in the
# operating system's as well as Active State's package manager
###

### More or Less Odie Universal
addAutoPath /opt/local/odie/lib
addAutoPath /opt/local/httpd/sites/common/lib

if { $::tcl_platform(platform) == "unix" } {
    addAutoPath /opt/local/lib
    addAutoPath /usr/local/lib
    addAutoPath /usr/lib
}
if { $::tcl_platform(os) == "Darwin" } {
    addAutoPath ~/Library/Application\ Support/ActiveState/Teapot/repository/package/macosx-universal/lib/
    addAutoPath ~/Library/Application\ Support/ActiveState/Teapot/repository/package/tcl/lib/
}

