#!/bin/bash

# crude script to show unused/duplicated C macros
# uses cscope for symbol search
# deepaknag 10/4/13

function scream ()
{
    echo "########################################################################"
    echo $1
    echo "########################################################################"
}

function usage ()
{
    echo "usage: $0 [-r] [-m <hdr_dir>] [-s <src_dir>]"
    echo -e "\t-r rebuilds cscopedb in <src_dir>"
    echo -e "\t-m, -s default to curdir"
    exit 1
}

while getopts ":m:s:r" o; do
    case "${o}" in
	m)
	    MDIR=${OPTARG}
	    ;;
	s)
	    SDIR=${OPTARG}
	    ;;
	r)
	    REBUILD_DB=1
	    ;;
	*)
	    usage
	    ;;
    esac
done

if [ -z $MDIR ] ; then
    MDIR=.
fi
if [ -z $SDIR ] ; then
    SDIR=.
fi

echo "headers dir set to $MDIR"
echo "sources dir set to $SDIR"

if [ ! -z $REBUILD_DB ] ; then
    echo "rebuilding cscope database"
    ( cd $SDIR &&  find . -name "*.[h|c]" > cscope.files ; cscope -b -k )
fi

echo "looking for #defines in C/h files under $MDIR"
MLIST=`find $MDIR -name "*.[c|h]" -exec grep "#define" {} \; | awk '{ print $2 }' | cut -d"(" -f1 | sort`

scream "printing duplicate macros:"
echo $MLIST | tr ' ' '\n' | uniq -d
echo "done!"

echo "building source file list"
FLIST=`find $SDIR -name "*.[c|h]"`

MLIST_U=`echo $MLIST | tr ' ' '\n' | uniq`

scream "printing unused $MDIR macros under $SDIR:"
for m in $MLIST_U ; do
    # the 4 below comes from "field number"
    # see: http://stackoverflow.com/questions/14915971/cscope-how-to-use-cscope-to-search-for-a-symbol-using-command-line
    nhits=`cscope -d -P$SDIR -f$SDIR/cscope.out -L4$m | wc -l`
    count=`expr 0 + $nhits`
    if [ $count -eq 1 ] ; then
	echo "$m"
    fi
done
echo "done!"
