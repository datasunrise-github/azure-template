resetDict() {

  cd /opt/datasunrise

  host=`hostname -i`

  sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService CLEAN_LOCAL_SETTINGS \
  PRINT_PROGRESS \
  REMOVE_SERVER_BY_HOST_PORT=1 \
  DICTIONARY_TYPE=$3 \
  DICTIONARY_HOST=$4 \
  DICTIONARY_PORT=$5 \
  DICTIONARY_DB_NAME=$6 \
  DICTIONARY_LOGIN=$7 \
  DICTIONARY_PASS=$8 \
  FIREWALL_SERVER_NAME=`hostname` \
  FIREWALL_SERVER_HOST=$host \
  FIREWALL_SERVER_BACKEND_PORT=11000 \
  FIREWALL_SERVER_CORE_PORT=11001 \
  FIREWALL_SERVER_BACKEND_HTTPS=1 \
  FIREWALL_SERVER_CORE_HTTPS=1
  
}

resetAdminPassword() {

  logBeginAct "Reset Admin Password..."

  sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService SET_ADMIN_PASSWORD=$3
   
  RETVAL1=$?
   
  logEndAct "Reset DS Admin Password result - $RETVAL1"
  
 }

resetAudit() {

if [ "$3" == 2 ]; then

  echo "$3"

  az login --identity -u $9

  echo "$9"

  az mysql server configuration set --name log_bin_trust_function_creators --resource-group ${10} --server ${11} --value ON

  echo "${10} ${11} ${12}"

fi

echo "$3"

cd /opt/datasunrise

  sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService CHANGE_SETTINGS \
  AuditDatabaseType=$3 \
  AuditDatabaseHost=$4 \
  AuditDatabasePort=$5 \
  AuditDatabaseName=$6 \
  AuditLogin=$7 \
  AuditPassword=$8 \
  
}

setupProxy() {

  cd /opt/datasunrise/cmdline
  
  xtra_args=
  
  if [ "$3" = "oracle" ]; then
    xtra_args="-instance $5"
    
    if [ "$6" = "SYS" ] || [ "$6" = "sys" ]; then
      xtra_args="-instance $5 -sysDba"
      
    fi
      
  fi

  ./executecommand.sh addInstancePlus -name $1 $xtra_args -dbPort $2 -dbType $3 -dbHost $4 -database $5 -login $6 -password $7 -proxyHost `hostname -I` -proxyPort $8 -savePassword azurekv -azureSecretName dsSecretAdminPassword -azureKeyVault $9
  
}

setupDSLicense() {

  touch /tmp/appfirewall.reg
  
  echo "$1"

  echo "$1" > /tmp/appfirewall.reg  
  
  sudo mv /tmp/appfirewall.reg /opt/datasunrise/
  
  sudo chown datasunrise:datasunrise -R /opt/datasunrise/appfirewall.reg

}

setDictionaryLicense() {

  dsversion=`/opt/datasunrise/AppBackendService VERSION`
  
  if [ '6.3.1.99999' = "`echo -e "6.3.1.99999\n$dsversion" | sort -V | head -n1`" ] ; then
                        
    echo "DS version $dsversion" >> /home/test.txt 
    
    sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService IMPORT_LICENSE_FROM_FILE=/opt/datasunrise/appfirewall.reg
                  
  fi
 
}

checkInstanceExists() {

  instanceExists=
  
  for attempts in {1..100}
  do
    
    instances=`$1/cmdline/executecommand.sh showInstances`
    
    if [[ "$instances" == "No Instances" ]]; then
      
      echo "No Instances, waiting..."
      
      echo "$instances"
      
      sleep 5
      
      instanceExists=0
    
    else
      
      instanceExists=1 
      
      break
  
    fi
  
  done
  
  

}

copyProxies() {
  
  logBeginAct "Copy proxy..."
  
   service datasunrise stop

   sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService COPY_PROXIES

   sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService COPY_TRAILINGS

   service datasunrise start
  
   logEndAct "Proxies copied."
               
}

 setupCleaningTask() {
                    
    logBeginAct "Set node cleaning task..."
                    
    if [ "$1" == 0 ]; then
      
      local CLEANING_PT_JSON="{\"id\":-1,\"storePeriodType\":0,\"storePeriodValue\":0,\"name\":\"azure_remove_servers\",\"type\":32,\"lastExecTime\":\"\",\"nextExecTime\":\"\",\"lastSuccessTime\":\"\",\"lastErrorTime\":\"\",\"serverID\":0,\"forceUpdate\":false,\"params\":{},\"frequency\":{\"minutes\":{\"beginDate\":\"2018-09-28 00:00:00\",\"repeatEvery\":10}},\"updateNextExecTime\":true}" 
      
      echo "$CLEANING_PT_JSON"

      "$2"/cmdline/executecommand.sh arbitrary -function updatePeriodicTask -jsonContent "$CLEANING_PT_JSON"
      
      RETVAL=$?

    fi
    
    logEndAct "Set node cleaning task - $RETVAL"
}

runCleaningTask() {
                    
    logBeginAct "Run node cleaning task..."
                    
    if [ "$1" == 0 ]; then
      
      local EC2_CLEANING_TASK_ID=`$DSROOT/cmdline/executecommand.sh arbitrary -function getPeriodicTaskList -jsonContent "{taskTypes:[32]}" | python -c "import sys, json; print json.load(sys.stdin)['data'][1][0]"`
      
      "$2"/cmdline/executecommand.sh arbitrary -function executePeriodicTaskManually -jsonContent "{id:$EC2_CLEANING_TASK_ID}"
      
      RETVAL=$?
    
    fi
    
    logEndAct "Run node cleaning task - $RETVAL"
}

setupAdditionals() {               
  
  logBeginAct "Setting up additional parameters..."

  sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService CHANGE_SETTINGS=1 \
    WebLoadBalancerEnabled=1 \
    LogsDiscFreeSpaceLimit=2048 \
    LogTotalSizeCore=10000 \
    LogTotalSizeBackend=10000

  RETVAL=$?

  logEndAct "Set up additional parameters - $RETVAL"
}
