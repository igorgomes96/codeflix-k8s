kubectl apply -f namespace.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f db.yaml
kubectl apply -f db-service.yaml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/25.0.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/25.0.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/25.0.5/kubernetes/kubernetes.yml -n codeflix
kubectl create secret generic db-secret \
  --from-literal=username=root \
  --from-literal=password=root -n codeflix
kubectl apply -f keycloak.yaml
kubectl apply -f keycloak-import.yaml
kubectl get keycloaks/keycloak -o go-template='{{range .status.conditions}}CONDITION: {{.type}}{{"\n"}}  STATUS: {{.status}}{{"\n"}}  MESSAGE: {{.message}}{{"\n"}}{{end}}' -n codeflix -w
helm install rmq-operator bitnami/rabbitmq-cluster-operator
kubectl create secret generic rabbitmq-secret \
  --from-literal=username=adm_videos \
  --from-literal=password=123456 -n codeflix
kubectl apply -f rabbitmq.yaml
kubectl apply -f rabbitmq-topology.yaml
kubectl create secret generic gcp-credentials-secret \
  --from-file=gcp_credentials.json=.secrets/gcp_credentials.json -n codeflix
kubectl apply -f admin-catalog.yaml
kubectl apply -f admin-catalog-service.yaml

cluster_name=fullcycle
account=123821430529
region=us-east-2
vpc_id=vpc-0d31797de4d69506c
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$cluster_name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$region \
  --set vpcId=$vpc_id
kubectl get deployment -n kube-system aws-load-balancer-controller -w
kubectl apply -f ingress.yaml


kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml

PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -n codeflix -o go-template='{{.data.elastic | base64decode}}')
kubectl port-forward service/elasticsearch-es-http 9200 -n codeflix


kubectl get beat -n codeflix

kubectl port-forward service/kibana-kb-http 5601 -n codeflix

kubectl get secret elasticsearch-es-elastic-user -n codeflix -o=jsonpath='{.data.elastic}' | base64 --decode; echo