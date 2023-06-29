curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
exit
yc init

# install kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# https://cloud.yandex.ru/docs/managed-kubernetes/quickstart

yc managed-kubernetes cluster get-credentials test-k8s-cluster --external
kubectl config view

yc container cluster list
yc container cluster list-node-groups catqtl2jnk3df4vq2amb
yc compute disk list

kubectl get all --ignore-not-found
kubectl get nodes --ignore-not-found

# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


# add repo for postgres-operator
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
# install the postgres-operator
helm install postgres-operator postgres-operator-charts/postgres-operator
# add repo for postgres-operator-ui
helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui
# install the postgres-operator-ui
helm install postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui

# if you've created the operator using helm chart
kubectl get pod -l app.kubernetes.io/name=postgres-operator

# or helm chart
helm install postgres-operator-ui ./charts/postgres-operator-ui

# if you've created the operator using helm chart
kubectl get pod -l app.kubernetes.io/name=postgres-operator-ui

kubectl port-forward svc/postgres-operator-ui 8081:80

# create a Postgres cluster
kubectl create -f manifests/minimal-postgres-manifest.yaml

# check the deployed cluster
kubectl get postgresql

# check created database pods
kubectl get pods -l application=spilo -L spilo-role

# check created service resources
kubectl get svc -l application=spilo -L spilo-role

export PGPASSWORD=$(kubectl get secret postgres.acid-minimal-cluster.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
export PGSSLMODE=require
psql -U postgres