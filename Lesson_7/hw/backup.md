# Резервное копирование и восстановление 

Использование утилиты pg_probackup в качестве системы резервного копироввания СУБД
***

## Установка

Пакет для установки утилиты pg_probackup доступен в репозитории PostgresPro. Добавим репозиторий к машинам, на которых установлен postgres.

```bash
$ sudo sh -c 'echo "deb [arch=amd64] https://repo.postgrespro.ru/pg_probackup/deb/ $(lsb_release -cs) main-$(lsb_release -cs)" > /etc/apt/sources.list.d/pg_probackup.list'
$ sudo wget -O - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG_PROBACKUP | sudo apt-key add -
$ sudo apt-get update
```

Установим сам pg_probackup

```bash
$ sudo apt install pg-probackup-14 pg-probackup-14-dbg postgresql-14-pg-checksums -y
```
***

## Подготовка к использованию

Для тестирования probackup к одной из машин(реплике) я подключаю дополнительный диск, монтирую его в специально созданный для бекапов каталог. После добавляю переменную окружения

```bash
$ sudo mkdir /var/lib/postgresql/backups
$ sudo sh -c 'echo "/dev/vdc1 /var/lib/postgresql/backups xfs noatime,nodiratime,noexec 0 0" >> /etc/fstab'
$ sudo mount -a
$ sudo chown -R postgres:postgres /var/lib/postgresql/backups
$ sudo -iu postgres
$ echo "BACKUP_PATH=/var/lib/postgresql/backups">>~/.bash_profile
$ echo "export BACKUP_PATH">>~/.bash_profile
$ . .bash_profile
$ echo $BACKUP_PATH
/var/lib/postgresql/backups
```
***

## Инициализация каталога

Для выполнения резервного копирования инициализируем каталог под пользователем postgres(выполняется на реплике pgsql02):

```bash
$ pg_probackup-14 init
INFO: Backup catalog '/var/lib/postgresql/backups' successfully initialized
$ pg_probackup-14 add-instance --instance 'data-pgsql02' -D /var/lib/postgresql/14/data/
INFO: Instance 'data-pgsql02' successfully initialized
```
***

## БД и роль для выполнения РК

Создадим БД для подключения при РК:

```sql
postgres=# create database backupdb;
```

Создадим роль БД для выполнения РК:

```sql
postgres=# create user backup password 'backup';
postgres=# ALTER ROLE backup NOSUPERUSER;
postgres=# ALTER ROLE backup WITH REPLICATION;
postgres=# \c backupdb;
backupdb=# GRANT USAGE ON SCHEMA pg_catalog TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.current_setting(text) TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_is_in_recovery() TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_start_backup(text, boolean, boolean) TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_stop_backup(boolean, boolean) TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_create_restore_point(text) TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_wal() TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_last_wal_replay_lsn() TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.txid_current() TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.txid_current_snapshot() TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.txid_snapshot_xmax(txid_snapshot) TO backup;
backupdb=# GRANT EXECUTE ON FUNCTION pg_catalog.pg_control_checkpoint() TO backup;
```

Так же я добавил запись в файл pgpass для нового пользователя. В hba_conf ничего добавлять не стал, так как это локальный тестовый кластер и присутствует запись типа host all all ip/mask md5.
***

## Создание бэкапа

Выполним предварительный конфиг:

```sql
pg_probackup-14 set-config --instance=data-pgsql02 --pguser=backup --pgdatabase=backupdb
```

Запустим процесс РК:

```bash
$ pg_probackup-14 backup --instance=data-pgsql02 --stream --temp-slot
INFO: Backup start, pg_probackup version: 2.5.12, instance: data-pgsql02, backup ID: RWIMDW, backup mode: FULL, wal mode: STREAM, remote: false, compress-algorithm: none, compress-level: 1
INFO: This PostgreSQL instance was initialized with data block checksums. Data block corruption will be detected
INFO: Backup RWIMDW is going to be taken from standby
INFO: Database backup start
INFO: wait for pg_start_backup()
INFO: Wait for WAL segment /var/lib/postgresql/backups/backups/data-pgsql02/RWIMDW/database/pg_wal/000000030000000000000044 to be streamed
INFO: PGDATA size: 1258MB
INFO: Current Start LSN: 0/440000D0, TLI: 3
INFO: Start transferring data files
INFO: Data files are transferred, time elapsed: 4s
INFO: wait for pg_stop_backup()
INFO: pg_stop backup() successfully executed
INFO: stop_lsn: 0/462AA3A0
WARNING: Could not read WAL record at 0/462AA3A0: invalid record length at 0/462AA3A0: wanted 24, got 0
INFO: Wait for LSN 0/462AA3A0 in streamed WAL segment /var/lib/postgresql/backups/backups/data-pgsql02/RWIMDW/database/pg_wal/000000030000000000000046
```

Дальше следует серия записей о том, что не может быть прочитана WAL запись:

```text
WARNING: Could not read WAL record at 0/462AA3A0: invalid record length at 0/462AA3A0: wanted 24, got 0
```

Данная ошибка быдет продолжаться до тех пор, пока не произойдет запись или смещение WAL. Для проверки выполним вставку каких-либо данных или команду pg_switch_wal(), после чего увидим записи:

```text
INFO: Getting the Recovery Time from WAL
INFO: Syncing backup files to disk
INFO: Backup files are synced, time elapsed: 0
INFO: Validating backup RWIMDW
INFO: Backup RWIMDW data files are valid
INFO: Backup RWIMDW resident size: 1308MB
INFO: Backup RWIMDW completed
```
***

## Просмотр архивов

Для просмотра имеющихся архивов ввести команду:

```bash
$ pg_probackup-14 show

BACKUP INSTANCE 'data-pgsql02'
========================================================================================================================================
 Instance      Version  ID      Recovery Time           Mode  WAL Mode  TLI  Time    Data   WAL  Zratio  Start LSN   Stop LSN    Status
========================================================================================================================================
 data-pgsql02  14       RWIMDW  2023-06-19 19:27:59+00  FULL  STREAM    3/0   21s  1260MB  48MB    1.00  0/440000D0  0/462AA3A0  OK
```
***

## Выполнение инкрементальной копии

Выполним команду создания инкременальной копии:

```bash
pg_probackup-14 backup --instance=data-pgsql02 -b DELTA --stream --temp-slot
```

После завершения выведем список бэкапов:

```bash
$ pg_probackup-14 show

BACKUP INSTANCE 'data-pgsql02'
=========================================================================================================================================
 Instance      Version  ID      Recovery Time           Mode   WAL Mode  TLI  Time    Data   WAL  Zratio  Start LSN   Stop LSN    Status
=========================================================================================================================================
 data-pgsql02  14       RWIMTN  2023-06-19 19:43:31+00  DELTA  STREAM    3/3   10s    35MB  32MB    1.00  0/462AA3A0  0/4755FB28  OK
 data-pgsql02  14       RWIMDW  2023-06-19 19:27:59+00  FULL   STREAM    3/0   21s  1260MB  48MB    1.00  0/440000D0  0/462AA3A0  OK
```

Перед запуском бэкапа я выполнил INSERT 100000 значений в тестовую табличку, чтобы были видны изменения. Кака видно в результате поле Data показывает разницу в данных (инкремент) примерно 35Мб.


***

- [Назад](README.md)