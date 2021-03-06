#!/bin/sh

#parameters: machine name (required), CPU (number of cores), RAM (memory size in MB), HDD Disk size (in GB), ISO (Location of ISO image, optional), DATASTORE (Name of datastore name), NETWORK (Name of Network)
#default params: CPU: 2, RAM: 1024, DISKSIZE: 10GB, ISO: 'predefined iso', DATASTORE: datastore, NETWORK: VM Network

phelp() {
	echo "Script for automatic Virtual Machine creation for ESX"
	echo "Usage: ./create.sh options: n <|c|i|r|s|d|e>"
	echo "Where n: Name of VM (required), c: Number of virtual CPUs, i: location of an ISO image, r: RAM size in MB, s: Disk size in GB, d: Datatore Name, e: Network Name"
	echo "Default values are: CPU: 2, RAM: 1024MB, HDD-SIZE: 10GB, DATASTORE: datastore, NETWORK: VM Network"
}

#Setting up some of the default variables
CPU=2
RAM=1024
SIZE=10
ISO="ubuntu-18.04-netboot-amd64-unattended.iso"
DATASTORE=datastore
NETWORK="VM Network"
FLAG=true
ERR=false

#Error checking will take place as well
#the NAME has to be filled out (i.e. the $NAME variable needs to exist)
#The CPU has to be an integer and it has to be between 1 and 32. Modify the if statement if you want to give more than 32 cores to your Virtual Machine, and also email me pls :)
#You need to assign more than 1 MB of ram, and of course RAM has to be an integer as well
#The HDD-size has to be an integer and has to be greater than 0.
#If the ISO parameter is added, we are checking for an actual .iso extension
while getopts n:c:i:r:s:d:e: option
do
        case $option in
                n)
					NAME=${OPTARG};
					FLAG=false;
					if [ -z $NAME ]; then
						ERR=true
						MSG="$MSG | Please make sure to enter a VM name."
					fi
					;;
                c)
					CPU=${OPTARG}
					if [ `echo "$CPU" | egrep "^-?[0-9]+$"` ]; then
						if [ "$CPU" -le "0" ] || [ "$CPU" -ge "32" ]; then
							ERR=true
							MSG="$MSG | The number of cores has to be between 1 and 32."
						fi
					else
						ERR=true
						MSG="$MSG | The CPU core number has to be an integer."
					fi
					;;
				i)
					ISO=${OPTARG}
					if [ ! `echo "$ISO" | egrep "^.*\.(iso)$"` ]; then
						ERR=true
						MSG="$MSG | The extension should be .iso"
					fi
					;;
                r)
					RAM=${OPTARG}
					if [ `echo "$RAM" | egrep "^-?[0-9]+$"` ]; then
						if [ "$RAM" -le "0" ]; then
							ERR=true
							MSG="$MSG | Please assign more than 1MB memory to the VM."
						fi
					else
						ERR=true
						MSG="$MSG | The RAM size has to be an integer."
					fi
					;;
                s)
					SIZE=${OPTARG}
					if [ `echo "$SIZE" | egrep "^-?[0-9]+$"` ]; then
						if [ "$SIZE" -le "0" ]; then
							ERR=true
							MSG="$MSG | Please assign more than 1GB for the HDD size."
						fi
					else
						ERR=true
						MSG="$MSG | The HDD size has to be an integer."
					fi
					;;
                d)
					DATASTORE=${OPTARG};
					;;
                e)
					NETWORK=${OPTARG};
					;;
				\?) echo "Unknown option: -$OPTARG" >&2; phelp; exit 1;;
        		:) echo "Missing option argument for -$OPTARG" >&2; phelp; exit 1;;
        		*) echo "Unimplimented option: -$OPTARG" >&2; phelp; exit 1;;
        esac
done

if $FLAG; then
	echo "You need to at least specify the name of the machine with the -n parameter."
	exit 1
fi

if $ERR; then
	echo $MSG
	exit 1
fi

if [ -d /vmfs/volumes/"$DATASTORE"/"$NAME" ]; then
	echo "Directory - /vmfs/volumes/$DATASTORE/${NAME} already exists, can't recreate it."
	exit
fi

if [ ! -d /vmfs/volumes/"$DATASTORE" ]; then
	echo "Datastore doesn't exist. Please check your default variable or specified -d parameter."
	exit
fi

#Creating the folder for the Virtual Machine
mkdir /vmfs/volumes/${DATASTORE}/${NAME}

#Creating the actual Virtual Disk file (the HDD) with vmkfstools
vmkfstools -c "${SIZE}"G -a lsilogic /vmfs/volumes/${DATASTORE}/$NAME/$NAME.vmdk

#Creating the config file
touch /vmfs/volumes/${DATASTORE}/$NAME/$NAME.vmx

#writing information into the configuration file
cat << EOF > /vmfs/volumes/${DATASTORE}/$NAME/$NAME.vmx

config.version = "8"
virtualHW.version = "13"
vmci0.present = "TRUE"
displayName = "${NAME}"
floppy0.present = "FALSE"
numvcpus = "${CPU}"
scsi0.present = "TRUE"
scsi0.sharedBus = "none"
scsi0.virtualDev = "lsilogic"
memsize = "${RAM}"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "${NAME}.vmdk"
scsi0:0.deviceType = "scsi-hardDisk"
ide1:0.present = "TRUE"
ide1:0.fileName = "${ISO}"
ide1:0.deviceType = "cdrom-image"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
ethernet0.pciSlotNumber = "32"
ethernet0.present = "TRUE"
ethernet0.virtualDev = "e1000"
ethernet0.networkName = "${NETWORK}"
ethernet0.generatedAddressOffset = "0"
guestOS = "ubuntu-64"
toolScripts.afterPowerOn = "TRUE"
toolScripts.afterResume = "TRUE"
toolScripts.beforeSuspend = "TRUE"
toolScripts.beforePowerOff = "TRUE"
tools.syncTime = "FALSE"
EOF

#Adding Virtual Machine to VM register - modify your path accordingly!!
MYVM=`vim-cmd solo/registervm /vmfs/volumes/${DATASTORE}/${NAME}/${NAME}.vmx`
#Powering up virtual machine:
vim-cmd vmsvc/power.on $MYVM

VMID=`vim-cmd vmsvc/getallvms | grep ${NAME} | awk '{print $1}'`

echo "The Virtual Machine is now setup & the VM has been started up. You have the following configuration:"
echo "VMID: ${VMID}"
echo "Name: ${NAME}"
echo "CPU: ${CPU}"
echo "RAM: ${RAM}"
echo "HDD-size: ${SIZE}"
if [ -n "$ISO" ]; then
	echo "ISO: ${ISO}"
else
	echo "No ISO added."
fi
echo "NETWORK: ${NETWORK}"
echo "Thank you."
exit
