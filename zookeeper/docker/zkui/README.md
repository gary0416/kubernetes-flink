# ZKUI
A UI dashboard that allows CRUD operations on Zookeeper.

# Supported tags and respective Dockerfile links

 [2.0](https://github.com/gary0416/kubernetes-flink/blob/master/zookeeper/docker/zkui/Dockerfile)

# RUN
```
docker run --name zkui -d -e ZKLIST='zk1:2181,zk2:2181,zk3:2181' -p 19090:9090 gary0416/zkui

google-chrome http://localhost:19090
```

# Login Info
## Admin privileges(CRUD operations supported)
username: admin, pwd: manager

## Readonly privileges(Read operations supported)
username: appconfig, pwd: appconfig
