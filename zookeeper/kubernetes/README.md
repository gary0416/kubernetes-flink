# 说明
- 相比官网版本修改：增加ZK_REPLICAS环境变量才能正常启动。service暴露2181端口。
- gcr.io/google_samples/k8szk:v1或k8s.gcr.io/kubernetes-zookeeper:1.0-3.4.10需要梯子，registry.cn-beijing.aliyuncs.com/shannonai-k8s/k8szk代替，也可自己打包。
- 文档https://kubernetes.io/zh/docs/tutorials/stateful-application/zookeeper/
- hdp2.6.3里是zookeeper:3.4.6,当前使用的是3.4.14,也可自己打包https://github.com/gary0416/contrib/tree/master/statefulsets/zookeeper

# 使用
```
kubectl apply -f zookeeper.yaml -f zkui.yaml
```
通过ingress方式访问zkui(proxy方式无法处理页面跳转,会跳到/home然后报错)，浏览器打开zkui.gary.your-domain.com

# 测试
使用 zkCli.sh 脚本在 zk-0 Pod 上写入 world 到路径 /hello
```
kubectl exec zk-0 zkCli.sh create /hello world
```
从 zk-1 Pod 获取数据
```
kubectl exec zk-1 zkCli.sh get /hello
```

# metrics
```
kubectl exec zk-0 zkMetrics.sh
```

# 日志
```
kubectl logs zk-0 --tail 20
```

# 状态
```
kubectl get pod -w -l app=zk
```

# leader/follower
```
kubectl exec -it zk-0 /opt/zookeeper/bin/zkServer.sh status
```
