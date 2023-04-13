<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub Actions_ :robot:

</div>

<br/>

<div align="center">

[![k3s](https://img.shields.io/badge/k3s-v1.26.3-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled?style=for-the-badge&logo=renovatebot&logoColor=white&color=brightgreen)](https://github.com/renovatebot/renovate)

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster based on excellent template from [k8s-at-home/template-cluster-k3](https://github.com/k8s-at-home/template-cluster-k3s). I try to adhere to Infrastructure as Code (IaC) and GitOps practices using the tools like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

### Installation

My cluster is [k3s](https://k3s.io/) provisioned overtop bare-metal Ubuntu 20.04 using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

🔸 _[Click here](./provision/ansible/) to see my Ansible playbooks and roles._

### Core Components

- [projectcalico/calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin.
- [rook/rook](https://github.com/projectcalico/calico): Distributed block storage for peristent storage.
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

## 📂 Repository structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

```sh
📁 cluster      # k8s cluster defined as code
├─📁 flux       # flux, gitops operator, loaded before everything
├─📁 charts     # helm chart repos
├─📁 config     # cluster config
└─📁 apps       # regular apps, namespaced dir tree, loaded last
```

### Data Backup and Recovery

Rook does not have built in support for backing up PVC data so I am currently using a DIY _(or more specifically a "Poor Man's Backup")_ solution that is leveraging [Kyverno](https://kyverno.io/), [Kopia](https://kopia.io/) and native Kubernetes `CronJob` and `Job` resources.

At a high level the way this operates is that:

- Kyverno creates a `CronJob` for each `PersistentVolumeClaim` resource that contain a label of `snapshot.home.arpa/enabled: "true"`
- Everyday the `CronJob` creates a `Job` and uses Kopia to connect to a Kopia repository on my NAS over NFS and then snapshots the contents of the app data mount into the Kopia repository
- The snapshots made by Kopia are incremental which makes the `Job` run very quick.
- The app data mount is frozen during backup to prevent writes and unfrozen when the snapshot is complete.
- Recovery is a manual process. By using a different `Job` a temporary pod is created and the fresh PVC and existing NFS mount are attached to it. The data is then copied over to the fresh PVC and the temporary pod is deleted.

---

## 🌐 DNS

### Ingress Controller

I have port forwarded ports `80` and `443` to the load balancer IP of Metallb that's running in my Kubernetes cluster.

[Cloudflare](https://www.cloudflare.com/) works as a proxy to hide my homes WAN IP and also as a firewall. All the traffic coming into my ingress controller on port `80` and `443` comes from Cloudflare, I block all IPs not originating from the [Cloudflares list of IP ranges](https://www.cloudflare.com/ips/).

🔸 _Cloudflare is also configured to GeoIP block all countries except a few I have whitelisted_

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configure to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses `external-dns` looks at to gather DNS records to put in `Cloudflare` are ones that I explicitly set an annotation of `external-dns/is-public: "true"`

🔸 _[Click here](./provision/terraform/cloudflare) to see how else I manage Cloudflare._

### Internal DNS

[CoreDNS](https://github.com/coredns/coredns) is deployed on cluster and has direct access to my clusters ingress records and serves DNS for them in my internal network. `CoreDNS` is only listening on my `MANAGEMENT` and `SERVER` networks on port `53`.

For ad-blocking, I have [Blocky](https://github.com/0xERR0R/blocky)

---

## 🔧 Hardware

| Device              | Count | OS Disk Size | Data Disk Size       | Ram  | Purpose    |
| ------------------- | ----- | ------------ | -------------------- | ---- | ---------- |
| Intel NUC D54250WYK | 1     | 256GB SSD    | N/A                  | 16GB | k8s Master |
| Intel NUC6CAYH      | 1     | 256GB SSD    | N/A                  | 16GB | k8s Master |
| Intel NUC6I3SYH     | 1     | 256GB SSD    | 1TB NVMe (rook-ceph) | 32GB | K8s Master |
| HP Elitedesk 4590T  | 1     | 500GB SSD    | 1TB NVMe (rook-ceph) | 16GB | K8s Worker |
| HP Elitedesk 6500T  | 1     | 256GB SSD    | 1TB NVMe (rook-ceph) | 16GB | k8s Worker |
| Raspberry Pi 4      | 2     | 32GB         | N/A                  | 8GB  | K8s Worker |

---

## 🤝 Gratitude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community. A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).

---

## 📜 Changelog

See [commit history](https://github.com/vikaspogu/k8s-gitops/commits/main)

---

## 🔏 License

See [LICENSE](./LICENSE)
