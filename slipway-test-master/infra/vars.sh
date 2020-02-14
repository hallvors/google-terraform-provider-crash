# Variables for deploying to Google cloud
GOOGLE_PROJECT="moonlit-triumph-266108"
GOOGLE_REGION="europe-north1"
GOOGLE_ZONE="europe-north1-a"
# Google service account key file - keep in sync with defaults.json setting
# Relative to project root dir
GOOGLE_AUTH_FILE="config/local-secrets/moonlit-triumph-266108-6abe1b6dd265.json"
# domain name stuff
PROD_TLD="googleprovidertest.no"
NONPROD_TLD="googleprovidertest.no"
PROD_DNS_PROJECT=$GOOGLE_PROJECT

# The DNS zone must be created manually, this script won't create it
PROD_DNS_ZONE="googleprovidertest-no"
