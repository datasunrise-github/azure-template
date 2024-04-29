#!/bin/bash
ds_connect() {
    "$DSROOT"/cmdline/executecommand.sh connect -host `hostname` -port 11000 -login admin -password $ds_admin_password
}

resetDict() {
  HOST=`hostname -i`
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService CLEAN_LOCAL_SETTINGS \
  PRINT_PROGRESS \
  REMOVE_SERVER_BY_HOST_PORT=1 \
  DICTIONARY_TYPE=$dictionary_type \
  DICTIONARY_HOST=$dictionary_database_host \
  DICTIONARY_PORT=$dictionary_database_port \
  DICTIONARY_DB_NAME=$dictionary_name \
  DICTIONARY_LOGIN=$dictionary_database_login \
  DICTIONARY_PASS=$dictionary_database_password \
  FIREWALL_SERVER_NAME=`hostname` \
  FIREWALL_SERVER_HOST=$HOST \
  FIREWALL_SERVER_BACKEND_PORT=11000 \
  FIREWALL_SERVER_CORE_PORT=11001 \
  FIREWALL_SERVER_BACKEND_HTTPS=1 \
  FIREWALL_SERVER_CORE_HTTPS=1
}

resetAdminPassword() {
  logBeginAct "Reset Admin Password..."
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService SET_ADMIN_PASSWORD=$ds_admin_password
  RETVAL1=$? 
  logEndAct "Reset DS Admin Password result - $RETVAL1"
 }

resetAudit() {
  if [ "$AuditType" == 2 ]; then
    az mysql server configuration set --name log_bin_trust_function_creators --resource-group $resource_group_name --server $audit_server_name --value ON
  fi
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService CHANGE_SETTINGS \
  AuditDatabaseType=$AuditType \
  AuditDatabaseHost=$audit_database_host \
  AuditDatabasePort=$audit_database_port \
  AuditDatabaseName=$audit_database_name \
  AuditLogin=$audit_database_login \
  AuditPassword=$audit_database_password 
}

setupProxy() {
  logBeginAct "Creating new Proxy"
  xtra_args=
  if [ "$target_db_type" = "oracle" ]; then
    xtra_args="-instance $instance_name"
    if [ "$target_db_login" = "SYS" ] || [ "$target_db_login" = "sys" ]; then
      xtra_args="-instance $instance_name -sysDba"
    fi
  fi
  $DSROOT/cmdline/executecommand.sh addInstancePlus -name $instance_name $xtra_args -dbPort $target_db_port -dbType $target_db_type -dbHost $target_db_host -database $target_database -login $target_db_login -password $target_db_password -proxyHost `hostname -I` -proxyPort $target_proxy_port -savePassword azurekv -azureSecretName dsSecretAdminPassword -azureKeyVault $key_vault_name
  logEndAct "Creating new Proxy result - $?"
}

setupDSLicense() {
  touch /tmp/appfirewall.reg
  echo "$ds_license" > /tmp/appfirewall.reg  
  mv /tmp/appfirewall.reg $DSROOT
  chown datasunrise:datasunrise $DSROOT/appfirewall.reg
}

setDictionaryLicense() {
  dsversion=`/opt/datasunrise/AppBackendService VERSION`
  if [ '6.3.1.99999' = "`echo -e "6.3.1.99999\n$dsversion" | sort -V | head -n1`" ] ; then
    LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService IMPORT_LICENSE_FROM_FILE=$DSROOT/appfirewall.reg
  fi
}

checkInstanceExists() {
    log "Checking existing instances..."
    ds_connect
    instanceExists=
    local instances=`$DSROOT/cmdline/executecommand.sh showInstances`;
        if [[ "$instances" == "No Instances" ]]; then
            instanceExists=0
            log "No instances found, returning 0."
            return 0
        else
            instanceExists=1
            log "Instances found, returning 1."
            return 1
        fi
}

