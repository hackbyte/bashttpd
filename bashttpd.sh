#!/bin/bash
####################################################################################################
#
# bashttpd - Bourne-again Shell (based) Hypertext Transfer Protocol Daemon
#
# Crappy stuff to serve just one file like a real httpd would do.
# No user inputs (nothing to sanitize!), file (content) specified and preloaded at launch,
# So, keep it as small as possible. ;)
#
# inspired from:
# httpd as bashism via (german) /
# https://www.heise.de/newsticker/meldung/Webserver-als-Shell-Einzeiler-1936993.html
# logging() based loosely on echoerr() via http://stackoverflow.com/a/2990533
#
# No (cmdline) options, fsckit. ;)
#
# My versioning sheme is _really_ simple. I just use a timestamp according to
# ISO 8601:2004 / EN 28601:1992 using a 24hr day based on
# european central time or european central summer time
# (CET=UTC+1, CEST=UTC+2) because of:
# https://en.wikipedia.org/wiki/ISO_8601#General_principles
#
# take it or i don't care........ ;)
# Ah, version-number detail varies with needs, if i version more than one
# change a day, i may add a counter, or i may even specify versions via
# date down to hours/minutes/seconds/ticks on the host..
#
# but that rarely happens at all....
#
# For a single or just first release in any given time domain,
# only the changed parts may be included!
# Anything behind that will probably be omitted. ;)
#
# I just jerked that into the keyboard, i do not really maintain it, for now.
#
# Anyways, you can reach me at bashttpd at hackbyte dot de if you need to.
#
# CHANGELOG:
# version 20161216T10:30    Coming to existence in this universe.
#                           I serve, therefore i am.
#
# version 20161216T19:23    heh, o.k. it could be better.
#
# version 20161217          what the? it's getting bigger.
#                           but who cares? ;)
#
# version 20151218          o.k. fsckit, we even include a md5
#                           digest for the file we serve. ;)
#
# version 20161218T05:00    Sometimes, writing documentation is
#                           really chilling task...
#
# version 20161218T18:00    Now we even deliver an accurate MD5 digest. 8-)
#
# version 20161225          Fixed Loggingfoo into some 'usable state'
#                           Additionally, changed file to serve vars w/o reflecting changes
#                           to handle them that way.... fixed.
#
####################################################################################################
#
# 'user' configurable stuff
#
CFG_BASEDIR="/home/hackbyte/wpad/"
CFG_FILETOSERVE=${CFG_BASEDIR}"wpad.dat"
#CFG_FILETOSERVE="/home/hackbyte/bin/bashttpd.sh"
CFG_OURPORT=8080
 
# Please change _only_ these, according to your local machine....
THISHOSTS_NETCAT=$(which netcat)            # Which could/should be 'netcat' or
                                            # just 'nc'
NETCAT_OPTIONS="-c -l -p ${CFG_OURPORT}"    # Well well, you should know what
                                            # _you_ do....
#LOGTOSTDERR=1                               # Log to stderr? yes=1/no=0
####################################################################################################
#
# PLEASE do not touch anything below this, unless you know what you do...
# if so .. have fun. ;)
#
THISHOSTS_DATE=$(which date)            # Should not change at all
THISHOSTS_LOGGER=$(which logger)        # Should not change at all
THISHOSTS_STAT=$(which stat)            # Should not change at all
THISHOSTS_MD5SUM=$(which md5sum)        # Should not change at all
####################################################################################################
#
# Stuff i need for convenience or clearness of what we do...... ;)
#
OUR_FSCKING_NAME=$(basename ${0})       # cuz, you're free to name it what the
                                        # heck you want.... even if you have
                                        # an army of me running.... ;)
