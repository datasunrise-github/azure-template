resetDict() {

  cd /opt/datasunrise

  sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService CLEAN_LOCAL_SETTINGS \
  DICTIONARY_TYPE=$3 \
  DICTIONARY_HOST=$4 \
  DICTIONARY_PORT=$5 \
  DICTIONARY_DB_NAME=$6 \
  DICTIONARY_LOGIN=$7 \
  DICTIONARY_PASS=$8 \
  FIREWALL_SERVER_NAME=$9'-'`hostname` \
  FIREWALL_SERVER_HOST=`hostname` \
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

  ./executecommand.sh addInstancePlus -name $1 $xtra_args -dbPort $2 -dbType $3 -dbHost $4 -database $5 -login $6 -password $7 -proxyHost `hostname -I` -proxyPort $8 -savePassword ds 
  
}

setupDSLicense() {

  touch /tmp/appfirewall.reg
  
  echo "$1"

  echo "$1" > /tmp/appfirewall.reg  
  
  sudo mv /tmp/appfirewall.reg /opt/datasunrise/
  
  sudo chown datasunrise:datasunrise -R /opt/datasunrise/

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
  
  #for attempts in {1..50}
  #do
    
   # instances=`$1/cmdline/executecommand.sh showInstances`
    
    #if [[ "$instances" == "No Instances" ]]; then
      
     # echo "No Instances, waiting..."
      #sleep 5
                              
    #else
      
     # echo "No Instances found. Will copy."
   service datasunrise stop
   sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService COPY_PROXIES
   sudo LD_LIBRARY_PATH="$1":"$1/lib":$LD_LIBRARY_PATH AF_HOME="$2" AF_CONFIG="$2" $1/AppBackendService COPY_TRAILINGS
   service datasunrise start
   #sleep 10
      #break
      
    #fi
                        
  #done
  
  logEndAct "Proxies copied."
               
}
