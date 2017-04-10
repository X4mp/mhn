#!/bin/bash

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh

# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "samba"

echo "deb http://en.archive.ubuntu.com/ubuntu precise main multiverse" | sudo tee -a /etc/apt/sources.list
apt-get update
apt-get -y install git python-pip supervisor
pip install virtualenv

# Get the Wordpot source
cd /opt
git clone https://github.com/x4mp/samba-dc-hpfeeds.git
cd samba-dc-hpfeeds

virtualenv env
. env/bin/activate
pip install -r requirements.txt

cat >> samba-dc-hpfeeds.conf <<EOF
{
  "host": "$HPF_HOST",
  "port" : $HPF_PORT,
  "channel" : "samba.events",
  "ident" : "$HPF_IDENT",
  "secret" : "$HPF_SECRET",
  "tail_file" : "/var/log/samba/samba.log"

}
EOF

# Set up supervisor
cat > /etc/supervisor/conf.d/collector-dc.conf <<EOF
[program:hpfeeds-collector-dc]
command=/usr/bin/python /opt/samba-dc-hpfeeds/collector.py /opt/samba-dc-hpfeeds/samba-dc-hpfeeds.conf
stdout_logfile=/var/log/collector.log
stderr_logfile=/var/log/collector.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update

