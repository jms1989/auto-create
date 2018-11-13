#!/bin/sh

# My script to check status of a running VM from VM-Tools running inside the guest OS.
# Author: Michael SanAngelo (msanangelo@gmail.com)

if [ -z "$*" ]; then 
	echo "This script checks if VM Tools is running in the guest";
    echo "Usage: ./toolstatus.sh VMID";
else 
    VMID=$1;
    TOOLS=`vim-cmd vmsvc/get.guest "${VMID}" 2>/dev/null | grep -E toolsStatus | awk '{print $3}' | sed -e 's/^"//' -e 's/",$//'`;

    if [ -z $TOOLS ]; then
        echo "Sorry, that VM ID doesn't exist.";
    else
        if [ $TOOLS = "toolsNotRunning" ]; then
            echo "VM is Not Ready";
        else
            echo "VM is Ready";
        fi
    fi
fi
exit