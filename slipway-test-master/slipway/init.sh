#!/bin/bash
set +x

SCRIPT_DIR="$(realpath "${0}" | xargs dirname)"

source "${SCRIPT_DIR}/shellscripts/init-vars.sh"

echo "#   Will initialize '$TARGET_ENV' setup for '$PROJECT_NAME' (on '$BRANCH')"
echo "#   ...using config from working dir, ${PROJECT_DIR}"
echo "#   ...setting up stuff in ${GOOGLE_PROJECT},"
echo "#      authenticating with credentials from ${GOOGLE_AUTH_FILE}"
echo ""

function terraformUpdatevm() {
  terraform apply \
  -var "service_account_file=${GOOGLE_AUTH_FILE}" \
  -var "project_appname=${PROJECT_NAME}" \
  -var "google_project_name=${GOOGLE_PROJECT}" \
  -var "google_region=${GOOGLE_REGION}" \
  -var "google_zone=${GOOGLE_ZONE}" \
  -var "project_repository=${GITHUB_REPO}" \
  -var "os_user=${USER}" \
  -var "project_dir=${PROJECT_DIR}"\
  -var "gh_key=${GITHUB_KEYFILE}"
}

# Terraform also supports a command line "config dir" argument, but this is
# considered deprecated and won't work nicely with the output command.
# Hence, use CD..
cd "${PROJECT_DIR}/slipway/terraform/init-updatevm"

# Because backend config does not support variable interpolation,
# values need to come from the command line. This is not quite ideal
# because later uses of apply depends on what state init was run in..
terraform init \
  -backend-config "bucket=terraform-state-ggle-terraform-provider-test-staging" \
  -backend-config "credentials=${GOOGLE_AUTH_FILE}"
terraform workspace select $TARGET_ENV || terraform workspace new $TARGET_ENV
echo "Setting up virtual machine for updating disk to create images from"

terraformUpdatevm

VM_NAME=$(terraform output updatevm_name)
VM_IP=$(terraform output updatevm_ip)
VM_DISK=$(terraform output update_disk_link)
SSH_CMD_ROOT="gcloud compute --project "$GOOGLE_PROJECT" ssh --zone "$GOOGLE_ZONE" "$VM_NAME" --command "

# If we don't have an IP address, it means the VM is not running
if [[ "x$VM_IP" == "x" ]]; then
  # If the Update VM is stopped, we need to start it
  gcloud compute --project "$GOOGLE_PROJECT" instances start --zone "$GOOGLE_ZONE" "$VM_NAME"
  echo "# waiting for instance to come up .."
  RET=12
  until [ $RET -eq 0 ]; do
    sleep 30
    $SSH_CMD_ROOT true || :
    RET=$?
  done
  terraformUpdatevm
  VM_IP=$(terraform output updatevm_ip)
fi

# echo "Setting up database"
# # Create DB in a separate step. Init code is common for all environment, DB is not.
# cd "${PROJECT_DIR}/slipway/terraform/init-db"
# terraform init \
#   -backend-config "bucket=terraform-state-${PROJECT_NAME}-${TARGET_ENV}${GLOBAL_NAME_POSTFIX}" \
#   -backend-config "credentials=${GOOGLE_AUTH_FILE}"
# terraform workspace select $TARGET_ENV || terraform workspace new $TARGET_ENV

# If we have a password stored, we should not generate a new one
# DB_PASSWORD=$(terraform output database_password)
# 
# terraform apply \
#   -var "service_account_file=${GOOGLE_AUTH_FILE}" \
#   -var "project_appname=${PROJECT_NAME}" \
#   -var "google_project_name=${GOOGLE_PROJECT}" \
#   -var "google_region=${GOOGLE_REGION}" \
#   -var "db_pass=${DB_PASSWORD}" \
#   -var "google_zone=${GOOGLE_ZONE}"
# 
# # If we created a password, let's prepare recording it in a suitable place..
# DB_PASSWORD=$(terraform output database_password)
# 
# DB_USER=$(terraform output database_user)
# # if we didn't have db pw earlier, let's get it..
# DB_PASSWORD=$(terraform output database_password)
# DB_NAME=$(terraform output database_name)

cd "${PROJECT_DIR}"

