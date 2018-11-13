#!/bin/sh

# My script to extract the primary IP of a running VM from VM-Tools running inside the guest OS.
# Author: Michael SanAngelo (msanangelo@gmail.com)

if [ -z "$*" ]; then 
	echo "This script outputs the Guest OS IP Address if VM Tools is running in the guest";
    echo "Usage: ./vmip.sh VMID";
else 
    VMID=$1;
    VMIP=`vim-cmd vmsvc/get.summary "${VMID}" 2>/dev/null | grep -E ipAddress | awk '{print $3}' | sed -e 's/^"//' -e 's/"$//'`;

    if [ -z $VMIP ]; then
        echo "Sorry, that VM ID doesn't exist.";
    else
        if [ $VMIP = "<unset>" ]; then
            echo "IP Address is Unavaliable";
        else
            echo "IP Address = ${VMIP}";
        fi
    fi
fi
exit