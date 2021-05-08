# Azure LB Deep Dive

## 有关LB底层设计原理
Azure LB 不管什么模式，永远都是DSR(Direct Server Response)模式，具体说明如下：

* 进来流量  
Client --> LB --> 一组MUX形成一个ring --> 物理机Hyper-V --> Virtual Switch --> VFP (Virtual Filter Platform) --> Azure VM 

* 出去流量  
Azure VM --> VFP --> Internet

* 上述概念说明   

  * MUX 是做五元组hash的，能决定将流量发给哪个物理机。
  * 只有在进来的时候，流量才经过MUX，出去的时候不经过MUX。 
  * 对于Internal LB，只有第一次五元组的时候，流量经过MUX，以后VFP会cache住这个记录，VM间通信不再经过VFP

## Float IP 的解释

azure LB FloatIP启用之后，在后端的VM上，抓包看到的IP是负载均衡器的IP（这也就是为何要将负载均衡器的FrontIP配置到VM的loopback上）。如果不启用，则抓包看到的IP是当前VM的IP。  

linux 在loopback上添加ip的命令：  
``` sudo ip addr add 20.55.205.90 dev lo```

已测试,参考截图 [FloatIP.png](FloatIP.png)   
[启用FloatIP抓包](floatip.pcap)，[不启用FloatIP抓包](nofloatip.pcap)

  * 不启用float IP的情况下，在进来的流量的时候，VFP会将destination IP由LB的IP改成VM的内网IP。出去的时候，VM将流量发给VTP，然后VTP将源IP由VMIP改成LB FrontIP发出去。
  * 启用Float IP的情况下，VFP就不做IP转换的操作了，出去流量是由VM到VFP直接出去的。
  * 无论是否启用Float IP，出去流量都不经过MUX，这也就是为何说Azure LB永远工作在DSR(Direct Server Response)模式下

