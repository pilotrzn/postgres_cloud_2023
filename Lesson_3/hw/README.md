# Домашнее задание

***
В качестве тестового стенда используется ВМ с ОС Ubuntu:

```bash
dbadmin@pgsql01:~$ cat /etc/os-release
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"
```

***
Для установки PostgreSQL добавляем репозиторий:

```bash
dbadmin@pgsql01:~$ sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
dbadmin@pgsql01:~$ sudo wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null 
dbadmin@pgsql01:~$ sudo apt update
```

***
После этого будет доступна последняя версия:

```bash
dbadmin@pgsql01:~$ sudo apt install postgresql-15
```
***

В систему подключен диск размером 10Гб, отформатирован в xfs формат. 
Далее останавливаем сервис postgresql.service, примапливаем диск в каталог /var/lib/postgresql через /etc/fstab, настраиваем права и создаем каталоги. После этого под пользователем postgres инициализируем кластер. 

```bash
dbadmin@pgsql01:~$ sudo systemctl stop postgresql.service
dbadmin@pgsql01:~$ sudo sh -c 'echo "/dev/vdb1 /var/lib/postgresql xfs noatime,nodiratime,noexec 0 0" >> /etc/fstab'
dbadmin@pgsql01:~$ sudo mount -a
dbadmin@pgsql01:~$ sudo mkdir -p /var/lib/postgresql/15/{main,log} # каталог под бд и логи, будут настроены дополнительно
dbadmin@pgsql01:~$ sudo chown -R postgres:postgres /var/lib/postgresql
dbadmin@pgsql01:~$ sudo -iu postgres
postgres@pgsql01:~$ /usr/lib/postgresql/15/bin/initdb -k -E UTF8 -D /var/lib/postgresql/15/main
dbadmin@pgsql01:~$ sudo systemctl start postgresql.service
```
***

Поскольку каталог БД соответствует значению, прописанному в postgresql.conf, кластер запустится без ошибок. Расположение конфигураций кластера postgresql в OS Ubuntu - /etc/postgresql/15/main - дефолтный кластер.

```bash
dbadmin@pgsql01:~$ cat /etc/postgresql/15/main/postgresql.conf | grep 'data_dir'
data_directory = '/var/lib/postgresql/15/main'          # use data in another directory
```
***

После запуска службы переходим в сессию пользователя postgres и проверяем возможность подключения к БД или просто запускаем psql:

```bash
dbadmin@pgsql01:~$ sudo -iu postgres
postgres@pgsql01:~$ psql
psql (15.3 (Ubuntu 15.3-1.pgdg20.04+1))
Type "help" for help.

postgres=#
```

или 

```bash
dbadmin@pgsql01:~$ sudo -u postgres psql
psql (15.3 (Ubuntu 15.3-1.pgdg20.04+1))
Type "help" for help.

postgres=#
```

Лично мне нравится первый вариант :)
***

Создадим тестовые данные:

```sql
postgres=# create database test;
CREATE DATABASE
postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# create table t1(id int, txt text);
CREATE TABLE
test=# insert into t1(id,txt) select id, md5(random()::text) from generate_series(1,1000) id;
INSERT 0 1000
```
***

Теперь остановим postgresql, выключим ВМ, отключим от нее диск.
Создадим новую ВМ и подключим к ней диск с БД.
на ВМ так же установим postgresql-15.

```bash
dbadmin@pgsql02:~$ lsblk /dev/vdb
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vdb    252:16   0  10G  0 disk
└─vdb1 252:17   0  10G  0 part
```
***

После установки postgresql останавливаем сервис postgresql.service.
Выполним аналогично первой ВМ подключение диска в каталог /var/lib/postgresql через /etc/fstab:

```bash
dbadmin@pgsql02:~$ sudo mount -a
dbadmin@pgsql02:~$ df -h
...
/dev/vdb1        10G  189M  9.9G   2% /var/lib/postgresql
```
***

И теперь попробуем запустить сервис.

```bash
dbadmin@pgsql02:~$ sudo systemctl start postgresql.service
dbadmin@pgsql02:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
***

Попробуем подключиться и проверить наличие бд:

```bash
dbadmin@pgsql02:~$ sudo -u postgres psql
psql (15.3 (Ubuntu 15.3-1.pgdg20.04+1))
Type "help" for help.

postgres=# \l
                                                 List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    | ICU Locale | Locale Provider |   Access privileges
-----------+----------+----------+-------------+-------------+------------+-----------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
 test      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
(4 rows)
```

Как видно на листинге, база присутствует.

***

[Назад](../README.md)