# Загрузка данных Чикагского такси

Загрузим в наш кластер уже известный датасет Чикагского такси.
***

## Подключимся к кластеру:

```bash
$ cockroach sql --insecure
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v23.1.5 (x86_64-pc-linux-gnu, built 2023/07/01 01:33:00, go1.19.10) (same version as client)
# Cluster ID: 30e9272c-c09c-420b-9834-36b1631c7bb5
#
# Enter \? for a brief introduction.
#
root@localhost:26257/defaultdb> \l
List of databases:
    Name    | Owner | Encoding |  Collate   |   Ctype    | Access privileges
------------+-------+----------+------------+------------+--------------------
  defaultdb | root  | UTF8     | en_US.utf8 | en_US.utf8 |
  postgres  | root  | UTF8     | en_US.utf8 | en_US.utf8 |
  system    | node  | UTF8     | en_US.utf8 | en_US.utf8 |
(3 rows)
root@localhost:26257/defaultdb> \du
List of roles:
  Role name |                   Attributes                    | Member of
------------+-------------------------------------------------+------------
  root      | Superuser, Create role, Create DB               | {admin}
  admin     | Superuser, Create role, Create DB               | {}
  node      | Superuser, Create role, Create DB, Cannot login | {}
(3 rows)
```
***
## Создадим базу и таблицу.

В качестве демонстрации используем роль root. В продуктивных средах рекомендуется использовать роли с ограничениями в правах.

```sql
root@localhost:26257/defaultdb> create database taxi;
CREATE DATABASE

Time: 35ms total (execution 35ms / network 0ms

root@localhost:26257/defaultdb> \c taxi
using new connection URL: postgresql://root@localhost:26257/taxi?application_name=%24+cockroach+sql&connect_timeout=15&sslmode=disable

root@localhost:26257/taxi> create table taxi_trips (
                        -> unique_key text,
                        -> taxi_id text,
                        -> trip_start_timestamp TIMESTAMP,
                        -> trip_end_timestamp TIMESTAMP,
                        -> trip_seconds bigint,
                        -> trip_miles numeric,
                        -> pickup_census_tract bigint,
                        -> dropoff_census_tract bigint,
                        -> pickup_community_area bigint,
                        -> dropoff_community_area bigint,
                        -> fare numeric,
                        -> tips numeric,
                        -> tolls numeric,
                        -> extras numeric,
                        -> trip_total numeric,
                        -> payment_type text,
                        -> company text,
                        -> pickup_latitude numeric,
                        -> pickup_longitude numeric,
                        -> pickup_location text,
                        -> dropoff_latitude numeric,
                        -> dropoff_longitude numeric,
                        -> dropoff_location text
                        -> );
CREATE TABLE

Time: 27ms total (execution 25ms / network 2ms)
```
***
## Загрузка данных 

Перед загрузкой данные *.csv скопированы на одну из нод кластера. Чтобы начать процесс загрузки в БД файлы необходимо поместить в локальное хранилище сервера, как описано в [документации](https://www.cockroachlabs.com/docs/stable/cockroach-nodelocal-upload). Для этого создадим bash скрипт:

```bash
#!/bin/bash
cd /var/lib/cockroach/dump;

for file in taxi.csv.*; do
        echo "$file file start to nodelocal";
        cockroach nodelocal upload $file taxi/$file --insecure;
done;
```

Общее время загрузки: 218min
***

Далее загружаем данные непосредственно в БД. Так же, воспользуемся скриптом:

```bash
#!/bin/bash
cd /var/lib/cockroach/cockroach-data/extern/taxi;

time for file in taxi.csv.*;
  do
    echo -e "Load file $file";
    cockroach  sql -d taxi -e \
        "IMPORT INTO taxi_trips (unique_key, taxi_id, trip_start_timestamp, trip_end_timestamp, trip_seconds, \
        trip_miles, pickup_census_tract, dropoff_census_tract, pickup_community_area, dropoff_community_area, fare, \
        tips, tolls, extras, trip_total, payment_type, company, pickup_latitude, pickup_longitude, pickup_location, \
        dropoff_latitude, dropoff_longitude, dropoff_location) CSV DATA ('nodelocal://1/taxi/$file') WITH DELIMITER=',', skip='1',nullif = '';" \
        --insecure;
  done;
```

Общее время загрузки около 9 минут.
***

## Запрос данных

Выполняем запрос  как в прошлых заданиях по кликхаусу и постгрес

```sql
root@localhost:26257/taxi> SELECT payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c 
FROM t.taxitrips
group by payment_type
order by 3;
  payment_type | tips_percent |    c
---------------+--------------+-----------
  Prepaid      |            0 |        6
  Way2ride     |           12 |       27
  Split        |           17 |      180
  Dispute      |            0 |     5596
  Pcard        |            2 |    13575
  No Charge    |            0 |    26294
  Mobile       |           16 |    61256
  Prcard       |            1 |    86053
  Unknown      |            0 |   103869
  Credit Card  |           17 |  9224956
  Cash         |            0 | 17231871
(11 rows)

Time: 63.334s total (execution 63.327s / network 0.007s)

```
Собственно результат запроса.
***

## Какие проблемы были

В запросе можно увидеть, что я обращаюсь к совершенно другой таблице, нежели та, которую создавал. Случилось так потому, что при попытке загрузить данные скриптом я пару раз ошибся в пути к nodelocal и еще в каком-то моменте, что привело к ошибке 

```
ERROR: relation "taxi_trips" is offline: importing
```

Как ее устранить и как удалить "битую" таблицу я не выяснил, но честно сказать, особо и не искал. 


***
[Назад](README.md)