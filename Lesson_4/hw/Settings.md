# Домашнее задание

## Тестовый стенд

```text
 Стенд: VirtualBox
 OS: Ubuntu 20.04
 CPU: 4
 RAM: 4GB
 Каталог для БД: vdi 10gb, примонтирован в /var/lib/postgresql/14
```

```bash
NAME="Ubuntu"
VERSION="20.04.5 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.5 LTS"
VERSION_ID="20.04"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
```

***
## Версия Postgres

```sql
postgres=# select version();
version
PostgreSQL 14.6 (Ubuntu 14.6-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, 64-bit
(1 строка)
```
***
## Параметры сервера в postgresql.conf

(добавлены параметры логирования, включен вывод только данных контрольных точек):

```text
max_connections = 60
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_timeout = '15min'
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 8MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = '4'
max_parallel_workers_per_gather = '2'
max_parallel_workers = '4'
max_parallel_maintenance_workers = '2'
log_checkpoints = 'on'
checkpoint_warning = '10s'
log_connections = 'off'
log_destination = 'stderr'
log_directory = 'log'
log_disconnections='off'
log_duration= 'off'
log_error_verbosity= 'default'
log_file_mode= '416'
log_filename= 'postgresql-%Y-%m-%d.log'
log_line_prefix= '%t [%p]: [%l-1] '
log_lock_waits= 'off'
log_min_duration_statement= '5s'
log_rotation_age= '1d'
log_rotation_size= '0'
log_statement= 'none'
log_temp_files= '0'
log_timezone= 'W-SU'
log_truncate_on_rotation= 'on'
logging_collector= 'on'
autovacuum_vacuum_scale_factor = '0.08'
autovacuum_vacuum_insert_scale_factor = '0.08'
log_autovacuum_min_duration = '-1'
autovacuum_max_workers = '4'
autovacuum_naptime = '15s'
autovacuum_vacuum_threshold = '20'
autovacuum_vacuum_cost_delay = '10'
autovacuum_vacuum_cost_limit = '1000'
autovacuum_analyze_scale_factor = '0.2'
```
***

## Настройка Huge_pages:

Для автоматизации настройки больших страниц воспользуемся скриптом. Создадим файл huge.sh, сделаем его исполняемым(chmod +x). В файл запишем скрипт:

```text
#!/bin/bash
pid=`head -1 /var/lib/postgresql/14/main/postmaster.pid`
echo "Pid:            $pid"
peak=`grep ^VmPeak /proc/$pid/status | awk '{ print $2 }'`
echo "VmPeak:            $peak kB"
hps=`grep ^Hugepagesize /proc/meminfo | awk '{ print $2 }'`
echo "Hugepagesize:   $hps kB"
hp=$((peak/hps))
echo Set Huge Pages:     $hp
```

Далее запустим скрипт. Важно! сервер БД при этом должен быть запущен!

```bash
postgres@pg14-srv01:~/14/main$ ./huge.sh 
Pid:            3233
VmPeak:            1165464 kB
Hugepagesize:   2048 kB
Set Huge Pages: 569
```

Результат работы скрипта сообщает, что можно задать 569 страниц.
Выполняем(от пользователя с адм. правами):

```bash
root@pg14-srv01:~# echo 'vm.nr_hugepages=569' >> /etc/sysctl.d/99-sysctl.conf
root@pg14-srv01:~# echo 'vm.swappiness = 5' >> /etc/sysctl.d/99-sysctl.conf
root@pg14-srv01:~# sysctl - p --system
```

Так же изменяем параметр использования свопа - vm.swappiness.
в конфиг сервера postgresql.conf добавим параметр и выполним перезапуск службы

```text
huge_pages = on
```

Проверка HugePages:

```bash
postgres@pg14-srv01:~$ grep ^HugePages /proc/meminfo
HugePages_Total:     569
HugePages_Free:      544
HugePages_Rsvd:      510
HugePages_Surp:        0
```
*** 

## Тесты

Теперь можно выполнить нагрузочное тестирование.

### Тест 1.1:

```bash
postgres@pg14-srv01:~$ pgbench -c 8 -C -j 2 -P 10 -T 120 -M extended testdb
pgbench (14.6 (Ubuntu 14.6-1.pgdg20.04+1))
starting vacuum...end.
progress: 10.0 s, 353.8 tps, lat 17.233 ms stddev 5.253
progress: 20.0 s, 349.4 tps, lat 17.511 ms stddev 5.334
progress: 30.0 s, 351.3 tps, lat 17.325 ms stddev 5.292
progress: 40.0 s, 355.8 tps, lat 17.208 ms stddev 5.351
progress: 50.0 s, 355.3 tps, lat 17.139 ms stddev 5.483
progress: 60.0 s, 360.4 tps, lat 16.903 ms stddev 5.200
progress: 70.0 s, 354.4 tps, lat 17.148 ms stddev 5.337
progress: 80.0 s, 361.0 tps, lat 16.905 ms stddev 5.203
progress: 90.0 s, 333.3 tps, lat 18.341 ms stddev 6.319
progress: 100.0 s, 360.6 tps, lat 16.858 ms stddev 5.151
progress: 110.0 s, 359.6 tps, lat 16.943 ms stddev 5.408
progress: 120.0 s, 336.6 tps, lat 18.102 ms stddev 5.942
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 8
number of threads: 2
duration: 120 s
number of transactions actually processed: 42325
latency average = 17.290 ms
latency stddev = 5.460 ms
average connection time = 4.266 ms
tps = 352.660066 (including reconnection times)
```
***

