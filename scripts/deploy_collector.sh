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
git clone https://github.com/x4mp/hpfeeds-collector.git
cd hpfeeds-collector

virtualenv env
. env/bin/activate
pip install -r requirements.txt

cat >> hpfeeds-collector.conf <<EOF
{
  'host': '$HPF_HOST',
  'port' : $HPF_PORT,
  'channel' : 'samba.fileaudit',
  'ident' : '$HPF_IDENT',
  'secret' : '$HPF_SECRET',
  'tail_file' : '/var/log/samba/audit.log'

}
EOF

# Set up supervisor
cat > /etc/supervisor/conf.d/collector.conf <<EOF
[program:hpfeeds-collector]
command=/usr/bin/python /opt/hpfeeds-collector/collector.py
stdout_logfile=/var/log/collector.log
stderr_logfile=/var/log/collector.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update

