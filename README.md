# svr_fans

Simple script to control Dell PowerEdge R720xd server fan speeds via their iDRAC using IPMITool commands.

Script will also work with the Dell PowerEdge R#10-series. (Note: Fanspeed control still works even though an error will be thrown. Just ignore the error.)

## Requirements:
This script checks for the below packages. If not found, it will attempt to install them via APT.
- IPMITools
- NetCat

Not checked or installed via script:
- Git (needed for the install and self-update process to work.)

## Install:
This script is self-updating. The self-update routine uses git commands to make the update.

`git clone https://github.com/DocDrydenn/svr_fans.git`

(Future update will allow the user to skip the self-update function... allowing the script to be "installed" and/or run from outside of a git clone.) 

## Usage:
```
./svr_fans.sh <h> ## /full/path/config.conf

    ##          FanSpeed Percentage (Required)
                (Number between 20 and 100)

    file        Config file path and name

    -h or h     Show this usage and exit.
```
 ## Config:
  
 - Line #1 - IP Address of iDRAC
 - Line #2 - ServerName (This can be whatever you want)
 - Line #3 - iDRAC User Name
 - Line #4 - iDRAC User Password
  
## Multiple Servers
  - Option 1 - Each server will be given the same fan speed:
  
    Add additional server info to each line of the config file (seperated by spaces). 
    (See example in `svr_fans_example.conf`)
  
  - Option 2 - Each server will be given a different fan speed:
  
    Just use multiple calls to the script using different config files and the desired fan speed.
    (Future update will allow individual server fan speeds to be added to the config file... making this easier to do.) 
  
## Screenshot:
![svr_fans](https://user-images.githubusercontent.com/48564375/150647817-9b99cb2d-cdda-42ee-96a7-36352ef674cd.png)

