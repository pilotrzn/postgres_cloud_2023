# Разворачивание postgres StatefulSet

Для разворачивания используем манифест:

- [postgres](../material/les2/postgres/postgres.yaml)

Перед началом создадим namespace и сделем его по-умолчанию:

```bash
$ kubectl create namespace pg-kube
$ kubectl config set-context --current --namespace=pg-kube
```

Далее, чтобы развернуть postgres, нужно выполнить команду:

```bash
$ kubectl apply -f postgres.yaml

service/postgres created
statefulset.apps/postgres-statefulset created
```

После ввода через некоторое время будет развернут Pod.
***

Проверим возможность подключения к БД через psql. Для начала выполним проборс портов в куб:

```bash 
$ minikube service postgres --url -n pg-kube
http://192.168.58.2:30375
```

В консоли получили информацию для подключения к postgres. Используем информацию для подключения через psql, используя логопасы в манифесте:

```bash
$ psql -h 192.168.58.2 -p 30375 -U myuser -W myapp
Password: 
psql (14.8 (Ubuntu 14.8-0ubuntu0.22.04.1), server 15.3 (Debian 15.3-1.pgdg120+1))
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
Type "help" for help.

myapp=#
```

В результате попадаем в консоль.
***

[Назад](README.md)




