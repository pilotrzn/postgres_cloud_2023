# Как я разворачивал отказоустойчивое решение на patroni

Мне пришлось разворачивать решение в 2 ЦОДах, связанных между собой единой "размазанной сетью". Здесь опишу текстом, с приведением примеров некоторых конфигов. Суть задачи - сделать катастрофоустойчивое решение на случай переезда клстера СУБД в другой ЦОД или переезда клиента(приложения), работающего с БД.
***

В 1 ЦОДе был развернут кластер patroni из 2 нод postgres  dcs etcd. Для назначения VIP адреса используется пакет vip-manager, который работает в связке с etcd/consul. Способ развертывания не буду тут описывать, на прошлых ДЗ уже выполнялось. 

Дальше пришло задание сделать репликацию во второй ЦОД. Для реализации решили использовать вариант standby cluster patroni. 
***

Настройка кластера ничем не отличается от настройк4и обычного кластера, кроме того, что в конфиге  добавляется блок :

```text
patroni_standby_cluster:
  host: "IP"  # an address of remote master
  port: "5432"  # a port of remote master
  primary_slot_name: "standby_cluster"  
```

Далее, для возможности создать реплику необходимо настроить pg_hba.conf - добавить в файл запись, типа:

```text
host replication replicator IP/mask md5
```

где IP - адрес или адреса машин standby кластера. Эта запись позволит подключиться и выполнить pg_basebackup серверу standby.

После завершения процесса создания базовой копии в логе postgres обнаружил ошибки об отсутствующем слоте репликации. При этом patroni работал без ошибок, запущенному сервису соответствовало состояние Standby Leader. 

Чтобы исправить эту ошибку вручную создал слот репликации на сервере, который указан в конфиге patroni_standby_cluster:host

```sql
postgres=# select pg_create_physical_replication_slot('standby_cluster');
```

После создания слота проблема ушла, состояние репликации так же проверял, данные синронизировались. И далее уже запустил реплику standby кластера. Делал постепенно во избежание нагрузки на мастер standby.
***

в нашем варианте использовался vip-manager, который в случае со standby кластером не применим, так как у каждого кластера свой кластер etcd. Для VIP применили Keepalived. Чтобы адрес "уезжал" всегда на мастера, использовали скрипт:

keepalived.conf

```
global_defs {
   router_id ocp_vrrp
   enable_script_security
   script_user root
}
 
vrrp_script check_pg_status {
   script "/usr/libexec/keepalived/pg_checkstatus.sh"
    interval 6
    fall 3                  # require 3 failures for KO
    init_fail
}
 
vrrp_instance VI_1 {
   interface eth0
   virtual_router_id 51
   priority  100
   advert_int 1
   state  BACKUP
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    track_script {
        check_pg_status
    }
   virtual_ipaddress {
       IP/mask
   }
}
```

pg_checkstatus.sh

```
#!/usr/bin/env bash
set -e
PGHOME=/usr/bin
PGPORT=5432

LOGFILE=/var/log/keepalived/keepalived_pg.log
LOGFILE=/tmp/keepalived_pg.log

SQL1='SELECT pg_is_in_recovery();'

DB_ROLE=`echo $SQL1  |$PGHOME/psql -d postgres -U postgres -At -w`

if [ $DB_ROLE == 't' ] ; then
    echo -e `date +"%F %T"` "`basename $0`: [INFO] PostgreSQL is running in STANDBY mode." >> $LOGFILE
	exit 1
elif [ $DB_ROLE == 'f' ]; then
    echo -e `date +"%F %T"` "`basename $0`: [INFO] PostgreSQL is running in PRIMARY mode." >> $LOGFILE
	exit 0
fi
```
***

### Тесты отказоустойчивости.

Для проверки остановил продуктивный кластер в ЦОД1. Чтобы standby кластер стал мастером, нужно закомментировать блок конфигурации в файле patroni.yml в ЦОД2. Кластер переходит в состояние основного автоматически, перегружать patroni не пришлось. VIP назначился автоматически.

Вернуть основной кластер в продуктив просто не получилось, пришлось выполнить создание standby кластера в ЦОД1 с полным pg_basebackup с ЦОД2. То есть решение со stanby cluster все-таки одностороннее, нет возможности вернуть основной кластер в строй, если standby подняли до основного.

Считаю решение полезным, но пока недоработанным. Но, тут уже много факторов должно учитываться. При падении основного кластера неизвестно как быстро будет устранена проблема, и соответственно неисзвестно сколько данных будет обработано в БД. А хранить большое количество WAL для подержания такого варианта репликации нецелесообразно и дорого.
***

[Назад](README.md)
