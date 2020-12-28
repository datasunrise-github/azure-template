sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

sudo sh -c 'echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

sudo yum install azure-cli -y

echo "Azure CLI was successfully installed" >> /home/test.txt

az login --identity -u $1

echo "Azure successful login" >> /home/test.txt

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum install jq -y

echo "jq was successfully installed" >> /home/test.txt

sudo yum install java-1.8.0-openjdk -y

sudo yum install unixODBC -y

echo "unixODBC install OK" >> /home/test.txt 
