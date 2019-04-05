#!/bin/sh

export EX_MASTER=$(gcloud compute instances list --filter="(tags.items:controller)" | grep -v NAME | awk '{ print $5 }')

cat > hosts.ini <<EOF
[master]
$(gcloud compute instances list --filter="(tags.items:controller)" | grep -v NAME | awk '{ print $5 }')
[node]
$(gcloud compute instances list --filter="(tags.items:worker)" | grep -v NAME | awk '{ print $5 }')
[kube-cluster:children]
master
node
EOF

sed -i -e '0,/init_opts/s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/'"$EX_MASTER"'/' group_vars/all.yml 

ansible-playbook getup.yaml

scp root@$EX_MASTER:/etc/kubernetes/admin.conf .

sed -i -e '0,/server/s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/'"$EX_MASTER"'/' admin.conf

mv admin.conf ~/.kube/config
