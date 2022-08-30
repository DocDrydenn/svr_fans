#!/bin/bash

VER="2.9"

# Requires Curl, NetCat, and IPMITool.
PackagesArray=('netcat' 'ipmitool')

# Set Server Arrays
ServerIPArray=(); ServerNameArray=(); ServerUserArray=(); ServerPassArray=(); ServerFanspeedArray=()

# Set Script Update Strings
SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )
BRANCH="main"
USAGE=0
DEBUG=0
CONF=""
SPEED=0
USESPEEDARRAY=0

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
  echo "1. Required Packages:"
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
  echo 'Usage: ./svr_fans.sh <h> <##> /full/path/config.conf'
  echo
  echo '    ##                Global FanSpeed Percentage (Optional)'
  echo '                      (Number between 20 and 100)'
  echo '                  (This will over-ride any speeds set in CONF)'
  echo
  echo '    /path/file.ext    Config file path and name'
  echo
  echo '    -h or h           Show this usage and exit.'
  echo
  exit 0
}

# Flag Processing Function
flags() {

  # Check for HELP argument
    ([ "$1" = "h" ] || [ "$1" = "-h" ]) && usage_example
    ([ "$2" = "h" ] || [ "$2" = "-h" ]) && usage_example
    ([ "$3" = "h" ] || [ "$3" = "-h" ]) && usage_example

  echo "Validating CONF..."
  # Check for CONF argument
  if [[ -f ${1} ]]; then
    CONF=$1
  elif [[ -f ${2} ]]; then
    CONF=$2
  elif [[ -f ${3} ]]; then
    CONF=$3
  else
    echo "  Missing or Invalid CONF."
    echo
    usage_example
  fi
  
  # Load Arrays from CONF file
  { read -a ServerIPArray; read -a ServerNameArray; read -a ServerUserArray; read -a ServerPassArray; read -a ServerFanspeedArray; } <$CONF #$SCRIPTPATH/svr_fans.conf

  # Check for equal array element counts (skip FanspeedArray)
  if ! [[ "${#ServerIPArray[@]}|${#ServerNameArray[@]}|${#ServerUserArray[@]}|${#ServerPassArray[@]}" = "${#ServerIPArray[@]}|${#ServerIPArray[@]}|${#ServerIPArray[@]}|${#ServerIPArray[@]}" ]]; then
    echo "  CONF contents are Invalid."
    echo
    usage_example
  fi
  echo "  CONF appears valid."

echo "Validating Fan Speed(s)..."
  # Check for SPEED argument
  if [[ $1 =~ ^[0-9]+$ ]]; then
    SPEED=$1
  elif [[ $2 =~ ^[0-9]+$ ]]; then
    SPEED=$2
  elif [[ $3 =~ ^[0-9]+$ ]]; then
    SPEED=$3
  elif [[ ${#ServerFanspeedArray[@]} -gt 0 ]]; then
    USESPEEDARRAY=1
  else
    echo "  Missing or Invalid Fan Speed."
    echo
    usage_example
  fi 
  # Check for SPEED argument range
  if [ "$USESPEEDARRAY" -eq 0 ]; then
    if [ "$SPEED" -lt 20 ] || [ "$SPEED" -gt 100 ]; then
      echo '  Fan Speed Variable Out of Range.'
      echo
      usage_example
    fi
  fi
  if [ "$USESPEEDARRAY" -eq 1 ]; then
    echo "  CONF Fan Speeds appears valid."
  else
    echo "  Global Over-ride Fan Speed appears valid."
  fi
  echo
}

# Execute Script
clear
echo "=========================================="
echo " Dell PowerEdge R720xd Server Fan Control"
echo "   v$VER by DocDrydenn"
echo "=========================================="
echo

# Flag Check
flags $1 $2 $3

# Package Check
packages #Uncomment for Production
echo
self_update #Uncomment for Production
echo

# Set FanControl String
FanControl='raw 0x30 0x30 0x01 0x00'

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
      if [ "$USESPEEDARRAY" -eq 1 ]; then
        SPEED=${ServerFanspeedArray[$keys]}
      fi
      FanSpeed='raw 0x30 0x30 0x02 0xff 0x'$( printf '%x\n' $SPEED )
      echo "    Requesting Fans Set to "$SPEED"%..."
      if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U ${ServerUserArray[$keys]} -P ${ServerPassArray[$keys]} $FanSpeed; then
        echo "    ✓ Fans Set to "$SPEED"%"
      else
        echo "    ✗ Setting Fans to "$SPEED"% Failed"
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
