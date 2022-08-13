#!/bin/bash

developerid='EQHXZ8M8AV'
dlurl='https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg'
dmgfile="$(/usr/bin/basename "$dlurl")"
workdir="$(/usr/bin/mktemp -d)"
dl_chrome_app="/Volumes/Google Chrome/Google Chrome.app"
CHROME="/Applications/Google Chrome.app"
notification=no

function checkapp() {
    #
    # Import form script-modules/bash_function_checkapp
    #
    local PathToApp DeveloperId IsSigned DEVID ROOTCA APPLEROOTCA TeamIdentifier
    PathToApp="$1"
    DeveloperId="$2"

    if [ -x "/usr/local/bin/santactl" ]; then
        santa_version="$(/usr/local/bin/santactl version | awk '$1 == "santad" {print $3}')"
        checker="/usr/local/bin/santactl version:$santa_version"
        santa_major_version="$(echo "$santa_version" | awk -F. '{print $1}')"
        # https://github.com/google/santa/releases/tag/2022.1
        # PR_no: 713
        if [ "$santa_major_version" -ge 2022 ]; then
            cert_index=0
        else
            cert_index=1
        fi
        IsSigned="$(/usr/local/bin/santactl fileinfo --key Code-signed "$PathToApp")"
        if [ "$IsSigned" != "Yes" ]; then
            echo "$PathToApp is not code-signed.($checker)"
            return 1
        fi

        DEVID="$(/usr/local/bin/santactl fileinfo --cert-index "$cert_index" --key "Organizational Unit" "$PathToApp")"
        if [ "$DEVID" != "$DeveloperId" ]; then
            echo "$PathToApp: Developer ID is $DEVID. But it must be $DeveloperId.($checker)"
            return 1
        fi

        ROOTCA="$(/usr/local/bin/santactl fileinfo --cert-index -1 --key SHA-256 "$PathToApp")"
        APPLEROOTCA="$(/usr/local/bin/santactl fileinfo --cert-index -1 --key SHA-256 /System/Library/CoreServices/Finder.app)"
        if [ "$ROOTCA" != "$APPLEROOTCA" ]; then
            echo "$PathToApp: ROOT CA of code-signing is not match.($checker)"
            return 1
        fi
    elif [ -x /usr/bin/codesign ]; then
        checker="/usr/bin/codesign"
        TeamIdentifier="$(/usr/bin/codesign --verify --verbose --display "$PathToApp" 2>&1 \
            | /usr/bin/awk -F= '$1 == "TeamIdentifier" {print $2}')"
        if [ "$TeamIdentifier" != "$DeveloperId" ]; then
            echo "$PathToApp: TeamIdentifier is $TeamIdentifier. But it must be $DeveloperId.($checker)"
            return 1
        fi
    else
        echo "No tool for ckeck $PathToApp here. Checking is abort."
        return 1
    fi

    echo "Application's code signing check is passed with ${checker}."
    return 0
}

function shlogger() {
    #
    # Import form script-modules/bash_function_shlogger
    #
    # `shlogger "your message"` then logging file and put it std-out.
    # `shlogger "your message" 2` then logging file and put it std-err.
    # Other than 2 is ignored.
    local logfile scriptname timestamp label mode
    logfile="/tmp/jamf-script.log"
    scriptname="$(/usr/bin/basename "$0")"
    timestamp="$(/bin/date "+%F %T")"
    mode="$2"
    case "${mode:-1}" in
        2)
            label="[error]"
            echo "$timestamp $scriptname $label $1" | /usr/bin/tee -a "$logfile" >&2
            ;;
        *)
            label="[info]"
            echo "$timestamp $scriptname $label $1" | /usr/bin/tee -a "$logfile"
            ;;
    esac
}

function show_notification() {
    # Usage:
    # show_notigication "notification title" "Notification message body"

    local subject msg cuser
    subject="$1"
    msg="$2"
    cuser="$(/usr/bin/stat -f %u /dev/console)"

    echo "tell application \"System Events\" to display notification \"$msg\" with title \"$subject\"" \
        | /bin/launchctl asuser "$cuser" /usr/bin/osascript -
}

if [ -e "$CHROME" ]; then
    installed_version="$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" "$CHROME/Contents/Info.plist")"
    current_stable_version="$(/usr/bin/curl --disable --silent https://omahaproxy.appspot.com/all | /usr/bin/awk -F, '/mac,stable/ {print $3}')"

    if [ -z "$current_stable_version" ]; then
        shlogger "Faild to get current stable version with curl" 2
        shlogger "Abort." 2
        exit 1
    fi

    if [ "$installed_version" = "$current_stable_version" ]; then
        shlogger "$CHROME is uptodate. The version is $current_stable_version"
        shlogger "Nothing to do."
        exit 0
    else
        shlogger "$CHROME is out of date. The version is ${installed_version}."
        shlogger "The latest stable version is ${current_stable_version}."
    fi
fi

shlogger "Start download dmg from $dlurl"
/usr/bin/curl --disable --silent --output "${workdir}/${dmgfile}" "$dlurl"
if [ ! -f "${workdir}/${dmgfile}" ]; then
    shlogger "Failed to download $dmgfile from $dlurl" 2
    shlogger "Abort" 2
    exit 1
fi

shlogger "Mount dmg file: $dmgfile"
devfile="$(/usr/bin/hdiutil attach -nobrowse "${workdir}/${dmgfile}" | /usr/bin/grep Chrome | /usr/bin/awk '{print $1}')"
if check_result="$(checkapp "$dl_chrome_app" "$developerid")"; then
    shlogger "$check_result"
    runstate="$(/usr/bin/pgrep Chrome | /usr/bin/wc -l)"
    shlogger "Chrome run state: $runstate"
    if [ "$runstate" -ne 0 ]; then notification=yes; fi
    if [ -d "$CHROME" ]; then
        tmpdir="/tmp/$(/usr/bin/uuidgen)"
        /bin/mkdir -m 755 "$tmpdir"
        /bin/mv "$CHROME" "$tmpdir"
    fi
    /bin/cp -af "$dl_chrome_app" /Applications
    shlogger "Install Chrome into /Applications"
    /usr/bin/xattr -r -d com.apple.quarantine "$CHROME"
    shlogger "Remove com.apple.quarantine from $CHROME"
    result=0
else
    shlogger "$check_result" 2
    shlogger "Codesign check failed." 2
    result=1
fi

/usr/bin/hdiutil detach -quiet "$devfile"
rm -rf "$workdir"

shlogger "Show notification: $notification"
if [ "$notification" = yes ]; then
    show_notification "Googole Chrome has updated!" "Restart Google Chrome now."
fi
shlogger "Done."

exit $result
