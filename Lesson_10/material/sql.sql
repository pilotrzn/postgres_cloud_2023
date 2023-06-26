Проверка для bigquery
SELECT payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips` 
group by payment_type
order by 3;


Работаем с виртуалкой в gcp

Установка postgres
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'И ставим postgres14
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add 
sudo apt -y update
sudo apt-cache search postgresql | grep postgresql
sudo apt -y install postgresql-14

--Скопировать файлы из разных бакетов
gsutil -m cp gs://chicago10/taxi.csv.000000000000 .

gsutil -m cp gs://chicago70/taxi_trips_000000000000.csv .

--Поставить gcsfuse
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install gcsfuse

--Далее примонтрировать бакет
mkdir gcsfuse
cd gcsfuse/
gcsfuse chicago70 . 


create extension file_fdw;
create server pgcsv foreign data wrapper file_fdw;

create foreign table taxi_trips_fdw_2 (
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
)
server pgcsv
options(filename '/tmp/taxi_trips_000000000000.csv', format 'csv', header 'true', delimiter ',');

postgres=# \timing
Timing is on.
postgres=# select count(*) from taxi_trips_fdw_2;

create table taxi as select * from taxi_trips_fdw_2;
select count(*) from taxi;



create table taxi_trips (
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


COPY taxi_trips(unique_key, 
taxi_id, 
trip_start_timestamp, 
trip_end_timestamp, 
trip_seconds, 
trip_miles, 
pickup_census_tract, 
dropoff_census_tract, 
pickup_community_area, 
dropoff_community_area, 
fare, 
tips, 
tolls, 
extras, 
trip_total, 
payment_type, 
company, 
pickup_latitude, 
pickup_longitude, 
pickup_location, 
dropoff_latitude, 
dropoff_longitude, 
dropoff_location)
FROM PROGRAM 'awk FNR-1 /tmp/taxi_trips_000000000000.csv | cat' DELIMITER ',' CSV HEADER;

select * from pg_stat_progress_copy;

for f in /tmp/taxi_trips_2020_10/taxi*
do
	echo -e "Processing $f file..."
	psql "host=localhost port=5432 dbname=taxi user=postgres sslmode=require" -c "\\COPY taxi_trips FROM PROGRAM 'cat $f' CSV HEADER"
done




\copy (select taxi_id from taxi_trips) to /tmp/taxi_id.csv DELIMITER ',' CSV HEADER
create table taxi as (select taxi_id from taxi_trips);
truncate taxi;

pgloader --type csv                                   \
         --field "taxi_id"         		              \
         --with truncate                              \
         --with "fields terminated by ','"            \
         /tmp/taxi_id.csv                             \
         postgres:///postgres?tablename=taxi


--Запускаем на наше бд запрос
SELECT payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c
FROM taxi_trips
group by payment_type
order by 3;
