#!/bin/sh
##############################################################################
#
# Purpose: Count ctrl characters in committed files and make sure we don't
#          commit files with ctrl characters.
#
# Programmer: Mark C. Miller
# Created:    April 30, 2008
#
# Modifications:
#
#   Mark Miller, Mon Jun 23 17:07:38 PDT 2008
#   Added docs/website to skip
#
#   Mark C. Miller, Tue Dec  9 00:19:04 PST 2008
#   Obtain list of changed files via FLIST ($3) argument and loop
#   over them via 'read' sh builtin method.
#
#   Mark C. Miller, Tue Dec  9 23:11:02 PST 2008
#   Re-factored a lot of skip logic to HandleCommonSkipCases. Adjusted
#   main file loop to account for fact that FLIST file now includes file
#   status chars as well as file name.
#
#   Kathleen Bonnell, Mon Jan 26 17:16:17 PST 2009
#   Added windowsbuild/ThirdParty to the skip list.
#
#   Tom Fogal, Sun Mar 22 16:10:25 MST 2009
#   I added a case for build_visit to be ignored.
#
#   Tom Fogal, Mon Jul 20 21:12:09 MDT 2009
#   Allow PNGs.
#
#   Tom Fogal, Sat Aug 22 16:25:07 MDT 2009
#   Allow `configure', it's autogenerated.
#
#   Kathleen Bonnell, Wed Nov 17 10:20:16 PST 2010
#   Added vendor_branches to skip list.
#
#   Cyrus Harrison, Fri Jan 14 10:48:50 PST 2011
#   Add docs to the skip list.
#
#   Brad Whitlock, Tue Jul 26 10:28:47 PDT 2011
#   Add releases to skip list.
#
#   Brad Whitlock, Fri May 18 17:15:34 PDT 2012
#   Add .rc and .in files to skip list.
#
#   Brad Whitlock, Wed Jun 13 13:57:01 PDT 2012
#   Skip for qtssh files.
#
##############################################################################
REPOS="$1"
TXN="$2"
FLIST="$3"

#
# Create a temp file containing the ctrl char(s) we wan't to grep for
#
ctrlCharFile=/tmp/visit_git_hook_ctrl_M_char_$$.txt
if test -n "$TMPDIR"; then
    ctrlCharFile=$TMPDIR/visit_git_hook_ctrl_M_char_$$.txt
fi
echo -e '\r' > $ctrlCharFile

#
# Iterate over the list of files
#
while read fline; do

    #
    # Get file status and name
    #
    fstat=`echo $fline | tr -s ' ' | cut -d' ' -f1` 
    fstat=${fstat:0:1}
    fname=`echo $fline | tr -s ' ' | cut -d' ' -f2` 

    #
    # Skip common cases of deletions, dirs, non-text files
    #
    if `HandleCommonSkipCases $fstat $fname`; then
        continue
    fi

    #
    # Filter out other cases HandleCommonSkipCases doesn't catch
    #
    case $fname in
        *.doc)
            continue
            ;;
        *.ini)
            continue
            ;;
        *src/third_party_builtin/*|*src/common/icons/*)
            continue
            ;;
        *src/exe/*|*src/bin/*|*src/archives/*|*src/help/*)
            continue
            ;;
        *src/java/images/*|*src/tools/mpeg_encode/*)
            continue
            ;;
        */tools/qtssh/*|*/tools/qtssh/windows/*)
            continue
            ;;
        *windowsbuild/*)
            continue
            ;;
        *.bat)
            continue
            ;;
        *.rc)
            continue
            ;;
        *.in)
            continue
            ;;
        *docs/WebSite/*)
            continue
            ;;
        *svn_bin/build_visit)
            continue
            ;;
        *svn_bin/bv_support/*)
            continue
            ;;
        *png)
            continue
            ;;
        *configure)
            continue
            ;;
        *docs/*)
            continue
            ;;
        *vendor_branches/*)
            continue
            ;;
        */releases/*)
            continue
            ;;
    esac

    #
    # Using svnlook to cat the file and examine it for ctrl chars.
    #
    git show :$fname | grep -q -f $ctrlCharFile 1>/dev/null 2>&1
    commitFileHasCtrlChars=$?

    # If the file we're committing has ctrl chars, reject it
    if test $commitFileHasCtrlChars -eq 0; then
        log "File \"$fname\" appears to contain '^M' characters, maybe from dos?."
        log "Please remove them before committing. Try using dos2unix tool."
        rm -f $ctrlCharFile
        exit 1
    fi

done < $FLIST

# clean up
rm -f $ctrlCharFile

# all is well!
exit 0