# Caching server guide

This repo contains basic scripts for automatic deploy [Lancache](http://lancache.net/) caching server on fresh installed os.

Prerequisites
---
- OS: Ubuntu 18.04
- HDD: min 100GB
- RAM: min 4GB

---
HOWTO 
---
You need to download`init.sh`shell script from this repository and start it with root access level
```shell
wget https://raw.githubusercontent.com/rpele/caching-server/main/init.sh
sudo bash ./init.sh
```

After this you need to point DNS server to this machine. 

OR use original docs [Lancache docs](http://lancache.net/docs/) 
