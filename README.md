# azure-template
The template automatically deploys DataSunrise Suite cluster on Microsoft Azure Cloud based on the Azure Resource Manager (ARM) template.

DataSunrise is cross-platform, high-performance software that secures databases and data in real time, and helps protect companies’ sensitive data from outside threats and internal security breaches.


The DataSunrise infrastructure includes:
* DataSunrise autoscaling nodes (instances).
* Configuration and audit storages based on Azure databases.
* Azure’s Load balancer is used to distribute the traffic between living nodes.

All these components are located inside a Custom Virtual Network with the specified subnets.

DataSunrise Configuration and Audit databases are configured on PostgreSQL server.

You can connect to DataSunrise Web Console by connecting to the LoadBalancer public IP address 11000 port. It will automatically connect to one of the configured nodes.
 
The Target DB will be automatically added to the DataSunrise Suite server.
