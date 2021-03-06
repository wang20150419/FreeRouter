#!/bin/sh
#NS Lookup for domain listed in DomainList.txt
#And Generate Route add command for host
#Author:Bi Qin
#Website:http://www.lifetyper.com
#Version:X00 
#Date2014-05-20
set -x

DomainBulk=$1
CleanDNS="8.8.8.8"
TempScript="./temproute.sh"
DomainList="./Domains.txt"
AddMode="$2"

RouterName=$(nvram get router_name)

if [ $RouterName = "DD-WRT" ]
#DD-WRT Router
then
    VPNSRVSUB=$(nvram get pptpd_client_srvsub)
    PPTPDEV=$(route -n | grep ^${VPNSRVSUB%.[0-9]*} | awk '{print $NF}' | head -n 1)
    VPNGW=$(ifconfig $PPTPDEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
    FINAL_GW="gw ""$VPNGW"
    OutPutScript="/jffs/pptp/route.sh"
else
#OpenWRT Router
    VPNGW=$(ifconfig | grep "pptp" | sed -e "s#^\([^ ]*\) .*#\1#g")
    FINAL_GW="dev ""$VPNGW"
    OutPutScript="/autoddvpn/route.sh"
fi

if [ -f "$TempScript" ]
then
	rm "$TempScript"
fi

RouteDomain()
{
    echo "#Add for $Domain" >>$TempScript
    echo "$Domain" >>$DomainList
    nslookup $Domain $CleanDNS|grep "Address"|sed '1d'|\
    awk -F " " '{print $3'}|grep -v ":"|\
    sed -e "s#\(.*\)#\$1 -host \1 \$2#g"\
    >>$TempScript
}

for i in 1 2 3 4 5 6 7 8 9 10
do
	Domain=$(echo $DomainBulk|sed -e "s#\*#$i#g")
	RouteDomain $Domain
	chmod +x $TempScript
	/bin/sh $TempScript "route add" "$FINAL_GW" 
if [ $AddMode = "$2" ]
then
	cat $TempScript >> $OutPutScript
fi
done
exit 0
