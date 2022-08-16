ds_params="./$1"
install_libraries="./$2"
identity=$3
pre_setup="./$4"
link_to_DS_build=$5
ds_setup="./$6"
dictionary_type=$7
dictionary_database_host=$8
dictionary_database_port=$9
dictionary_name=${10}
dictionary_database_login=${11}
audit_type=${12}
audit_database_host=${13}
audit_database_port=${14}
audit_database_name=${15}
audit_database_login=${16}
ds_server_name=${17}
key_vault_name=${18}
ds_remove_servers="./${19}"
instance_name=${20}
target_db_port=${21}
target_db_type=${22}
target_db_host=${23}
target_database=${24}
target_db_login=${25}
target_proxy_port=${26}
vm_count=${27}
resource_group_name=${28}
vm_scale_set_name=${29}
ds_root='/opt/datasunrise'
AF_HOME=$ds_root
AF_CONFIG=$AF_HOME


source $ds_params
source $pre_setup
source $ds_setup
source $ds_remove_servers

logBeginAct "Datasunrise installation script has been started"

logBeginAct "Install_libraries execution"

echo "3 $3"

echo $identity

$install_libraries $identity

RETVAL=$?

logEndAct "Install_libraries execution result - $RETVAL" 

logBeginAct "Pre_setup execution"

install_product $link_to_DS_build

ds_admin_password=`az keyvault secret show --name dsSecretAdminPassword --vault-name $key_vault_name --query value --output tsv`

RETVAL=$?

logEndAct "Exit code after installation - $RETVAL"

dictionary_database_password=`az keyvault secret show --name dsSecretDictionaryAdminPassword --vault-name $key_vault_name --query value --output tsv`

logBeginAct "DS_setup execution"

resetDict $ds_root $AF_HOME $dictionary_type $dictionary_database_host $dictionary_database_port $dictionary_name $dictionary_database_login $dictionary_database_password $ds_server_name

RETVAL=$?

logEndAct "Exit code after dictionary configuration - $RETVAL"

if [ "$RETVAL" == "93" ]; then

  resetAdminPassword $ds_root $AF_HOME $ds_admin_password
  
  RETVAL1=$?

  logEndAct "Exit code after admin password is changed - $RETVAL1"

fi

audit_database_password=`az keyvault secret show --name dsSecretAuditAdminPassword --vault-name $key_vault_name --query value --output tsv`

if [ "$audit_type" == "postgresql" ]; then

  AuditType=1
  
  echo $AuditType
  
elif [ "$audit_type" == "mssql" ]; then

  AuditType=6

  echo $AuditType

elif [ "$audit_type" == "mysql" ]; then

  AuditType=2

  echo $AuditType
  
fi

resetAudit $ds_root $AF_HOME $AuditType $audit_database_host $audit_database_port $audit_database_name $audit_database_login $audit_database_password $identity $resource_group_name $audit_server_name

RETVAL1=$?

logEndAct "Exit code after audit configuration - $RETVAL1"

sudo service datasunrise start

sleep 20

logBeginAct "Datasunrise Suite was successfully started"

logBeginAct "Setting up license..."

ds_connect $ds_admin_password

ds_license=`az keyvault secret show --name dsSecretLicenseKey --vault-name $key_vault_name --query value --output tsv`

echo $ds_license

setupDSLicense $ds_license
  
RETVAL1=$?

logEndAct "Exit code after license is gotten - $RETVAL1"

setDictionaryLicense $ds_root $AF_HOME
  
RETVAL1=$?

logEndAct "Exit code after license is set - $RETVAL1"

sudo service datasunrise start

logBeginAct "Datasunrise Suite was successfully started"

ds_connect $ds_admin_password

echo "$RETVAL"

logBeginAct "Checking existing instances..."

if [ "$RETVAL" != "93" ]; then

  sleep 80
  
fi

checkInstanceExists $ds_root 

echo $instanceExists

target_db_password=`az keyvault secret show --name dsSecretTargetAdminPassword --vault-name $key_vault_name --query value --output tsv`

if [ "$instanceExists" == "0" ]; then
  
 logBeginAct "Create proxy..."

 ds_connect $ds_admin_password 

 setupProxy $instance_name $target_db_port $target_db_type $target_db_host $target_database $target_db_login $target_db_password $target_proxy_port $key_vault_name

 ds_connect $ds_admin_password

 RETVAL_LOGIN=$?

 echo "$RETVAL_LOGIN"

 setupCleaningTask $RETVAL_LOGIN $ds_root
  
else
  
 logBeginAct "Copy proxy..."

 ds_connect $ds_admin_password 

 copyProxies $ds_root $AF_HOME

 ds_connect $ds_admin_password

 RETVAL_LOGIN=$?

 echo "$RETVAL_LOGIN"

 runCleaningTask $RETVAL_LOGIN $ds_root

fi
