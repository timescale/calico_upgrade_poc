# Helper scripts to prepare calico upgrade manifests

These scripts can be used to prepare a manifest to upgrade calico using the method described in their official [documentation](https://projectcalico.docs.tigera.io/maintenance/kubernetes-upgrade#upgrading-an-installation-that-uses-manifests-and-the-kubernetes-api-datastore). Scripts rely on the yq tool, which should be preinstalled.

## Scripts that are included into this repo

```
calico_script.sh

positional arguments:
   yaml manifest file
   file name to save the obtained resources - optional
```

Expects calico upgrade manifest as first input. Scans the manifest and prepares a list of resources that exist in it. Gets all discovered resources from the cluster that is currently configured as active in ~/.kube/config.

```
pretty_printer.sh
```

Expects a manifest file as input. Creates backup of the original manifest. Normalises the manifest so that all resources and keys inside them are in alphabetical order and overwrites the original file. 

## Upgrade steps

```
git clone git@github.com:timescale/calico_upgrade_poc.git
cd calico_upgrade_poc
curl -O https://docs.projectcalico.org/archive/v3.21/manifests/calico.yaml
./scripts/pretty_printer.sh calico.yaml
./scripts/calico_script.sh calico.yaml resources_before_upgrade.yaml
./scripts/pretty_printer.sh resources_before_upgrade.yaml
# compare normalised version of manifests with resources before upgrade
vimdiff calico.yaml resources_before_upgrade.yaml
```
This is the beginning of manual step.

We need to compose a new manifest that includes all env vars of calico deployment, labels, annotations from resources_before_upgrade.yaml, but at the same time includes all CRDs, RBAC and new resources from the new upgrade manifest. It's quite difficult to automate this part reliably, that's why we only need to rely on common sense and it can be a bit tedious to create this new manifest.

Save the new manifest as calico_upgrade.yaml

After the new manifest is created, we need to apply it:

```
kubectl apply -f calico_upgrade.yaml
```

## Checking how upgrade is progressing

Checking how upgrade is progressing boils down to checking rollout staus of calico-node DaemonSet and calico-kube-controllers Deployment. DS is going to restart pods one by one and each of them should start after a few seconds. If any of the pods gets stuck, it needs to be investigated.

```
kubectl rollout status deployment -n kube-system calico-kube-controllers
kubectl rollout status ds -n kube-system calico-node
```

## Rollback

We've saved the version of calico resources before upgrade in `resources_before_upgrade.yaml`. Rollback to the previous version of calico should be as easy as applying that manifest:

```
kubectl apply -f resources_before_upgrade.yaml
```
