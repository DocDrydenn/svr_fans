# svr_fans.sh

Simple script to control Dell PowerEdge R720xd server fan speeds via their iDRAC using IPMITool commands.

Script will also work with the Dell PowerEdge R#10-series. *(Note: Running this script on those servers will throw an error; just ignore it.)*

## Requirements:
This script checks for the below packages. If not found, it will attempt to install them via APT.
- IPMITools
- NetCat

Not checked or installed via script:
- Git *(needed for the install and self-update process to work.)*

## Install:
This script is self-updating. The self-update routine uses git commands to make the update.

`git clone https://github.com/DocDrydenn/svr_fans.git`

*(Future update will allow the user to skip the self-update function... allowing the script to be "installed" and/or run from outside of a git clone.)*

## Usage:
```
./svr_fans.sh <h> <##> /full/path/config.conf

    ##              Global FanSpeed Percentage (Optional)
                    (Number between 20 and 100)
                    (This will over-ride any speeds set in CONF)'

    /path/file.ext  Config file path and name

    -h or h         Show this usage and exit.
```
 ## Config:
 *Note: Highly recommend putting your config file somewhere outside of the git clone folder. Self-Update will overwrite any changes you make to the example file.*
  
 - Line #1 - IP Address of iDRAC
 - Line #2 - ServerName (This can be whatever you want)
 - Line #3 - iDRAC User Name
 - Line #4 - iDRAC User Password
 - Line #5 - FanSpeed Percentage
  
### Example Config (2 Servers)
```
192.168.1.100 192.168.1.101
Server1 Server2
root root
12345 12345
50 50
```

## Screenshot:
![svr_fans](https://user-images.githubusercontent.com/48564375/150647817-9b99cb2d-cdda-42ee-96a7-36352ef674cd.png)

