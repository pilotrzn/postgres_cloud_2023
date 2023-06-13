# Кластер etcd

Установка распределенной системы конфигураций(DCS) etcd. На всех машинах предполагаемого кластера  устанавливаем пакет etcd:

```bash
$ sudo apt install etcd
```

После установки рекомендуется проверить, что сервис не запущен. Если запушен - остановить.
***
Далее выполняем кофигурирование. на каждой машине создаем конфигурационный файл в каталоге /etc/default/etcd.conf

на ВМ1:

```
ETCD_NAME="etcd01"
ETCD_LISTEN_CLIENT_URLS="http://192.168.122.55:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.122.55:2379"
ETCD_LISTEN_PEER_URLS="http://192.168.122.55:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.55:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-postgres-cluster"
ETCD_INITIAL_CLUSTER="etcd01=http://192.168.122.55:2380,etcd02=http://192.168.122.56:2380,etcd03=http://192.168.122.57:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_INITIAL_ELECTION_TICK_ADVANCE="false"
ETCD_ENABLE_V2=true
```

на ВМ2:

```
ETCD_NAME="etcd02"
ETCD_LISTEN_CLIENT_URLS="http://192.168.122.56:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.122.56:2379"
ETCD_LISTEN_PEER_URLS="http://192.168.122.56:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.56:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-postgres-cluster"
ETCD_INITIAL_CLUSTER="etcd01=http://192.168.122.55:2380,etcd02=http://192.168.122.56:2380,etcd03=http://192.168.122.57:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_INITIAL_ELECTION_TICK_ADVANCE="false"
ETCD_ENABLE_V2=true
```

на ВМ3:

```
ETCD_NAME="etcd03"
ETCD_LISTEN_CLIENT_URLS="http://192.168.122.57:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.122.57:2379"
ETCD_LISTEN_PEER_URLS="http://192.168.122.57:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.122.57:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-postgres-cluster"
ETCD_INITIAL_CLUSTER="etcd01=http://192.168.122.55:2380,etcd02=http://192.168.122.56:2380,etcd03=http://192.168.122.57:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_INITIAL_ELECTION_TICK_ADVANCE="false"
ETCD_ENABLE_V2=true
```

После конфигурирования запускаем сервис на всех машинах:

```
$ sudo systemctl enable --now etcd.service
```

Если не возникло проблем при запуске, можно проверить состояние кластера. рекомендую создать скриптик для проверки:

```bash
#!/bin/bash

export ETCDCTL_API=3
HOST_1=192.168.122.55
HOST_2=192.168.122.56
HOST_3=192.168.122.57
ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379
etcdctl --write-out=table --endpoints=$ENDPOINTS member list
etcdctl --write-out=table --endpoints=$ENDPOINTS endpoint status
```

 Результат можно получить в виде:

 ```bash
 dbadmin@etcd03:~$ bash etcd_stat.sh 
+------------------+---------+--------+-------------------------+-------------------------+
|        ID        | STATUS  |  NAME  |       PEER ADDRS        |      CLIENT ADDRS       |
+------------------+---------+--------+-------------------------+-------------------------+
|  e4e7bb124be494a | started | etcd01 | http://192.168.122.55:2380 | http://192.168.122.55:2379 |
| 1783ba84822970d4 | started | etcd03 | http://192.168.122.57:2380 | http://192.168.122.57:2379 |
| 3ec22bdc73937461 | started | etcd02 | http://192.168.122.56:2380 | http://192.168.122.56:2379 |
+------------------+---------+--------+-------------------------+-------------------------+
+------------------+------------------+---------+---------+-----------+-----------+------------+
|     ENDPOINT     |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+------------------+------------------+---------+---------+-----------+-----------+------------+
| 192.168.122.55:2379 |  e4e7bb124be494a |  3.2.26 |   25 kB |     false |         2 |      18310 |
| 192.168.122.56:2379 | 3ec22bdc73937461 |  3.2.26 |   25 kB |     false |         2 |      18310 |
| 192.168.122.57:2379 | 1783ba84822970d4 |  3.2.26 |   25 kB |      true |         2 |      18310 |
+------------------+------------------+---------+---------+-----------+-----------+------------+
```

***

После завершения настройки резкомендуется сменить параметр ETCD_INITIAL_CLUSTER_STATE с new на existing.
Делается во избежание "рассыпания" кластера если одна из нод упадет. после старта нода не сможет подключиться к существующему кластеру.

- [Назад](README.md)