OUR_PID=${BASHPID}                      # want to be able to tell you my PID
OUR_LINEBREAK="\r\n"                    # do not even ask! ;)
#OUR_LOGCMD="${THISHOSTS_LOGGER} --stderr -t ${OUR_FSCKING_NAME}"
OUR_LOGCMD="${THISHOSTS_LOGGER} -t ${OUR_FSCKING_NAME}"
                                        # And finally, we wanna give you some clue who we are,
                                        # if we write something to the syslog(!).
####################################################################################################
#
# If you know any way we can handle that with bash _only_, please tell me. ;)
#
OUR_FILELENGTH="$(${THISHOSTS_STAT} -c %s ${CFG_FILETOSERVE})"
####################################################################################################
#
# we're using netcat, told ya?
#
OUR_NETCAT_CMD="${THISHOSTS_NETCAT} ${NETCAT_OPTIONS}"
#OUR_NETCAT_CMD="cat -"
####################################################################################################
# datefoo
MADATE() { printf "%s" "$($THISHOSTS_DATE '+%Y%m%dT%T.%N (%Z UTC%:::z)')"; }
MASHORTDATE() { printf "%s" "$($THISHOSTS_DATE '+%Y%m%dT%T (%Z UTC%:::z)')"; }
####################################################################################################
#
LOGFOO() {
    MAMSG="$(MADATE) pid:${OURPID} $*"
    printf "%s" "${MAMSG}" | $OUR_LOGCMD
    }
LOGSHORTFOO() {
    MAMSG="$(MASHORTDATE) pid:${OURPID} $*"
    printf "%s" "${MAMSG}" | $OUR_LOGCMD
    }
####################################################################################################
#
MAKE_MD5SUM() {
    MAKE_MD5SUMVAR=$(${THISHOSTS_MD5SUM} ${CFG_FILETOSERVE})
    echo -n "${MAKE_MD5SUMVAR:00:32}"
    }
####################################################################################################
#
MAKE_HEADER() {
    OUR_HEADERBUILD="" ## always clean up before use ;)
    OUR_HEADERBUILD="${OUR_HEADERBUILD}HTTP/1.1 200 OK${OUR_LINEBREAK}"
    #OUR_HEADERBUILD="${OUR_HEADERBUILD}Content-Type: application/x-ns-proxy-autoconfig${OUR_LINEBREAK}"
    OUR_HEADERBUILD="${OUR_HEADERBUILD}Content-Type: application/x-ns-proxy-autoconfig${OUR_LINEBREAK}"
    OUR_HEADERBUILD="${OUR_HEADERBUILD}Content-Length: ${OUR_FILELENGTH}${OUR_LINEBREAK}"
    OUR_HEADERBUILD="${OUR_HEADERBUILD}Content-MD5: $(MAKE_MD5SUM)${OUR_LINEBREAK}"
    OUR_HEADERBUILD="${OUR_HEADERBUILD}Connection: close${OUR_LINEBREAK}"
    #Content-Type: text/html; charset=ISO-8859-15
    #Cache-Control: no-cache
    OUR_HEADERBUILD="${OUR_HEADERBUILD}${OUR_LINEBREAK}"
    echo -n "${OUR_HEADERBUILD}"
    }
####################################################################################################
#
PUT_BODY() {
    echo -e "$(<${CFG_FILETOSERVE})"
    }
 
####################################################################################################
#
MAIN_LOOP() {
    while true ; do {
        #echo -en "${OUR_CONTENT}}" | ${OUR_NETCAT_CMD} 2>&1 >/dev/null
        echo -e "${1}" | ${OUR_NETCAT_CMD} 2>&1 | $OUR_LOGCMD
        LOGFOO "${CFG_FILETOSERVE} queried!"
        } ; done
}
 
####################################################################################################
#
# Well done, we're going to serve the steak...
#
$(LOGSHORTFOO "${OUR_FSCKING_NAME} started with ${CFG_FILETOSERVE} size ${OUR_FILELENGTH} bytes...")
MAIN_LOOP "$(MAKE_HEADER)$(PUT_BODY)"

