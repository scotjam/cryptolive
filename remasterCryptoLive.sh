#!/usr/bin/env bash

#Largely based on https://help.ubuntu.com/community/LiveCDCustomization
sudo apt-get install -y squashfs-tools genisoimage

#directory into which we will put the livecd contents
START_DIR=`pwd`
WORK_DIR="/media/temp-iso"

#username of the user we're adding to the livecd
CRYPTO_USER="cryptolive"

#prevent python3 from creating .pyc python bytecode cache files
PYTHONDONTWRITEBYTECODE="TRUE" #any value will do


if [[ ! -e ./ubuntu-16.04.3-desktop-amd64.iso ]]; then
	wget http://releases.ubuntu.com/16.04/ubuntu-16.04.3-desktop-amd64.iso
fi

sudo mkdir $WORK_DIR
sudo chmod 775 $WORK_DIR
sudo mkdir /media/ubuntu-iso

#mount our ubuntu ISO so that we can start copying files from it to 
# a local directory for editing
sudo mount -o loop ./ubuntu-16.04.3-desktop-amd64.iso /media/ubuntu-iso

#sudo cp -rT /media/ubuntu-iso $WORK_DIR
#copy all files from the ISO to our working directory 
# (excluding squashfs beacuse we need to unsquash that and recreate it anyway)
sudo rsync --exclude=/casper/filesystem.squashfs -a /media/ubuntu-iso/ $WORK_DIR

#"unzip" the compressed livecd filesystem into current directory
sudo unsquashfs /media/ubuntu-iso/casper/filesystem.squashfs

#rename the uncompressed copy to indicate it's being edited
sudo mv squashfs-root edit


#if this file is being run from a clone of https://github.com/scotjam/cryptolive 
# (which it definitely should be) then the next piece is unnecessary as
# the main install script file will already exist
if [[ ! -e ./offlineWalletInstall.sh ]]; then
	#copy main installation script into our expanded squashfs filesystem for chroot
	wget https://github.com/scotjam/cryptolive/raw/master/offlineWalletInstall.sh
	#fix dos endline characters (could equally have used dos2unix) to get 
	# rid of bash: $'\r': command not found
	sed -i 's/\r$//' ./offlineWalletInstall.sh
	#make it executable
	chmod a+x ./offlineWalletInstall.sh	
fi


#copy it into the edited filesystem
sudo cp offlineWalletInstall.sh edit/tmp/

#pull your host's resolvconf info into the chroot
sudo mount -o bind /run/ edit/run

#(these mount important directories of your host system - if you later decide to delete the edit/ directory, then make sure to unmount before doing so, otherwise your host system will become unusable at least temporarily until reboot)
sudo mount --bind /dev/ edit/dev

#NOTE: Recommended that you do not do this unless you know what you're doing Depending on your configuration, you may also need to copy the hosts file. In our case it seems to be necessary otherwise we can't ping the host from within the guest
sudo cp /etc/hosts edit/etc/





#good reading about what the next command does here: https://help.ubuntu.com/community/BasicChroot

#below executes commands inside chroot itself. Could have alternatively gone with a separate script file like this:
#chroot edit/ ./chroot.sh
#################################################
#execute everything (before the second EOF) inside chroot
cat << EOF | sudo chroot edit
#redefine variables so they work inside chroot too
WORK_DIR="/media/temp-iso"
CRYPTO_USER="cryptolive"

#mount host resources into chroot directories
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

#export variables for GPG signing
export HOME=/root
export LC_ALL=C

#set up packaging in chroot
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
#sudo apt update
sudo apt-get update

#add user to install files
#echo "password should always be cryptoLive initially to achieve same iso hash value"
useradd -m -p tigKKMAi8ERPw -s /bin/bash $CRYPTO_USER
#adduser --disabled-password --gecos "" $CRYPTO_USER #doesn't allow sudo commands to be executed
usermod -aG sudo $CRYPTO_USER

#move crypto wallet install script into user's account
mv /tmp/offlineWalletInstall.sh /home/$CRYPTO_USER/

#good reading about the next command here: https://askubuntu.com/questions/294736/run-a-shell-script-as-another-user-that-has-no-password
#executes crypto wallet install script as user
#sudo -H -u $CRYPTO_USER /home/$CRYPTO_USER/offlineWalletInstall.sh

#instead of the above, trying executing as chroot directly
cd /home/$CRYPTO_USER
./offlineWalletInstall.sh

