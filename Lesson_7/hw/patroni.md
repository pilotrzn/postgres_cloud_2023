# Кластер patroni

Установка PostgreSQL и patroni будет выполнена также с помощью ansible.
Тут вкратце опишу этапы установки и приложу конфигурационные файлы.
***

## Установка postgres 14

### Подключаем репозиторий 

```bash
$ sudo apt update && sudo apt upgrade -y 
$ echo deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main | sudo tee -a /etc/apt/sources.list.d/pgdg.list 
$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
$ sudo apt-get update && sudo apt -y install postgresql-14'
```

После установки postgres неоходимо остановить запущенный кластер и выключить сервис(disable).
***

## Устанавливаем patroni

Сервис patroni устанавливается из репозитория pypa при наличии подключения к интернету. Иначе используется либо локальное хранилище пакетов, либо установка заранее скачанных пакетов на компьютере с доступом в интернет(вариант если у нас имеется закрытый контур)

Перед установкой проверяем, установлены ли пакеты и если отсутствуют, устанавливаем

  - python3
  - python3-apt
  - python3-psycopg2
  - python3-pip

Далее ставим пакеты для работы patroni.

```bash
$ pip3 install psycopg2-binary
$ pip3 install patroni
$ pip3 install patroni[etcd]
```
***

### Настройка сервиса

Для работы сервиса создаем файл сервиса в каталоге /etc/systemd/system

- [patroni.service](patroni.service)
***

### Конфигурирование

На каждой ноде с установленным postgres создаем конфигурационный файл в каталоге /etc/patroni/patroni.yml

- [patroni](patroni_1.yml)

В конфиге сразу выполняется тюнинг postgres под параметры сервера. Дальшейшие настройки в зависимости от выполняемых задач в БД или нагрузки изменяются через patroni:

```bash
$ patronictl -c /etc/patroni/patroni.yml edit-config
```

Для корректной работы необходимо создать каталог /var/log/patroni

Так же рекомендуется задать права для пользователя postgres для каталогов:

- /var/log/patroni
- /var/lib/postgresql/
- /etc/patroni
***

### Инициализация БД

Если конфигурация файла [patroni](patroni_1.yml) выполнена корректно, то после запуска сервиса patroni будет автоматически проинициализирован новый кластер postgres, созданы необходимые для работы пользователи и заданы пароли(пользователи и пароли указаны в  секции postgresql/authentification)

После запуска сервер, на котором был запущен patroni автоматически становится мастером. Далее можно запустить patroni на остальных серверах БД. В результате, если все выполнено корректно, можно увидеть следующий результат:

```bash
postgres@pgsql01:~$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: ya-cloud ----+--------------+---------+----+-----------+
| Member  | Host        | Role         | State   | TL | Lag in MB |
+---------+-------------+--------------+---------+----+-----------+
| pgsql01 | 10.129.0.15 | Leader       | running |  1 |           |
| pgsql02 | 10.129.0.17 | Sync Standby | running |  1 |         0 |
| pgsql03 | 10.129.0.22 | Replica      | running |  1 |         0 |
```
 
 В моей конфигурации заданы параметры:

- synchronous_mode: true
- synchronous_node_count: 1

Это означает, что у нас синхронная репликация для 1 ноды(отмечена Sync Standby). Остальные возможные ноды будут в асинхронном режиме.


- [Назад](README.md)