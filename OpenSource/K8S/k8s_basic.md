#### K8S 常用的几个yaml文件

##### kubectl cheetsheet

* kubectl command   
  https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#autoscale


* 直接创建pod(在先前版本的k8s创建的是deployment)  
   ``` kubectl run nginx --image=nginx ```


* 创建pod的时候指定资源限制，如果只指定limits，不指定requests，那么requests就和limits一样。但是如果指定了requests，没有指定limits，则没有limits限制。  
  ``` kubectl run nginx-pod --image=nginx --limits cpu=200m,memory=512Mi --requests 'cpu=100m,memory=256Mi' ```


* 直接创建 deployment  
  ``` kubectl create deployment nginx --image=nginx ```


* 暴漏pod的端口为load balancer  
  ``` kubectl expose pod nginx --port 80 --target-port 80 --type LoadBalancer ```


* 暴漏deployment为load balancer  
  ``` kubectl expose deployment nginx-deployment --port 80 --type LoadBalancer ```


* 使用HPA自动扩容pod(即使deployment没有指定资源limit也能创建hpa，但是不工作的)  
  ``` kubectl autoscale deployment nginx-deployment --cpu-percent=50 --min=3 --max=10 ```
  ``` kubectl get hpa ```

##### 常用测试的yaml

* [创建deployment](nginx-dep.yaml)
* [创建svc](nginx-dep-svc.yaml)
* [创建hpa自动扩容](nginx-dep-hpa.yaml)
  