install_product() {

  wget -O DataSunrise_Suite.linux.64bit.run $1

  echo "DS download OK" >> /home/test.txt

  chmod +x DataSunrise_Suite.linux.64bit.run

  echo "chmod OK" >> /home/test.txt

  ./DataSunrise_Suite.linux.64bit.run --target tmp install -f --no-password --no-start
  
}
