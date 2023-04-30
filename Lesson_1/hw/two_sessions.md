# Пример работы изоляции

- создание бд.

```sql
postgres=# create database iso_test;
postgres=# \c iso_test;
iso_test=# alter database iso_test set search_path to iso,public;
```
  - создание и наполнение таблицы.
  
```sql
iso_test=# create table iso.persons(id serial, first_name text, second_name text);
iso_test=# insert into persons(first_name, second_name) values('ivan', 'ivanov'),('petr', 'petrov');
iso_test=# \set AUTOCOMMIT off;
```

## Приступаем к тестам.

- открыты 2 консоли. Подключены к новой БД. В обиех консолях отключаем AUTOCOMMIT

```sql
 iso_test=# \set AUTOCOMMIT OFF
 ```

 - текущий уровень изоляции

```sql
iso_test=*# show transaction isolation level;
 transaction_isolation 
-----------------------
 read committed
```

- в первой консоли выполняем

```sql
iso_test=# insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1
```

- во второй

```sql
iso_test=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```

Согласно правилам уровня Read committed -  вторая транзакция видит только зафиксированные данные, а незафиксированные другими транзакциями не видны. После фиксации изменений первой транзакции(COMMIT;) во второй запрос выводит:

```sql
iso_test=*# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```

- меняем уровень изоляции, команду выполняем в обеих консолях

```sql
iso_test=# set transaction isolation level repeatable read;
```

- в первой консоли выполняем вставку
  
```sql
iso_test=*# insert into persons(first_name, second_name) values('sveta', 'svetova');
INSERT 0 1
```

- во второй консоли результат с прошлого теста

```sql
iso_test=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```

В первой консоли выполняем COMMIT, во второй пробуем вывести запрос, - результат тот же. Выполняем во второй COMMIT, после этого выполняем запрос и видим новую строку, вставленную в первой транзакции.

Тут разница между заданными уровнями видна четко:

при уровне repeatable read транзакция видит только те данные, которые были зафиксированы до ее начала, но не видит изменений других транзакции, даже если изменения зафиксированы. Это отличие от read committed - транзакция видит снимок данных на момент выполнения первого оператора. В read committed же видимость на этапе выполнения текущего оператора, то есть изменения, примененные другими транзакциями будут видны операторам текущей. В repeatable read будут видны только по завершении текущей транзакции.

[Назад](README.md)