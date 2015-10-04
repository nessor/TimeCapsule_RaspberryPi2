#!/bin/bash

# Installscript for running a TimeCapsule on a RaspberryPi2 (4Cores)
# Must be run as root (i.e. sudo setup.sh)

apt-get update
apt-get upgrade --yes
apt-get install libdb-dev libdbus-glib-1-dev libwrap0-dev python-dbus-dev libldap2-dev libgcrypt11-dev libacl1-dev tracker-miner-fs libkrb5-dev libafpclient-dev libafsauthent1 libevent-dev libafsrpc1 systemtap-sdt-dev libcrack2-dev gcc libssl-dev perl flex libmysqlclient-dev libtracker-sparql-0.14-dev libdbus-c++-dev libpam0g-dev python-dbus libopenafs-dev libtracker-miner-0.14-dev linux-headers-rpi-rpfv libavahi-client-dev swapspace gdebi-core --yes

cleanup() {
    cd ~
    rm src -R
}
errorreport(){
    
    echo 'An Error happend:' $error 'Exit.'
    exit 1
}

hddwahl(){
    read -p "Do you have already an HTF+ formated Disk installed? (Y/N)" antwort
    if [$antwort -eq "N"] || [$antowrt -eq "n"]
        then
            apt-get install hfsplus hfsprogs --yes
            read -p "Attention!!! All data will be lost in the following steps! Press any key to continue... " -n1 -s
            read -p "Enter the whished name:" Partitionsname 
            read -p "Enter the /dev Pfad:" Geraetedatei 
            mkfs.hfsplus -s -J -v $Partitionsname $Geraetedatei
            cp -v /etc/fstab{,.orig}
            echo -e "UUID=$(blkid -o value -s UUID $Geraetedatei)\t/var/timemachine\thfsplus\tforce,rw\t0 0" | sudo tee -a /etc/fstab
            install -o nobody -g nogroup -m 775 -d /var/timemachine
            mount -a
            mountingpoint="/var/timemachine"
    elif [$antwort -eq "Y"] || [$antowrt -eq "y"]
        then
            read -p "Please enter your mounting Point of your HTF+ formated disk:" mountingpoint
            echo 'okay. Installation starts now.'
    fi
}

hddwahl

cd ~ && mkdir src && cd src
wget http://prdownloads.sf.net/netatalk/netatalk-3.1.7.tar.gz
tar -xvf netatalk-3.1.7.tar.gz
cd netatalk-3.1.7

./configure --prefix=/usr --disable-maintainer-mode --enable-fhs --with-cracklib --with-init-style=debian-sysv --enable-quota --with-shadow --enable-krbV-uam --with-cnid-dbd-backend --with-cnid-cdb-backend --with-tracker-pkgconfig-version=0.14 --with-cnid-default-backend=dbd LDFLAGS="-lafsauthent -lpthread"

error = $(echo $?)      #Wenn Fehler auftritt, dann errorreport
if [$error != 0]
    errorreport
fi

make -j4
error = $(echo $?)      #Wenn Fehler auftritt, dann errorreport
if [$error != 0]
    errorreport
fi
make install
error = $(echo $?)      #Wenn Fehler auftritt, dann errorreport
if [$error != 0]
    errorreport
fi

create-cracklib-dict -o /usr/lib/cracklib_dict /usr/share/dict/words
gzip /usr/lib/cracklib_dict.pwd
afppasswd -c
cp -v /etc/nsswitch.conf{,.orig}
sed -i '/^hosts: /s/$/ mdns/' /etc/nsswitch.conf
cd ~
cp -i afpd.service /etc/avahi/services/afpd.service
cd ~/src

wget -O netatalk_3.1.0-1+rpi_armhf.deb http://bit.ly/17DRz4q
gdebi netatalk_3.1.0-1+rpi_armhf.deb
sudo update-rc.d netatalk defaults

cleanup

echo 'Installation complete. Take a look at your Mac...'
