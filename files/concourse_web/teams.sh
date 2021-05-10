#!/bin/bash
export HOME="/root"
export AWS_DEFAULT_REGION=${aws_default_region}
export CONCOURSE_USER=${concourse_username}
export CONCOURSE_PASSWORD=${concourse_password}

fly_tarball="/usr/local/concourse/fly-assets/fly-linux-amd64.tgz"
mkdir -p $HOME/bin
tar -xzf $fly_tarball -C $HOME/bin/

# wait for Concourse to start
if [[ "$(rpm -qf /sbin/init)" == upstart* ]]; then
    # todo: check if upstart service is running
    :
else
    i=0
    while ! $(systemctl is-active --quiet concourse-web.service); do
      sleep 5
      ((i=i+1))
      if [[ $i -gt 200 ]]; then
        exit 1
      fi
    done
fi

$HOME/bin/fly --target ${target} login \
--concourse-url http://127.0.0.1:8080 \
--username $CONCOURSE_USER \
--password $CONCOURSE_PASSWORD

team_check=`$HOME/bin/fly -t ${target} teams | grep -v name | grep -v main`

for team in $(ls $HOME/teams); do
    echo "--- $team ---"
    /root/bin/fly -t ${target} set-team \
    --non-interactive \
    --team-name=$team \
    --config=/root/teams/$team/team.yml
done
