# k8s-cluster

![image](https://github.com/user-attachments/assets/ea679c53-87fa-43dd-aba2-a557611c833b)
![image](https://github.com/user-attachments/assets/21cc3e10-89cf-4f88-9a53-a4c5f408b915)
![image](https://github.com/user-attachments/assets/b3147ba5-d71a-49a8-bce6-d386ca3d1d52)

## why?

### motivation of switching to K8s
Prior to running a K8s cluster I ran every service with docker-compose. Docker-compose had many issues when I used it, especially containers stopping but not starting again and secrets being stored in unencrypted files. Managing around 10 LXCs in proxmox which are all running docker-compose and some service is quite time-consuming and a lot of manual work. If I lost my backups I would have to manually install and configure everything AGAIN so the declarative nature of k8s is just great.

### the main benefits of my K8s cluster in conjunction with OpenTofu and Ansible

1. Backing up my cluster is way easier than my docker-compose LXC system ever was since it's just 4 VMs (3 Nodes and 1 Fileshare).
2. Updating is easier too, because I basically only have to update 2 different systems, because 3 VMs are identical.
3. My cluster is also more stable because I am able to reboot VMs without any services going down.
4. K8s supports secrets, which docker-compose doesn't. Having **all my secrets stored in unencrypted .env files** on docker-compose VMs never felt right to me.
5. K8s is also entirely declaratively configurable. So even if I lose my Backups, I don't have to configure anything manually ever **AGAIN**.
6. I just like playing with k8s.

## how to install
   
### setup vms
0. install kubectl, opentofu, ansible, kubeseal on youre workstation.
1. execute the terraform file
   1. modify values of variables in vars.tf
   1. `tofu plan -out`
   2. `tofu apply plan`
3. execute ansible/dnf-update.yaml
4. execute ansible/k3s-node-setup.yaml

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
