yc compute instance create \
  --name srv-pgsql01 \
  --hostname srv-pgsql01 \
  --cores 2 \
  --memory 2 \
  --create-boot-disk size=5G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
  --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4,ipv4-address=10.130.0.21 \
  --zone ru-central1-c \
  --core-fraction 20 \
  --preemptible \
  --metadata-from-file ssh-keys=/home/aavdonin/.ssh/yandex_rsa.pub  


  yc compute instance create \
  --name srv-pgsql02 \
  --hostname srv-pgsql02 \
  --cores 2 \
  --memory 2 \
  --create-boot-disk size=5G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
  --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4,ipv4-address=10.130.0.21 \
  --zone ru-central1-c \
  --core-fraction 20 \
  --preemptible \
  --metadata-from-file ssh-keys=/home/aavdonin/.ssh/yandex_rsa.pub  

yc compute instance create \
  --name srv-monitor \
  --hostname srv-pgsql02 \
  --cores 2 \
  --memory 2 \
  --create-boot-disk size=5G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
  --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4,ipv4-address=10.130.0.21 \
  --zone ru-central1-c \
  --core-fraction 20 \
  --preemptible \
  --metadata-from-file ssh-keys=/home/aavdonin/.ssh/yandex_rsa.pub  