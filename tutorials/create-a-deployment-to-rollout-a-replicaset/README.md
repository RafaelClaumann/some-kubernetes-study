https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment

## Create a Deployment to rollout a ReplicaSet

Create a Deployment to rollout a ReplicaSet, the ReplicaSet creates Pods in the background. Check the status of the `Rollout` to see if it succeeds or not.

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

``` bash
## kubectl apply -f deployment.yaml       
    deployment.apps/nginx-deployment created
```

When you inspect the Deployments in your cluster, the following fields are displayed:
- `NAME` lists the names of the Deployments in the namespace.
- `READY` displays how many replicas of the application are available to your users. It follows the pattern ready/desired.
- `UP-TO-DATE` displays the number of replicas that have been updated to achieve the desired state.
- `AVAILABLE` displays how many replicas of the application are available to your users.
- `AGE` displays the amount of time that the application has been running.

Notice how the number of desired replicas is 3 according to `.spec.replicas` field.

``` bash
## kubectl get deployments
    NAME               READY   UP-TO-DATE   AVAILABLE   AGE
    nginx-deployment   2/3     3            3           34s
```

Podemos verificar o status(*rollout status*) do `Deployment` através do comando:
``` bash
## run kubectl rollout status deployment/nginx-deployment.
    Waiting for rollout to finish: 2 out of 3 new replicas  have been updated... deployment "nginx-deployment" successfully rolled out
```

ReplicaSet output shows the following fields:
- `NAME` lists the names of the ReplicaSets in the namespace.
- `DESIRED` displays the desired number of replicas of the application, which you define when you create the Deployment. This is the desired state.
- `CURRENT` displays how many replicas are currently running.
- `READY` displays how many replicas of the application are available to your users.
- `AGE` displays the amount of time that the application has been running.

Notice that the name of the ReplicaSet is always formatted as [DEPLOYMENT-NAME]-[RANDOM-STRING].

``` bash
## kubectl get replicasets                           
    NAME                          DESIRED   CURRENT   READY   AGE
    nginx-deployment-66b6c48dd5   3         3         3       15m

## kubectl get deployments,replicaset,pods 
    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-deployment   3/3     3            3           28m

    NAME                                          DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-deployment-66b6c48dd5   3         3         3       28m

    NAME                                    READY   STATUS    RESTARTS   AGE
    pod/nginx-deployment-66b6c48dd5-2c6fn   1/1     Running   0          28m
    pod/nginx-deployment-66b6c48dd5-lq8cp   1/1     Running   0          28m
    pod/nginx-deployment-66b6c48dd5-n7vps   1/1     Running   0          28m
```

To see the `Labels` automatically generated for each Pod.
``` bash
## kubectl get pods --show-labels   
    NAME                                READY   STATUS    RESTARTS   AGE   LABELS
    nginx-deployment-66b6c48dd5-2c6fn   1/1     Running   0          32m   app=nginx,pod-template-hash=66b6c48dd5
    nginx-deployment-66b6c48dd5-lq8cp   1/1     Running   0          32m   app=nginx,pod-template-hash=66b6c48dd5
    nginx-deployment-66b6c48dd5-n7vps   1/1     Running   0          32m   app=nginx,pod-template-hash=66b6c48dd5
```
