#!/bin/bash

set -euxo pipefail

export AWS_DEFAULT_REGION=${aws_default_region}
UUID=$(dbus-uuidgen | cut -c 1-8)
TOKEN=$(curl -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" "http://169.254.169.254/latest/api/token")
export INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token:$TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
export AWS_AZ=$(curl -H "X-aws-ec2-metadata-token:$TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep availabilityZone|awk -F\" '{print $4}')
export HOSTNAME=${name}-$AWS_AZ-$UUID

mkdir -p /etc/concourse

# Obtain keys from AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id ${tsa_host_key_public_secret_arn} --query SecretString --output text > /etc/concourse/tsa_host_key.pub
aws secretsmanager get-secret-value --secret-id ${worker_key_private_secret_arn} --query SecretString --output text > /etc/concourse/worker_key
chmod 0600 /etc/concourse/*

hostnamectl set-hostname $HOSTNAME
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$HOSTNAME

# Git etc expect ca-certificates.crt, not ca-bundle.crt
ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt

#echo abc

touch /var/spool/cron/root
echo "*/3 * * * * /home/root/healthcheck.sh" >> /var/spool/cron/root
chmod 644 /var/spool/cron/root

wget -q https://github.com/concourse/concourse/releases/download/v${concourse_version}/concourse-${concourse_version}-linux-amd64.tgz
tar -zxf concourse-*.tgz -C /usr/local

cat >> /etc/profile.d/concourse.sh << \EOF
  PATH="/usr/local/concourse/bin:$PATH"
EOF

source /etc/profile.d/concourse.sh

if [[ "$(rpm -qf /sbin/init)" == upstart* ]];
then
    initctl start concourse-worker
else
    systemctl enable concourse-worker.service
    systemctl start concourse-worker.service
fi
