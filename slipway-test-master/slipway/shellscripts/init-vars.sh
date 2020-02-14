#!/bin/bash
set -e

##
# Checks conditions and sets variables for init.sh and deploy.sh
# Expects that the _current working directory_ is the root directory of the
# repository you're about to init machines for or deploy. Running the script
# from anywhere else (including the dir the script lives in) will fail.
##

die() { echo "[ERROR] $@" 1>&2 ; exit 1; }

if [[ x"$1" == x"--help" || x"$1" == x"-h" || x"$1" == x"-?" ]]; then
  echo "This script deploys projects to Google Cloud"
  echo "You can optionally specify environment and branch:\n  $> ./${0} <optional:environment> <optional:branch_name>"
  echo "Environment (staging or production) defaults to 'staging' and branch to the currently checked out branch"
  exit 0
fi

PROJECT_DIR="${PWD}"
INFRA="${PROJECT_DIR}/infra";
PROJECT_NAME="${PWD##*/}"
TARGET_ENV="${1:-staging}"
GITHUB_REPO=git@github.com:minus/slipway-test.git
GITHUB_KEYFILE="${PROJECT_DIR}/config/local-secrets/github_key"
CHECKED_OUT_BRANCH=master
BRANCH="${2:-$CHECKED_OUT_BRANCH}"
TS=$(TZ=UTC date +%Y%m%d-%H%M)

if [[ "x$PROJECT_NAME" == x"slipway" ]]; then
  die "run this script from some project directory (for example running ./slipway/script.sh from repository root folder)"
fi

# common sanity checks: no branch but 'master' can be deployed to prod
# we don't allow deployments to production unless 'master' is checked out locally 
#  (this guards against deployment setup changes comitted on other branches)
# we don't allow deployments to production if we have uncomitted stuff in infra/

if [[ "x$TARGET_ENV" == x"production" ]]; then
  [[ "x$BRANCH" == x"master" ]] || die "Branch \"$BRANCH\" can't be deployed to production, only master can."

  [[ "x$CHECKED_OUT_BRANCH" == x"master" ]] || die "Local branch must be master to deploy to production, but it's $CHECKED_OUT_BRANCH"

  [[ -z "$(git status -s ${INFRA})" ]] || die "Directory ${INFRA} is unclean, refusing to deploy to master (maybe check git status?)."

fi

if [ -f "${PROJECT_DIR}/infra/vars.sh" ]; then
  source "${PROJECT_DIR}/infra/vars.sh"
else
  die "Expected variable definition file not found: 'infra/vars.sh'"
fi
NONPROD_DNS_PROJECT=$GOOGLE_PROJECT
NONPROD_DNS_ZONE=$PROD_DNS_ZONE

if [ -z ${GOOGLE_AUTH_FILE+x} ]; then
  die "GOOGLE_AUTH_FILE must be defined (in infra/vars.sh)"
fi
if [ -z ${GOOGLE_PROJECT+x} ]; then
  die "GOOGLE_PROJECT must be defined (in infra/vars.sh)"
fi
if [ -z ${GOOGLE_REGION+x} ]; then
  die "GOOGLE_REGION must be defined (in infra/vars.sh)"
fi
if [ -z ${GOOGLE_ZONE+x} ]; then
  die "GOOGLE_ZONE must be defined (in infra/vars.sh)"
fi
if [ -z ${PROD_DNS_PROJECT+x} ]; then
  die "PROD_DNS_PROJECT must be defined (in infra/vars.sh)"
fi
if [ -z ${PROD_DNS_ZONE+x} ]; then
  die "PROD_DNS_ZONE must be defined (in infra/vars.sh) (also the zone must exist in the Google project)"
fi
if [ -z ${GLOBAL_NAME_POSTFIX+x} ]; then
  # Pardon the cruft.. some resources are global and even if you delete them, Google will remember
  # the name for a while. We define an optional postfix (might for example be "-1") for bucket names
  # and perhaps other global resources to work around this issue.
  GLOBAL_NAME_POSTFIX=""
fi
# service account key file path should be absolute after all
GOOGLE_AUTH_FILE="${PROJECT_DIR}/${GOOGLE_AUTH_FILE}"

GOOGLE_MINUS_TEST_KEY="${GOOGLE_AUTH_FILE}"

GOOGLE_MINUS_INFRA_TEST_KEY="${GOOGLE_AUTH_FILE}"


# If there's content in PROJECT_DIR/infra/encrypted-secrets,
# we decrypt those files to project's local-secrets
ENCRYPTED_SECRETS_DIR="${INFRA}/encrypted-secrets"
DECRYPTED_SECRETS_DIR="${PROJECT_DIR}/config/local-secrets"
if [[ -d $ENCRYPTED_SECRETS_DIR ]]; then
  for file in $ENCRYPTED_SECRETS_DIR/*
  do
    [[ -f "$file" ]] || continue
    target="${DECRYPTED_SECRETS_DIR}/$(basename $file)"
    echo "found $file, does $target exist?"
    if [[ ! -f $target || $target -ot $file ]]; then
      echo "Decrypting secrets from $PROJECT_NAME, password is likely available in Bitwarden"
      ansible-vault decrypt $file --output=$target
    fi
  done
fi

if [[ "x$TARGET_ENV" == x"production" ]]; then
  TLD=$PROD_TLD
  PUB_SERVER="${PROD_PUBLIC_DOMAIN}"
  INTERNAL_SERVER=$PROD_INTERNAL_DOMAIN
  ADM_SERVER="admin.${PROD_INTERNAL_DOMAIN}"
  DNS_PROJECT=$PROD_DNS_PROJECT
  DNS_ZONE=$PROD_DNS_ZONE
  if [[ "x$DNS_PROJECT" == x"minus-as-infrastructure" ]]; then
    DNS_AUTH_FILE=$GOOGLE_MINUS_INFRA_TEST_KEY
  else
    DNS_AUTH_FILE=$GOOGLE_AUTH_FILE
  fi
else
  TLD=$NONPROD_TLD
  PUB_SERVER="public.${PROJECT_NAME}-${TARGET_ENV}.${NONPROD_TLD}"
  INTERNAL_SERVER=$PUB_SERVER
  ADM_SERVER="admin.${PROJECT_NAME}-${TARGET_ENV}.${NONPROD_TLD}"
  DNS_PROJECT=$NONPROD_DNS_PROJECT
  DNS_ZONE=$NONPROD_DNS_ZONE
  DNS_AUTH_FILE=$GOOGLE_MINUS_TEST_KEY
fi
