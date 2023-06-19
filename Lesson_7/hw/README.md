# Домашнее задание


- [Список задач](Task.md)

Работы по развертыванию кластера patroni будут выполнены на ВМ Ubuntu 20.04.
Создано:
-  3 ВМ для etcd;
-  3 ВМ для postgres/patroni/pgbouncer. Для ВМ с postgres так же создан дополнительный диск на 20 Гб для хранения каталога с БД.
- 1 ВМ для haproxy;

На всех ВМ используется ОС Ubuntu 20.04.

Процесс развертывания кластеров выполнен с помощью плейбука ansible

- [Кластер etcd](etcd.md)
- [Кластер patroni](patroni.md)
- [pgbouncer](pgbouncer.md)
- [HAproxy](haproxy.md)
- [Тесты отказоустойчивости](tests.md)
- [Резервное копирование](backup.md)

- [Назад](../README.md)