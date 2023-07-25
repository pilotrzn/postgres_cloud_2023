# Процедура развертывания клсатера CockroachDB

Для процедуры развертывания кластера используем 3 ВМ на Ubuntu 20.04 c CPU-4 и RAM-6Gb. В данном примере без использования сервификатов.

| VM Name | OS | CPU | RAM | OS disk | Data disk | IP |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| cockroach01 | Ubuntu 20.04 | 4 | 6 | 10 | 30 | 192.168.122.30 |
| cockroach02 | Ubuntu 20.04 | 4 | 6 | 10 | 30 | 192.168.122.31 |
| cockroach03 | Ubuntu 20.04 | 4 | 6 | 10 | 30 | 192.168.122.32 |

***

## Установка 

На всех машинах выполняем 

```bash
$ sudo apt install ntp
$ ntpq -pn
$ sudo wget -qO- https://binaries.cockroachdb.com/cockroach-v23.1.5.linux-amd64.tgz | tar  xvz && sudo cp -i cockroach-v23.1.5.linux-amd64/cockroach /usr/local/bin/ 
```

Создаем каталог и монтируем в него дополнительный диск для данных 

```bash
$ mkdir -p /var/lib/cockroach 
$ sudo sh -c 'echo "/dev/vdb1 /var/lib/cockroach xfs noatime,nodiratime,noexec 0 0" >> /etc/fstab'
$ sudo mount -a
$ sudo useradd cockroach
$ sudo chown -R cockroach /var/lib/cockroach
```

Далее создадим сервис cockroachdb.service на каждой ноде. 

```bash
$ sudo vim /etc/systemd/system/insecurecockroachdb.service
[Unit]
Description=Cockroach Database cluster node
Requires=network.target
[Service]
Type=notify
WorkingDirectory=/var/lib/cockroach
ExecStart=/usr/local/bin/cockroach start --insecure --advertise-addr=192.168.122.30 --join=192.168.122.31,192.168.122.32 --cache=.25 --max-sql-memory=.25
TimeoutStopSec=60
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cockroach
User=cockroach
[Install]
WantedBy=default.target
```

Для каждой ноды указываем следующий конфиг в строке ExecStart:

| server | advertise-addr | join |
|:---:|:---:|:---:|
| cockroach01 | 192.168.122.30 | 192.168.122.31,192.168.122.32 |
| cockroach02 | 192.168.122.31 | 192.168.122.30,192.168.122.32 |
| cockroach03 | 192.168.122.32 | 192.168.122.30,192.168.122.31 |

Далее выполняем:

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl start insecurecockroachdb.service
```

После запуска сервисов нужно инициализировать кластер(запускаем на первой ноде)):

```bash
$ cockroach init --insecure
Cluster successfully initialized
```

Получаем ответ об успешной инициализации. Проверяем состояние:

```bash
$ cockroach node status --insecure
  id |       address        |     sql_address      |  build  |              started_at        | locality | is_available | is_live
-----+----------------------+----------------------+---------+--------------------------------+----------+--------------+----------
   1 | 192.168.122.30:26257 | 192.168.122.30:26257 | v23.1.5 | 2023-07-23 18:26:24.302096 UTC |          | true         | true
   2 | 192.168.122.32:26257 | 192.168.122.32:26257 | v23.1.5 | 2023-07-23 18:26:24.528739 UTC |          | true         | true
   3 | 192.168.122.31:26257 | 192.168.122.31:26257 | v23.1.5 | 2023-07-23 18:26:24.524609 UTC |          | true         | true
(3 rows)
```

Так мы получаем кластер cockroachdb.

***
[Назад](README.md)