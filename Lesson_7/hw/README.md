# Домашнее задание


- [Список задач](Task.md)

Работы по развертыванию кластера patroni будут выполнены на Яндекс cloud.
Создано 3 ВМ для etcd, 3 ВМ lkz postgres/patroni/pgbouncer. Для ВМ с postgres так же создан дополнительный диск на 20 Гб для хранения каталога с БД.
Для haproxy создана отдельная ВМ.

Для pg_probackup создана отдельная ВМ.

Процесс развертывания кластеров выполнен с помощью плейбука ansible

- [Кластер etcd](etcd.md)
- [Кластер patroni](patroni.md)
- [pgbouncer и haproxy](pgbouncer.md)
- [Тесты отказоустойчивости](tests.md)

- [Назад](../README.md)