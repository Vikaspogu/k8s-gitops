# Bootstrapping Applications

- Ubuntu Prepare playbook by running task `ansible:playbook:ubuntu-prepare`

- Run the k3s install playbook by running task `ansible:playbook:k3s-install`

- Verify cluster is ready for Flux `flux --kubeconfig=./kubeconfig check --pre`

_NOTE:_ Comment [apps.yaml](../cluster/base/apps.yaml) until the rook-ceph is ready to create pvc

Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors on this second run.

- Run k3s post-install `ansible:playbook:k3s-post-install`

- Check for rook-ceph pods, once ready create a test-pvc `kubectl apply -f ../docs/test-pvc.yaml`

- Uncomment [apps.yaml](../cluster/base/apps.yaml) and create object `kubectl apply -k cluster/base/apps.yaml`
