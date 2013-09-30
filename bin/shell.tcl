#!/bin/sh
# \
exec /usr/local/bin/wish8.5 "$0" ${1+"$@"}

source /opt/local/odie/init.tcl
package require tkcon
set ::tkcon::OPT(exec)  {}
::tkcon::Init
