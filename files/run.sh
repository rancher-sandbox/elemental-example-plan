#!/bin/sh

set -x -e

# Note: ${CATTLE_AGENT_EXECUTION_PWD} is where the binaries from the images are
for i in rke2 k3s; do
    mkdir -p /etc/rancher/$i/config.yaml.d
    cat > /etc/rancher/$i/config.yaml.d/99-node-labels.yaml << EOF
node-label+:
- label=value
EOF
done

cat > /etc/sysconfig/network/ifcfg-eth0 << EOF
STARTMODE=auto
BOOTPROTO='static'
IPADDR='192.168.1.2/24'
EOF

systemctl restart network
