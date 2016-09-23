#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


MASTER_ADDRESS=${1:-"8.8.8.18"}

MASTER_IP=`hostname -i`

cat <<EOF >/etc/kubernetes/kube-controller-manager
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
KUBE_MASTER="--master=${MASTER_IP}:8080"
KUBE_LEADER_ELECT="--leader-elect=true"

# --root-ca-file="": If set, this root certificate authority will be included in
# service account's token secret. This must be a valid PEM-encoded CA bundle.
KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE="--root-ca-file=/srv/kubernetes/ca.crt"

# --service-account-private-key-file="": Filename containing a PEM-encoded private
# RSA key used to sign service account tokens.
KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE="--service-account-private-key-file=/srv/kubernetes/server.key"

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--terminated-pod-gc-threshold=10"

EOF

KUBE_CONTROLLER_MANAGER_OPTS="  \${KUBE_LOGTOSTDERR} \\
                                \${KUBE_LOG_LEVEL}   \\
                                \${KUBE_MASTER}      \\
                                \${KUBE_LEADER_ELECT} \\
                                \${KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE} \\
                                \${KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE} \\
                                \${KUBE_CONTROLLER_MANAGER_ARGS}"

cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/kube-controller-manager
ExecStart=/usr/bin/kube-controller-manager ${KUBE_CONTROLLER_MANAGER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager