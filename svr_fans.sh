#!/bin/bash

# Requires NetCat to be installed.


# Set UserName & Password
user="root"
pass="14151415"

# Set Server Name & IP Arrays
declare -a ServerIPArray
ServerNameArray=('MasterServer' 'VMServer' 'BackupServer')
ServerIPArray=('192.168.1.250' '192.168.1.251' '192.168.1.252')

# Set FanSpeed String
#     20% raw 0x30 0x30 0x02 0xff 0x14
#     30% raw 0x30 0x30 0x02 0xff 0x1E
#     40% raw 0x30 0x30 0x02 0xff 0x28
FanSpeed='raw 0x30 0x30 0x02 0xff 0x28'

echo "===================="
echo " Server Fan Control"
echo "===================="
echo ""

for keys in "${!ServerNameArray[@]}"
    do
        echo "Checking for ${ServerNameArray[$keys]}"

        if nc -z -w 5 ${ServerIPArray[$keys]} 22 2>/dev/null; then
            echo " ✓ ${ServerNameArray[$keys]} Found"
            echo ""
            echo " Requesting ${ServerNameArray[$keys]} Fan Control..."
            if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U $user -P $pass raw 0x30 0x30 0x01 0x00; then
                echo " ✓ Control Granted"
                echo ""
                echo " Requesting Fans Set to 40%..."
                if ipmitool -I lanplus -H ${ServerIPArray[$keys]} -U $user -P $pass $FanSpeed; then
                    echo " ✓ Fans Set to 40%"
                else
                    echo " ✗ Setting Fans to 40% Failed"
                fi
            else
                echo " ✗ Fan Control Denied"
            fi
        else
            echo " ✗ ${ServerNameArray[$keys]} Not Found"
        fi
        echo ""
   done

echo ""
echo "============================="
echo " Server Fan Control Complete"
echo "============================="
echo ""
exit 0
