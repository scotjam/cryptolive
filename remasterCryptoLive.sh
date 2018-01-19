#!/usr/bin/env bash

#Largely based on https://help.ubuntu.com/community/LiveCDCustomization
sudo apt-get install -y squashfs-tools genisoimage

#directory into which we will put the livecd contents
WORK_DIR="/media/temp-iso"

#username of the user we're adding to the livecd
CRYPTO_USER="cryptolive"

cd ~

if [[ ! -e ./ubuntu-16.04.3-desktop-amd64.iso ]]; then
	wget http://releases.ubuntu.com/16.04/ubuntu-16.04.3-desktop-amd64.iso
fi

sudo mkdir $WORK_DIR
sudo chmod 775 $WORK_DIR
sudo mkdir /media/ubuntu-iso

#mount our ubuntu ISO so that we can start copying files from it to 
# a local directory for editing
sudo mount -o loop ~/ubuntu-16.04.3-desktop-amd64.iso /media/ubuntu-iso

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
	wget https://pastebin.com/raw/hBqu4dc8
	#fix dos endline characters (could equally have used dos2unix) to get 
	# rid of bash: $'\r': command not found
	sed -i 's/\r$//' ./hBqu4dc8
	mv ./hBqu4dc8 ./offlineWalletInstall.sh
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
dpkg-query -W --showformat='${Package} ${Version}\n' > /tmp/filesystem.manifest
exit
#################################################
EOF


#make old manifest file writable
sudo chmod +w $WORK_DIR/casper/filesystem.manifest

#overwrite it with updated manifest
sudo mv -f edit/tmp/filesystem.manifest $WORK_DIR/casper/filesystem.manifest
sudo cp $WORK_DIR/casper/filesystem.manifest $WORK_DIR/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' $WORK_DIR/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' $WORK_DIR/casper/filesystem.manifest-desktop

#compress filesystem
#sudo rm $WORK_DIR/casper/filesystem.squashfs we didn't copy it (rsync exclude) so we don't need to delete it
sudo mksquashfs edit $WORK_DIR/casper/filesystem.squashfs
 
#update filesystem size (needed by installer)
sudo bash -c "printf $(sudo du -sx --block-size=1 edit | cut -f1) > $WORK_DIR/casper/filesystem.size"
 
#umount outside of chroot
sudo umount edit/dev
sudo umount edit/run

cd $WORK_DIR
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

sudo apt-get install -y xorriso
dd if=~/ubuntu-16.04.3-desktop-amd64.iso bs=512 count=1 of=~/my_isohdpfx.bin
cd $WORK_DIR

#create image
xorriso -as mkisofs \
  -isohybrid-mbr ~/my_isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o ~/cryptoLive-0.1.0.iso \
  $WORK_DIR

sha256sum ~/cryptoLive-0.1.0.iso > ~/cryptoLive-0.1.0.iso.sha256

cd ~
#clean up iso mounting
#sudo umount $WORK_DIR
sudo umount /media/ubuntu-iso
sudo rm -rf $WORK_DIR
sudo rm -rf /media/ubuntu-iso

sudo rm -rf ./edit
rm ~/offlineWalletInstall.sh
rm ~/my_isohdpfx.bin

#to prevent redownloading every time during testing
#rm ~/ubuntu-16.04.3-desktop-amd64.iso
