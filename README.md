# elemental-example-plan

This repository is an example of a custom plan that can be applied before bootstrapping a node within elemental.

This github repository is configured as such that each new commit on main will re-build the plan image and push it to the Github container registry as `ghcr.io/rancher-sandbox/elemental-example-plan:main`.

A plan is just a container image which is executed in the host context without any container engine, but which carries the binaries within a folder which can be accessed during execution (via `CATTLE_AGENT_EXECUTION_PWD` env var).

Plans have a `run.sh` file that is executed when a plan is run by `system-agent`.

To build the plan, checkout this repository

```bash
git clone https://github.com/rancher-sandbox/elemental-example-plan
cd elemental-example-plan
```

edit `files/run.sh`, build container image with it:

```bash
docker build -t elemental-example-plan .
```

and then push the image to a registry, as it should be accessible remotely by nodes.

Plans can be either specified remotely via a management cluster, or locally by writing plan files in `/var/lib/elemental/agent/plans` inside a node host folder, which is running the `rancher-system-agent`.
Note: During node provisioning elemental configures the `/var/lib/elemental` path over the standard `/var/lib/rancher` path. If you wan to run a local plan after cluster provisioning, you need to switch to the /var/lib/rancher path.

For example, a plan file (ending up with `.plan`) might look like:

```json
{"instructions":[{"name":"test","image":"ghcr.io/rancher-sandbox/elemental-example-plan:main"}]}
```

in the Elemental context, we could overlay those files also via cloud config during the early boot:

```yaml
stages:
   initramfs:
     -
       files:
       - path: /var/lib/elemental/agent/plans/test.plan
         content: |
               {"instructions":[{"name":"test","image":"ghcr.io/rancher-sandbox/elemental-example-plan:main"}]}
         permissions: 0600
         owner: 0
         group: 0
```

You can create a local plan via a [MachineRegistration CRD](https://github.com/rancher/elemental-operator#machineregistration) , used to register a node in Rancher Manager

```yaml
apiVersion: elemental.cattle.io/v1beta1
kind: MachineRegistration
metadata:
  name: test-nodes
  namespace: fleet-default
spec:
  config:
    cloud-config:
      users:
      - name: root
        passwd: linux
      write_files:
      - path: /var/lib/elemental/agent/plans/test.plan
        permissions: "0600"
        content: |
          {"instructions":[{"name":"test","image":"ghcr.io/rancher-sandbox/elemental-example-plan:latest"}]}
    elemental:
      install:
        reboot: true
        device: /dev/vda
        debug: true
  machineName: m-${System Information/Manufacturer}-${System Information/Product Name}-${System Information/UUID}
```

The config file can be supplied also while building the ISO:

```bash
wget https://raw.githubusercontent.com/rancher/elemental/master/elemental-iso-build
chmod +x elemental-iso-build
./elemental-iso-build <path_to_yaml_above>
```


## Notes

The plan entrypoint is in `files/run.sh` and currently tries to set a static IP and k3s/rke2 node label `label=value` for each node running the plan.
