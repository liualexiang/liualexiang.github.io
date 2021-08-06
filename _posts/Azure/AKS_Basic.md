
- [AKS 基本上手操作](#aks-基本上手操作)
  - [创建AKS](#创建aks)
  - [下载kubectl，并配置kubeconfig](#下载kubectl并配置kubeconfig)
  - [验证集群状态](#验证集群状态)
  - [部署一个简单的nginx deployment，并指定replicas为3](#部署一个简单的nginx-deployment并指定replicas为3)
  - [有关Storage Class和PVC](#有关storage-class和pvc)
  - [创建Service，利用Azure Load Balancer将服务发布出去](#创建service利用azure-load-balancer将服务发布出去)
  - [试用application gateway ingress](#试用application-gateway-ingress)
  - [使用nginx 做为ingress controller(heml3)：](#使用nginx-做为ingress-controllerheml3)
  - [备注: K8s的一些基本知识](#备注-k8s的一些基本知识)
### AKS 基本上手操作
#### 创建AKS

在Azure Portal上可以直接创建AKS，需要注意的是：

1. 可以启用Virtual nodes，但启用Virtual nodes的时候，需要单独为Virtual node启用一个子网，该子网中不能包含其他资源。
2. 如果想要让aks和azure container registry 无缝集成，那么aks认证的时候要选择system-assigned managed identity，而不能选择service principal
3. 在同一个aks集群中，可以创建linux的pool，也可以同时再添加一个windows 的pool。在集群创建之后，也可以再添加pool。创建好的node pool的VM在scale set中可以看到，但在VM中看不到。
4. 在启用multi pool的情况下，AKS 的node是放在scale set中，在VM界面看不到，只能在scale set中管理，如果要启用ssh，可以对scale set的extension中发送ssh public key的方式来启用。如果不启用multi pool，那么创建出来的VM不是被scale set管理，可以直接在VM界面看到。

#### 下载kubectl，并配置kubeconfig
1. 可以直接下载kubectl二进制文件，或使用apt/yum/brew等下载，也可以用az aks install-cli命令下载
2. 使用az cli命令更新kubeconfig文件：az aks update-credentials --resource-group myResourceGroup --name myAKSCluster

#### 验证集群状态

```bash
kubectl get nodes
kubectl get svc
kubectl get pod -n kube-system
```

#### 部署一个简单的nginx deployment，并指定replicas为3

保存下面的文件为 nginx-dep.yaml，然后执行 kubectl apply -f nginx-dep.yaml

```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```
之后执行 kubectl get pod -o wide 看下pod分布状态.

#### 有关Storage Class和PVC

Storage Class定义了创建PV的时候卷的类型，PVC用于动态创建卷
示例：创建一个managed premium disk的storage class。将下面代码复制为azure-premium-sc.yaml，然后执行 kubectl apply -f azure-premium-sc.yaml。下同，后续不再说明

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: managed-premium-retain
provisioner: kubernetes.io/azure-disk
reclaimPolicy: Retain
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
```

然后创建pvc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium-retain
  resources:
    requests:
      storage: 5Gi
```

执行  kubectl get pvc 可以看到pvc已经创建成功，登录Azure Portal上在Disk界面也可以看到这个磁盘。

手动挂载卷，需要记录下刚创建的卷Resource ID，在卷的属性界面可以看到，同时也要指定卷的名字，这个名字是在Azure Portal中看到的名字。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginxpv
spec:
  containers:
  - image: nginx:1.15.5
    name: nginxpv
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 250m
        memory: 256Mi
    volumeMounts:
      - name: azure
        mountPath: /mnt/azure
  volumes:
      - name: azure
        azureDisk:
          kind: Managed
          diskName: kubernetes-dynamic-pvc-07105594-8fca-4f01-90d9-13c2b6db9469
          diskURI: /subscriptions/5fb605ab-c16c-4184-8a02-fee38cc11b8c/resourceGroups/mc_xiangliu_csa_xiangaks_eastus2/providers/Microsoft.Compute/disks/kubernetes-dynamic-pvc-07105594-8fca-4f01-90d9-13c2b6db946但此时操作比较复杂，创建了pv之后，还需要检查下卷名字以及id。我们也可以在一个yaml文件中创建pvc和挂载卷的。
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium-retain
  resources:
    requests:
      storage: 5Gi
---
kind: Pod
apiVersion: v1
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: nginx:1.15.5
    volumeMounts:
    - mountPath: "/mnt/azure"
      name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: azure-managed-disk
```

#### 创建Service，利用Azure Load Balancer将服务发布出去
AKS创建的Load Balancer类型的SVC，默认情况下就是和api server共用同一个lb，不过会添加一个新的front ip address。在load balancer rules里面能够看到转发的具体规则

```yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: lb-for-nginx-dep
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: nginx
```

#### 试用application gateway ingress

* 首先要安装ingress controller，然后才能使用。

创建service principal, 将配置信息保存到parameters.json

```bash
az ad sp create-for-rbac --skip-assignment -o json > auth.json
appId=$(jq -r ".appId" auth.json)
password=$(jq -r ".password" auth.json)
objectId=$(az ad sp show --id $appId --query "objectId" -o tsv)

cat <<EOF > parameters.json
{
  "aksServicePrincipalAppId": { "value": "$appId" },
  "aksServicePrincipalClientSecret": { "value": "$password" },
  "aksServicePrincipalObjectId": { "value": "$objectId" },
  "aksEnableRBAC": { "value": false }
}
EOF

```

* 下载ingress安装文件，创建一个新的resource group (创建az group deployment的过程会比较长，大概5分钟左右)

```bash
wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/deploy/azuredeploy.json -O template.json

resourceGroupName="MyIngressResourceGroup"
location="eastus2"
deploymentName="ingress-appgw"

# create a resource group
az group create -n $resourceGroupName -l $location

# modify the template as needed
az group deployment create \
        -g $resourceGroupName \
        -n $deploymentName \
        --template-file template.json \
        --parameters parameters.json
```

* 设置AAD Pod Identity, 添加 application-gateway-kubernetes-ingress helm 包

```bash
# helm init 可能会失败，提示helm init命令找不到，此时需要检查helm版本，helm 2需要针对helm设置单独的service account，需要helm init，但helm 3取消了这个功能，helm 3可以直接读取kube config
kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml

kubectl create serviceaccount --namespace kube-system tiller-sa
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller-sa
helm init --tiller-namespace kube-system --service-account tiller-sa
helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update
```

* 安装ingress controller helm chart
```bash
applicationGatewayName=$(jq -r ".applicationGatewayName.value" deployment-outputs.json)
resourceGroupName=$(jq -r ".resourceGroupName.value" deployment-outputs.json)
subscriptionId=$(jq -r ".subscriptionId.value" deployment-outputs.json)
identityClientId=$(jq -r ".identityClientId.value" deployment-outputs.json)
identityResourceId=$(jq -r ".identityResourceId.value" deployment-outputs.json)

wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml

```

修改一下变量

```bash
sed -i "s|<subscriptionId>|${subscriptionId}|g" helm-config.yaml
sed -i "s|<resourceGroupName>|${resourceGroupName}|g" helm-config.yaml
sed -i "s|<applicationGatewayName>|${applicationGatewayName}|g" helm-config.yaml
sed -i "s|<identityResourceId>|${identityResourceId}|g" helm-config.yaml
sed -i "s|<identityClientId>|${identityClientId}|g" helm-config.yaml
```

开始安装

```bash
helm install -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --generate-name
```


首先先通过上一步创建nginx deployment，并通过lb将其发布出去，之后再创建application gw ingress

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: appgw-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: lb-for-nginx-dep
          servicePort: 80
```

#### 使用nginx 做为ingress controller(heml3)：

* 对于发布单一应用，可以创建一个ingress，然后发布应用的时候，默认就使用这个ingress
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# create deployment and service
kubectl create deployment nginxtest --image=nginx
kubectl expose deployment nginxtest --port 80


# create ingress and route the traffic to specify service

cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx01-ingress
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginxtest
            port:
              number: 80
EOF

```

* 如果应用比较多，每个应用要使用单独的ingress，那么可以通过ingress.class的方法指定.

```yaml
helm install nginx-ingress ingress-nginx/ingress-nginx  --set kubernetes.io/ingress.class: nginx1

# ingress Route的annotation中指定 ingress.class名字
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: nginx01-ingress-route
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx1
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: nginx01
          servicePort: 80
        path: /
```

* 使用let's encrypt自动申请证书

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx

# 记录下public ip地址, 针对公网域名DNS，设置 *.domain.com 的A记录，指向 ingress public ip
kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller

# 安装 cert-manager，它将自动向let's encrypt 申请证书
kubectl label namespace default cert-manager.io/disable-validation=true
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install \
  cert-manager \
  --version v0.16.1 \
  --set installCRDs=true \
  jetstack/cert-manager

# 创建Cluster Issuer或Issuer。Issuer只在单一namespace可用，但ClusterIssuer可以跨namespace使用。我们这次就创建一个Cluster Issuer

cat << EOF | kubectl apply -f -

apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: test@email.com
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
          podTemplate:
            spec:
              nodeSelector:
                "kubernetes.io/os": linux
EOF


kubectl create deployment testnginx --image=nginx
kubectl expose deployment testnginx --port=80

cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: testweb-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - testweb.liualexiang.com
    secretName: testweb-tls
  rules:
  - host: testweb.liualexiang.com
    http:
      paths:
      - backend:
          serviceName: testnginx
          servicePort: 80
        path: /
EOF
```
kubectl get ingress，获得ingress的HOSTS名字，然后浏览器https访问下，即可访问成功

#### 备注: K8s的一些基本知识
* 使用Azure CNI的网络插件，每一个pod上的ip都直接用了网卡的ip。还有常见的几个网络插件如calico(三层), flannel (overlay)
* Service的类型为Cluster, Nodepod, LoadBalancer，其中cluster模式只能在集群内通信，nodepod模式通过iptables上做了转发，该iptables在每一个node上都有，loadbalancer模式则直接利用了云厂商的4层负载均衡器
* 可以用application gateway替代ingress

�均衡器
* 可以用application gateway替代ingress

