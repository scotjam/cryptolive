#!/usr/bin/env bash

#Shell script to install a selection of popular crypto currency clients for secure offline cold storage
#Providing offline transaction signing capabilities where available (e.g. electrum if version has been
# made available for a specific currency). Useful for building livecd ISO from running system:
# 1) install clean Ubuntu 16.04 system,
# 2) run this script (read it first to make sure it's puling things from their original sources and
#   not doing anything fishy (also good to check hashes / signatures of downloaded files before installation).
# 3) use a tutorial such as this to create your own livecd
# The purpose of creating a script to do this is so that we have an exact set of commands. If we start with
# a specific ubuntu iso (16.04), install it without an internet connection, then plug in the internet only
# to run this script, it may be possible to have a sort of deterministic livecd build that will be possible
# for trusted 3rd parties to verify. That makes it comfortable for more casual users to set up an offline
# signing situation for multiple cryptocurrencies by booting from a livecd (currently only possible
# for BTC, using the electrum client bundled with the TAILS livecd).

#TODO - make apt-get install deterministic https://askubuntu.com/questions/92019/how-to-install-specific-ubuntu-packages-with-exact-version
#TODO - add NEM

#Currently supported currencies: BTC BCH LTC DASH ETH XMR MIOTA ZEC XRP STR + walletgenerator.net

WORK_DIR="/home/cryptolive"

: <<'COMMENT_OUT'
xargs rm -rf <deletefiles.list
COMMENT_OUT

cd $WORK_DIR
mkdir $WORK_DIR/cryptoLiveExtras

#BTC Bitcoin (electrum). To run: electrum
sudo -S apt-get install -y python3-setuptools python3-pyqt5 pyqt5-dev-tools python3-pip python-pip libzbar-dev git
sudo -S pip install zbar
sudo -S pip3 install https://github.com/spesmilo/electrum/archive/3.0.5.zip
sudo -S git clone -b "3.0.5" https://github.com/spesmilo/electrum
cd electrum
sudo pyrcc5 icons.qrc -o /usr/local/lib/python3.5/dist-packages/electrum_gui/qt/icons_rc.py



#LTC Litecoin (electrum-ltc). To run: electrum-ltc
sudo -S apt-get install -y python3-setuptools python3-pyqt5 python3-pip python3-dev libssl-dev
sudo -S pip3 install https://electrum-ltc.org/download/Electrum-LTC-3.0.5.1.tar.gz

#BCH Bitcoin Cash (electron-cash). To run: electron-cash
sudo -S pip3 install https://electroncash.org/downloads/3.1.2/win-linux/ElectronCash-3.1.2.tar.gz

#DASH Dash (electrum-dash). To run: electrum-dash
#NOTE: ImportError: No module named 'version' or ImportError: cannot import name 'ELECTRUM_VERSION' or similar 
#is an issue with using python3 to install a python2 app. use pip install not pip3 install. 
# Otherwise all references need to be updated in the source code - see here for what was done for electrum proper - 
# https://github.com/spesmilo/electrum/issues/2995 and https://github.com/spesmilo/electrum/commit/30069324d53af2161e317da46fd266e60c899a37
sudo -S apt-get install -y python-pip libusb-1.0-0-dev libudev-dev python-qt4
sudo -S pip install https://github.com/akhavr/electrum-dash/releases/download/2.9.3.1/Electrum-DASH-2.9.3.1.tar.gz

