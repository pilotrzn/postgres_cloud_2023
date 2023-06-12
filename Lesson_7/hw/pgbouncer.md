# Настройка pgbouncer

## Создание бд для примеров

Для демонстрации работы в postgres создадим пользователей и базы:

roles

```sql
postgres=# create role user1 login inherit password '123';
postgres=# create role user2 login inherit password '123';
postgres=# create role user3 login inherit password '123';
```

databases

```sql
postgres=# create database db1;
postgres=# create database db2 owner user2;
postgres=# create database db3 owner user3;
```
***

## Установка
На каждом сервере с БД postgres так же установлен сервиc pgbouncer
Пакет pgbouncer доступен в репозитории:

```bash
$ sudo apt install pgbouncer
```
***

## Каталоги
Созданы каталоги для конфигурации и логов:

- pgbouncer_conf_dir: "/etc/pgbouncer"
- pgbouncer_log_dir: "/var/log/pgbouncer"
***

## Сервис

Скорректирован фалй сервиса:

```text
[Unit]
Description=pgBouncer connection pooling for PostgreSQL
After=syslog.target network.target

[Service]
Type=forking

User=postgres
Group=postgres

PermissionsStartOnly=true
ExecStartPre=-/bin/mkdir -p /run/pgbouncer {{ pgbouncer_log_dir }}
ExecStartPre=/bin/chown -R postgres:postgres /run/pgbouncer {{ pgbouncer_log_dir }}

ExecStart=/usr/sbin/pgbouncer -d {{ pgbouncer_conf_dir }}/pgbouncer.ini

ExecReload=/bin/kill -SIGHUP $MAINPID
PIDFile=/run/pgbouncer/pgbouncer.pid
Restart=on-failure

LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
```
***

## Конфигурация

Для удобства администрирования секцию databases можно вынести в отдельный файл,в ini добавить include.


```bash
cat /etc/pgbouncer/pgbouncer.ini 
[databases]

postgres = host=127.0.0.1 port=5432 dbname=postgres 
db1 = host=127.0.0.1 port=5432 dbname=db1
db2 = host=127.0.0.1 port=5432 dbname=db2
db3 = host=127.0.0.1 port=5432 dbname=db3


[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /run/pgbouncer/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = 6432
unix_socket_dir = /var/run/postgresql
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres
stats_users = postgres
ignore_startup_parameters = extra_float_digits,geqo,search_path

pool_mode = session
server_reset_query = DISCARD ALL
max_client_conn = 10000
default_pool_size = 20
query_wait_timeout = 120
reserve_pool_size = 1
reserve_pool_timeout = 1
max_db_connections = 1000
pkt_buf = 8192
listen_backlog = 4096

log_connections = 0
log_disconnections = 0
```
***
## Userlist

Для настройки доступа к БД через pgbouncer настраивается файл /etc/pgbouncer/userlist.txt

В строке должно быть минимум два поля, заключённых в двойные кавычки. В первом поле задаётся имя пользователя, а во втором — пароль, либо открытым текстом, либо защищённый MD5 или SCRAM. Остальное содержимое строки pgbouncer игнорирует. Кавычки в этой строке можно записать, продублировав их.

Принятый в Postgres Pro формат пароля, защищённого MD5:

"md5" + md5(password + username)

Способ получения хеша:

- в postgres выполнить запрос 
   
```sql
$ select usename,passwd from pg_shadow ;
```

- выполнить команду:

```bash
$ echo -n "md5"; echo -n "password123admin" | md5sum | awk '{print $1}'
```

В данной команде необходимо написать пароль и имя пользователя слитно

Вариант наполнения файла userlist:

```text
"postgres" "postgrespass"
"user1" "md5b17de164c65acfe9da9d8ca1a331cec1"
"user2" "md5245a2b356234ce1ea772e164e596f395"
"user3" "md5a668e2d5689fb7624bd7da83b26be6cc"
```


***

## Проверка и доступ к админке

Чтобы проверить, что наши базы доступны для подключения через pgbouncer к админке:

```sql
postgres@pgsql02:~$ psql -p 6432 pgbouncer
Password for user postgres: 
psql (14.8 (Ubuntu 14.8-1.pgdg20.04+1), server 1.19.0/bouncer)
Type "help" for help.

pgbouncer=#
```
 
Чтобы подключаться без ввода пароля добавим запись в файл .pgpass:

```text
localhost:6432:*:postgres:postgrespass
```

В админке запросим список всех БД:

```sql
pgbouncer=# show databases;
  name    |   host    | port | database  | force_user | pool_size | min_pool_size | reserve_pool | pool_mode | max_connections | current_connections | paused | disabled 
-----------+-----------+------+-----------+------------+-----------+---------------+--------------+-----------+-----------------+---------------------+--------+----------
 db1       | 127.0.0.1 | 5432 | db1       |            |        20 |             0 |            1 |           |            1000 |                   0 |      0 |        0
 db2       | 127.0.0.1 | 5432 | db2       |            |        20 |             0 |            1 |           |            1000 |                   0 |      0 |        0
 db3       | 127.0.0.1 | 5432 | db3       |            |        20 |             0 |            1 |           |            1000 |                   0 |      0 |        0
 pgbouncer |           | 6432 | pgbouncer | pgbouncer  |         2 |             0 |            0 | statement |            1000 |                   0 |      0 |        0
 postgres  | 127.0.0.1 | 5432 | postgres  |            |        20 |             0 |            1 |           |            1000 |                   0 |      0 |        0
(5 rows)
```
***

pgbouncer так устроен, - чтобы появился доступ к какой-либо бд через pgbouncer, сначала нужно добавить запись в databases и выполнить рестарт сервиса.





- [Назад](README.md)