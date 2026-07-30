Helm install
```
wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz  
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz 
sudo mv linux-amd64/helm /usr/local/bin/helm  
sudo chmod 777 /usr/local/bin/helm # give permissions 
helm version
```
Ingress install
```
kubectl create ns ingress-nginx 
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml
```