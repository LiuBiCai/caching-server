if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

mkdir -p /opt/caching-server
cd /opt/caching-server

#Install required libs
sudo apt update && apt install -y sudo curl git

#Install docker via script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

#Install currently latest docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

#Install lancache
git clone https://github.com/lancachenet/docker-compose.git
cd docker-compose
#removing default .env file
rm .env

#Collect your main ip address
IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | head -1)
#Or set manualy
#IP=10.0.30.19

cat  << EOF > ./.env
## See the "Settings" section in README.md for more details

## Set this to true if you're using a load balancer, or set it to false if you're using seperate IPs for each service.
## If you're using monolithic (the default), leave this set to true
USE_GENERIC_CACHE=true

## IP addresses that the lancache monolithic instance is reachable on
## Specify one or more IPs, space separated - these will be used when resolving DNS hostnames through lancachenet-dns. Multiple IPs can improve cache priming performance for some services (e.g. Steam)
## Note: This setting only affects DNS, monolithic and sniproxy will still bind to all IPs by default
LANCACHE_IP=$IP

## IP address on the host that the DNS server should bind to
DNS_BIND_IP=$IP

## DNS Resolution for forwarded DNS lookups
UPSTREAM_DNS=8.8.8.8

## Storage path for the cached data
## Note that by default, this will be a folder relative to the docker-compose.yml file
CACHE_ROOT=./lancache

## Change this to customise the size of the disk cache (default 1000000m)
## If you have more storage, you'll likely want to increase this
## The cache server will prune content on a least-recently-used basis if it
## starts approaching this limit.
## Set this to a little bit less than your actual available space 
CACHE_DISK_SIZE=450000m

## Change this to customise the size of the nginx cache manager (default 500m)
## DO NOT CHANGE THIS LIGHTLY. The defaults are enough to address 8TB of cache storage.  Increasing
## this value will cause performance problems, and may cause the cache to fail to start entirely.
CACHE_MEM_SIZE=500m

## Change this to limit the maximum age of cached content (default 3650d)
CACHE_MAX_AGE=3650d

## Set the timezone for the docker containers, useful for correct timestamps on logs (default Europe/London)
## Formatted as tz database names. Example: Europe/Oslo or America/Los_Angeles
TZ=Europe/London

CACHE_DOMAINS_REPO="https://github.com/LiuBiCai/cache-domains.git"
CACHE_DOMAINS_BRANCH="master"

EOF

echo "Starting containers..."

cat << EOF > /etc/systemd/system/caching-server.service
[Unit]
Description=Caching server stack
Requires=docker.service
After=docker.service

[Service]
Restart=always
WorkingDirectory=/opt/caching-server/docker-compose

ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start caching-server
systemctl enable caching-server
systemctl status caching-server

echo "--------------------------------------------------------------\n"
echo "Now you need to setup DNS server address on your router to $IP"
echo "--------------------------------------------------------------\n"