#ETH Ethereum (MyEtherWallet). To run: node /usr/sbin/etherwallet/bin/startMEW.js
sudo -S apt-get install -y nodejs-legacy npm
cd $WORK_DIR
wget https://github.com/kvhnuke/etherwallet/releases/download/v3.11.2.4/etherwallet-v3.11.2.4.zip
unzip $WORK_DIR/etherwallet-v3.11.2.4.zip 
sudo -S rm -rf /usr/sbin/etherwallet
sudo -S mv $WORK_DIR/etherwallet-v3.11.2.4 /usr/sbin/etherwallet
cd /usr/sbin/etherwallet && sudo -S npm install open
#How to change working directory when open a file with double clicking on ubuntu desktop?
#https://askubuntu.com/questions/262861/how-to-change-working-directory-when-open-a-file-with-double-clicking-on-ubuntu
#Exec=bash -c 'cd "%k" && $WORK_DIR/path/to/your/file'
echo "[Desktop Entry]
Comment=Javascript ether wallet (Ethereum)
Exec=node /usr/sbin/etherwallet/bin/startMEW.js
GenericName[en_US]=Ethereum Wallet
GenericName=MyEtherWallet Ethereum Wallet 
Icon=/usr/sbin/etherwallet/images/myetherwallet-logo-square.png
Name[en_US]=Ethereum Wallet
Name=MyEtherWallet Ethereum Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/ethereum;" > $WORK_DIR/ether-wallet.desktop
desktop-file-validate $WORK_DIR/ether-wallet.desktop
#sudo -S rm /usr/share/applications/ether-wallet.desktop
sudo -S desktop-file-install $WORK_DIR/ether-wallet.desktop
rm $WORK_DIR/ether-wallet.desktop
sudo -S chmod a+x /usr/share/applications/ether-wallet.desktop

#XMR Monero (Monero Wallet Generator). To run: firefox /usr/sbin/monerowallet/monero-wallet-generator.html
sudo -S apt-get install -y git
cd $WORK_DIR
git clone -b "custom-entropy" https://github.com/moneromooo-monero/monero-wallet-generator
wget https://getmonero.org/press-kit/symbols/monero-symbol-480.png
mv ./monero-symbol-480.png ./monero-wallet-generator
#git clone -b "gh-pages" https://github.com/davidshimjs/qrcodejs
sudo -S rm -rf /usr/sbin/monerowallet
sudo -S mv $WORK_DIR/monero-wallet-generator /usr/sbin/monerowallet
echo "[Desktop Entry]
Comment=moneromooo html monero wallet
Exec=firefox /usr/sbin/monerowallet/monero-wallet-generator.html
GenericName[en_US]=Monero Wallet
GenericName=Monero Wallet 
Icon=/usr/sbin/monerowallet/monero-symbol-480.png
Name[en_US]=Monero Wallet
Name=Monero Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/monero;" > $WORK_DIR/monero-wallet.desktop
desktop-file-validate $WORK_DIR/monero-wallet.desktop
#sudo -S rm /usr/share/applications/monero-wallet.desktop
sudo -S desktop-file-install $WORK_DIR/monero-wallet.desktop
rm $WORK_DIR/monero-wallet.desktop
sudo -S chmod a+x /usr/share/applications/monero-wallet.desktop


#QR creator without the base43 nonsense of electrum. To run: nodejs ./javascript-qrcode-master/bin/qrcode -i /path/to/inputfile -o /path/to/outputfile -f svg
#To open svg files use imagemagick's "display": display /path/to/outputfile.svg
cd $WORK_DIR
wget https://github.com/siciarek/javascript-qrcode/archive/master.zip
mv ./master.zip ./javascript-qr.zip
unzip ./javascript-qr.zip 
sudo -S apt-get -y install nodejs
#npm install javascript-qrcode
mv ./javascript-qrcode-master $WORK_DIR/cryptoLiveExtras/javascript-qrcode-master

#printer driver source - add your own here - 
#wget http://download.brother.com/welcome/dlf100421/hl1110cupswrapper-3.0.1-1.i386.deb
#sudo ln -s /etc/init.d/cups /etc/init.d/lpd
#sudo mkdir /var/spool/lpd
#iff apparmor-utils are installed
#sudo aa-complain cupsd

#sudo mkdir /usr/share/cups/model
#sudo dpkg -i --force-all hl1110cupswrapper-3.0.1-1.i386.deb

