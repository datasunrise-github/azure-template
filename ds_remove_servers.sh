ds_connect() {
    
    cd /opt/datasunrise/cmdline
    
    sleep 30

    ./executecommand.sh connect -host `hostname` -port 11000 -login admin -password $1
    
}

ds_showservers() {

    touch /tmp/ds_servers.txt

    cd /opt/datasunrise/cmdline

    ./executecommand.sh showDsServers | grep 11000 > /tmp/ds_servers.txt
    
}

get_ds_servers_list() {

    ds_servers_count=`wc -l < /tmp/ds_servers.txt`

    echo "ds_servers_count=$ds_servers_count" >> /home/test.txt

    ds_server_name_del=()

    ds_server_name_cont=()

    vm_count=$(($1-1))

    echo "vm_count=$vm_count" >> /home/test.txt

    for i in {0..$ds_servers_count}
    do
        while IFS='' read -r DS_LINE || [[ -n "$DS_LINE" ]]; do

            IFS=':'; ARG=($DS_LINE); unset IFS;

            CK_DS_NAME=`echo ${ARG[0]} | tr -d '[:space:]'`
            CK_DS_HOST_NAME=`echo ${ARG[1]} | tr -d '[:space:]'`
        
            echo "CK_DS_NAME=$CK_DS_NAME" >> /home/test.txt

            echo "CK_DS_HOST_NAME=$CK_DS_HOST_NAME" >> /home/test.txt

            for ((j=0; j<=$vm_count; j++))

            do

                echo "j=$j" >> /home/test.txt

                hostname_scale=$(az vmss list-instances -g $2 -n $3 | jq ".[$j].osProfile.computerName")

                hostname_scale="${hostname_scale//\"}"

                echo "hostname_scale=$hostname_scale" >> /home/test.txt

                if [ "$hostname_scale" == "$CK_DS_HOST_NAME" ]; then

                    ds_server_name_cont+=($CK_DS_NAME);

                    echo "CK_DS_NAME_cont=$CK_DS_NAME" >> /home/test.txt

                else 
                    if [[ " ${ds_server_name_del[@]} " =~ " ${CK_DS_NAME} " ]]; then

                        continue

                    else
                        ds_server_name_del+=($CK_DS_NAME);

                        echo "CK_DS_NAME_del=$CK_DS_NAME" >> /home/test.txt

                    fi
                fi

             done

        done < /tmp/ds_servers.txt

    done
    
}
 
remove_odd_servers () {
 
     if [ ${#ds_server_name_cont[@]} != ${#ds_server_name_del[@]} ]; then

        echo "ds_server_name_cont_count=${#ds_server_name_cont[@]}" >> /home/test.txt

        echo "ds_server_name_del_count=${#ds_server_name_del[@]}" >> /home/test.txt

        for cont in ${ds_server_name_cont[@]}
        do

            ds_server_name_del=("${ds_server_name_del[@]/$cont}") 

            echo "cont=$cont" >> /home/test.txt

        done

        for del in ${ds_server_name_del[@]}

        do 

            ./executecommand.sh delDsServer -name $del

            echo "del=$del" >> /home/test.txt

        done
    fi
    
}
