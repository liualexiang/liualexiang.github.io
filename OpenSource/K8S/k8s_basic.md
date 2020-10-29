#### K8S 常用的几个yaml文件

##### kubectl cheetsheet

* kubectl command   
  https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#autoscale
<br />


* 直接创建pod(在先前版本的k8s创建的是deployment)  
   ``` kubectl run nginx --image=nginx ```
<br />

* 创建pod的时候指定资源限制，如果只指定limits，不指定requests，那么requests就和limits一样。但是如果指定了requests，没有指定limits，则没有limits限制。  
  ``` kubectl run nginx-pod --image=nginx --limits cpu=200m,memory=512Mi --requests 'cpu=100m,memory=256Mi' ```
<br /> 

* 直接创建 deployment  
  ``` kubectl create deployment nginx --image=nginx ```
<br />

* 显示pod的label
``` kubectl get pod --show-labels ```

* 给 pod 打label
``` kubectl label pod nginx-test-6557497784-2wwsq labeltest=labelvalue ```

* 暴漏pod的端口为load balancer  
  ``` kubectl expose pod nginx --port 80 --target-port 80 --type LoadBalancer ```
<br />

* 暴漏deployment为load balancer  
  ``` kubectl expose deployment nginx-deployment --port 80 --type LoadBalancer ```
<br />

* 使用HPA自动扩容pod(即使deployment没有指定资源limit也能创建hpa，但是不工作的)  
  ``` kubectl autoscale deployment nginx-deployment --cpu-percent=50 --min=3 --max=10 ```
  ``` kubectl get hpa ```

##### 常用测试的yaml

* [创建deployment](nginx-dep.yaml)
* [创建svc](nginx-dep-svc.yaml)
* [创建hpa自动扩容](nginx-dep-hpa.yaml)
  

##### k8s 证书管理

* 通过cert-manager来管理证书  
* cert-manager 是通过CRD(custom resource defination) 来管理证书， 会起几个cert-manager的pod，如果遇到问题，可以排查这几个pod状态。
  https://cert-manager.io/docs/installation/kubernetes/
<br />

* 通过let's Encrypt自动申请证书。申请之后，可以用 kubectl get certificate 来查看申请到的证书，状态为Ready时表示可用
  https://docs.microsoft.com/en-us/azure/aks/ingress-tls
  <br />

* 故障排查
  
 ``` 
 kubectl get certificate
 kubectl get certificaterequest
 kubectl get clusterissuers
 ```
