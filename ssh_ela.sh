RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
echor () {
	printf "${RED}[ `basename $0` ] $1 ${NC}\n"
}
echog () {
	printf "${GREEN}[ `basename $0` ] $1 ${NC}\n"
}
echob () {
	printf "${BLUE}[ `basename $0` ] $1 ${NC}\n"
}

[ "`command -v python3`" = "" ] && echo "python not found. Please install python using e.g.: sudo apt install -y python3" && exit 1
# [ "`command -v ssh`" = "" ] && echo "ssh not found. Please install ssh." && exit 1
# [ "`command -v scp`" = "" ] && echo "scp not found. Please install scp." && exit 1
# [ "`command -v op`" = "" ] && echo "op not found. Please install op." && exit 1
# Get the directory of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# echo "Script is located in: $SCRIPT_DIR"


ssh_ela () {
    my_cscs_username="$1"
    [ "$USER" = "glensk" ] && [ "$1" = "" ] && my_cscs_username="aglensk"
    if [ "$my_cscs_username" = "" ];then
        echor "my_cscs_username is empty. Please provide it as a first argument. Exit."
        return 1
    fi
    cscs_passwords="$2"
    cscs_otp="$3"


if [ "$USER" != 'glensk' ];then
if [ "$1" = "" ];then
if [ "$2" = "" ];then
    cscs_passwords=$2
    if [ "$cscs_passwords" = "" ];then
        echor "cscs_passwords is empty. Please provide it as a second argument. Exit."
        return 1
    fi
    cscs_otp=$3
    if [ "$cscs_otp" = "" ];then
        echor "cscs_otp is empty. Please provide it as a third argument. Exit."
        return 1
    fi
fi
fi
fi
    # echob "my_cscs_username: $my_cscs_username"
    # echob "cscs_passwords: $cscs_passwords"
    # echob "cscs_otp: $cscs_otp"







    folder_ssh=$HOME/.ssh

    folder_cscs=$folder_ssh/cscs_daily_key

    cscs_public_key=$folder_cscs/cscs-key-cert.pub
    cscs_public_key_script=$folder_ssh/cscs-key-cert.pub

    cscs_private_key=$folder_cscs/cscs-key
    cscs_private_key_script=$folder_ssh/cscs-key

    running_cscs_keygen="true"
    [ ! -e $folder_cscs ] && mkdir -p $folder_cscs
    folder_control_path_files="$HOME/.ssh/ControlPath_files"
    [ ! -e $folder_control_path_files ] && mkdir -p $folder_control_path_files

    control_path_file="$HOME/.ssh/ControlPath_files/$my_cscs_username@ela.cscs.ch:22"
    if [ ! -e $control_path_file ];then
        :   
    else
        echog "Great, $control_path_file exists."
        back=`ssh ela "hostname" | cut -c-3`
        # echo "back: $back"
        if [ "$back" == "ela" ];then
            echog "Great, you are successfully connected to ela through ControlPathFile $control_path_file. Nothing to do."
            echog "scp -i $cscs_private_key $cscs_public_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub"
            scp -i $cscs_private_key $cscs_public_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub
            echog "scp -i $cscs_private_key $cscs_private_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key"
            scp -i $cscs_private_key $cscs_private_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key
            return 0
        else
            echob "It seems the ControlPathFile $control_path_file has no working ssh connection. Will remove it and try to connect."
            rm -f $control_path_file   
        fi
    fi    


    # echo "cscs_public_key: $cscs_public_key"
    # echo '111'
    if [ -e "$cscs_public_key" ];then
        # echo "File $cscs_public_key exists."
        path_to_file=$cscs_public_key
        lastModificationSeconds=$(date -r "$path_to_file" +%s)
        currentSeconds=$(date +%s)
        ((elapsedSeconds = currentSeconds - lastModificationSeconds))
        elapsedHours=`echo $elapsedSeconds | awk '{print $1/3600}'`
        smaller_24h=`echo "$elapsedHours < 24" | bc`

        if [[ $(find "$cscs_public_key" -mtime +1 -print) ]]; then
            echo "rm -f $cscs_public_key"
            rm -f $cscs_public_key # file is older then one day
            echog "cscs_public_key : $cscs_public_key ==> I have removed it since it was older then one day ($elapsedHours hours). Will run cscs-keygen.py"
        else
            # file exists and is recent

            if [ "$smaller_24h" = "1" ];then
                echog "cscs_public_key: $cscs_public_key ==> is very recent (1) ($elapsedHours hours). Nothing to do."
                running_cscs_keygen="false"
            else
                # echog "cscs_public_key: $cscs_public_key ==> is older then 24 hours. Will rm -f $cscs_public_key and $cscs_private_key and run cscs-keygen.py"
                rm -f $cscs_public_key # file is older then one day
                rm -f $cscs_private_key # file is older then one day
                echog "cscs_public_key : $cscs_public_key ==> I have removed it since it was older then one day ($elapsedHours hours). Will run cscs-keygen.py"
            fi
        fi
    else
        echog "cscs_public_key : $cscs_public_key ==> does not exist. Will run cscs-keygen.py"
    fi


    # echo "NOW EXIT 345"
    # exit
    # echo "cscs_private_key: $cscs_private_key"
    
    if [ -e "$cscs_private_key" ];then
        # echo "File $cscs_private_key exists."
        path_to_file=$cscs_private_key
        lastModificationSeconds=$(date -r "$path_to_file" +%s)
        currentSeconds=$(date +%s)
        ((elapsedSeconds = currentSeconds - lastModificationSeconds))
        elapsedHours=`echo $elapsedSeconds | awk '{print $1/3600}'`

        if [[ $(find "$cscs_private_key" -mtime +1 -print) ]]; then
            echo "rm -f $cscs_private_key"
            rm -f $cscs_private_key # file is older then one day
            echog "cscs_private_key: $cscs_private_key ==> I have removed it since it was older then one day ($elapsedHours hours). Will run cscs-keygen.py."
            [ "$running_cscs_keygen" = "false" ] && running_cscs_keygen="true"
        else
            # file exists and is recent

            echog "cscs_private_key: $cscs_private_key ==> is very recent (2) ($elapsedHours hours). Nothing to do."
        fi
    else
        echog "cscs_private_key: $cscs_private_key ==> does not exist. Will run cscs-keygen.py"
        [ "$running_cscs_keygen" = "false" ] && running_cscs_keygen="true"
    fi


    [ ! -e "$cscs_public_key" ] && [ -e   "$cscs_private_key" ] && rm -f $cscs_private_key && running_cscs_keygen="true"
    [ -e   "$cscs_public_key" ] && [ ! -e "$cscs_private_key" ] && rm -f $cscs_public_key  && running_cscs_keygen="true"
    [ ! -e "$cscs_public_key" ] && [ ! -e "$cscs_private_key" ] && running_cscs_keygen="true"

    # echo "running_cscs_keygen: $running_cscs_keygen"
    if [ "$running_cscs_keygen" = "true" ];then
        cd $SCRIPT_DIR
        echog "Am now in folder: `pwd`"
        echog "Running \`op item get ...\` to get cscs_username."
        cscs_username=$my_cscs_username

        if [ "$USER" = "glensk" ];then # in this case I use 1password
        if [ "$1" = "" ];then
        if [ "$2" = "" ];then
            echog "cscs_username: $cscs_username ==> Now running \`op item get ...\` to get cscs_passwords."
            cscs_passwords=`op item get sns6rmk2wbh7nohznpdnsixmly --account my.1password.com --reveal --field password`
            if [ "$cscs_passwords" = "" ];then
                echor "cscs_passwords is empty. Exit."
                return 1
            fi
            echog "cscs_passwords: Got it. ==> Now running \`op item get ...\` to get cscs_otp."
            cscs_otp=`op item get sns6rmk2wbh7nohznpdnsixmly --account my.1password.com --otp`
            if [ "$cscs_otp" = "" ];then
                echor "cscs_otp is empty. Exit."
                return 1
            fi
            echog "cscs_otp: Got it"
        fi
        fi
        fi
        # echo "cscs_username:$cscs_username"
        # echo "cscs_passwords:$cscs_passwords"
        # echo "cscs_otp:$cscs_otp"
        # echog "#############################################################"
        # echog "# Next you will need your CSCS credentials ($my_cscs_username, pw, OTP)"
        # echog "#############################################################"
        echog "==> running: python cscs-keygen.py to download the daily ssh-key file pair from cscs."

        python3 cscs-keygen.py $cscs_username $cscs_passwords $cscs_otp
        echog "==> running: python cscs-keygen.py done"

        # touch $folder_ssh/cscs-key
        # touch $folder_ssh/cscs-key-cert.pub

        
        
        if [ ! -e "$cscs_public_key_script" ];then
            echor "$cscs_public_key_script was not created (1) => It seems cscs-keygen.py was not successful. Exit."
            return 1
        else
            echog "created key in $cscs_public_key_script, will move it to $cscs_public_key"
            mv $cscs_public_key_script $cscs_public_key
        fi 


        if [ ! -e "$cscs_private_key_script" ];then
            echor "$cscs_private_key_script was not created (2) => It seems cscs-keygen.py was not successful. Exit."
            return 1
        else
            echog "created key in $cscs_private_key_script,              will move it to $cscs_private_key"
            mv $cscs_private_key_script $cscs_private_key
        fi 

        

        if [ ! -e "$cscs_public_key" ];then
            echor "$cscs_public_key does not exist. Exit."
            return 1
        else
            if [[ $(find "$cscs_public_key" -mtime +1 -print) ]]; then
                echor "File $cscs_public_key exists BUT is older than 1 day. Therefor, did not obtain proper certificate. Exit."
                return 1
            else
                echog "File $cscs_public_key exists and is not older than 1 day. As it should be."
            fi
        fi


        if [ ! -e "$cscs_private_key" ];then
            echor "$cscs_private_key does not exist. Exit."
            return 1
        else
            if [[ $(find "$cscs_private_key" -mtime +1 -print) ]]; then
                echor "File $cscs_private_key exists BUT is older than 1 day. Therefor, did not obtain proper certificate. Exit."
                return 1
            else
                echog "File $cscs_private_key exists and is not older than 1 day. As it should be."
            fi
        fi
        echog "scp -i $cscs_private_key $cscs_public_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub"
               scp -i $cscs_private_key $cscs_public_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key-cert.pub
        echog "scp -i $cscs_private_key $cscs_private_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key"
               scp -i $cscs_private_key $cscs_private_key $my_cscs_username@ela.cscs.ch:/users/$my_cscs_username/.ssh/cscs-key
    fi

    echo "#############################################################"
    echo "# Now will log you into ela                                 #"
    echo "# once there: run:                                          #"
    echo "# ssh -i ~/.ssh/cscs-key daint.alps    # or                 #"
    echo "# ssh -i ~/.ssh/cscs-key eiger         # or                 #"
    echo "# ssh -i ~/.ssh/cscs-key bris ten  ==> this I can not do currently though todi is up  #"
    echo "#############################################################"
    ssh -i $cscs_private_key $my_cscs_username@ela.cscs.ch
}

username=$1
passwords=$2
otp=$3
echo "Username: $username"
echo "Password: $passwords"
echo "OTP: $otp"
ssh_ela $username $passwords $otp