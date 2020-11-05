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


##### 切换kubeconfig

* 默认kubeconfig保存在 ~/.kube/config 文件中，里面可以存多个集群的信息。
  
  ```
  kubectl config current-context
  kubectl config use-context CONTEXT_NAME
  kubectl config get-contexts
  kubectl config get-clusters
  ```

##### 管理coreDNS

在先前k8s版本中，使用的是kube-dns，在k8s 1.12之后被CoreDNS替代。coreDNS是通过 [Corefile](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/) 管理的，可以通过利用[hosts plugin](https://coredns.io/plugins/hosts/)编辑coredns的configmap来添加自定义dns条目   
```
kubectl edit configmap coredns -n kube-system
```

在corefile中添加下面的几项   
```
    example.org {
      hosts {
        11.22.33.44 www.example.org
        fallthrough
      }
    }
```

然后可以起一个测试dns的pod来测一下解析
```
 kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml
```


不过在云平台托管的k8s中，如Azure的AKS中，无权限编辑 Corefile，以Azure为例，Azure提供的aks的coredns的deployment中，添加了对挂载的volume的支持，通过查看coredns的deployment可以看到，默认挂载了一个叫做 coredns-custom的ConfigMap，因此我们可以创建一个名为 coredns-custom的configmap，在这个configmap中来添加自定义DNS解析的条目.

首先先看一下默认的配置:  
```
kubectl describe deployment coredns -n kube-system


  Volumes:
   config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      coredns
    Optional:  false
   custom-config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      coredns-custom
    Optional:  true
   tmp:
```

添加自定义解析，将 www.example.org 解析到 11.22.33.44，需要注意的是：configmap的名字必须为 coredns-custom，这样CoreDNS才能识别，其他名字无法识别   
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom # this is the name of the configmap you can overwrite with your changes
  namespace: kube-system
data:
    test.override: | # you may select any name here, but it must end with the .override file extension
          hosts example.org { 
              11.22.33.44 www.example.org
          }
```

之后需要重启coreDNS才能生效  
```
kubectl rollout restart -n kube-system deployment/coredns
```


