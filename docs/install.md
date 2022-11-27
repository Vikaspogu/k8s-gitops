# 🚀 Installation

## 📝 Prerequisites

- Fedora Servers

### ⚡ Preparing Fedora Server with Ansible

📍 Here we will be running a Ansible Playbook to prepare Fedora Server for running a Kubernetes cluster.

📍 Nodes are not security hardened by default, you can do this with [dev-sec/ansible-collection-hardening](https://github.com/dev-sec/ansible-collection-hardening) or similar if it supports Fedora Server.

1. Ensure you are able to SSH into your nodes from your workstation using a private SSH key **without a passphrase**. This is how Ansible is able to connect to your remote nodes.

   [How to configure SSH key-based authentication](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)

2. Install the Ansible deps

    ```sh
    task ansible:init
    ```

3. Verify Ansible can view your config

    ```sh
    task ansible:list
    ```

4. Verify Ansible can ping your nodes

    ```sh
    task ansible:ping
    ```

5. Run the Fedora Server Ansible prepare playbook

    ```sh
    task ansible:prepare
    ```

6. Reboot the nodes

    ```sh
    task ansible:reboot
    ```

### ⛵ Installing k3s with Ansible

📍 Here we will be running a Ansible Playbook to install [k3s](https://k3s.io/) with [this](https://galaxy.ansible.com/xanmanning/k3s) wonderful k3s Ansible galaxy role. After completion, Ansible will drop a `kubeconfig` in `./provision/kubeconfig` for use with interacting with your cluster with `kubectl`.

☢️ If you run into problems, you can run `task ansible:nuke` to destroy the k3s cluster and start over.

1. Verify Ansible can view your config

    ```sh
    task ansible:list
    ```

2. Verify Ansible can ping your nodes

    ```sh
    task ansible:ping
    ```

3. Install k3s with Ansible

    ```sh
    task ansible:install
    ```

4. Post install k3s with Ansible

    ```sh
    task ansible:post-install
    ```

5. Verify the nodes are online

    ```sh
    task cluster:nodes
    # NAME           STATUS   ROLES                       AGE     VERSION
    # k8s-0          Ready    control-plane,master      4d20h   v1.21.5+k3s1
    # k8s-1          Ready    worker                    4d20h   v1.21.5+k3s1
    ```

### ☁️ Configuring Cloudflare DNS with Terraform

📍 Review the Terraform scripts under `./provision/terraform/cloudflare/` and make sure you understand what it's doing (no really review it).

If your domain already has existing DNS records **be sure to export those DNS settings before you continue**.

1. Pull in the Terraform deps

    ```sh
    task terraform:init
    ```

2. Review the changes Terraform will make to your Cloudflare domain

    ```sh
    task terraform:plan
    ```

3. Have Terraform apply your Cloudflare settings

    ```sh
    task terraform:apply
    ```

If Terraform was ran successfully you can log into Cloudflare and validate the DNS records are present.

The cluster application [external-dns](https://github.com/kubernetes-sigs/external-dns) will be managing the rest of the DNS records you will need.

### 🔹 GitOps with Flux

📍 Here we will be installing [flux](https://toolkit.fluxcd.io/) after some quick bootstrap steps.

1. Verify Flux can be installed

    ```sh
    task cluster:verify
    # ► checking prerequisites
    # ✔ kubectl 1.21.5 >=1.18.0-0
    # ✔ Kubernetes 1.21.5+k3s1 >=1.16.0-0
    # ✔ prerequisites checks passed
    ```

2. Push you changes to git

    📍 **Verify** all the `*.sops.yaml` and `*.sops.yml` files under the `./cluster` and `./provision` folders are **encrypted** with SOPS

    ```sh
    git add -A
    git commit -m "Initial commit :rocket:"
    git push
    ```

3. Install Flux and sync the cluster to the Git repository

    ```sh
    task cluster:install
    # namespace/flux-system configured
    # customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
    ```

4. Verify Flux components are running in the cluster

    ```sh
    task cluster:pods -- -n flux-system
    # NAME                                       READY   STATUS    RESTARTS   AGE
    # helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
    # kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
    # notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
    # source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
    ```

### 🎤 Verification Steps

_Mic check, 1, 2_ - In a few moments applications should be lighting up like a Christmas tree 🎄

You are able to run all the commands below with one task

```sh
task cluster:resources
```

1. View the Flux Git Repositories

    ```sh
    task cluster:gitrepositories
    ```

2. View the Flux kustomizations

    ```sh
    task cluster:kustomizations
    ```

3. View all the Flux Helm Releases

    ```sh
    task cluster:helmreleases
    ```

4. View all the Flux Helm Repositories

    ```sh
    task cluster:helmrepositories
    ```

5. View all the Pods

    ```sh
    task cluster:pods
    ```

6. View all the certificates and certificate requests

    ```sh
    task cluster:certificates
    ```

7. View all the ingresses

    ```sh
    task cluster:ingresses
    ```

🏆 **Congratulations** if all goes smooth you'll have a Kubernetes cluster managed by Flux, your Git repository is driving the state of your cluster.

☢️ If you run into problems, you can run `task ansible:nuke` to destroy the k3s cluster and start over.

🧠 Now it's time to pause and go get some coffee ☕ because next is describing how DNS is handled.
