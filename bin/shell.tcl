#!/bin/sh
# \
exec wish "$0" ${1+"$@"}

source /opt/local/odie/init.tcl
package require tkcon
set ::tkcon::OPT(exec)  {}
::tkcon::Init