#sudo apt-get install lib32stdc++6-4.7-dev 
#sudo dpkg -i --force-all hl1110cupswrapper-3.0.1-1.i386.deb
#sudo dpkg -i --force-all hl1110lpr-3.0.1-1.i386.deb
#lsusb # Bus <BUSID> Device <DEVID>: ID <PRINTERID>:<VENDOR> Hewlett-Packard DeskJet D1360
# chmod 0666 /dev/bus/usb/<BUSID>/<DEVID>
#sudo chmod 666 /dev/bus/usb/xxx/xxx
#sudo echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"<VENDOR>\", ATTRS{idProduct}==\"<PRINTERID>\", GROUP=\"lp\", MODE:=\"666\"" >> /etc/udev/rules.d/10-local.rules

#optional - install drivers for HL1110 printer
wget https://pastebin.com/raw/aqJDr46n
sed -i 's/\r$//' ./aqJDr46n
mv ./aqJDr46n ./linux-brprinter-installer-2.2.0-1
chmod a+x linux-brprinter-installer-2.2.0-1
echo "unresolved error at end of installation - ls: cannot access \'/etc/udev/rules.d/*.rules\': No such file or directory"
sudo ./linux-brprinter-installer-2.2.0-1 HL-1110

#XMR Monero (Monero GUI). To run: monero-gui-launch
mkdir $WORK_DIR/monero-offline-sign
cd $WORK_DIR/monero-offline-sign
wget https://www.reddit.com/r/Monero/comments/6b2od3/a_stepbystep_guide_for_cold_storage_and_offline/
cd $WORK_DIR
mv ./monero-offline-sign $WORK_DIR/cryptoLiveExtras/monero-offline-sign
wget https://downloads.getmonero.org/gui/monero-gui-linux-x64-v0.11.1.0.tar.bz2
tar -vxjf ./monero-gui-linux-x64-v0.11.1.0.tar.bz2
wget https://getmonero.org/press-kit/symbols/monero-symbol-480.png
mv ./monero-symbol-480.png ./monero-gui-v0.11.1.0
#git clone -b "gh-pages" https://github.com/davidshimjs/qrcodejs
sudo -S rm -rf /usr/sbin/monero-gui
sudo -S mv $WORK_DIR/monero-gui-v0.11.1.0 /usr/sbin/monero-gui
echo "[Desktop Entry]
Comment=Monero GUI wallet
Exec=/usr/sbin/monero-gui/start-gui.sh
GenericName[en_US]=Monero GUI Wallet
GenericName=Monero GUI Wallet 
Icon=/usr/sbin/monero-gui/monero-symbol-480.png
Name[en_US]=Monero GUI Wallet
Name=Monero GUI Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/monero;" > $WORK_DIR/monero-gui.desktop
desktop-file-validate $WORK_DIR/monero-gui.desktop
#sudo -S rm /usr/share/applications/monero-gui.desktop
sudo -S desktop-file-install $WORK_DIR/monero-gui.desktop
rm $WORK_DIR/monero-gui.desktop
sudo -S chmod a+x /usr/share/applications/monero-gui.desktop
sudo -S ln -s /usr/sbin/monero-gui/start-gui.sh /usr/sbin/monero-gui-launch

#Base43 converter to convert electrum-qr codes from base43 back to reality. To run: firefox $WORK_DIR/base43js-master/index.html (or firefox $WORK_DIR/base43js-master/2way.html)
sudo -S apt-get install -y npm
cd $WORK_DIR
wget https://github.com/jacoblyles/base43js/archive/master.zip
mv $WORK_DIR/master.zip $WORK_DIR/electrum-base43js-qrconvert.zip
unzip $WORK_DIR/electrum-base43js-qrconvert.zip 
npm install tap
#optional: to get encoding and decoding (2way) - 
# this is the only file that has been edited by me, the author of 
# this script. No hash / signature available so please view it with an 
# html or text editor before opening it in 
# a browser to verify it's not doing anything fishy!
cd $WORK_DIR/base43js-master
wget https://pastebin.com/raw/ASuube2M
mv ./ASuube2M ./2way.html
mv ./base43js-master $WORK_DIR/cryptoLiveExtras/base43js-master


