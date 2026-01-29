#!/bin/bash
check_host=$(hostname | cut -c -3)
[ "$check_host" != "ela" ] && echo "ERROR: you need to run this on ela (not daint or other)!" && exit

echo "Running \"quota\""
myquota=$(quota)

projects=$(groups)
for project in $projects;do
	nh_total=0
	echo
	goto="daint"
	conversion="17280"
	conv_eiger="15360"
	[ "$project" == "sd25" ] && goto="eiger" && conversion=$conv_eiger
	[ "$project" == "sd37" ] && goto="eiger" && conversion=$conv_eiger
	[ "$project" == "sd39" ] && goto="eiger" && conversion=$conv_eiger
	storage_quota=$(echo "$myquota" | grep "$project" | awk '{print $12}')
	used_quota=$(echo "$myquota" | grep "$project" | awk '{print $6}')
	# usernames_all=$(getent group "$project")  # unused, kept for reference
	#echo "project: $project" # $usernames_all" # sd28
	usernames=$(getent group "$project" | sed 's|.*:||' | sed 's|aglensk||' | sed 's|aradocea||' | sed 's|sarni||' | sed 's|asimard||' | sed 's|,| |g' | tr -s " " | awk '{$1=$1;print}' | awk '{$1=$1;print}') # e.g. aglensk
	echo "project: $project usernames: $usernames ($goto $conversion)" 
        usage=$(ssh $goto sreport cluster AccountUtilizationByDay Accounts="$project" start=2025-01-01)
    	#echo "-- begin"
        #echo "$usage"
    	#echo "-- fin"
	for username in ${usernames//,/ };do
	   if [ "$username" == "aglensk" ] || [ "$username" == "aradocea" ] || [ "$username" == "asimard" ] || [ "$username" == "sarni" ];then
		:
	   else
		len=${#username}
		x=$(echo 15 "$len" | awk '{print $1-$2}')
		username_out=$(printf "%*s%s" "$x" '' "$username")
	        fullname=$(getent passwd "$username" | sed 's|:/users.*||' | sed 's|.*:||')
	        #echo "  $username $fullname"
		# idu=$(id "$username")  # unused, kept for debugging
                usage_user=$(echo "$usage" | grep "$username" | awk '{print $6}')
		[ "$usage_user" == "" ] && usage_user=0 
		if [ "$usage_user" != "0" ];then
			usage_node_hours=$(echo "$usage_user" $conversion | awk '{print $1/$2}'  | awk '{ printf "%d\n", $1+0.5; }')
        		usage_user=$usage_node_hours
		fi
		nh_total=$(echo "$nh_total" "$usage_user" | awk '{print $1+$2}')
		len0=${#usage_user}
		x=$(echo 15 "$len0" | awk '{print $1-$2}')
		usage_user_out=$(printf "%*s%s" "$x" '' "$usage_user")
		echo "project: $project username : $username_out $usage_user_out nh >> $fullname" # >> $idu"
           fi
	done
	echo "-----------------------------------------------------------------------"
	echo "project: $project TOTAL    :                             $nh_total nh"
	echo "project: $project TOTAL    :                             $used_quota/$storage_quota (storage quota)"
	#sreport -t --parsable2 cluster AccountUtilizationByDay Accounts=$project
	#out=`sacct --starttime 2025-01-01 --user smohebi --group 32956 --format=User,JobID,Jobname,partition,state,time,start,end,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist | wc -l`
done
echo 
