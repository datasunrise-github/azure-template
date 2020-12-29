sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

sudo yum install azure-cli -y

logBeginAct "Azure CLI was successfully installed"

az login --identity -u $1

logBeginAct "Azure successful login"

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum install jq -y

logBeginAct "jq was successfully installed"

sudo yum install java-1.8.0-openjdk -y

sudo yum install unixODBC -y

logBeginAct "unixODBC install OK"

curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo

sudo ACCEPT_EULA=Y yum install msodbcsql17 -y

logBeginAct "mssqlODBCdriver install OK"
