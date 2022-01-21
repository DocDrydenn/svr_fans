#!/bin/bash

VER="1.0"

# Requires Curl, NetCat, and IPMITool.
declare -a PackagesArray; PackagesArray=('netcat' 'ipmitool' 'mt-st')

# Set Server Arrays
declare -a ServerIPArray; ServerIPArray=('192.168.1.250' '192.168.1.251' '192.168.1.252')
declare -a ServerNameArray; ServerNameArray=('MasterServer' 'VMServer' 'BackupServer')
declare -a ServerUserArray; ServerUserArray=('root' 'root' 'root')
declare -a ServerPassArray; ServerPassArray=('14151415' '14151415' '14151415')

SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"             # get name of the file (not full path)
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )                                  # fixed to make array of args (see below)
BRANCH="main"

self_update() {
  echo "Checking for Online Updates..."
  cd "$SCRIPTPATH"
  git fetch
                                               #https://github.com/DocDrydenn/srv_fans/releases/latest"
  [ -n "$(git diff --name-only "origin/$BRANCH" "$SCRIPTFILE")" ] && {
    echo "Found a new version of me, updating myself..."
    git pull --force
    git checkout "$BRANCH"
    git pull --force
    echo "Running the new version..."
    cd -                                       # return to original working dir
    exec "$SCRIPTNAME" "${ARGS[@]}"

    # Now exit this old instance
    exit 1
  }
  echo "Already the latest version."
}

# Package Check/Install Function
packages() {
  echo "Required Packages:"
  install_pkgs=" "
  for keys in "${!PackagesArray[@]}"; do
    REQUIRED_PKG=${PackagesArray[$keys]}
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    if [ "" = "$PKG_OK" ]; then
      echo "Checking for $REQUIRED_PKG: Not Found."
      install_pkgs+=" $REQUIRED_PKG"
    else
      echo "Checking for $REQUIRED_PKG: Found."
    fi
  done
  echo "Installing Missing Packages:"
  apt --dry-run install $install_pkgs #debug
  #apt install -y $install_pkgs
}

# Usage Example Function
usage_example() {
  echo 'Usage: ./svr_fans.sh <h> ##'
  echo
  echo '    ##          FanSpeed Percentage (Required)'
  echo '                (Number between 20 and 100)'
  echo
  echo '    -h or h     Show this usage and exit.'
  echo
}

# Execute Script
echo '=============================='
echo ' PowerEdge Server Fan Control'
echo '=============================='
echo

# Package Check
packages
self_update

exit 0

# Check for Usage flag
if ([ "$1" = "-h" ] || [ "$1" = "h" ]); then
  usage_example
  exit 0
fi

# Check for valid FanSpeed variable
case "$1" in
    ("" | *[!0-9]*)
        echo 'Invalid FanSpeed Variable.'
	echo
	usage_example
        exit 1
esac
if [ "$1" -lt 20 ] || [ "$1" -gt 100 ]; then
    echo 'FanSpeed Variable Out of Range.'
    echo
    usage_example
    exit 1
fi

# Set FanControl & FanSpeed Strings
FanControl='raw 0x30 0x30 0x01 0x00'
FanSpeed='raw 0x30 0x30 0x02 0xff 0x'$( printf '%x\n' $1 )

# Do it!
for keys in "${!ServerNameArray[@]}"
    do
        echo "Checking for ${ServerNameArray[$keys]}"

        if nc -z -w 5 ${ServerIPArray[$keys]} 22 2>/dev/null; then
            echo " ✓ ${ServerNameArray[$keys]} Found"
            echo ""
            echo " Requesting ${ServerNameArray[$keys]} Fan Control..."
            if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U ${ServerUserArray[$keys]} -P ${ServerPassArray[$keys]} $FanControl; then
                echo " ✓ Control Granted"
                echo ""
                echo " Requesting Fans Set to "$1"%..."
                if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U ${ServerUserArray[$keys]} -P ${ServerPassArray[$keys]} $FanSpeed; then
                    echo " ✓ Fans Set to "$1"%"
                else
                    echo " ✗ Setting Fans to "$1"% Failed"
                fi
            else
                echo " ✗ Fan Control Denied"
            fi
        else
            echo " ✗ ${ServerNameArray[$keys]} Not Found"
        fi
        echo
   done

echo
echo '======================================='
echo ' PowerEdge Server Fan Control Complete'
echo '======================================='
echo
exit 0
