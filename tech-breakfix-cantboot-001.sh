#!/bin/bash
MYHOSTNAME=`hostname`
MYNAME=`whoami`

if [[ ! $MYNAME == "root" ]]
then
	echo "$0 needs to be run by the root user."
	exit 3
fi

# startup
logger -p local0.notice "Initiating $0 with option $@"
echo "Initiating $0 with option $@"


break() {

	sed  -i '130i      filter = [ "r|.*/|" ]' /etc/lvm/lvm.conf
	dracut -f  &>> /dev/null

	touch /var/tmp/.kc1
	echo "Applying break....	DONE"
	echo "Your system has been modified."

}

fix() {
	# checking to make sure we have the .GOOD.crt and .GOOD.key saved from the break
	if [[ -f /var/tmp/.kc1 ]]; then
		
	Replace filter = [ "r|.*/|" ] with  filter = [ "a|/dev/sda|", "r|.*/|" ] in /etc/lvm/lvm.conf
	
	dracut -fv /boot/initramfs-3.10.0-957.el7.x86_64.img 3.10.0-957.el7.x86_64

		rm -rf /var/tmp/.kc1
		echo "Applying fix.........	SUCCESS"
	else
		echo "It seems like break was not run successfully.  Run $0 break first."
		exit 7
	fi
}


grade() {

	STATUS="failed"
	echo "Grading.  Please wait."

	if  ! [ -f /var/tmp/.kc1 ]
	then
		echo "It seems like break was not run successfully.  Run $0 break first."
		exit 7
	fi


	[ ! -z $(systemctl list-units --type target --state active | grep -o $(systemctl get-default)) ]
	var1=$?

	
	[ ! -z $(lsinitrd | grep ^lvm) ]
	var2=$?


	dracut -fv /tmp/test.img $(awk '/^menuentry.*{/,/^}/' /boot/grub2/grub.cfg | awk -vRS="\n}\n" -vDEFAULT="$((default+1))" 'NR==DEFAULT' | grep -o '/vmlinuz-.*' | awk '{print $1}' | cut -c 10-) &> /tmp/test.dracut ; [ ! -z $(grep -o "Including module: lvm" /tmp/test.dracut | sort -u | awk '{print $3}') ]
         var3=$?


	[ -z $(lvs 2>&1 | grep -o rejected | sort -u) ]
        var4=$?


	[ -z $(grep -Ev "^[[:space:]]*#|^$|^[[:space:]]*;" /etc/lvm/lvm.conf | grep -o volume_list) ] || [ ! -z $(grep -Ev "^[[:space:]]*#|^$|^[[:space:]]*;" /etc/lvm/lvm.conf | grep volume_list | grep -o $(lvs | awk '$1~"root"{print $2}')) ]
	var5=$?


	[ $(awk '/^menuentry.*{/,/^}/' /boot/grub2/grub.cfg | awk -vRS="\n}\n" -vDEFAULT="$((default+1))" 'NR==DEFAULT' | grep -o '/vmlinuz-.*' | awk '{print $1}' | cut -c 10-) == $(uname -a | awk '{print $3}') ]
	var6=$?

	grep "filter = [ "r|.*/|" ]" /etc/lvm/lvm.conf &>> /dev/null
       var7=$?


	if [[ $var1 == "0" && $var2 == "0" &&  $var3 == "0"  && $var4 == "0"  &&  $var5 == "0" && $var6 == "0" && $var7 != "0" ]]
	then
	 	STATUS="success"
	fi

	# end your grading code here

	if [[ $STATUS == "success" ]]
        then
	        echo "Success."
                echo "${bold}COMPLETION CODE: CANTRHEL7USERBOOT${normal}"
        else
                echo "Sorry.  There still seems to be a problem"
	fi

}

case "$1" in
	break)
		break
		;;
	grade)
		grade
		;;
  #	fix)
  #		echo "This will revert the changes made by break."
  #              read -p "Are you sure you want to continue (y/n)? " ANSWER
  #              if [[ "$ANSWER" == "y" ]]; then
  #                      fix
  #              else
  #                      echo "Exiting without making a change."
  #              fi
  #              ;;
	*)
		echo $"Usage: $0 {grade}"
		exit 2
esac


# ending
logger -p local0.notice "Completed $0 with option $@ successfully"
echo "Completed $0 with option $@ successfully"
exit 0
