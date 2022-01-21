#!/bin/bash

VER="2.5"

# Requires Curl, NetCat, and IPMITool.
PackagesArray=('netcat' 'ipmitool')

# Set Server Arrays
ServerIPArray=()
ServerNameArray=()
ServerUserArray=()
ServerPassArray=()

# Set Script Update Strings
SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )
BRANCH="main"

# Script Update Function
self_update() {
  echo "2. Script Updates:"
  cd "$SCRIPTPATH"
  timeout 1s git fetch --quiet
  timeout 1s git diff --quiet --exit-code "origin/$BRANCH" "$SCRIPTFILE"
  [ $? -eq 1 ] && {
    echo "  ✗ Version: Mismatched."
    echo "2a. Fetching Update:"
    if [ -n "$(git status --porcelain)" ];  # opposite is -z
    then
      git stash push -m 'local changes stashed before self update' --quiet
    fi
    git pull --force --quiet
    git checkout $BRANCH --quiet
    git pull --force --quiet
    echo "  ✓ Update Complete. Running New Version. Standby..."
    sleep 3
    cd - > /dev/null                        # return to original working dir
    exec "$SCRIPTNAME" "${ARGS[@]}"

    # Now exit this old instance
    exit 1
    }
  echo "  ✓ Version: Current."
}

# Package Check/Install Function
packages() {
  echo "1. Requierd Packages:"
  install_pkgs=" "
  for keys in "${!PackagesArray[@]}"; do
    REQUIRED_PKG=${PackagesArray[$keys]}
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    if [ "" = "$PKG_OK" ]; then
      echo "  ✗ $REQUIRED_PKG: Not Found."
      install_pkgs+=" $REQUIRED_PKG"
    else
      echo "  ✓ $REQUIRED_PKG: Found."
    fi
  done
  if [ " " != "$install_pkgs" ]; then
  echo
  echo "1a. Installing Missing Packages:"
  echo
  #apt --dry-run install $install_pkgs #debug
  apt install -y $install_pkgs
  fi
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
clear
echo "=========================================="
echo " Dell PowerEdge R720xd Server Fan Control"
echo "   v$VER by DocDrydenn"
echo "=========================================="
echo

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

# Package Check
packages
echo
self_update
echo

# Load Arrays from CONF file
{ read -a ServerIPArray; read -a ServerNameArray; read -a ServerUserArray; read -a ServerPassArray; } <$SCRIPTPATH/svr_fans.conf

# Set FanControl & FanSpeed Strings
FanControl='raw 0x30 0x30 0x01 0x00'
FanSpeed='raw 0x30 0x30 0x02 0xff 0x'$( printf '%x\n' $1 )

# Let's Do It!
echo "3. Fan Control:"
for keys in "${!ServerNameArray[@]}"; do
  echo "  Checking for ${ServerNameArray[$keys]}"
  if nc -z -w 5 ${ServerIPArray[$keys]} 22 2>/dev/null; then
    echo "    ✓ ${ServerNameArray[$keys]} Found"
    echo ""
    echo "    Requesting ${ServerNameArray[$keys]} Fan Control..."
    if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U ${ServerUserArray[$keys]} -P ${ServerPassArray[$keys]} $FanControl; then
      echo "    ✓ Control Granted"
      echo ""
      echo "    Requesting Fans Set to "$1"%..."
      if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U ${ServerUserArray[$keys]} -P ${ServerPassArray[$keys]} $FanSpeed; then
        echo "    ✓ Fans Set to "$1"%"
      else
        echo "    ✗ Setting Fans to "$1"% Failed"
      fi
    else
      echo "    ✗ Fan Control Denied"
    fi
  else
    echo "    ✗ ${ServerNameArray[$keys]} Not Found"
  fi
  echo
done

echo "============================================"
echo " Dell PowerEdge R720xd Server Fan Control"
echo "============================================"
echo
exit 0
