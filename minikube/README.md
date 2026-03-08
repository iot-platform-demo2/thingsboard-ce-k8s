# Minikube microservices deployment scripts

This folder containing scripts and Kubernetes resources configurations to run ThingsBoard in Microservices mode on Minikube cluster.

You can find the deployment guide by the [**link**](https://thingsboard.io/docs/user-guide/install/cluster/minikube-cluster-setup/).

For HTTPS on `k3s` with `ingress-nginx`, deploy the TLS resources from this folder. The script installs `cert-manager` automatically if it is missing:

```
./k8s-deploy-tls.sh
```
