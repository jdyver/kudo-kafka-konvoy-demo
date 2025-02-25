# Kudo Kafka on Konvoy Demo

_NB: This is a work in progress. PRs and issues are most welcome._

## Background

This demo is designed to show a simple container running in Konvoy writing to Kudo Kafka. Another container reads from the Kudo Kafka stream and outputs the Kafka messages to logs, which you can follow to demonstrate.


## Prereqs 

- Konvoy Kubernetes Cluster 1.13 or above
- Installed and configured kubectl with version 1.13 or later


## Step 1 - Install Kudo on Konvoy

```
./kudo-prereqs.sh
```

## Step 2 - Install Kudo CLI

```
brew tap kudobuilder/tap
brew install kudo-cli
```

## Step 3 - Launch ZooKeeper

```
kubectl kudo install zookeeper --instance=zk
```

Use `kubectl get pods` to observe when all the ZK nodes are up and have STATUS `RUNNING`.


## Step 4 - Launch Kafka 

```
kubectl kudo install kafka --instance=kafka --parameter ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 --parameter ZOOKEEPER_PATH=/small -p BROKERS_COUNTER=3
```

Use `kubectl get pods` to observe when all the Kafka brokers are up and have STATUS `RUNNING`.  (Very slow to come up)


## Step 5 - Deploy Generator and Consumer

Update generator and consumer yamls with broker IP
```
 $ TEMPIP=$(kubectl describe svc kafka-svc | grep Endpoints | grep 9093 | awk '{print $2}' | cut -f1 -d :); sed -i -e "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$TEMPIP/g" kafka-demo-*; rm *-e
```
...or work for it file by file as below (unneccessary if you ran the above command)
```
 $ kubectl describe svc kafka-svc
Name:              kafka-svc
Namespace:         default

...

Port:              server  9093/TCP
kind: Deployment
TargetPort:        9093/TCP
Endpoints:         192.168.170.203:9093,192.168.185.141:9093,192.168.253.142:9093
Port:              client  9092/TCP

...
```
- From example above pull 192.168.170.203 and update BOTH yamls
```
 $ cat kafka-demo-generator-kudo.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kudo-kafka-generator
  
...

        args: ["--broker", "192.168.170.203:9093"]
        
 $ cat kafka-demo-consumer-kudo.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
 name: kudo-kafka-consumer

...

          value: 192.168.170.203:9093
```

Now deploy
```
kubectl apply -f kafka-demo-generator-kudo.yaml
kubectl apply -f kafka-demo-consumer-kudo.yaml
```

## Step 6 - Observe Kafka message read/write


Run `kubectl get pods` to find the pod ID of the pods for the generator and consumer service.

```
k get pods

NAME                                    READY   STATUS    RESTARTS   AGE
kafka-kafka-0                          1/1     Running   0          76m
kafka-kafka-1                          1/1     Running   0          76m
kafka-kafka-2                          1/1     Running   0          75m
kudo-kafka-consumer-85d8cd54df-7nhnn   1/1     Running   0          61m
kudo-kafka-generator-bfbfbc749-rf7tz   1/1     Running   0          64m
zk-zookeeper-0                         1/1     Running   0          7m21s
zk-zookeeper-1                         1/1     Running   0          8m18s
zk-zookeeper-2                         1/1     Running   0          9m11s
```

Then, follow the logs for the consumer or generator pods to show reading/writing to Kafka.
```
kubectl logs $(kubectl get pods | grep consumer | awk '{print $1}') --tail=5 --follow
```
...or copy / paste the exact service name above into the below command
```
k logs kudo-kafka-consumer-85d8cd54df-7nhnn --tail=5 --follow

Message: b'2019-06-21T16:18:20Z;5;0;3072'
Message: b'2019-06-21T16:18:29Z;2;4;9296'
Message: b'2019-06-21T16:18:30Z;6;3;6477'
Message: b'2019-06-21T16:18:31Z;2;0;4452'
Message: b'2019-06-21T16:18:32Z;4;1;7288'
Message: b'2019-06-21T16:18:37Z;9;1;7198'
Message: b'2019-06-21T16:18:39Z;2;0;9703'
Message: b'2019-06-21T16:18:46Z;1;2;1323'
Message: b'2019-06-21T16:18:48Z;3;6;5534'
Message: b'2019-06-21T16:18:55Z;3;4;1143'
Message: b'2019-06-21T16:18:58Z;7;9;217'
Message: b'2019-06-21T16:18:59Z;3;0;2691'
Message: b'2019-06-21T16:19:03Z;2;5;8785'
Message: b'2019-06-21T16:19:04Z;3;5;4883'
Message: b'2019-06-21T16:19:06Z;9;0;9543'
Message: b'2019-06-21T16:19:07Z;1;3;7573'
Message: b'2019-06-21T16:19:08Z;1;0;4322'
Message: b'2019-06-21T16:19:10Z;6;4;6676'
```

## Step 7 - Load Kafka Grafana dashboard

Run the following command to enable Kafka metrics export:

```
kubectl create -f https://raw.githubusercontent.com/kudobuilder/operators/master/repository/kafka/docs/v0.2/resources/service-monitor.yaml
```

Open Grafana from the Konvoy Ops Portal.

On the left nav bar, hover over the "+" icon and select "Import". 

The JSON for the Kafka dashboard can be found [here](https://raw.githubusercontent.com/kudobuilder/operators/master/repository/kafka/docs/v0.2/resources/grafana-dashboard.json).
Copy that json, then select the 'Prometheus' option in the drop down at the bottom and select "Import".
