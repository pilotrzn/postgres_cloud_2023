# Настройка pgbouncer и haproxy

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

```bash
cat /etc/pgbouncer/pgbouncer.ini 
[databases]
postgres = host=127.0.0.1 port=5432 dbname=postgres 

* = host=127.0.0.1 port=5432

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

в данной команде необходимо написать пароль и имя пользователя слитно









- [Назад](README.md)