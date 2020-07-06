#### Kibana 可视化的一些注意事项

##### Kibana 和ES的集成

默认情况下，解压Kibana之后，直接运行./bin/kibana即可和本机的 ElasticSearch集成(localhost:9200)，但是kibana也监听在本机loccalhost地址上，如果要更改监听地址，那么需要在./conf/kibana.yml文件中指定 server.host: "0.0.0.0"。  
Kibana 默认没有用户名密码，ElasticSearch 可以 通过x-pack插件来启用认证，kibana如果要做认证的话，一般做法是在kibana前端挂一个nginx，然后通过nginx来做认证.  

注意：Kibana一定要和ES版本一致，否则会出错。  
有关更多配置可参考：https://www.elastic.co/guide/en/kibana/current/settings.html

##### 搜索
在[搜索栏](https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html)，可以直接搜某一个字段的值，如果想要精确搜索某些字段的值，可以用"字段:值 AND 字段:值"的方法进行搜索，示例  
```
destIp:10.21.1.208 AND srcPort:23552
```

如果要搜索srcIP不是某个值，示例：  
```
NOT srcIp: 10.21.1.208
```

##### 创建可视化Visualize

* 创建一个比较常见的柱状图 Vertical bar chart

以统计某个时间段内排名靠前10的destIp为例，同时每一个值还有一个 traffic的字段，这个字段代表了入站或出战流量，我们还想再同一个柱状图上，显示出入站和出站的流量分布  
由于要选择统计数据，所以Y-Axis Aggregation选择为Count (默认就是Count), Custom Label可以不写，有可以写为"Total Count"  
buckets 就是要做的分类，其中 buckets type选择 X-Axis，Aggregation 选为 Terms，Field选为destIp.keyword，这样就以destIp将数据按柱状图展示了。同时Order By选为 metric: Total Count，Order选择Descending降序，Size为10，这样就将Top 10的DestIp取出来，Custom Label可以留空，也可以输入"Top 10 IPs"，之后点击下"运行"，就可以了。  
此时还需要将同一个destIp按出入站流量在同一个柱状图上分开，因此我们还要Add sub-buckets，这次选择Split Bars(如果选择Split Charts，那么会将出站和入站流量在同一个柱状图中以两个柱展示)，选择Split Bars的话，就是在一个柱上以颜色区分开，Sub Aggregation依然是Terms，Field为traffic.keyword,其他和之前类似，不做过多解释。之后点击运行看下效果

* Metric 图表

如果想要在Dashboard中显示一个具体的数值，那么可以在Visualize中选择Metric这个图表  
在Metric图表中，还可以显示记录的最早时间，操作如下：  
将Aggregation选择为Min，field为date: @timestamp，然后点击运行即可.

* Pie Chart

同样是设置Aggregation, Field, Order By Order, Size，不再赘述

* 创建Search，并在Dashboard中展示
  
在Discover中，可以创建一个search，在search左侧菜单中，添加要展示的字段(默认不添加则显示所有字段)，搜索框可以输入 * 全部搜索，也可以自定义，之后保存  
在创建dashboard的时候，点击add，除了添加之前在visualize 中保存的charts之外，还可以添加刚刚保存的search结果.




[^_^]:
    还未按照下面的blog测试:https://www.cnblogs.com/sanduzxcvbnm/p/12841986.html