copyProxies() {
  logBeginAct "Copy Proxies"
  service datasunrise stop
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService COPY_PROXIES
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_CONFIG" $DSROOT/AppBackendService COPY_TRAILINGS
  service datasunrise start
  sleep 5
  logEndAct "Copy Proxies finished"
}

setupCleaningTask() {
  logBeginAct "Set node cleaning task..."
  ds_connect
  RETVAL=$?
    if [ "$RETVAL" == 0 ]; then
      local CLEANING_PT_JSON="{\"id\":-1,\"storePeriodType\":0,\"storePeriodValue\":0,\"name\":\"azure_remove_servers\",\"type\":32,\"lastExecTime\":\"\",\"nextExecTime\":\"\",\"lastSuccessTime\":\"\",\"lastErrorTime\":\"\",\"serverID\":0,\"forceUpdate\":false,\"params\":{},\"frequency\":{\"minutes\":{\"beginDate\":\"2018-09-28 00:00:00\",\"repeatEvery\":10}},\"updateNextExecTime\":true}"
      "$DSROOT"/cmdline/executecommand.sh arbitrary -function updatePeriodicTask -jsonContent "$CLEANING_PT_JSON"
      RETVAL=$?
    fi
    logEndAct "Set node cleaning task - $RETVAL"
}

runCleaningTask() {
    logBeginAct "Run node cleaning task..."
    ds_connect
    RETVAL=$?
    if [ "$RETVAL" == 0 ]; then
      local EC2_CLEANING_TASK_ID=`$DSROOT/cmdline/executecommand.sh arbitrary -function getPeriodicTaskList -jsonContent "{taskTypes:[32]}" | python3 -c "import sys, json; print json.load(sys.stdin)['data'][1][0]"`
      "$DSROOT"/cmdline/executecommand.sh arbitrary -function executePeriodicTaskManually -jsonContent "{id:$EC2_CLEANING_TASK_ID}"     
      RETVAL=$?
    fi
    logEndAct "Run node cleaning task - $RETVAL"
}

setupAdditionals() {
  logBeginAct "Setting up additional parameters"
  LD_LIBRARY_PATH="$DSROOT":"$DSROOT/lib":$LD_LIBRARY_PATH AF_HOME="$AF_HOME" AF_CONFIG="$AF_HOME" $DSROOT/AppBackendService CHANGE_SETTINGS=1 \
    WebLoadBalancerEnabled=1 \
    LogsDiscFreeSpaceLimit=2048 \
    LogTotalSizeCore=10000 \
    LogTotalSizeBackend=10000 \
    InstallationType=2 \
    GenerateCrashDump=1 \
    GenerateCrashDumpBackend=1
  RETVAL=$?
  logEndAct "Set up additional parameters result - $RETVAL"
}

cleanLogs() {
  logBeginAct "Clean DS logs..."
  rm -f $DSROOT/logs/Backend*
  rm -f $DSROOT/logs/CoreLog*
  rm -f $DSROOT/logs/WebLog*
  logEndAct "Clean DS logs done - $?"
}

cleanSQLite() {
  logBeginAct "Clean DS SQLite context..."
  rm -f $DSROOT/audit.db*
  rm -f $DSROOT/event.db*
  rm -f $DSROOT/dictionary.db*
  rm -f $DSROOT/local_settings.db*
  rm -f $DSROOT/lock.db*
  logEndAct "Clean DS SQLite context done - $?"
}

generateCrashDumps() {
  logBeginAct "Configuring Core Dumps..."
  echo "AF_GENERATE_NATIVE_DUMPS=1" | tee -a /etc/datasunrise.conf
  echo "" >> /etc/sysctl.conf
  echo "kernel.core_pattern=core-%e" | tee -a /etc/sysctl.conf
  echo "kernel.core_uses_pid=0" | tee -a /etc/sysctl.conf
  sysctl -p -q
  logEndAct "Configuring Core Dumps result $?"
}