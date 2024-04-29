#!/bin/bash

install_product() {
  wget --no-check-certificate -q -O DataSunrise_Suite.linux.64bit.rpm "$DSDISTURL"
  log "Build download result $?"
  rpm -Uvh ./DataSunrise_Suite.linux.64bit.rpm
  log "DataSunrise installation result $?"
}

install_libraries() {
  logBeginAct "Updating system packages..."
  ACCEPT_EULA=Y yum update -y -q
  logEndAct "Updating system packages result $?"
  
  logBeginAct "Configuring JVM..."
  jvmpath=`find / -name libjvm.so`
  echo $jvmpath | tr " " "\n" | sed -e "s/libjvm.so//" > /etc/ld.so.conf.d/jvm.conf
  ldconfig
  logEndAct "Configuring JVM result - $?"

  az login --identity -u $AZURE_IDENTITY
  log "Azure login result $?"
}

configureJVM() {
  logBeginAct "Configuring JVM..."
  jvmpath=`find / -name libjvm.so`
  echo $jvmpath | tr " " "\n" | sed -e "s/libjvm.so//" > /etc/ld.so.conf.d/jvm.conf
  ldconfig
  logEndAct "Configuring JVM result - $?"
}

configureKeepAlive() {
  echo "" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_keepalive_time = 60" | tee -a /etc/sysctl.conf
  echo "net.ipv4.tcp_keepalive_intvl = 10" | tee -a /etc/sysctl.conf
  echo "net.ipv4.tcp_keepalive_probes = 6" | tee -a /etc/sysctl.conf
  sysctl -p -q
}

configureLocalFirewallRules() {
  logBeginAct "Enabling required ports in the firewalld"
  log "Enabling Interchange Manager ports access (11002-11012/tcp)..."
  firewall-cmd --add-port 11002-11012/tcp --zone public --permanent
  log "Interchange Manager ports access enabled"

  log "Enabling the inbound access to the Proxy port"
  firewall-cmd --add-port $target_proxy_port/tcp --zone public --permanent
  log "Proxy port access enabled"

  firewall-cmd --reload
  logEndAct "Enabling required ports in the firewalld completed"
}
