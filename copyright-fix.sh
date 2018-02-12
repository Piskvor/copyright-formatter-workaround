#!/usr/bin/env bash

# Depends on: xargs git grep tr wc sed
# Optional: parallel

set -uo pipefail

# shortest format possible; replaceable for non-git VCS?
STATUS_CMD="git status --porcelain=1"

# set up noop functions, to be overwritten from copyright-fix-hooks
function pre-copyright-fix () {
    true
}
function dir-copyright-fix () {
    true
}
function exclude-copyright-files() {
    true
}
function log-copyright-actions() {
    declare LOG_INPUT=${*:-$(</dev/stdin)}
    for PARAM in ${LOG_INPUT}; do
        echo -n ${PARAM}
    done
}
function post-copyright-fix() {
    true
}

CFH="$(realpath $(dirname $0))/copyright-fix-hooks"
if [ -e "$CFH" ]; then
    # load the hooks if exist - see below for the functions used
    source "$CFH"
fi
set -e


FILE=${1:-}
if [ "$FILE" = "" ] ; then

    RP=$(realpath $0)

    # use GNU Parallel if exists, else xargs
    XARGS=$(which parallel)
    XARGS_ARGS=""
    if [ ! -x "$XARGS" ]; then
        XARGS=xargs
        XARGS_ARGS="-n1"
    fi

    pre-copyright-fix
    # if we want to run in a specific directory, go there
    DIR=$(dir-copyright-fix)
    if [ "$DIR" != "" ] && [ -e "$DIR" ]; then
        cd "$DIR"
    fi

    IFS=" "
    # only check for changed PHP files
    FILES=$(${STATUS_CMD} | grep -E '\.php$' || true)
    if [ "$FILES" != '' ] ; then
        # check if we wish to exclude anything from the check (e.g. dev.php or whatnot)
        EXCLUDE_FILES=$(exclude-copyright-files || true)
        if [ "$EXCLUDE_FILES" != '' ] ; then
            FILES=$(echo ${FILES} | grep -Ev ${EXCLUDE_FILES} || true)
        fi
        # crude filter to exclude change status, name before a file was renamed, etc.
        FILES=$(echo ${FILES} | sed 's/.* //' || true)
    fi

    FILES_COUNT=$(echo ${FILES} | wc -w)
    if [ "$FILES_COUNT" -gt 0 ] ; then
        log-copyright-actions $(echo "© files: $FILES_COUNT ( $(echo ${FILES}) ) ")
        # check that only a single copyright block exists
        echo ${FILES} | $XARGS $XARGS_ARGS $RP --check-single &
        # remove the double asterisk at comment start
        echo ${FILES} | $XARGS $XARGS_ARGS $RP
        wait
    fi
else
    CHECK_SINGLE_COPYRIGHT=${1:-}
    if [ "$CHECK_SINGLE_COPYRIGHT" = "--check-single" ]; then
        FILE=${2:-"what"}
        grep -Hcr '@copyright' ${FILE} | grep -F '.php' | grep -Ev ':1' | sed 's/^/Problematic copyrights: /' >&2
    else
        TMPFILE_OLD=$(mktemp)
        TMPFILE_NEW=$(mktemp)
        # clean up after we're done
        trap "rm ${TMPFILE_NEW} ${TMPFILE_OLD} 2>/dev/null || true" INT EXIT
        # while we could operate on the actual file, in practice that sometimes truncates the file
        cp ${FILE} ${TMPFILE_OLD}
        OLD_HASH=$(sha1sum < ${FILE})
        # we assume that the copyright block is right at line 2 and LF ("UN*X-style") linebreaks
        tr '\n' '\r' < ${TMPFILE_OLD} | sed 's~<?php.\/\*\*\+~<?php\r/*~' | tr '\r' '\n' > ${TMPFILE_NEW} || true
        NEW_HASH=$(sha1sum < ${TMPFILE_NEW})
        if [ "$OLD_HASH" != "$NEW_HASH" ]; then
            if [ "$(wc -l < ${TMPFILE_NEW})" -lt 5 ]; then
                echo -e  "\e[91mBAD FIX: $FILE\e[0m"
                exit 4
            fi
            cp ${TMPFILE_NEW} ${FILE}
        fi
        if [ "$OLD_HASH" != "$NEW_HASH" ]; then
            log-copyright-actions $(echo ${FILE})
            post-copyright-fix ${FILE}
        fi
    fi
fi