Повторим тест с большим количеством коннектов:

### Тест 2.1:

```bash
postgres@pg14-srv01:~$ pgbench -c 50 -C -j 2 -P 10 -T 120 -M extended testdb
pgbench (14.6 (Ubuntu 14.6-1.pgdg20.04+1))
starting vacuum...end.
progress: 10.0 s, 381.2 tps, lat 111.070 ms stddev 26.557
progress: 20.0 s, 387.3 tps, lat 112.283 ms stddev 23.788
progress: 30.0 s, 381.4 tps, lat 113.903 ms stddev 22.974
progress: 40.0 s, 377.0 tps, lat 116.768 ms stddev 23.210
progress: 50.0 s, 387.8 tps, lat 112.155 ms stddev 22.961
progress: 60.0 s, 382.5 tps, lat 111.364 ms stddev 28.651
progress: 70.0 s, 193.2 tps, lat 225.450 ms stddev 335.003
progress: 80.0 s, 319.5 tps, lat 143.734 ms stddev 190.031
progress: 90.0 s, 387.1 tps, lat 111.555 ms stddev 24.603
progress: 100.0 s, 370.2 tps, lat 115.930 ms stddev 37.261
progress: 110.0 s, 382.0 tps, lat 113.123 ms stddev 24.202
progress: 120.0 s, 389.1 tps, lat 112.744 ms stddev 21.550
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 50
number of threads: 2
duration: 120 s
number of transactions actually processed: 43432
latency average = 120.280 ms
latency stddev = 93.932 ms
average connection time = 5.085 ms
tps = 361.811508 (including reconnection times)
```
 
Результат в целом не сильно отличается. Так же проверим использование огромных страниц:

 ```bash
 postgres@pg14-srv01:~$ grep ^HugePages /proc/meminfo
HugePages_Total:     569
HugePages_Free:      289
HugePages_Rsvd:      255
HugePages_Surp:        0
```

Как видим, страницы активно используются.

 Теперь отключим параметр syncronous_commit, как делали  в задании с журналами.
 Выполним перезапуск сервера и запустим предыдущие тесты.
***

### Тест 1.2:

 ```bash
 postgres@pg14-srv01:~$ pgbench -c 8 -C -j 2 -P 10 -T 120 -M extended testdb
pgbench (14.6 (Ubuntu 14.6-1.pgdg20.04+1))
starting vacuum...end.
progress: 10.0 s, 414.8 tps, lat 15.094 ms stddev 4.628
progress: 20.0 s, 422.8 tps, lat 14.825 ms stddev 4.564
progress: 30.0 s, 421.9 tps, lat 14.851 ms stddev 4.495
progress: 40.0 s, 422.9 tps, lat 14.825 ms stddev 4.443
progress: 50.0 s, 426.5 tps, lat 14.689 ms stddev 4.435
progress: 60.0 s, 427.6 tps, lat 14.630 ms stddev 4.452
progress: 70.0 s, 432.2 tps, lat 14.489 ms stddev 4.398
progress: 80.0 s, 429.8 tps, lat 14.595 ms stddev 4.462
progress: 90.0 s, 424.7 tps, lat 14.733 ms stddev 4.583
progress: 100.0 s, 427.5 tps, lat 14.645 ms stddev 4.517
progress: 110.0 s, 431.3 tps, lat 14.512 ms stddev 4.440
progress: 120.0 s, 430.1 tps, lat 14.568 ms stddev 4.509
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 8
number of threads: 2
duration: 120 s
number of transactions actually processed: 51127
latency average = 14.703 ms
latency stddev = 4.497 ms
average connection time = 3.945 ms
tps = 426.026743 (including reconnection times)
```

По сравнению с предыдущим тестом (1.1) видим прирост tps и количества транзакций.
Выполним второй тест.
***

### Тест 2.2:

```bash
postgres@pg14-srv01:~$ pgbench -c 50 -C -j 2 -P 10 -T 120 -M extended testdb
pgbench (14.6 (Ubuntu 14.6-1.pgdg20.04+1))
starting vacuum...end.
progress: 10.0 s, 392.0 tps, lat 112.834 ms stddev 13.992
progress: 20.0 s, 394.9 tps, lat 113.324 ms stddev 13.931
progress: 30.0 s, 396.2 tps, lat 112.843 ms stddev 14.845
progress: 40.0 s, 376.1 tps, lat 118.769 ms stddev 17.984
progress: 50.0 s, 383.6 tps, lat 116.903 ms stddev 15.197
progress: 60.0 s, 369.7 tps, lat 121.198 ms stddev 17.248
progress: 70.0 s, 405.2 tps, lat 110.393 ms stddev 14.042
progress: 80.0 s, 407.4 tps, lat 109.875 ms stddev 13.556
progress: 90.0 s, 403.6 tps, lat 110.596 ms stddev 14.328
progress: 100.0 s, 408.9 tps, lat 109.355 ms stddev 13.504
progress: 110.0 s, 410.5 tps, lat 108.793 ms stddev 13.431
progress: 120.0 s, 409.0 tps, lat 109.640 ms stddev 13.305
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 50
number of threads: 2
duration: 120 s
number of transactions actually processed: 47613
latency average = 112.708 ms
latency stddev = 15.214 ms
average connection time = 4.921 ms
tps = 396.651615 (including reconnection times)
```

Второй тест так же отличается по производительности, но не настолько,как в тесте с меньшей нагрузкой(2.1).

- [Назад](README.md)