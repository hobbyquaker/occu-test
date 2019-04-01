#!/bin/bash

FLAVOR=${FLAVOR:-beta}

echo "creating directories"
[[ ! -d /etc/config ]] && mkdir -p /etc/config
[[ ! -d /www/rega ]] && mkdir -p /www/rega
[[ ! -d /config ]] && mkdir -p /config

echo "creating hook scripts"
echo -e "#!/bin/bash\necho /bin/hm_startup executed" > /bin/hm_startup
echo -e "#!/bin/bash\necho /bin/hm_autoconf executed" > /bin/hm_autoconf
chmod a+x /bin/hm_startup /bin/hm_autoconf

echo "cloning occu"
if [[ -d /occu ]]; then
 (cd /occu; git pull)
else
  git clone --depth=50 --branch=master https://github.com/jens-maus/occu /occu
fi

echo "copying files"
cp -v /occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/etc/rega.conf /etc/
echo -e "XmlRpcServerPort=31999" >>/etc/rega.conf
cp -v /occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/etc/config/InterfacesList.xml /etc/config/
cp -v /occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/bin/* /bin/
cp -v /occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI-Beta/bin/ReGaHss /bin/ReGaHss.beta
cp -v homematic.regadom /etc/config/
chmod -R a+rw /etc/config
[[ ${FLAVOR} =~ normal|community ]] && echo "/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/lib/" >/etc/ld.so.conf.d/hm.conf
[[ ${FLAVOR} =~ beta ]] && echo "/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI-Beta/lib/" >/etc/ld.so.conf.d/hm.conf

echo "installing required packages"
#dpkg --add-architecture i386
#apt-get -qq update || true
if [ $(dpkg-query -W -f='${Status}' libc6:i386 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -qq install libc6:i386
fi
if [ $(dpkg-query -W -f='${Status}' libstdc++6:i386 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -qq install libstdc++6:i386
fi
if [ $(dpkg-query -W -f='${Status}' libstdc++6:i386 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -qq install expect-dev
fi
ldconfig

echo "installing nvm/nodejs dependencies"
source ~/.bashrc
source ~/.profile
if [ ! -d ${NVM_DIR} ]; then
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
  source ~/.bashrc
  source ~/.profile
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 6
npm install

echo "running occu test..."
export FLAVOR=${FLAVOR}
npm test ${1}