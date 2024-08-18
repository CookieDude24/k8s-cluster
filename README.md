# k8s-homelab

## how to install
   
### setup vms
1. execute the terraform file
2. execute ansible/dnf-update.yaml
3. execute ansible/k3s-node-setup.yaml

### bootstrap cluster with k3sup

1. ssh into workstation vm
2. use k3sup to bootstrap k3s cluster
   1. `curl -sLS https://get.k3sup.dev | sh`
   2. `sudo cp k3sup /usr/local/bin/k3sup`
   3. `k3sup install --ip $FIRST-MASTER-NODE-IP --tls-san $KUBEVIP-IP --cluster --k3s-channel stable --k3s-extra-args "--disable servicelb" --local-path $HOME/.kube/config --user maxid --ssh-key .ssh/$SSH-KEY`
3. deploy all manifests in kubernetes/infrastructure/kubevip
4. change the cluster ip in the kubeconfig file to the kubevip-ip
5. add additional nodes with:  `k3sup join --ip $NODE-IP --server-ip $KUBEVIP-IP --server --k3s-channel stable --user maxid --ssh-key .ssh/$SSH-KEY`

### restore sealed-secrets encryption key

create the main.key manifest for sealed-secrets (I store my keys in my password manager)

1. `kubectl apply sealed-secrets/controller.yaml`
2. `kubectl delete pod -n kube-system -l name=sealed-secrets-controller`

### enable authentik remote-cluster integration 

1.  install the authentik-remote-cluster-integration.yaml
2. create the kubeconfig file for the integration
   1. `KUBE_API=$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")`
   2. `NAMESPACE=authentik`
   3. `SECRET_NAME=$(kubectl get serviceaccount authentik-remote-clusters -o jsonpath='{.secrets[0].name}' 2>/dev/null || echo -n "authentik-remote-clusters")`
   4. `KUBE_CA=$(kubectl -n $NAMESPACE get secret/$SECRET_NAME -o jsonpath='{.data.ca\.crt}')`
   5. `KUBE_TOKEN=$(kubectl -n $NAMESPACE get secret/$SECRET_NAME -o jsonpath='{.data.token}' | base64 --decode)`
   6. ``` yaml  
      echo "apiVersion: v1
      kind: Config
      clusters:
      - name: default-cluster
        cluster:
        certificate-authority-data: ${KUBE_CA}
        server: ${KUBE_API}
        contexts:
      - name: default-context
        context:
        cluster: default-cluster
        namespace: $NAMESPACE
        user: authentik-user
        current-context: default-context
        users:
      - name: authentik-user
        user:
        token: ${KUBE_TOKEN}" > config.yaml
      ``` 