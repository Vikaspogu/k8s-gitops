# 1password connect

Create a new vault in 1password named `Kubernetes`

To create server and token:

```bash
eval $(op signin)
op connect server create k3s-homelab-0
op connect token create "k3s homelab 0 token" --server k3s-homelab-0 --vaults Kubernetes,r
```
