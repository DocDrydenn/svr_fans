#!/bin/bash

# Requires NetCat and IPMITool to be installed.

# Set Server Arrays
declare -a ServerIPArray; ServerIPArray=('192.168.1.250' '192.168.1.251' '192.168.1.252')
declare -a ServerNameArray; ServerNameArray=('MasterServer' 'VMServer' 'BackupServer')
declare -a ServerUserArray; ServerUserArray=('root' 'root' 'root')
declare -a ServerPassArray; ServerPassArray=('14151415' '14151415' '14151415')

usage_example() {
  echo 'Usage: ./svr_fans.sh <h> ##'
  echo
  echo '    ##          FanSpeed Percentage (Required)'
  echo '                (Number between 20 and 100)'
  echo
  echo '    -h or h     Show this usage and exit.'
  echo
}

echo '=============================='
echo ' PowerEdge Server Fan Control'
echo '=============================='
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
