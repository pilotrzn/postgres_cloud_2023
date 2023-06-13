# Тестирование работы отказоустойчивости patroni

Для проверки работоспособности патрони  выключим(перезагрузим машину с текущим мастером)

текущее состояние кластера:

```bash
postgres@pgsql01:~$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: ya-cloud ----+--------------+---------+----+-----------+
| Member  | Host        | Role         | State   | TL | Lag in MB |
+---------+-------------+--------------+---------+----+-----------+
| pgsql01 |192.168.122.50 | Leader       | running |  1 |           |
| pgsql02 |192.168.122.51 | Sync Standby | running |  1 |         0 |
| pgsql03 |192.168.122.52 | Replica      | running |  1 |         0 |
+---------+-------------+--------------+---------+----+-----------+
```

Проверяем подключение через haproxy и состояние сервера:

```sql
$ psql -h 192.168.122.53 -U user1 -p 5000 -d mb4
psql (14.8 (Ubuntu 14.8-0ubuntu0.22.04.1))
Type "help" for help.

mb4=> select pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 f
(1 row)
```

Видим, что подключены к мастеру.
***

Отправляем на перезагрузку мастер:

- сначала видим картину, что мастером стал второй сервер, бывший мастер в состоянии stopped
```bash
postgres@pgsql02:~$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: ya-cloud ----+---------+---------+----+-----------+
| Member  | Host        | Role    | State   | TL | Lag in MB |
+---------+-------------+---------+---------+----+-----------+
| pgsql01 |192.168.122.50 | Replica | stopped |    |   unknown |
| pgsql02 |192.168.122.51 | Leader  | running |  1 |           |
| pgsql03 |192.168.122.52 | Replica | running |  1 |         0 |
+---------+-------------+---------+---------+----+-----------+
```
- через некоторое время видим следующее состояние:
```bash
postgres@pgsql02:~$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: ya-cloud ----+--------------+---------+----+-----------+
| Member  | Host        | Role         | State   | TL | Lag in MB |
+---------+-------------+--------------+---------+----+-----------+
| pgsql01 |192.168.122.50 | Replica      | running |  2 |         0 |
| pgsql02 |192.168.122.51 | Leader       | running |  2 |           |
| pgsql03 |192.168.122.52 | Sync Standby | running |  2 |         0 |
+---------+-------------+--------------+---------+----+-----------+
```

Проверяем состояние подключения:

```sql
mb4=> select pg_is_in_recovery();
server closed the connection unexpectedly
        This probably means the server terminated abnormally
        before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
mb4=> select pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 f
(1 row)

mb4=>
```

Видно, что произошло переключение и снова подключены к мастеру.
***


При отключении мастера, синхронная реплика стала мастером, асинхронная реплика через некоторое время "догнала" новый мастер и стала синхронной. Восстановишийся после перезагрузки бывший мастер стал асинхронной репликой.

в логе второго сервера, который стал мастером видно как произошло изменение:

```text
2023-06-10 20:34:02,878 INFO: no action. I am (pgsql02), a secondary, and following a leader (pgsql01)
2023-06-10 20:34:12,837 INFO: no action. I am (pgsql02), a secondary, and following a leader (pgsql01)
2023-06-10 20:34:22,839 INFO: no action. I am (pgsql02), a secondary, and following a leader (pgsql01)
2023-06-10 20:34:28,989 WARNING: Request failed to pgsql01: GET http://10.129.0.15:8008/patroni (HTTPConnectionPool(host='10.129.0.15', port=8008): Max retries exceeded with url: /patroni (Caused by ProtocolError('Connection aborted.', ConnectionResetError(104, 'Connection reset by peer'))))
2023-06-10 20:34:28,994 WARNING: Could not activate Linux watchdog device: "Can't open watchdog device: [Errno 2] No such file or directory: '/dev/watchdog'"
2023-06-10 20:34:29,000 INFO: promoted self to leader by acquiring session lock
2023-06-10 20:34:29,004 INFO: cleared rewind state after becoming the leader
2023-06-10 20:34:31,188 INFO: no action. I am (pgsql02), the leader with the lock
2023-06-10 20:34:41,018 INFO: Lock owner: pgsql02; I am pgsql02
2023-06-10 20:34:41,039 INFO: Assigning synchronous standby status to ['pgsql03']
2023-06-10 20:34:43,155 INFO: Synchronous standby status assigned to ['pgsql03']
```

Если обратить внимание на время записей в логе, становится понятно, что реакция на падение мастера произошла менее чем за секунду. Обычная работа кластера - запись в лог происходит каждые 10 секунд, записывается состояние сервера. В момент падения мастера патрони не дожидается, пока пройдет 10 секунд, реагирует моментально на потерю мастера.

Но это с учетом отсутствующей нагрузки. В продуктивной среде возможно будет большее время переключения, зависит от загруженности сервера.


- [Назад](README.md)