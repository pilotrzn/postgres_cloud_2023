# Работа с большими данными на PostgreSQL


Для начала установим инстанс postgresql. Воспользуемся стендом с установленной ОС Ubuntu 20.04.
Установим PostgreSQL 14.


***
Для тестов используем файлы с данными такси Чикаго:

```text
learning_files/chicago10$ ls -lh
total 9,7G
-rw-rw-r-- 1 255M taxi.csv.000000000000
-rw-rw-r-- 1 255M taxi.csv.000000000001
    ...
-rw-rw-r-- 1 255M taxi.csv.000000000037
-rw-rw-r-- 1 254M taxi.csv.000000000038
```

Для загрузки данных в postgres создадим базу и таблицу в ней:

```sql
postgres=# create database taxi;
postgres=#/c taxi;
taxi=# create table taxi_trips (
unique_key text, 
taxi_id text, 
trip_start_timestamp TIMESTAMP, 
trip_end_timestamp TIMESTAMP, 
trip_seconds bigint, 
trip_miles numeric, 
pickup_census_tract bigint, 
dropoff_census_tract bigint, 
pickup_community_area bigint, 
dropoff_community_area bigint, 
fare numeric, 
tips numeric, 
tolls numeric, 
extras numeric, 
trip_total numeric, 
payment_type text, 
company text, 
pickup_latitude numeric, 
pickup_longitude numeric, 
pickup_location text, 
dropoff_latitude numeric, 
dropoff_longitude numeric, 
dropoff_location text
);
```
***
Данные загружаем скриптиком:

```txt
#!/bin/bash

for f in /home/aavdonin/learning_files/chicago10/taxi*
do
        echo -e "Processing $f file..."
        psql "host=192.168.122.10 port=5432 dbname=taxi user=postgres " -c "\\COPY taxi_trips FROM PROGRAM 'cat $f' CSV HEADER"
done
```
***
После загрузки проверяем размер БД:

```sql
postgres=# \l+ taxi 
                                               List of databases
 Name |  Owner   | Encoding |   Collate   |    Ctype    | Access privileges | Size  | Tablespace | Description 
------+----------+----------+-------------+-------------+-------------------+-------+------------+-------------
 taxi | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |                   | 10 GB | pg_default | 
(1 row)
```
***
Выполним запрос:

```sql
postgres=# \c taxi 
You are now connected to database "taxi" as user "postgres".

taxi=# \timing
taxi=# SELECT payment_type, 
    round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, 
    count(*) as c
FROM taxi_trips
group by payment_type
order by 3;

 payment_type | tips_percent |    c     
--------------+--------------+----------
 Prepaid      |            0 |        6
 Way2ride     |           12 |       27
 Split        |           17 |      180
 Dispute      |            0 |     4921
 Pcard        |            2 |    13566
 No Charge    |            0 |    22628
 Mobile       |           16 |    61255
 Prcard       |            1 |    86039
 Unknown      |            0 |    98051
 Credit Card  |           17 |  8929229
 Cash         |            0 | 16907926
(11 rows)

Time: 33859.327 ms (00:33.859)
```

Данный результат показал 33 сек. Первый запуск произведен в dbeaver, результат был 2м 47с.

Ну и для общей картины план запроса:

```text
 Sort  (cost=1587271.38..1587271.40 rows=9 width=47) (actual time=34423.185..34438.509 rows=11 loops=1)
   Sort Key: (count(*))
   Sort Method: quicksort  Memory: 25kB
   ->  Finalize GroupAggregate  (cost=1587268.64..1587271.23 rows=9 width=47) (actual time=34423.086..34438.476 rows=11 loops=1)
         Group Key: payment_type
         ->  Gather Merge  (cost=1587268.64..1587270.74 rows=18 width=79) (actual time=34423.068..34438.417 rows=33 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Sort  (cost=1586268.61..1586268.64 rows=9 width=79) (actual time=34410.165..34410.167 rows=11 loops=3)
                     Sort Key: payment_type
                     Sort Method: quicksort  Memory: 27kB
                     Worker 0:  Sort Method: quicksort  Memory: 27kB
                     Worker 1:  Sort Method: quicksort  Memory: 27kB
                     ->  Partial HashAggregate  (cost=1586268.34..1586268.47 rows=9 width=79) (actual time=34410.025..34410.034 rows=11 loops=3)
                           Group Key: payment_type
                           Batches: 1  Memory Usage: 32kB
                           Worker 0:  Batches: 1  Memory Usage: 32kB
                           Worker 1:  Batches: 1  Memory Usage: 32kB
                           ->  Parallel Seq Scan on taxi_trips  (cost=0.00..1477416.67 rows=10885167 width=16) (actual time=2.046..30541.830 rows=8707943 loops=3)
 Planning Time: 0.423 ms
 Execution Time: 34438.685 ms
(21 rows)
```
***

[Назад](README.md)