#GCP_SERVICE_ACCOUNT_FILE=$GOOGLE_AUTH_FILE ansible-playbook \
#	-i "${VM_IP}," \
#	-e "project_appname=${PROJECT_NAME}" \
#	-e "github_keyfile=${GITHUB_KEYFILE}" \
#	-e "google_zone=${GOOGLE_ZONE}" \
#	-e "google_region=${GOOGLE_REGION}" \
#	-e "google_project=${GOOGLE_PROJECT}" \
#	-e "app_directory=/srv/www/${PROJECT_NAME}" \
#	-e "app_infra_apt_dir=${INFRA}/apt" \
#	-e "local_directory=${PROJECT_DIR}"\
#  -e "service_account_file=${GOOGLE_AUTH_FILE}" \
#	-v \
#	"${SCRIPT_DIR}/ansible/bootstrap_updatevm.yaml"
#
## initial checkout
#GCP_SERVICE_ACCOUNT_FILE=$GOOGLE_AUTH_FILE ansible-playbook \
#	-i "${VM_IP}," \
#	-e "project_appname=${PROJECT_NAME}" \
#	-e "github_repo=${GITHUB_REPO}" \
#	-e "branch=${BRANCH}" \
#	-e "env=${TARGET_ENV}" \
#	-e "google_zone=${GOOGLE_ZONE}" \
#	-e "google_region=${GOOGLE_REGION}" \
#	-e "google_project=${GOOGLE_PROJECT}" \
#	-e "github_keyfile=${GITHUB_KEYFILE}" \
#	-e "app_directory=/srv/www/${PROJECT_NAME}" \
#	-e "local_directory=${PROJECT_DIR}"\
#  -v \
#  -e "service_account_file=${GOOGLE_AUTH_FILE}" \
#  -e "database_user=${DB_USER}"\
#  -e "database_password=${DB_PASSWORD}"\
#  -e "database_name=${DB_NAME}"\
#  -e "database_host=127.0.0.1"\
#  -e "public_server_name=${PUB_SERVER}"\
#  -e "internal_server_name=${INTERNAL_SERVER}"\
#  -e "admin_server_name=${ADM_SERVER}"\
#	"${SCRIPT_DIR}/ansible/deploy.yaml"


#CRON_DIR="${INFRA}/cron"
#if [ -d $CRON_DIR ]; then
#  echo "Now setting up cron jobs for ${PROJECT_NAME}-${TARGET_ENV}"
#
#  for file in ${CRON_DIR}/*
#  do
#    GCP_SERVICE_ACCOUNT_FILE=$GOOGLE_AUTH_FILE ansible-playbook \
#      -i "${VM_IP}," \
#      -e "project_appname=${PROJECT_NAME}" \
#      -e "env=${TARGET_ENV}" \
#      -e "app_directory=/srv/www/${PROJECT_NAME}" \
#      -e "local_directory=${PROJECT_DIR}"\
#      -vv \
#      -e "cron_config_file=${file}"\
#      -e "admin_server_name=${ADM_SERVER}"\
#      "${SCRIPT_DIR}/ansible/cron.yaml"
#  done
#fi


# We're done using the update-vm, and we want to create an image from the disk
gcloud compute --project "$GOOGLE_PROJECT" instances stop --zone "$GOOGLE_ZONE" "$VM_NAME"

# img must be all lower case
IMG_NAME=$(echo "${PROJECT_NAME}-${BRANCH}-$TS" | tr '[:upper:]' '[:lower:]')

cd "${PROJECT_DIR}/slipway/terraform/rollout"

echo "Now setting up actual machines to serve ${PROJECT_NAME}-${TARGET_ENV}"
terraform init \
  -backend-config "bucket=terraform-state-ggle-terraform-provider-test-staging" \
  -backend-config "credentials=${GOOGLE_AUTH_FILE}"
terraform workspace select $TARGET_ENV || terraform workspace new $TARGET_ENV

terraform apply \
  -var "service_account_file=${GOOGLE_AUTH_FILE}" \
  -var "project_appname=${PROJECT_NAME}" \
  -var "google_project_name=${GOOGLE_PROJECT}" \
  -var "service_account_file_dns=${DNS_AUTH_FILE}" \
  -var "google_dns_project_name=${DNS_PROJECT}" \
  -var "google_dns_zone=${DNS_ZONE}" \
  -var "top_level_domain=${TLD}" \
  -var "public_server_name=${PUB_SERVER}" \
  -var "internal_server_name=${INTERNAL_SERVER}" \
  -var "admin_server_name=${ADM_SERVER}" \
  -var "google_region=${GOOGLE_REGION}" \
  -var "google_zone=${GOOGLE_ZONE}" \
  -var "project_repository=${GITHUB_REPO}"\
  -var "branch=${BRANCH}" \
  -var "update_disk_link=${VM_DISK}" \
  -var "img_name=${IMG_NAME}"

