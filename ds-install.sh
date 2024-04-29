#!/bin/bash
STP_BGN_TS="$(date +%s)"
AZURE_IDENTITY="$1"
DSDISTURL="$2"
dictionary_type="$3"
dictionary_database_host="$4"
dictionary_database_port="$5"
dictionary_name="$6"
dictionary_database_login="$7"
audit_type="$8"
audit_database_host="$9"
audit_database_port=${10}
audit_database_name=${11}
audit_database_login=${12}
ds_server_name=${13}
key_vault_name=${14}
instance_name=${15}
target_db_port=${16}
target_db_type=${17}
target_db_host=${18}
target_database=${19}
target_db_login=${20}
target_proxy_port=$target_db_port
DSROOT="/opt/datasunrise"
AF_HOME=$DSROOT
AF_CONFIG=$AF_HOME

if [ "$audit_type" == "postgresql" ]; then
  AuditType=1  
elif [ "$audit_type" == "mssql" ]; then
  AuditType=6
elif [ "$audit_type" == "mysql" ]; then
  AuditType=2 
fi

source $PWD/ds-params.sh
source $PWD/ds-pre-setup.sh
source $PWD/ds-setup.sh
touch /tmp/ds-install.log
PREP_LOG=/tmp/ds-install.log

logBeginAct "Datasunrise installation script has been started"
logBeginAct "Pre-configuring DataSunrise node before installation"
install_libraries
configureKeepAlive
configureLocalFirewallRules
generateCrashDumps
RETVAL=$?
logEndAct "Pre-configuring DataSunrise node before installation result - $RETVAL" 
logBeginAct "Install DataSunrise"
install_product
ds_admin_password=`az keyvault secret show --name dsSecretAdminPassword --vault-name $key_vault_name --query value --output tsv`
RETVAL=$?
logEndAct "Install DataSunrise result - $RETVAL"
dictionary_database_password=`az keyvault secret show --name dsSecretDictionaryAdminPassword --vault-name $key_vault_name --query value --output tsv`
logBeginAct "Switch DS dictionary to the remote"
systemctl stop datasunrise
sleep 10
resetDict
RETVAL_DICT=$?
logEndAct "Switch DS dictionary to the remote result - $RETVAL_DICT"
if [ "$RETVAL_DICT" == "93" ]; then
  resetAdminPassword
  RETVAL1=$?
  logBeginAct "Prepare DS License"
  ds_license=`az keyvault secret show --name dsSecretLicenseKey --vault-name $key_vault_name --query value --output tsv`
  setupDSLicense
  RETVAL1=$?
  logEndAct "Prepare DS License result - $RETVAL1"
  logBeginAct "Settings DS License to Dictionary"
  setDictionaryLicense
  RETVAL1=$?
  logEndAct "Setting DS License to Dictionary result - $RETVAL1"
  audit_database_password=`az keyvault secret show --name dsSecretAuditAdminPassword --vault-name $key_vault_name --query value --output tsv`
  logBeginAct "Switch DS audit storage to the remote"
  resetAudit
  RETVAL1=$?
  logEndAct "Switch DS audit storage to the remote result - $RETVAL1"
fi
service datasunrise start
log "Wait for DataSunrise Service Unit is fully started"
sleep 20
logBeginAct "Datasunrise was successfully started"
logBeginAct "Preparing to Setup new Proxies or Copy from the existing setup"
checkInstanceExists
target_db_password=`az keyvault secret show --name dsSecretTargetAdminPassword --vault-name $key_vault_name --query value --output tsv`
if [[ "$instanceExists" == "0" && "$RETVAL_DICT" == "93" ]]; then
  log "First Node configuration sequence started"
  setupProxy
  setupCleaningTask
  setupAdditionals
  elif [[ "$instanceExists" == "0" && "$RETVAL_DICT" == "94" ]]; then
    while true; do
      checkInstanceExists
      if [ "$instanceExists" == "1" ]; then
        copyProxies
        runCleaningTask
        break
      fi
      log "Waiting until Database Instance comes up"
      sleep 10
    done
  else
   log "Subsequent Node configuration sequence started"
   copyProxies
   runCleaningTask
fi
logEndAct "Create/Copy Proxy section completed!"
STP_END_TS=$(date +%s)
STP_ELAPSED=$(($STP_END_TS-$STP_BGN_TS))
logEndAct "DataSunrise Setup finished in $STP_ELAPSED sec"