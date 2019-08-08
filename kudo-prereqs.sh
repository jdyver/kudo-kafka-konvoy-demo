kubectl create -f https://raw.githubusercontent.com/kudobuilder/kudo/0.5.0/docs/deployment/00-prereqs.yaml
sleep 1
kubectl create -f https://raw.githubusercontent.com/kudobuilder/kudo/0.5.0/docs/deployment/10-crds.yaml
sleep 1
kubectl create -f https://raw.githubusercontent.com/kudobuilder/kudo/0.5.0/docs/deployment/20-deployment.yaml
