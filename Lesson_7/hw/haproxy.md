# Настройка haproxy

## Установка haproxy

Пакет haproxy доступен в репозитории

```bash 
$ sudo apt install haproxy
```
***

## Параметры ядра

Для корректной работы haproxy необходимо задать параметр

net.ipv4.ip_nonlocal_bind = 1

Выполняется либо через команду sysctl, либо добавить запись в файл /etc/sysctl.d/99-sysctl.conf.
***

## Сервис haproxy

Создаем файл для сервиса

```text
# /etc/systemd/system/haproxy.service
[Unit]
Description=HAProxy Load Balancer
After=network.target

[Service]
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy/haproxy.pid"
ExecStartPre=/bin/mkdir -p /run/haproxy

ExecStartPre=/usr/sbin/haproxy -f $CONFIG -c -q
ExecStart=/usr/sbin/haproxy -Ws -f $CONFIG -p $PIDFILE
ExecReload=/usr/sbin/haproxy -f $CONFIG -c -q

ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=143
Type=notify


[Install]
WantedBy=multi-user.target
```
***

## Конфигурация haproxy

Чтобы сервис работал и выполнял подключения к нодам с БД, настраиваем конфиг:

- [haproxy.cfg](haproxy_1.cfg)

В данном случае для подключения к БД используются порты:

- 5000 подключение к мастеру
- 5001 подключение к реплике
- 5002 подключение к синхронной реплике
- 5003 подключение к асинхронной реплике

- [Назад](README.md)