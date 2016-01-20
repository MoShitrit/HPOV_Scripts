#!/bin/ksh
#Script To Compare IP Address From OV Agent Configuration and actual IP Address
#Author: Moshe Shitrit
#Creation Date: May 9, 2013
#Revision Date: June 6, 2013

#Check The Operating System

OS=`uname`
RealNodeName=`hostname`

#Set the OV Path Variable According to OS

case "$OS" in
        SunOS|HP-UX|Linux)
                OVPATH=/opt/OV/bin
                        ;;
        AIX)
                OVPATH=/usr/lpp/OV/bin
                        ;;
esac

#Get IP Address Of Server, add it to a variable called "TrueIP"

TrueIP=`nslookup \$RealNodeName |grep Address |awk '{print $2}' |tail -1`

#Get IP Address From OV Configuration, add it to a varible called "OVIP"

OVIP=`$OVPATH/ovconfget |grep OPC_IP_ADDRESS |awk -F"=" '{print $2}'`

#Check the variables for errors:

if [ "$TrueIP" = "" ] ; then
        TrueIP=`grep \"$RealNodeName\" /etc/hosts |awk '{print $1}'`
fi

if [ "$OVIP" = "" ] ; then
        $OVPATH/ovconfchg -ns eaagt -set OPC_IP_ADDRESS $TrueIP
fi

OVIP=`$OVPATH/ovconfget |grep OPC_IP_ADDRESS |awk -F"=" '{print $2}'`

if [ "$OVIP" = "" ] ; then
        $OVPATH/opcmsg severity=Major a="OVO Agent" o="IP Configuration" msg_grp=OpC msg_t="IP Address Is NULL In OVO Agent Configuration! Node Name: $RealNodeName"
else
        if [ "$TrueIP" != "" ] && [ "$TrueIP" != "$OVIP" ] ; then
                $OVPATH/ovconfchg -ns eaagt -set OPC_IP_ADDRESS $TrueIP
        fi

        OVIP=`$OVPATH/ovconfget |grep OPC_IP_ADDRESS |awk -F"=" '{print $2}'`

        if [ "$TrueIP" != "" ] && [ "$TrueIP" != "$OVIP" ] ; then
                $OVPATH/opcmsg severity=Critical a="OVO Agent" o="IP Configuration" msg_grp=OpC msg_t="IP Address In OVO Agent Configuration Does Not Match Actual Node IP! Node Name: $RealNodeName"
        fi
fi
