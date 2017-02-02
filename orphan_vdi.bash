#!/bin/bash

# script to list and optionally delete orphan VDIs
#
# Usage:
# orphan_vdi.bash [-x] <-s SR_UUID>
# You can obtain your storage repo UUID via:
# xe sr-list

# Logic:
# We assume that a VDI is orphan if no VM claims it.
#
# First print all VDIs managed by us:
# xe vdi-list
# Then, for each VDI, check if a VBD corresponds to it.
# xe vbd-list vdi-uuid=$vdi
#
# Glossary:
# VDI: Virtual Disk Image, a piece of storage repository given to a VM. Can be in many formats.
# 	Think of it as a virtual hard disk, stored as a flat file.
# VBD: Virtual Block Device, describes a VDI so that it can be plugged to a VM.
# 	Think of it as a mapping or connector between a VDI and a VM.
#	In XenCenter, see Storage tab within a VM.

function vdis_processor () {	
	if [ $# -ne 2 ] ; then
		echo "bad number of args to vdis_processor"
		return
	fi
	sr_uuid=$1
	do_delete=$2
	echo "vdis_processor: sr_uuid: $sr_uuid, do_delete: $do_delete"
	vdis=`xe vdi-list sr-uuid=$sr_uuid params=uuid managed=true --minimal`

	for vdi in `echo $vdis | tr ',' ' '` ; do
		vm_name=`xe vbd-list vdi-uuid=$vdi params=vm-name-label | grep vm | awk '{ print $NF }'`
		if [ $do_delete == 1 ] ; then
			if [ "$vm_name" == "" ] ; then
				echo -e "DO_DEL\t$vdi"
				xe vdi-destroy uuid=$vdi
			else
				echo -e "OK\t$vdi\t$vm_name"
			fi
		else
			if [ "$vm_name" == "" ] ; then
				echo -e "DEL\t$vdi"
			else
				echo -e "OK\t$vdi\t$vm_name"
			fi
		fi
	done
}

do_delete=0
while getopts ":xs:" opt; do
	case $opt in
	x)
		do_delete=1
		;;
	s)
		sr_uuid=$OPTARG
		;;
	esac
done

echo "args: sr_uuid: $sr_uuid, do_delete: $do_delete"
vdis_processor $sr_uuid $do_delete

