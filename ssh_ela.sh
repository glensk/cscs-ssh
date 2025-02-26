sshela () {
    runningcscskeygen="true"
    folder_ssh=$HOME/.ssh
    folder_cscs=$folder_ssh/cscs_daily_key
    [ ! -e $folder_cscs ] && mkdir -p $folder_cscs

    cscs_public_key=$folder_cscs/cscs-key-cert.pub
    cscs_public_key_script=$folder_ssh/cscs-key-cert.pub
    # echo "cscs_public_key: $cscs_public_key"

    if [ -e "$cscs_public_key" ];then
        # echo "File $cscs_public_key exists."
        if [[ $(find "$cscs_public_key" -mtime +1 -print) ]]; then
            echo "rm $cscs_public_key"
            rm $cscs_public_key # file is older then one day
            echo "cscs_public_key : $cscs_public_key ==> I have removed it since it was older then one day. Will run cscs-keygen.py"
        else
            # file exists and is recent
            path_to_file=$cscs_public_key
            lastModificationSeconds=$(date -r "$path_to_file" +%s)
            currentSeconds=$(date +%s)
            ((elapsedSeconds = currentSeconds - lastModificationSeconds))
            elapsedHours=`echo $elapsedSeconds | awk '{print $1/3600}'`
            echo "cscs_public_key: $cscs_public_key ==> is very recent ==> $elapsedHours hours. Nothing to do."
            runningcscskeygen="false"
        fi
    else
        echo "cscs_public_key : $cscs_public_key ==> does not exist. Will run cscs-keygen.py"
    fi


    cscs_private_key=$folder_cscs/cscs-key
    cscs_private_key_script=$folder_ssh/cscs-key

    # echo "cscs_private_key: $cscs_private_key"
    if [ -e "$cscs_private_key" ];then
        # echo "File $cscs_private_key exists."
        if [[ $(find "$cscs_private_key" -mtime +1 -print) ]]; then
            echo "rm $cscs_private_key"
            rm $cscs_private_key # file is older then one day
            echo "cscs_private_key: $cscs_private_key ==> I have removed it since it was older then one day. Will run cscs-keygen.py"
            [ "$runningcscskeygen" = "false" ] && runningcscskeygen="true"
        else
            # file exists and is recent
            path_to_file=$cscs_private_key
            lastModificationSeconds=$(date -r "$path_to_file" +%s)
            currentSeconds=$(date +%s)
            ((elapsedSeconds = currentSeconds - lastModificationSeconds))
            elapsedHours=`echo $elapsedSeconds | awk '{print $1/3600}'`
            echo "cscs_private_key: $cscs_private_key ==> is very recent ==> $elapsedHours hours. Nothing to do."
        fi
    else
        echo "cscs_private_key: $cscs_private_key ==> does not exist. Will run cscs-keygen.py"
        [ "$runningcscskeygen" = "false" ] && runningcscskeygen="true"
    fi


    [ ! -e "$cscs_public_key" ] && [ -e   "$cscs_private_key" ] && rm $cscs_private_key && runningcscskeygen="true"
    [ -e   "$cscs_public_key" ] && [ ! -e "$cscs_private_key" ] && rm $cscs_public_key  && runningcscskeygen="true"
    [ ! -e "$cscs_public_key" ] && [ ! -e "$cscs_private_key" ] && runningcscskeygen="true"

    # echo "runningcscskeygen: $runningcscskeygen"
    if [ "$runningcscskeygen" = "true" ];then
        cd ~/gdrive/repos_sdsc/cscs-ssh
        echo "Am now in folder `pwd`"
        echo "#############################################################"
        echo "# Next you will need your CSCS credentials (aglensk, pw, OTP)"
        echo "#############################################################"
        echo "==> running: python cscs-keygen.py"
        python cscs-keygen.py
        # touch $folder_ssh/cscs-key
        # touch $folder_ssh/cscs-key-cert.pub

        
        
        if [ ! -e "$cscs_public_key_script" ];then
            echo "$cscs_public_key_script does not exist. Exit."
            return 1
        else
            echog "created key in $cscs_public_key_script, will move it to $cscs_public_key"
            mv $cscs_public_key_script $cscs_public_key
        fi 


        if [ ! -e "$cscs_private_key_script" ];then
            echo "$cscs_private_key_script does not exist. Exit."
            return 1
        else
            echog "created key in $cscs_private_key_script,              will move it to $cscs_private_key"
            mv $cscs_private_key_script $cscs_private_key
        fi 

        

        if [ ! -e "$cscs_public_key" ];then
            echo "$cscs_public_key does not exist. Exit."
            return 1
        else
            if [[ $(find "$cscs_public_key" -mtime +1 -print) ]]; then
                echo "File $cscs_public_key exists BUT is older than 1 day. Therefor, did not obtain proper certificat. Exit."
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
                echor "File $cscs_private_key exists BUT is older than 1 day. Therefor, did not obtain proper certificat. Exit."
                return 1
            else
                echog "File $cscs_private_key exists and is not older than 1 day. As it should be."
            fi
        fi
        echog "scp -i $cscs_private_key $cscs_public_key aglensk@ela.cscs.ch:/users/aglensk/.ssh/cscs-key-cert.pub"
               scp -i $cscs_private_key $cscs_public_key aglensk@ela.cscs.ch:/users/aglensk/.ssh/cscs-key-cert.pub
        echog "scp -i $cscs_private_key $cscs_private_key aglensk@ela.cscs.ch:/users/aglensk/.ssh/cscs-key"
               scp -i $cscs_private_key $cscs_private_key aglensk@ela.cscs.ch:/users/aglensk/.ssh/cscs-key
    fi

    echo "#############################################################"
    echo "# Now will log you into ela                                 #"
    echo "# once there: run:                                          #"
    echo "# ssh -i ~/.ssh/cscs-key daint.alps    # or                 #"
    echo "# ssh -i ~/.ssh/cscs-key eiger         # or                 #"
    echo "# ssh -i ~/.ssh/cscs-key bristen  ==> this I can not do currently though todi is up  #"
    echo "#############################################################"
    ssh -i $cscs_private_key aglensk@ela.cscs.ch
}

sshela