#MIOTA IOTA (IOTA Paper Wallet). To run: firefox /usr/sbin/iota-wallet/index.html
cd $WORK_DIR
wget https://arancauchi.github.io/IOTA-Paper-Wallet/out/offline-build.zip
mkdir $WORK_DIR/iota-wallet
unzip $WORK_DIR/offline-build.zip -d $WORK_DIR/iota-wallet
rm $WORK_DIR/offline-build.zip
sudo -S rm -rf /usr/sbin/iota-wallet
sudo -S mv $WORK_DIR/iota-wallet /usr/sbin/iota-wallet
echo "[Desktop Entry]
Comment=MIOTA (IOTA) paper wallet generator
Exec=firefox /usr/sbin/iota-wallet/index.html
GenericName[en_US]=IOTA Paper Wallet
GenericName=IOTA Paper Wallet
Icon=/usr/sbin/iota-wallet/img/logo.png
Name[en_US]=IOTA Paper Wallet
Name=IOTA Paper Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/iota;" > $WORK_DIR/iota-wallet.desktop
desktop-file-validate $WORK_DIR/iota-wallet.desktop
#sudo -S rm /usr/share/applications/iota-wallet.desktop
sudo -S desktop-file-install $WORK_DIR/iota-wallet.desktop
rm $WORK_DIR/iota-wallet.desktop
sudo -S chmod a+x /usr/share/applications/iota-wallet.desktop

