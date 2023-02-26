#!/bin/bash
# Script Name: shoWnics.sh
# Description: Script that shows information about active WNICs (network interface name, driver, type of bus, chipset).
#              Tested on Linux version 5.10.0-kali9-amd64.
# Usage: shoWnics.sh
# Author: CheerfulAnt@outlook.com
# Version: 1.0
# Date: 14 December 2021 - 20:00 (UTC+02:00)


NET_DEVICES_PATH='/sys/class/net'
PCI_IDS_PATH='/usr/share/misc/pci.ids'
USB_IDS_PATH='/var/lib/usbutils/usb.ids'

function device_info_get {

    awk -v vendor_id="^$vendor_id" -v device_id="$device_id" -v subvendor_subdevice="$subvendor_subdevice" \
        'BEGIN {vendor_found=0;} 
            $0 ~ vendor_id {vendor_found=1; $1=""; sub(/^[ \t]+/,""); vendor=$0} 
            {
                if (vendor_found==1 && $0 ~ subvendor_subdevice && subvendor_subdevice) 
                    {$1=$2=""; sub(/^[ \t]/,""); device=$0; vendor_found=0} 
                else if (vendor_found==1 && $1 == device_id && ! subvendor_subdevice)
                    {$1=""; sub(/^[ \t]+/,""); device=$0; vendor_found=0} 
            }
        END {
                print vendor " "  device              
            }'  $device_ids

    return $device_info
}

for dev_net in $(ls $NET_DEVICES_PATH); do
    
    for is_wireless in $(ls $NET_DEVICES_PATH/$dev_net); do
	if [ $is_wireless = 'wireless' ]; then
		dev_driver=$(basename $(readlink "$NET_DEVICES_PATH/$dev_net/device/driver"))
        dev_bus=$(readlink -f "$NET_DEVICES_PATH/$dev_net/device")
	        pci_usb_device=$(readlink  "$NET_DEVICES_PATH/$dev_net/device/driver" | awk -F"/" '{print $(NF-2)}')
            
            if [ $pci_usb_device = 'pci' ]; then 
                    device_ids=$PCI_IDS_PATH
                    vendor_id=$(cut -d'x' -f2 "$dev_bus/vendor")
                    device_id=$(cut -d'x' -f2 "$dev_bus/device")
                    subvendor_subdevice=$(cat "$dev_bus/uevent" | grep PCI_SUBSYS_ID | awk -F':' '{sub(/PCI_SUBSYS_ID=/,""); print $1 " " $2}')
                    
                    vendor_device=$(device_info_get)

                    subvendor_subdevice=''
                   
                elif [ $pci_usb_device = 'usb' ]; then
                   dev_info=$(echo $dev_bus | rev | cut -d'/' -f2- | rev)
                   vendor_id=$(cat "$dev_info/idVendor")
                   device_id=$(cat "$dev_info/idProduct")
                   device_ids=$USB_IDS_PATH
                   vendor_device=$(device_info_get) 
                
                else
                    echo 'No vendor or device file'
            fi

        printf "%-7s %-11s %-5s %s \n" "$dev_net" "$dev_driver" "$pci_usb_device" "$vendor_device" 

    fi	
    done	
done
