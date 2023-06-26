# Установка minikube на ВМ или Yandex Cloud

Чтобы установить minikube нужно выполнить несколько простых действий:

```bash
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \ 
$ chmod +x minikube
$ sudo mkdir -p /usr/local/bin/
$ sudo install minikube /usr/local/bin/
```
***

После установки нужно запустить миникуб , указав драйвер ВМ. у меня используется kvm

```bash
$ minikube start --vm-driver=kvm2
```

В конце процесса дожидаемся сообщения:

```text
Готово! kubectl настроен для использования кластера "minikube" и "default" пространства имён по умолчанию
```

Миникуб установлен, можно использовать.
***

Для удобства можно так же вклчить веб-консоль.

```bash
$ minikube dashboard &
```

После ввода команды откроется браузер с консолью миникуба.

***
[Назад](README.md)