###
# Project Makefile tailored for Mac OSX
###
LOCAL_REPO=${HOME}/odie
SANDBOX=${LOCAL_REPO}/sandbox
DOWNLOAD=${LOCAL_REPO}/download
ODIEMIRRORURL=http://fossil.etoyoc.com/fossil

# Uncomment your platform of choice
include $(SANDBOX)/odie/odieConfig.sh.macosx
#include $(SANDBOX)/odie/odieConfig.sh.linux
#include $(SANDBOX)/odie/odieConfig.sh.unix
#include $(SANDBOX)/odie/odieConfig.sh.win

###
# Settings that are common (or commonly guessed) for all platforms
# and needed to build zipkits
###

TOADKIT=${LOCAL_REPO}/bin/toadkit_bare${EXE}
WISHKIT=${LOCAL_REPO}/bin/toadkit_bare${EXE}
TCLKIT=${LOCAL_REPO}/bin/tclkit_bare${EXE}
ZIPSETUP=${LOCAL_REPO}/bin/zzipsetupstub${EXE}
SHERPA=${LOCAL_REPO}/bin/sherpa${EXE}