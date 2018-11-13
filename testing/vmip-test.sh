#!/bin/sh

# A line to print all IP addresses associated with VM ID
# vim-cmd vmsvc/get.guest 95 2>/dev/null | grep -E ipAddress | awk '{print $3}' | grep  -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed '1d $d' | awk '{print NR, $1}' | sed 's/^/IP /'

# An attempt at outputting ipaddresses with some text prepended to each line and counted like so;
# IP Address 1 127.0.0.1
# IP Address 2 192.168.1.9
# IP Address 3 172.67.1.5
# IP Address 4 10.0.25.6

if [ -z "$*" ]; then 
	echo "This script outputs the Guest OS IP Address if VM Tools is running in the guest";
    echo "Usage: ./vmip.sh VMID";
else 
    VMID=$1;
    #VMIP=`vim-cmd vmsvc/get.summary "${VMID}" 2>/dev/null | grep -E ipAddress | awk '{print $3}' | sed -e 's/^"//' -e 's/"$//'`;
    VMIP=`vim-cmd vmsvc/get.guest "${VMID}" 2>/dev/null | grep -E ipAddress | awk '{print $3}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed '1d $d'`
    #VMIP2="${VMIP}" #`| awk '{print NR, $1}' | sed 's/^/IP Address /'`

    if [ -z $VMIP ]; then
        echo "Sorry, that VM ID doesn't exist.";
    else
        if [ $VMIP = "<unset>" ]; then
            echo "IP Address is Unavaliable";
        else
            awk '{print NR, $0}' | echo "${VMIP}"
            #echo "${VMIP}";
        fi
    fi
fi
exit