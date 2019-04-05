#!/bin/sh

#gcloud auth activate-service-account --key-file $GCE_PEM_FILE_PATH
#gcloud config set project $GCLOUD_PROJECT
#gcloud config set compute/region $GCLOUD_REGION
#gcloud config set compute/zone $GCLOUD_ZONE

# Create Infrastructure

rm -f ~/.ssh/google_compute_engine*

ssh-keygen -q -P "" -f ~/.ssh/google_compute_engine

terraform init 01-terraform

terraform apply -auto-approve -var "gce_zone=${GCLOUD_ZONE}" 01-terraform

ssh-add -D
ssh-add ~/.ssh/google_compute_engine

# Apply Ansible
cd 02-ansible && ./setup.sh
