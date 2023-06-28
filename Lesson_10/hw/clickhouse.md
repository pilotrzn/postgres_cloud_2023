# Работа с большими данными на ClickHouse

## Установка 
Используется ВМ с 4 CPU/4 RAM.

Для начала установим сервер ClickHouse:

```bash
$ sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8919F6BD2B48D754
$ echo "deb https://packages.clickhouse.com/deb stable main" | sudo tee -a /etc/apt/sources.list.d/clickhouse.list
$ sudo apt update 
$ sudo apt install clickhouse-server clickhouse-client
$ sudo systemctl start clickhouse-server
```
***

## Конфигурация

```bash
$ sudo mkdir -p /etc/clickhouse-server/{config.d,users.d}
```

Добавим конфигурационные файлы в созданные каталоги

### Доступ к серверу - возможность подключаться удаленно клиентом или dbeaver.

```bash
$ cat /etc/clickhouse-server/config.d/listen.xml 
<?xml version="1.0"?>

<clickhouse>
    <listen_host>0.0.0.0</listen_host>
</clickhouse>
```

### Пользователь myuser

```bash
$ cat /etc/clickhouse-server/users.d/dbuser.xml
<?xml version="1.0"?>

<clickhouse>
    <users>
    <myuser>
        <password>mypass</password>
        <networks>
            <ip>::/0</ip>
    </networks>
        <profile>default</profile>
        <quota>default</quota>
        <allow_databases>
	    <database>taxi</database>
        </allow_databases>
    </myuser>
    </users>
</clickhouse>
```
***

## БД и таблица

Создаем базу и таблицу

```text
click01 :) create database taxi;
click01 :) use taxi;
click01 :) CREATE TABLE taxi.taxi_trips(
    `unique_key` String,
    `taxi_id` String,
    `trip_start_timestamp` Datetime,
    `trip_end_timestamp` DateTime,
    `trip_seconds` Int64,
    `trip_miles` Decimal(70,3),
    `pickup_census_tract` Int64,
    `dropoff_census_tract` Int64,
    `pickup_community_area` Int64,
    `dropoff_community_area` Int64,
    `fare` Decimal(70,3),
    `tips` Decimal(70,3),
    `tolls` Decimal(70,3),
    `extras` Decimal(70,3),
    `trip_total` Decimal(70,3),
    `payment_type` String,
    `company` String,
    `pickup_latitude` Decimal(70,3),
    `pickup_longitude` Decimal(70,3),
    `pickup_location` String,
    `dropoff_latitude` Decimal(70,3),
    `dropoff_longitude` Decimal(70,3),
    `dropoff_location` String
)
ENGINE = MergeTree()
ORDER BY taxi_id;
```
***

## Данные

Для загрузки используем датасет чикагского такси, загрузку выполним с помощью скрипта:

```bash
#!/bin/bash
for f in /home/aavdonin/learning_files/chicago10/taxi*
do
	echo -e "Processing $f file...";
    sed -i 's/UTC//g' $f;
	clickhouse-client -h 192.168.122.16 --port 9000 --user=default --password 123456 -d taxi -q "INSERT INTO taxi_trips FORMAT CSVWithNames" <  $f;
done;
```

## Запрос

Выполним запрос к БД аналогично запросу в ПГ:

```sql
click01 :) SELECT payment_type, 
    round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, 
    count(*) as c
FROM taxi_trips
group by payment_type
order by 3;

┌─payment_type─┬─tips_percent─┬────────c─┐
│ Prepaid      │            0 │        6 │
│ Way2ride     │           12 │       27 │
│ Split        │           17 │      180 │
│ Dispute      │            0 │     4921 │
│ Pcard        │            2 │    13566 │
│ No Charge    │            0 │    22628 │
│ Mobile       │           16 │    61255 │
│ Prcard       │            1 │    86039 │
│ Unknown      │            0 │    98051 │
│ Credit Card  │           17 │  8929229 │
│ Cash         │            0 │ 16907926 │
└──────────────┴──────────────┴──────────┘

11 rows in set. Elapsed: 0.618 sec. Processed 26.12 million rows, 2.07 GB (42.24 million rows/s., 3.35 GB/s.)
```

Результат показал время выполнения  менее 1 секунды.

***
[Назад](README.md)