# Установка pg_probackup

В связи со спецификой моей работы для решения задачи хотелось использовать ОС Альт Линукс 10.1 в качестве стенда, но столкнулся с рядом сложностей, поэтому пока на Ubuntu)))
Для хранения бэкапов подключен дополнительно диск на 10 ГБ, примонтирован в каталог /var/lib/probackup


```bash
$ cat /etc/os-release
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"

# uname -a
Linux pgsql02 5.4.0-149-generic #166-Ubuntu SMP Tue Apr 18 16:51:45 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux

$ df -h /var/lib/probackup/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb1        10G  104M  9.9G   2% /var/lib/probackup

$ sudo chmod 777 /var/lib/probackup
```

Для установки pg_probackup подключаем репозиторий postgrespro.

```bash
$ sudo sh -c 'echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs) main-$(lsb_release -cs)" > /etc/apt/sources.list.d/pg_probackup.list' &&
 sudo wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG_PROBACKUP | sudo apt-key add - && sudo apt-get update

$ sudo DEBIAN_FRONTEND=noninteractive apt install pg-probackup-15 pg-probackup-15-dbg postgresql-contrib postgresql-15-pg-checksums -y
```

После установки наобходимо настроить каталог для работы с бэкапами. Для этого подключаемся в сессию пользователя postgres и настраиваем переменные окружения.

```bash
$ sudo su postgres
$ echo "BACKUP_PATH=/var/lib/probackup">>~/.bashrc
$ echo "export BACKUP_PATH">>~/.bashrc
$ cd ~
$ . .bashrc
$ echo $BACKUP_PATH
/var/lib/probackup
```

P.S. предпочитаю добавлять в /etc/profile, особенно если сервер используется только для конкретной задачи.


[Назад](README.md)


