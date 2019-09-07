# Flink On Kubernetes
通过zookeeper实现HA，存储使用HDFS。

## 参考
- https://github.com/apache/flink/tree/master/flink-contrib/docker-flink
- https://github.com/apache/flink/tree/master/flink-container/kubernetes
- https://github.com/docker-flink/docker-flink

# 部署
1. 部署zookeeper，用zookeeper/kubernetes目录下的zookeeper.yaml
2. 修改 1.9/kubernetes/conf 目录下的配置文件内容，如hdfs信息、flink-conf.yaml里的几个hdfs路径等。
3. 修改 1.9/kubernetes/jobmanager-statefulset.yaml 里HADOOP_USER_NAME环境变量为实际用户、ingress的host地址、pvc的storageClassName。
4. 修改 1.9/kubernetes/taskmanager-deployment.yaml 里HADOOP_USER_NAME环境变量为实际用户。
5. 部署：
```
kubectl create configmap hdfs-conf --from-file=conf/hdfs/hdfs-site.xml --from-file=conf/hdfs/core-site.xml
kubectl create configmap flink-conf --from-file=conf/flink/flink-conf.yaml --from-file=conf/flink/log4j-console.properties

kubectl apply -f jobmanager-statefulset.yaml -f taskmanager-deployment.yaml
```

其它：
- 需修改k8s nginx ingress的配置，body大小增大(用于上传jar，也可不修改)
- taskmanager.heap.size是公用的，taskmanager.numberOfTaskSlots数增加不会导致内存翻倍。
- 由于有堆外内存，所以内存配置需要小于k8s的限制，否则oom kill。

# 提交任务
## ui直接上传
submit new job -> 选择jar -> upload（jobmanager通过nfs的pvc共享存储,不支持hdfs）。
选择jar，Entry Class填写主程序包名和类名，submit。

## curl方式
```
# 上传jar
curl -X POST -H "Expect:" -F "jarfile=@/home/gary/demo-flink-sql.jar" http://jm.flink.gary.your-domain.com/jars/upload

# 获取jarId
curl -s -X GET http://jm.flink.gary.your-domain.com/jars | jq '.files[0].id'

# 启动
curl -X POST \
  http://jm.flink.gary.your-domain.com/jars/59e9b3ef-e470-4c12-8ef8-3088c3114129_demo-flink-sql.jar/run \
  -H 'Content-Type: application/json' \
  -d '{
    "entryClass": "com.gary.demo.flink.sql.Example",
    "parallelism": "1"
}'
```
