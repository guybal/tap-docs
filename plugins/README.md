# Command
```bash
kubectl tap-relocate
  --vmware-username MY-USERNAME \
  --vmware-password MY-PASSWORD \
  --install-registry-hostname YOU-KNOW-WHERE \
  --install-registry-username YOU-KNOW-WHO \
  --install-registry-password YOU-KNOW-WHAT \
  --install-repo MY-REGISTRY-SUBPATH \ 
  --package tap \
  --version 7.0.0-rc1
```

**Where**
- `--vmware-username` specifies the username for VMware tanzu network.
- `--vmware-password` specifies the password correspondent to the username for VMware tanzu network.
- `--install-registry-hostname` specifies your local private image registry hostname (fqdn).
- `--install-registry-username` specifies the username for your local private image registry.
- `--install-registry-password` specifies the password correspondent to the username for your local private image registry.
- `--install-repo` specifies the sub path for copying packages in your local private image registry (dedfaults to `tap`).
- `--package` specifies the type of package to relocate (accepts `tap`, `tbs`, `scg`).
- `--version` specifies the version of package for relocation. 
