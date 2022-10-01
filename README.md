# svr_fans.sh

Simple script to control Dell PowerEdge R720xd server fan speeds via their iDRAC using IPMITool commands.

Script will also work with the Dell PowerEdge R#10-series. *(Note: Running this script on those servers will throw an error; just ignore it.)*

## Requirements

This script checks for the below packages. If not found, it will attempt to install them via APT.

- IPMITools
- NetCat

Not checked or installed via script:

- Git *(needed for the install and self-update process to work.)*

## Install

This script is self-updating. The self-update routine uses git commands to make the update so this script should be "installed" with the below command.

`git clone https://github.com/DocDrydenn/svr_fans.git`

**UPDATE: If you decide not to install via a git clone, you can still use this script, however, it will just skip the update check and continue on.**

## Usage

```bash
./svr_fans.sh <h> <##> /full/path/config.conf

    ##                      Global FanSpeed Percentage (Optional)
                            (Number between 20 and 100)
                            (This will over-ride any speeds set in CONF)'

    /full/path/config.conf  Config file path and name

    -h or h                 Show this usage and exit.
```

## Config

 *Note: Highly recommend putting your config file somewhere outside of the git clone folder. Self-Update will overwrite any changes you make to the example file.*
  
- Line #1 - IP Address of iDRAC
- Line #2 - ServerName (This can be whatever you want)
- Line #3 - iDRAC User Name
- Line #4 - iDRAC User Password
- Line #5 - FanSpeed Percentage
  
### Example Config (2 Servers)

```CONF
192.168.1.100 192.168.1.101
Server1 Server2
root root
12345 12345
50 50
```

## Screenshot

![svr_fans](https://user-images.githubusercontent.com/48564375/150647817-9b99cb2d-cdda-42ee-96a7-36352ef674cd.png)
