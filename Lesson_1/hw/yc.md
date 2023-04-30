# Создание виртуальной машины на Yandex cloud

Перед началом развертывания был создан ssh ключ, открытый ключ сохранен в файл aavdonin.txt. После развертывания удалось подключиться под пользователем ubuntu с указанием имени ключа. Так ж предварительно был установлен и настроен Yandex cloud CLI.

Команда для развертывания: 

```bash
yc compute instance create \
  --name pgsrv01 \
  --hostname pgsrv01 \
  --cores 2 \
  --memory 4 \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
  --zone ru-central1-b \
  --metadata-from-file ssh-keys=/home/aavdonin/.ssh/aavdonin.txt
```

Установка Postgres:

```bash
sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql unzip mc
```

После установки проверяем работу Postgres:

```bash
ubuntu@pgsrv01:~$ pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

Для работы был изменен пароль пользователя БД postgres.
Скорректированы параметры:
 - listen_address = "*";
 - shared_buffers = 1GB;

Остальное настраивать не стал, для теста этого достаточно.

В конфигурации pg_hba изменен метод аутентификации для local на md5.
После изменений перезапущен сервер postgres.

[Назад](README.md)