#ZEC ZCash (ZCash Mini). To run: zcash-mini
cd $WORK_DIR 
git clone https://github.com/FiloSottile/zcash-mini
sudo -S apt-get install -y golang
sudo -S rm -rf /usr/sbin/zcashmini
cd zcash-mini && make && cd .. && sudo -S mv ./zcash-mini /usr/sbin/zcashmini
wget https://z.cash/theme/images/yellow-zcash-logo.png
sudo -S mv ./yellow-zcash-logo.png /usr/sbin/zcashmini
echo "[Desktop Entry]
Comment=Zcash mini wallet (command line)
Exec=bash -c \"/usr/sbin/zcashmini/bin/zcash-mini && sleep infinity\"
GenericName[en_US]=Zcash Mini Wallet
GenericName=Zcash Mini Wallet
Icon=/usr/sbin/zcashmini/yellow-zcash-logo.png
Name[en_US]=Zcash Mini Wallet
Name=Zcash Mini Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=true
Type=Application
MimeType=x-scheme-handler/zcash;" > $WORK_DIR/zcash-mini.desktop
desktop-file-validate $WORK_DIR/zcash-mini.desktop
#sudo -S rm /usr/share/applications/zcash-mini.desktop
sudo -S desktop-file-install $WORK_DIR/zcash-mini.desktop
rm $WORK_DIR/zcash-mini.desktop
sudo -S chmod a+x /usr/share/applications/zcash-mini.desktop
#symlink all binaries into /usr/sbin
for f in $(ls -d /usr/sbin/zcashmini/bin/*); 
	do sudo -S ln -s $f /usr/sbin; 
done

#XRP Ripple (Rippex Ripple Wallet fork). To run: ripple-wallet-launch
cd $WORK_DIR
wget https://s3.amazonaws.com/static.rippex.net/client/ripple-wallet-linux64-1.4.1.zip
mkdir $WORK_DIR/ripple-wallet
unzip $WORK_DIR/ripple-wallet-linux64-1.4.1.zip -d $WORK_DIR/ripple-wallet
rm $WORK_DIR/ripple-wallet-linux64-1.4.1.zip
wget https://ripple.com/files/ripple_logos.zip 
unzip ripple_logos.zip -d $WORK_DIR/ripple-wallet
rm $WORK_DIR/ripple_logos.zip
sudo -S rm -rf /usr/sbin/ripple-wallet
sudo -S mv $WORK_DIR/ripple-wallet /usr/sbin/ripple-wallet
echo "[Desktop Entry]
Comment=Rippex Ripple Wallet fork
Exec=/usr/sbin/ripple-wallet/RippleAdminConsole-1.4.1
GenericName[en_US]=Rippex Ripple Wallet
GenericName=Rippex Ripple Wallet
Icon=/usr/sbin/ripple-wallet/ripple_logos/ripple_logo_mark.png
Name[en_US]=Rippex Ripple Wallet
Name=Rippex Ripple Wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/ripple;" > $WORK_DIR/ripple-wallet.desktop
sudo -S chmod a+r /usr/sbin/ripple-wallet/ripple_logos/ripple_logo_mark.png
desktop-file-validate $WORK_DIR/ripple-wallet.desktop
#sudo -S rm /usr/share/applications/ripple-wallet
sudo -S desktop-file-install $WORK_DIR/ripple-wallet.desktop
rm $WORK_DIR/ripple-wallet.desktop
sudo -S chmod a+x /usr/share/applications/ripple-wallet.desktop
sudo -S ln -s /usr/sbin/ripple-wallet/RippleAdminConsole-1.4.1 /usr/sbin/ripple-wallet-launch 

#STR Stellar (Stellar Chat Desktop Client). To run: stellar-desktop-launch 
cd $WORK_DIR
wget https://github.com/stellarchat/desktop-client/releases/download/v3.3/StellarDesktopLinux64-v3.3.zip
unzip $WORK_DIR/StellarDesktopLinux64-v3.3.zip
mv ./linux64 ./StellarDesktop-v3.3
chmod +x $WORK_DIR/StellarDesktop-v3.3/StellarWallet 
wget https://s3.amazonaws.com/stellar.org/public/Stellar-presskit-150217.zip 
mkdir $WORK_DIR/StellarDesktop-v3.3/images
unzip Stellar-presskit-150217.zip -d $WORK_DIR/StellarDesktop-v3.3/images
rm $WORK_DIR/Stellar-presskit-150217.zip
sudo -S rm -rf /usr/sbin/stellar-desktop
sudo -S mv $WORK_DIR/StellarDesktop-v3.3 /usr/sbin/stellar-desktop
echo "[Desktop Entry]
Comment=Stellar Desktop wallet v3.3
Exec=/usr/sbin/stellar-desktop/StellarWallet
GenericName[en_US]=Stellar Desktop wallet
GenericName=Stellar Desktop wallet
Icon=/usr/sbin/stellar-desktop/images/stellar-rocket.png
Name[en_US]=Stellar Desktop wallet
Name=Stellar Desktop wallet
Categories=Finance;Network;
StartupNotify=false
Terminal=false
Type=Application
MimeType=x-scheme-handler/stellar;" > $WORK_DIR/stellar-desktop.desktop
desktop-file-validate $WORK_DIR/stellar-desktop
#sudo -S rm /usr/share/applications/stellar-desktop
sudo -S desktop-file-install $WORK_DIR/stellar-desktop.desktop
rm $WORK_DIR/stellar-desktop.desktop
sudo -S chmod a+x /usr/share/applications/stellar-desktop.desktop
sudo -S ln -s /usr/sbin/stellar-desktop/StellarWallet /usr/sbin/stellar-desktop-launch 

#XEM NEM
cd $WORK_DIR
wget https://www.dropbox.com/s/i2d31xwm7zpowbk/Voucher%2BPaper_Wallet_Generator%20--%20Apostille%20TX%2066f9b74a34747f904d97751f3bfd321201d6c7b351786148fd41ecd8e372d5f5%20--%20Date%202016-11-10.zip?dl=0
mv "Voucher+Paper_Wallet_Generator -- Apostille TX 66f9b74a34747f904d97751f3bfd321201d6c7b351786148fd41ecd8e372d5f5 -- Date 2016-11-10.zip?dl=0" ./NEM-Paper-Wallet.zip
#unzip $WORK_DIR/NEM-Paper-Wallet.zip
mv ./NEM-Paper-Wallet.zip $WORK_DIR/cryptoLiveExtras/NEM-Paper-Wallet.zip

#WalletGenerator.net for multiple crypto currencies. To run: firefox /usr/sbin/WalletGenerator.net/index.html
sudo -S apt-get install -y git
cd $WORK_DIR
git clone -b "v2017.12.30" https://github.com/MichaelMure/WalletGenerator.net 
sudo -S mv ./WalletGenerator.net /usr/sbin/WalletGenerator.net


sudo -S apt autoremove -y

sudo -S rm -f $WORK_DIR/electrum-base43js-qrconvert.zip
sudo -S rm -f $WORK_DIR/etherwallet-v3.11.2.4.zip
sudo -S rm -f $WORK_DIR/javascript-qr.zip
sudo -S rm -f $WORK_DIR/monero-gui-linux-x64-v0.11.1.0.tar.bz2
sudo -S rm -f $WORK_DIR/offline-build.zip
sudo -S rm -f $WORK_DIR/ripple-wallet-linux64-1.4.1.zip
sudo -S rm -f $WORK_DIR/StellarDesktopLinux64-v3.3.zip
sudo -S rm -rf $WORK_DIR/zcash-mini

#sudo -S add-apt-repository -y ppa:nemh/systemback
#sudo -S apt-get update

#echo "Systemback can be used to set up a livecd - click Live System create and follow the instructions. Save the image somewhere with at least 3GB free space"
#echo "Make sure to check the box to include user data files"
#echo "Once complete, you can also choose convert to ISO"
#echo "To copy to USB, launch systemback, insert an empty USB drive with at least 4GB capacity and click the refresh button"
#sudo -S apt-get install -y casper cifs-utils dmsetup grub-common grub-efi-amd64-bin grub-pc grub-pc-bin grub2-common isolinux keyutils libsystemback localechooser-data lupin-casper python-crypto python-ldb python-samba python-tdb samba-common samba-common-bin syslinux-utils systemback-cli systemback-efiboot-amd64 systemback-locales systemback-scheduler user-setup casper cifs-utils dmsetup grub-efi-amd64-bin isolinux keyutils libsystemback localechooser-data lupin-casper python-crypto python-ldb python-samba python-tdb samba-common samba-common-bin syslinux-utils systemback systemback-cli systemback-efiboot-amd64 systemback-locales systemback-scheduler user-setup

#sudo -S apt-get install -y systemback

#sudo -S apt-get install -y gksu

#gksu systemback
#commenting out as we're now editing an existing ISO here rather than making a new one from an installed system
#sudo -S mv /home/systemback_live_*.iso $WORK_DIR/cryptoLive-0.1.iso

#sudo -S add-apt-repository -y ppa:mkusb/ppa
#sudo -S apt-get update
#sudo -S apt-get install -y mkusb mkusb-nox usb-pack-efi

#commenting out as we're not making a USB just yet, and it won't work anyway without tty / gtk?
#sudo -S mkusb-nox $WORK_DIR/cryptoLive-0.1.iso

#create firefox profile for livecd user cryptolive
firefox -CreateProfile cryptolive

#Fix icon permissions
sudo chmod a+r /usr/local/lib/python2.7/dist-packages/usr/share/pixmaps/electrum-dash.png
sudo chmod a+r /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electrum.png
sudo chmod a+r /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electron-cash.png
sudo chmod a+r /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electrum-ltc.png

#copy icons to /usr/share/pixmaps/
sudo cp /usr/local/lib/python2.7/dist-packages/usr/share/pixmaps/electrum-dash.png /usr/share/pixmaps/
sudo cp /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electrum.png /usr/share/pixmaps/
sudo cp /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electrum-ltc.png /usr/share/pixmaps/
sudo cp /usr/local/lib/python3.5/dist-packages/usr/share/pixmaps/electron-cash.png /usr/share/pixmaps/

#add python installed apps to the ubuntu unity search bar
sudo desktop-file-install /usr/local/lib/python3.5/dist-packages/usr/share/applications/electrum.desktop
sudo desktop-file-install /usr/local/lib/python3.5/dist-packages/usr/share/applications/electrum-ltc.desktop
sudo desktop-file-install /usr/local/lib/python3.5/dist-packages/usr/share/applications/electron-cash.desktop 
sudo desktop-file-install /usr/local/lib/python2.7/dist-packages/usr/share/applications/electrum-dash.desktop 
sudo desktop-file-install /usr/local/lib/python2.7/dist-packages/usr/share/applications/electrum-dash.desktop 

#add permissions for user accounts to run the shortcuts
sudo chmod a+x /usr/share/applications/electrum.desktop
sudo chmod a+x /usr/share/applications/electrum-ltc.desktop
sudo chmod a+x /usr/share/applications/electron-cash.desktop
sudo chmod a+x /usr/share/applications/electrum-dash.desktop
sudo chmod a+x /usr/share/applications/ether-wallet.desktop
sudo chmod a+x /usr/share/applications/monero-wallet.desktop
sudo chmod a+x /usr/share/applications/monero-gui.desktop
sudo chmod a+x /usr/share/applications/iota-wallet.desktop
sudo chmod a+x /usr/share/applications/zcash-mini.desktop
sudo chmod a+x /usr/share/applications/ripple-wallet.desktop
sudo chmod a+x /usr/share/applications/stellar-desktop.desktop

: <<'COMMENT_OUT'
##########################
##########################
##########################
#The following section is all commented out
##########################
##########################
##########################
##########################

xargs rm -rf <deletefiles.list

#Another option for creating a bootable USB once we have an iso, but this script is now geared towards editing an existing iso instead of creating a bootable USB
STARTUP_DISK_CREATOR_LOC="$(dpkg -L usb-creator-gtk | grep bin/usb-creator-gtk)"
exec $STARTUP_DISK_CREATOR_LOC $WORK_DIR/cryptoLive-0.1.iso

#Remake ISO so it's hybrid bootable using xorriso, using the first byte from Ubuntu bootable disk
# following instructions from here: https://askubuntu.com/questions/625286/how-to-create-uefi-bootable-iso or here http://www.syslinux.org/wiki/index.php?title=Isohybrid
cd $WORK_DIR

ISO_SOURCE="$(ls /home/systemback_live_*.iso)"
mkdir tmp
sudo -S apt-get install -y xorriso 
sudo -S mkdir /media/temp-iso
dd if="$ISO_SOURCE" bs=512 count=1 of=$WORK_DIR/my_isohdpfx.bin
sudo -S mount /home/systemback_live_*.iso /media/temp-iso/
cd /media/temp-iso

xorriso -as mkisofs \
  -isohybrid-mbr $WORK_DIR/my_isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o $WORK_DIR/cryptoLive-0.1.iso \
  /media/temp-iso

cd $WORK_DIR
rm $WORK_DIR/mini.iso
rm -r $WORK_DIR/tmp
sudo -S umount /media/temp-iso
sudo -S rm -r /media/temp-iso
rm $WORK_DIR/my_isohdpfx.bin

cd $WORK_DIR
sudo -S apt-get install -y unetbootin

# Optional & DANGEROUS:
# copy to usb (make sure /dev/sdb is 
# definitely the drive you want to overwrite and that there is 
# nothing you want to keep!!). 
# Use sudo -S fdisk -l to see all disks and device paths
# sudo -S dd if=$WORK_DIR/cryptoLive-0.1.iso bs=2048 of=/dev/sdb

COMMENT_OUT

#Optional: test drive on virtualbox. Must log out and back in after running the commands below for them 
# to take full effect, but you may get away without doing so
# sudo -S apt-get install -y virtualbox virtualbox-ext-pack
# sudo -S usermod -a -G vboxusers $USER
# sudo -S VBoxManage internalcommands createrawvmdk -filename $WORK_DIR/usb.vmdk -rawdisk /dev/sdb1
# sudo -S chmod 777 $WORK_DIR/usb.vmdk
# gksu virtualbox
# echo "Create new virtual box, set type to Linux, Version to Other Linux 64 bit, next, next, "
# echo " do not add virtual hard disk, create, continue"
# echo "Click Settings, storage and click the little rectangle with green plus next to Controller:IDE"
# echo "Choose existing disk, navigate to $WORK_DIR/usb.vmdk and select it. Click open"
