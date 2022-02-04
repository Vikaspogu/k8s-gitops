<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub Actions_ :robot:

</div>

<br/>

<div align="center">

[![k3s](https://img.shields.io/badge/k3s-v1.23.3-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/vikaspogu/k8s-gitops/Schedule%20-%20Renovate?label=renovate&logo=renovatebot&style=for-the-badge)](https://github.com/vikaspogu/k8s-gitops/actions/workflows/renovate-schedule.yaml)
[![Lines of code](https://img.shields.io/tokei/lines/github/vikaspogu/k8s-gitops?style=for-the-badge&color=brightgreen&label=lines&logo=codefactor&logoColor=white)](https://github.com/vikaspogu/k8s-gitops/graphs/contributors)

</div>

---

## :book:&nbsp; Overview

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

### Directories

The Git repository contains the following directories under [cluster](./cluster/) and are ordered below by how [Flux](https://github.com/fluxcd/flux2) will apply them.

- **base**: directory is the entrypoint to [Flux](https://github.com/fluxcd/flux2).
- **crds**: directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists.
- **core**: directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by [Flux](https://github.com/fluxcd/flux2).
- **apps**: directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, [Flux](https://github.com/fluxcd/flux2) will prune resources here if they are not tracked by Git anymore.

### Networking

| Name                | CIDR              |
| ------------------- | ----------------- |
| Kubernetes Nodes    | `192.168.20.0/24` |
| Kubernetes pods     | `10.42.0.0/16`    |
| Kubernetes services | `10.43.0.0/16`    |

- HAProxy configured on Opnsense for the Kubernetes Control Plane Load Balancer.
- Calico configured with `externalIPs` to expose Kubernetes services with their own IP over BGP which is configured on my router.

---

## :globe_with_meridians:&nbsp; DNS

### Ingress Controller

I have port forwarded ports `80` and `443` to the load balancer IP of my ingress controller that's running in my Kubernetes cluster.

[Cloudflare](https://www.cloudflare.com/) works as a proxy to hide my homes WAN IP and also as a firewall. All the traffic coming into my ingress controller on port `80` and `443` comes from Cloudflare, I block all IPs not originating from the [Cloudflares list of IP ranges](https://www.cloudflare.com/ips/).

🔸 _Cloudflare is also configured to GeoIP block all countries except a few I have whitelisted_

### Internal DNS

[CoreDNS](https://github.com/coredns/coredns) is deployed on cluster and has direct access to my clusters ingress records and serves DNS for them in my internal network. `CoreDNS` is only listening on my `MANAGEMENT` and `SERVER` networks on port `53`.

For adblocking, I have [Blocky](https://github.com/0xERR0R/blocky)

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configure to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses `external-dns` looks at to gather DNS records to put in `Cloudflare` are ones that I explicitly set an annotation of `external-dns/is-public: "true"`

🔸 _[Click here](./provision/terraform/cloudflare) to see how else I manage Cloudflare._

### Dynamic DNS

My home IP can change at any given time and in order to keep my WAN IP address up to date on Cloudflare I have deployed a [CronJob](./cluster/apps/networking/cloudflare-ddns) in my cluster. This periodically checks and updates the `A` record `ipv4.domain.tld`.

---

## :zap:&nbsp; Network Attached Storage

:construction: Work in Progress :construction:

---

## :wrench:&nbsp; Hardware

| Device              | Count | OS Disk Size | Data Disk Size       | Ram  | Purpose    |
| ------------------- | ----- | ------------ | -------------------- | ---- | ---------- |
| Intel NUC D54250WYK | 1     | 256GB SSD    | N/A                  | 16GB | k8s Master |
| Intel NUC6CAYH      | 1     | 256GB SSD    | N/A                  | 16GB | k8s Master |
| Intel NUC6I3SYH     | 1     | 256GB SSD    | 1TB NVMe (rook-ceph) | 32GB | K8s Master |
| HP Elitedesk 4590T  | 1     | 500GB SSD    | 1TB NVMe (rook-ceph) | 16GB | K8s Worker |
| HP Elitedesk 6500T  | 1     | 256GB SSD    | 1TB NVMe (rook-ceph) | 16GB | k8s Worker |
| Raspberry Pi 4      | 2     | 32GB         | N/A                  | 8GB  | K8s Worker |

---

## :handshake:&nbsp; Graditude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community. A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).

---

## :scroll:&nbsp; Changelog

See [commit history](https://github.com/vikaspogu/k8s-gitops/commits/main)

---

## :lock_with_ink_pen:&nbsp; License

See [LICENSE](./LICENSE)
