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
dictionary_database_password=${12}
audit_type=${13}
audit_database_host=${14}
audit_database_port=${15}
audit_database_name=${16}
audit_database_login=${17}
audit_database_password=${18}
audit_server_name=${19}
ds_server_name=${20}
ds_admin_password=${21}
ds_remove_servers="/var/lib/waagent/custom-script/download/1/${22}"
ds_license=${23}
instance_name=${24}
target_db_port=${25}
target_db_type=${26}
target_db_host=${27}
target_database=${28}
target_db_login=${29}
target_db_password=${30}
target_proxy_port=${31}
vm_count=${32}
resource_group_name=${33}
vm_scale_set_name=${34}
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

RETVAL=$?

logEndAct "Exit code after installation - $RETVAL"

#curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo

#sudo yum remove unixODBC-utf16 unixODBC-utf16-devel 

#sudo ACCEPT_EULA=Y yum install msodbcsql17 -y

#sudo yum install unixODBC-devel -y

#echo "mssql driver was updated successfully" >> /home/test.txt

logBeginAct "DS_setup execution"

resetDict $ds_root $AF_HOME $dictionary_type $dictionary_database_host $dictionary_database_port $dictionary_name $dictionary_database_login $dictionary_database_password $ds_server_name

RETVAL=$?

logEndAct "Exit code after dictionary configuration - $RETVAL"

if [ "$RETVAL" == "93" ]; then

  resetAdminPassword $ds_root $AF_HOME $ds_admin_password
  
  RETVAL1=$?

  logEndAct "Exit code after admin password is changed - $RETVAL1"

fi

#printf "%q\n" "$dictionary_type"

#if [ "$dictionary_type" == "postgresql"]; then

 # AuditType=1
  
  #echo $AuditType
  
#elif [ "$dictionary_type" == "mssql"]; then

 # AuditType=6
  
#fi

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

if [ "$instanceExists" == "0" ]; then
  
 logBeginAct "Create proxy..."
 ds_connect $ds_admin_password 
 setupProxy $instance_name $target_db_port $target_db_type $target_db_host $target_database $target_db_login $target_db_password $target_proxy_port
 #setupCleaningTask
  
else
  
 logBeginAct "Copy proxy..."
 ds_connect $ds_admin_password 
 copyProxies $ds_root $AF_HOME
 #runCleaningTask

fi

logBeginAct "DS_remove_servers execution"

ds_connect $ds_admin_password

RETVAL1=$?

logEndAct "Exit code after connection attempt - $RETVAL1"

ds_showservers

RETVAL1=$?

logEndAct "Exit code after showDsServers - $RETVAL1"

get_ds_servers_list $vm_count $resource_group_name $vm_scale_set_name

remove_odd_servers

logBeginAct "The odd servers were successfully removed"
