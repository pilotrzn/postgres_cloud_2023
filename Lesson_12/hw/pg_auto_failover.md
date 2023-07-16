# Создание отказоустойчивости PostgeSQL с помощью расширения pg_auto_failover

HA Кластер управляется сервером, называемым монитором или управляющей нодой. на управляющей ноде есть БД, в которой хранится конфигурация отказоуйстойчивости и состояние кластера.
Управление полностью отдано сервису pgautofailover, сервис PostgeSQL отключен.

Для работы создаем 3 ВМ,- 2 для PostgeSQL, 1 для расширения(монитора). На всех ВМ ресурсы - 4CPU/4RAM.
***

## на всех ВМ установим PostgeSQL версии 14.

После установки удаляем созданный автоматически экземпляр.

```bash
~# sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
~# wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
~# apt update
~# apt install postgresql-14
~$ sudo pg_dropcluster 14 main --stop
~# apt install postgresql-14-auto-failover -y 
```
***

## Настроим ВМ pgmon
 
Создаем каталог для управляющей базы, добавляем пути в env, инициализируем управляющую ноду(монитор):

```bash
~$ mkdir -p 14/pgmon
~$ echo "export PATH=/usr/lib/postgresql/14/bin/:$PATH" >> .profile
~$ echo "export PGDATA=/var/lib/postgresql/14/pgmon" >> .profile
~$ . ~/.profile
```

Далее выполняем инициализацию.

```bash
~$ pg_autoctl create monitor \
    --auth trust \
    --no-ssl \
    --pgport 5432 \
    --hostname pgmon
```

После инициализации необходимо выполнить запуск сервиса. Рекомендации выдает консоль, выполнить нужно от root

```bash
~$ pg_autoctl show systemd
17:14:12 2260 INFO  HINT: to complete a systemd integration, run the following commands (as root):
17:14:12 2260 INFO  pg_autoctl -q show systemd --pgdata "/var/lib/postgresql/14/pgmon" | tee /etc/systemd/system/pgautofailover.service
17:14:12 2260 INFO  systemctl daemon-reload
17:14:12 2260 INFO  systemctl enable pgautofailover
17:14:12 2260 INFO  systemctl start pgautofailover

~$ sudo -i
~# pg_autoctl -q show systemd --pgdata "/var/lib/postgresql/14/pgmon" | tee /etc/systemd/system/pgautofailover.service
~# systemctl daemon-reload
~# systemctl enable --now pgautofailover.service
```

Результатом будет запущенный экземпляр монитора или управляющей ноды. В бд монитора можно зайти обычным способом, через psql. 
Для подключения серверов с БД им необходимо указывать адрес монитора. Для его получения нужно ввести кодманду:

```bash
$ pg_autoctl show uri
        Type |    Name | Connection String
-------------+---------+-------------------------------
     monitor | monitor | postgres://autoctl_node@pgmon:5432/pg_auto_failover?sslmode=prefer
```
***

## Настроим ВМ с БД на работу с auto failover

Предварительно создадим каталог для БД, настроим env - на обеих машинах с postgresql

```bash
~$ mkdir -p 14/data
~$ echo "export PATH=/usr/lib/postgresql/14/bin/:$PATH" >> .profile
~$ echo "export PGDATA=/var/lib/postgresql/14/data" >> .profile
~$ . ~/.profile
```

Далее создадим мастер ноду PostgreSQL с помощью расширения. 

```bash
~$ pg_autoctl create postgres \
  --pgdata /var/lib/postgresql/14/data \
  --pgport 5432 \
  --hostname `hostname -I` \
  --name `hostname -s` \
  --auth trust \
  --no-ssl \
  --monitor postgres://autoctl_node@pgmon:5432/pg_auto_failover?sslmode=prefer
```

Так же следуем рекомендациям команды  pg_autoctl show systemd для запуска сервиса.
***

После запуска мастера можем проверить состояние кластера в мониторе:

```bash
~$ pg_autoctl show state
   Name |  Node |           Host:Port |       TLI: LSN |   Connection |      Reported State |      Assigned State
--------+-------+---------------------+----------------+--------------+---------------------+--------------------
pgsrv01 |     1 | 192.168.122.80:5432 |   1: 0/177E5E8 |   read-write |              single |              single
```
***

Создадим реплику. В общем то выполняем те же действия что и на мастере. Во время создания наблюдаем в логе следующую запись:

```text
 INFO  pg_basebackup: initiating base backup, waiting for checkpoint to complete
 ```

 ,что говорит о создании реплики. После завершения команды так же необходимо добавить сервис и запустить его.
***

После запуска сервисов на обеих нодах PostgeSQL проверим что нам пишет монитор:

```bash
~$ pg_autoctl show state
   Name |  Node |           Host:Port |       TLI: LSN |   Connection |      Reported State |      Assigned State
--------+-------+---------------------+----------------+--------------+---------------------+--------------------
pgsrv01 |     1 | 192.168.122.80:5432 |   1: 0/3000110 |   read-write |             primary |             primary
pgsrv02 |     2 | 192.168.122.81:5432 |   1: 0/3000110 |    read-only |           secondary |           secondary
```

Видно, что теперь есть 2 машины, одна в состоянии read-write, другая - реплика, в состоянии read-only.

***
Для обеспечения доступа по выделенному адресу можно использовать Keepalived.


[Назад](../README.md)












