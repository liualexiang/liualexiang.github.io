#### 有关Azure disk的深入理解
##### Premium SSD 和 Standard SSD 有什么区别？

* Premium SSD和Standard SSD在相同尺寸大小的情况下，IOPS基本相同的
示例：Premium SSD P1卷大小为4G，Provisioned IOPS为120，Provisioned Throughputw为25MB/s(不考虑burst)；Standard SSD E1的卷大小4G，IOPS为 Up to 120,Troughput为Up to 25MB/s。

* 在对于IOPS和Throughput的解释上

Premium SSD是这么说的：
Premium SSD disks are designed to provide low single-digit millisecond latencies and target IOPS and throughput described in the preceding table 99.9% of the time.

Standard SSD 是这么说的：
Standard SSDs are designed to provide single-digit millisecond latencies and the IOPS and throughput up to the limits described in the preceding table 99% of the time.

区别在于Premium SSD设计的时候，提供的是较低的几毫秒延时，但Standard SSD是几毫秒延时。不过从实际测试来看，单一io的延时均为 2-3ms 左右（测试方法：使用fio 顺序write 将单线程io打满，用1s除以所完成的iops数）

* 所以Premium SSD和 Standard SSD更主要的区别就在于burst上了。Premium SSD能够在一定的时间内提供burst到baseline以上（最多3500）的IOPS，以满足业务临时对磁盘性能突增的要求，但Standard最多只能到达baseline的IOPS，在业务瞬间spike的时候，就会出现throttle的情况。

##### Azure SSD 会进行IO Merge 吗？
* Azure Standard SSD 和 Premium SSD 对单个IO最大支持256KB，如果系统内发起的单个IO大于256KB，如257KB则会按2个IO计算。
* 对于小于256KB的IO，如2个128KB的顺序IO，Azure不会将其merge成1个256KB的大IO.
* 随机IO在任何情况下都不会merge的，毕竟是对磁盘的不同位置进行操作.

##### 在对磁盘做IO Benchmark的注意事项
* 首先要考虑VM支持最大的IOPS以及VM机型的网络带宽限制，如果机型选择过小，有可能系统瓶颈在VM上，而不在磁盘本身。
* 要考虑使用多线程测试。在使用单线程测试的时候，每个线程发起IO请求，都要等这个IO完成之后才会进行下一个IO。经测试，每个IO的延时在2-3ms，因此单线程测试的时候，最高IOPS只能达到300--400左右，均为达到VM和Disk的瓶颈。这时候在fio命令中，可以通过 --numjobs 参数指定更高的线程数来突破此限制。

参考资料1：
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disks-types

参考资料2：
*By definition, each "thread" is a single-threaded IO operation. On a per-thread basis, a new IO will not be started until the preceding IO has completed. This fairly clearly gives us a relationship between the time that each operation takes to complete (ie, the latency) and the number of operations that can be competed per time unit (ie, IOPS). If each IO takes 0.1 seconds to run (100ms), then fairly clearly the maximum number of IOPS that can be generated is 10. If each IO takes 0.02 seconds (20ms), then we can do 50 IOPS.*

https://blog.docbert.org/queue-depth-iops-and-latency/