exit
#################################################
EOF




#can make $CRYPTO_USER perform an unattended install if we want (optional - it's a live cd so no install necessary)
#cd /home/$CRYPTO_USER
#wget https://pastebin.com/raw/Ga8CfRcB
#sed -i 's/\r$//' ./Ga8CfRcB
#mv Ga8CfRcB unattendedCryptoLive.sh
#sudo chmod a+x unattendedCryptoLive.sh
#sudo -H -u $CRYPTO_USER /home/$CRYPTO_USER/unattendedCryptoLive.sh
#rm ./unattendedCryptoLive.sh
#cd ~




#################################################
#execute everything (before the second EOF) inside chroot
cat << EOF | sudo chroot edit

#cleanup installed / temp files
apt-get autoremove
apt-get clean
apt-get autoclean
rm -rf /tmp/* ~/.bash_history
#undo hosts linking from sudo cp /etc/hosts edit/etc/
rm -f /etc/hosts
rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

#umount the things we mounted inside of chroot - can't chroot any more after this point
umount /proc || umount -lf /proc
umount /sys
umount /dev/pts

#generate updated manifest
echo "before new manifest"
dpkg-query -W --showformat='${Package} ${Version}\n' > /tmp/filesystem.manifest
echo "after new manifest"
exit
#################################################
EOF

#clear log files, cache files, time stamps and anything else we can think of that is likely
# to make the filesystem change over time even if we have done nothing different from our side

sudo rm -rf edit/var/log/*.log
sudo rm -rf edit/var/log/apt/*.log
sudo rm -rf edit/var/lib/apt/lists/*
sudo rm -rf edit/var/cache/*
sudo rm -rf edit/var/lib/doc-base/info/files*
sudo rm -rf edit/root/.wget-hsts
sudo rm -rf edit/root/.npm/registry.npmjs.org/source-map/.cache.json
sudo rm -rf edit/root/.npm/registry.npmjs.org/hawk/.cache.json
sudo rm -rf edit/root/.cache/*
sudo rm -rf edit/root/.mozilla/firefox/Crash Reports/*
sudo rm -rf edit/usr/sbin/zcashmini/.git
sudo rm -rf edit/run/log/journal/*
sudo rm -rf edit/run/reboot-required.pkgs
sudo rm -rf edit/run/sudo/ts/user
sudo rm -rf edit/.cache/

sudo find edit/ -name '*.pyc' -delete


: <<'COMMENT_OUT'
./var/lib/app-info/icons/ubuntu-xenial-security-main/64x64/eog_eog.png
./usr/local/lib/python3.5/dist-packages/qrcode/image/__pycache__/*
./usr/local/lib/python3.5/dist-packages/ecdsa-0.13.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/Electron_Cash-3.1.2.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/PyQt5-5.9.2.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/electrum_ltc/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/keepkey/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/email_requests/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/virtualkeyboard/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/greenaddress_instant/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/ledger/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/trustedcoin/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/audio_modem/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/digitalbitbox/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/labels/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/hw_wallet/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/trezor/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/cosigner_pool/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_plugins/__pycache__/*
./usr/local/lib/python3.5/dist-packages/ecdsa/__pycache__/*
./usr/local/lib/python3.5/dist-packages/dns/rdtypes/ANY/__pycache__/*
./usr/local/lib/python3.5/dist-packages/dns/__pycache__/*
./usr/local/lib/python3.5/dist-packages/dns/rdtypes/IN/__pycache__/*
./usr/local/lib/python3.5/dist-packages/dns/rdtypes/__pycache__/*
./usr/local/lib/python3.5/dist-packages/jsonrpclib/__pycache__/*
./usr/local/lib/python3.5/dist-packages/pyaes/__pycache__/*
./usr/local/lib/python3.5/dist-packages/protobuf-3.5.1.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/pyaes-1.6.1.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/Electrum_LTC-3.0.5.1.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/dnspython-1.15.0.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/google/protobuf/internal/__pycache__/*
./usr/local/lib/python3.5/dist-packages/google/protobuf/internal/import_test_package/__pycache__/*
./usr/local/lib/python3.5/dist-packages/google/protobuf/compiler/__pycache__/*
./usr/local/lib/python3.5/dist-packages/google/protobuf/pyext/__pycache__/*
./usr/local/lib/python3.5/dist-packages/google/protobuf/__pycache__/*
./usr/local/lib/python3.5/dist-packages/PyQt5/uic/widget-plugins/__pycache__/*
./usr/local/lib/python3.5/dist-packages/PyQt5/uic/port_v3/__pycache__/*
./usr/local/lib/python3.5/dist-packages/PyQt5/uic/Compiler/__pycache__/*
./usr/local/lib/python3.5/dist-packages/PyQt5/uic/Loader/__pycache__/*
./usr/local/lib/python3.5/dist-packages/PyQt5/uic/__pycache__/* 
./usr/local/lib/python3.5/dist-packages/electrum_gui/qt/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_gui/__pycache__/*
./usr/local/lib/python3.5/dist-packages/Electrum-3.0.5.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/Electrum-3.0.5.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/electrum/__pycache__/*


./usr/local/lib/python3.5/dist-packages/electrum_ltc_gui/qt/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_gui/__pycache__/*

./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/keepkey/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/email_requests/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/virtualkeyboard/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/greenaddress_instant/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/ledger/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/trustedcoin/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/audio_modem/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/digitalbitbox/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/labels/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/hw_wallet/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/trezor/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/cosigner_pool/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electrum_ltc_plugins/__pycache__/*


./usr/local/lib/python3.5/dist-packages/electroncash_gui/qt/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_gui/__pycache__/*

./usr/local/lib/python3.5/dist-packages/electroncash_plugins/keepkey/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/email_requests/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/virtualkeyboard/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/greenaddress_instant/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/ledger/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/trustedcoin/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/audio_modem/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/digitalbitbox/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/labels/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/hw_wallet/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/trezor/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/cosigner_pool/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash_plugins/__pycache__/*
./usr/local/lib/python3.5/dist-packages/electroncash/__pycache__/*

./usr/local/lib/python3.5/dist-packages/__pycache__/*
./usr/local/lib/python2.7/dist-packages/x11_hash-1.4.dist-info/RECORD
./usr/local/lib/python2.7/dist-packages/qrcode/*
./usr/lib/python3.5/idlelib/__pycache__/*
./usr/lib/python3.5/__pycache__/*

./usr/local/lib/python3.5/dist-packages/scrypt-0.8.0.dist-info/RECORD
./usr/local/lib/python3.5/dist-packages/jsonrpclib_pelix-0.3.1.dist-info/RECORD

./usr/local/lib/python3.5/dist-packages/_scrypt.cpython-35m-x86_64-linux-gnu.so
COMMENT_OUT

#make old manifest file writable
sudo chmod +w $WORK_DIR/casper/filesystem.manifest

#overwrite it with updated manifest
sudo mv -f $START_DIR/edit/tmp/filesystem.manifest $WORK_DIR/casper/filesystem.manifest
sudo cp $WORK_DIR/casper/filesystem.manifest $WORK_DIR/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' $WORK_DIR/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' $WORK_DIR/casper/filesystem.manifest-desktop

#compress filesystem
#sudo rm $WORK_DIR/casper/filesystem.squashfs we didn't copy it (rsync exclude) so we don't need to delete it
mksquashfs edit $WORK_DIR/casper/filesystem.squashfs
 
#update filesystem size (needed by installer)
sudo bash -c "printf $(sudo du -sx --block-size=1 edit | cut -f1) > $WORK_DIR/casper/filesystem.size"
 
#umount outside of chroot
sudo umount edit/dev
sudo umount edit/run

cd $WORK_DIR
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

sudo apt-get install -y xorriso
dd if=$START_DIR/ubuntu-16.04.3-desktop-amd64.iso bs=512 count=1 of=$START_DIR/my_isohdpfx.bin
cd $WORK_DIR

#create image
xorriso -as mkisofs \
  -isohybrid-mbr $START_DIR/my_isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o $START_DIR/cryptoLive-0.1.2.iso \
  $WORK_DIR

sha256sum $START_DIR/cryptoLive-0.1.2.iso > $START_DIR/cryptoLive-0.1.2.iso.sha256

#clean up iso mounting
#sudo umount $WORK_DIR
sudo umount /media/ubuntu-iso
sudo rm -rf $WORK_DIR
sudo rm -rf /media/ubuntu-iso

sudo rm -rf $START_DIR/edit
#rm ./offlineWalletInstall.sh 
rm $START_DIR/my_isohdpfx.bin

#to prevent redownloading every time during testing
#rm ./ubuntu-16.04.3-desktop-amd64.iso
