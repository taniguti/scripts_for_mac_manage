#!/bin/bash
# vim: set ts=4 sw=4 sts=0 ft=sh fenc=utf-8 ff=unix :

ksadmin="/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle/Contents/MacOS/ksadmin"
brand_path="/Library/Google/Google Chrome Brand.plist"
chrome_path="/Applications/Google Chrome.app"
chrome_info_plist="${chrome_path}/Contents/Info.plist"
ks_path="${chrome_path}/Contents/Frameworks/Google Chrome Framework.framework/Frameworks/KeystoneRegistration.framework/Versions/Current"
ks_payload="${ks_path}/Resources/Keystone.tbz"
install_script="${ks_path}/Helpers/ksinstall"
if [ ! -x "$install_script" ]; then
    install_script="${ks_path}/Resources/ksinstall.py"
fi

function shlogger() {
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

if [ ! -f "$chrome_info_plist" ]; then
    shlogger "Google Chrome is not installed. Nothing to do."
    exit 0
fi

chrome_update_url="$(/usr/libexec/PlistBuddy -c 'print KSUpdateURL' "$chrome_info_plist")"
chrome_version="$(/usr/libexec/PlistBuddy -c 'print KSVersion' "$chrome_info_plist")"
chrome_major_version="$(echo "$chrome_version" | /usr/bin/awk -F. '{print $1}')"
productid="$(/usr/libexec/PlistBuddy -c 'print KSProductID' "$chrome_info_plist")"

shlogger "Google Chrome version $chrome_version is installed."
if [ "$chrome_major_version" -lt 100 ]; then
    shlogger "Sorry. Update Google chrome version 100 or later prior to use me." 2
    exit 1
fi

if [ ! -f "$ks_payload" ]; then
    shlogger "Not found: $ks_payload" 2
    exit 1
fi

if [ ! -x "$install_script" ]; then
    shlogger "Not found: $install_script" 2
    exit 1
fi

if [ "$(whoami)" != root ]; then
    shlogger "Use me as root." 2
    exit 1
fi

shlogger "Install Keystone, $install_script --install $ks_payload --force ..."
if "$install_script" --install "$ks_payload" --force >/dev/null 2>&1; then
    shlogger "Keystone got installed"
else
    shlogger "Keystaone install got failed" 2
    exit 1
fi


shlogger "Register Chrome with Keystone"
if "$ksadmin" --register \
    --productid "$productid" \
    --version "$chrome_version" \
    --xcpath "$chrome_path" \
    --url "$chrome_update_url" \
    --tag-path "$chrome_info_plist" \
    --tag-key "KSChannelID" \
    --brand-path "$brand_path" \
    --brand-key "KSBrandID" \
    --version-path "$chrome_info_plist" \
    --version-key "KSVersion"; then
    shlogger "Got Registered"
    result=0
else
    shlogger "Failed to register"
    result=1
fi
exit "$result"
