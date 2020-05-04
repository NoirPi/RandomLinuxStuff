#!/usr/bin/env bash

# configuration for cloudflare
CLOUDFLARE_EMAIL="admin@example.com"            ## Cloudflare Login Email
CLOUDFLARE_API_KEY="put-your-key-here"          ## Cloudflare API Key
CLOUDFLARE_CONFIG_PATH="/etc/letsencrypt"       ## Cloudflare Config Path
DOMAIN="example.com"                            ## Domain
OS_PACKAGE_COMMAND="apt install -y"             ## os command to install packages (apt, yum)

# as root configure your cloudflare secrets
mkdir -p ${CLOUDFLARE_CONFIG_PATH}
cat <<CLOUDFLARE_CONFIG > ${CLOUDFLARE_CONFIG_PATH}/cloudflare.ini
dns_cloudflare_email="${CLOUDFLARE_EMAIL}"
dns_cloudflare_api_key="${CLOUDFLARE_API_KEY}"
CLOUDFLARE_CONFIG

# make sure they are hidden, the api key is more powerful than a password!
chmod 0700 ${CLOUDFLARE_CONFIG_PATH}
chmod 0400 CLOUDFLARE_CONFIG_PATH/cloudflare.ini

# install pip, upgrade, then install the cloudflare/certbot tool
${OS_PACKAGE_COMMAND} python3-pip
pip3 install --upgrade pip
pip3 install certbot-dns-cloudflare
pip3 install --upgrade acme

# generate a wildcard cert for the domain using a dns challenge
#
# --quiet, suppress output
# --non-interactive, avoid user input
# --agree-tos, agree to tos on first run
# --keep-until-expiring, keep existing certs
# --preferred-challenges, specify to use dns-01 challenge
# --dns-cloudflare, use the cloudflare dns plugin
# --dns-cloudflare-credentials, path to ini config
# -d, domains to generate keys for, you can add additional ones if needed
certbot certonly \
  --quiet \
  --non-interactive \
  --agree-tos \
  --keep-until-expiring \
  --preferred-challenges dns-01 \
  --dns-cloudflare \
  --dns-cloudflare-credentials ${CLOUDFLARE_CONFIG_PATH}/cloudflare.ini \
  -d ${DOMAIN},*.${DOMAIN}