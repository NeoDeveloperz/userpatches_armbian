#!/bin/bash

#set -x







BLACK='\e[0;30m'
WHITE='\e[0;37m'
RED='\e[0;31m'
BLUE='\e[0;34m'
YELLOW='\e[0;33m'
GREEN='\e[0;32m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
NC='\033[0m'


RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4





# Prüfen, ob die Variable $BOARD gesetzt ist
if [ -z "$BOARD" ]; then
  echo "${RED}ERROR${NC}: ${CYAN}Var \$BOARD not set!."
  exit 1
fi




# Setzen der hwboard-Variablen
hwboard=$BOARD



# Pfade, desen rechte gesetzt werden müssen
paths=("/etc/init.d/set_led_trigger.sh" "/var/lib/bananapi" "/usr/share/libarys")

# Verzeichnisse die erstellt werden müssen
dirs=("/var/lib" "/usr/local/bin" "/usr/share/libarys")


# Definiere onBOARD LED init.d-Service Trigger Scripts
TMP_LED_TRIGGER="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh" # File in OVERLAY (NEEDS COPY TO)
LED_TRIGGER_SERVICE="/etc/init.d/set_led_trigger.sh" # File in CHROOT-TARGET

# Github Repository List
git_repos="/tmp/overlay/git_repos/repos.txt"

# GPIO Libarys Dir
$GPIO_LIBARYS="/usr/share/libarys"



# Definieren des Quell- und Zielverzeichnisses der Board-Determinier Datein
BOARD_DETERMINER_SOURCE_DIR="/tmp/overlay/boards/$hwboard"
BOARD_DETERMINER_TARGET_DIR="/var/lib"






manage_service() {
	local scriptname=$1
	local option=$2

	if [[ -z "$scriptname" || -z "$option" ]]; then
		echo "Usage: manage_service <scriptname> <option>"
		echo "Options: defaults, remove, disable, enable"
		return 1
	fi

	case $option in
	defaults | remove | disable | enable)
		echo "${GREEN}INFO: ${BLUE} Register init.d-service: $scriptname "
		sudo update-rc.d "$scriptname" "$option"
		;;
	*)
		echo "Invalid option: $option"
		echo "Options: defaults, remove, disable, enable"
		return 1
		;;
	esac
}





create_dirs() {
    echo "${GREEN}INFO ${BLACK}: ${CYAN}Creating directories: ${dirs[@]} ${NC}"
	for dir in "${dirs[@]}"; do
		mkdir -p "$dir"
		chmod 777 -R "$dir"
	done
}

grant_permissions() {
	echo "${GREEN}INFO ${BLACK}: ${CYAN}GRANT PERMISSIONS: ${paths[@]} ${NC}"
	for path in "${paths[@]}"; do
		chmod 777 -R "$path"
	done
}





install() {
	local distro=$1
  	local release=$2

	if [[ -z "$distro" || -z "$release" ]]; then
    	echo "Usage: install <distro> <release>"
    	echo "Distro: debian, ubuntu"
		echo "Release-Debian: stretch, buster, bullseye, bookworm, trixie, sid"
		echo "Release-Ubuntu: xenial, bionic, focal, jammy, noble"
		echo "Release-Both: default"
    	return 1
  	fi

	case $release in
	  stretch|buster|bullseye|bookworm|trixie|sid|xenial|bionic|focal|jammy|noble)
	  	packages_file="/tmp/overlay/packages_files/$distro/$release.txt"
	  	install_packages "${packages_file}"
		;;
      default)
	    packages_file="/tmp/overlay/packages_files/$release.txt"
		install_packages "${packages_file}"
		;;
	  *)
		echo "Invalid Release!"
		return 1
		;;
	esac
}



install_packages() {
  local package_file=$1

  echo -e "${RED}Console > ${NC}${CYAN} Installing APT-Packages!"

  if [[ ! -f "$package_file" ]]; then
    echo "File $package_file not found!"
    return 1
  fi
  while IFS= read -r package; do
    if [[ -n "$package" ]]; then
      echo "${GREEN} Installing $package..."
      apt-get install -y "$package"
    fi
  done < "$package_file"
}






git_repos() {
    echo -e "${RED}Console > ${NC}${CYAN} Cloning Git-Repoisotrys!"

  	if [ ! -f "$git_repos" ]; then
	    echo "$git_repos does not exist."
	    exit 1
	fi

	while IFS= read -r repo; do
	    echo "Cloning $repo..."
		cd /usr/share/libarys
	    git clone "$repo"
	done < "$git_repos"

	chmod 777 -R ./*
	echo -e "/usr/local/lib" >> /etc/ld.so.conf
		

	echo "${RED}INFO: ${CYAN} Installing BPI-WiringPi2 !"
	cd BPI-WiringPi2
	./build 
	ldconfig
	cd wiringPi
  	make static
  	sudo make install-static
	echo "${RED}INFO: ${CYAN} DONE Installing BPI-WiringPi2 !"


	echo "${RED}INFO: ${CYAN} Installing BPI-WiringPi2-Python !"
	cd /usr/share/libarys/BPI-WiringPi2-Python
	swig -python wiringpi.i
	python3 setup.py build install
	echo "${RED}INFO: ${CYAN} DONE Installing BPI-WiringPi2-Python !"


	echo "${RED}INFO: ${CYAN} Installing RPi.GPIO !"
	cd /usr/share/libarys/RPi.GPIO
	python3 create_gpio_user_permissions.py
	python3 setup.py install
	echo "${RED}INFO: ${CYAN} DONE Installing RPi.GPIO !"


	echo "${RED}INFO: ${CYAN} Installing luma.oled !"
	cd /usr/share/libarys/luma.oled

	commands=("python3 -m pip install -U pip" "python3 -m pip install setuptools disutils wheel" "python3 -m pip install pillow" "python3 -m pip install luma.oled")
	for command in "${commands[@]}"; do
		if "$command" 2>/dev/null; then 
		echo "Der Befehl $command wurde erfolgreich ausgeführt." 
	else 
		echo "Der Befehl mit  ist fehlgeschlagen. Führe den Befehl ohne diesen Parameter aus." 
		"$command" --break-system-packages
	fi
	done
	
	python3 setup.py install
	echo "${RED}INFO: ${CYAN} DONE Installing luma.oled !"

}


create_usr_and_grps() {
	echo "${RED}INFO: ${CYAN} Creating default USER: ${GREEN}bananapi !"
	useradd -m bananapi
	echo "${BLUE}ADDING USER TO GPIO-GORUPS: I2C, SPI & GPIO!"

	groupadd -f -r gpio

	cd /usr/share/libarys/RPi.GPIO
	python3 create_gpio_user_permissions.py

	gpasswd -a bananapi sudo
	gpasswd -a bananapi i2c
	gpasswd -a bananapi spi
	gpasswd -a bananapi gpio

}

enable_gpio_interfaces() {
	echo "${RED}INFO: ${CYAN} ENABLING ALL HARDWARE INTERFACES!"
	if [[ "$hwboard" == "bananapim2berry" || "$hwboard" == "bananapim2ultra" ]]; then
		echo -e "fdt_overlays=sun8i-r40-i2c2 sun8i-r40-i2c3 sun8i-r40-spi-spidev0 sun8i-r40-spi-spidev1 sun8i-r40-uart2" >> /boot/armbianEnv.txt
	else
		echo "${RED}ERROR: CANT ENABLE HARDWARE INTERFACES RIGHT NOW, DEVICETREEOVERLAYS FOR THIS BOARD ARE CURRENTLY NOT SUPPORTED!"
	fi
}

board_determiner() {
	echo "${RED}INFO: ${CYAN} COPYING BOARD-DETERMINIER FILES!"
    if [ -d "$BOARD_DETERMINER_SOURCE_DIR" ]; then
        cp -r "$BOARD_DETERMINER_SOURCE_DIR"/* "$BOARD_DETERMINER_TARGET_DIR"/
        echo "${GREEN}INFO: ${CYAN}COPYIN FROM > $BOARD_DETERMINER_SOURCE_DIR | to >  $BOARD_DETERMINER_TARGET_DIR | !."
    else
        echo "${RED}ERROR: ${CYAN}Dir $BOARD_DETERMINER_SOURCE_DIR dosent exist."
        exit 1
    fi
	echo "${RED}INFO: ${CYAN} DONE COPYING BOARD-DETERMINIER FILES!"
}




led_trigger() {
	echo "${GREEN}INFO: Settingup onBOARD LED Trigger to: ${RED}RED: ${BLUE}CPU0 ${GREEN}GREEN: ${CYAN}heartbeat!"

	case $hwboard in 
		bananapim2ultra)
			echo "${GREEN}INFO: ${CYAN}Copying LED-Trigger from overlay to /etc/init.d !"
			cp -r "$TMP_LED_TRIGGER" "$LED_TRIGGER_SERVICE"
			grant_permissions;
			echo "Enable init.d Service!"
			sleep 1
			manage_service "set_led_trigger.sh" "defaults"
			;;
		bananapim2berry)
			echo "${GREEN}INFO: ${CYAN}Copying LED-Trigger from overlay to /etc/init.d !"
			cp -r "$TMP_LED_TRIGGER" "$LED_TRIGGER_SERVICE"
			grant_permissions;
			echo "Enable init.d Service!"
			sleep 1
			manage_service "set_led_trigger.sh" "defaults"
			;;
        *)
            echo "INVALID"
            ;;
    esac
}







build() {
    apt-get update;
    install "default";

    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps

}

build_xenial() {
    apt-get update;
    install "ubuntu" "xenial";
    create_dirs;
    led_trigger;
    board_determiner;
    
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_bionic() {
	apt-get update;
    install "ubuntu" "bionic";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_focal() {
	apt-get update;
    install "ubuntu" "focal";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_jammy() {
	apt-get update;
    install "ubuntu" "jammy";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_noble() {
	apt-get update;
    install "ubuntu" "noble";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_stretch() {
	apt-get update;
    install "debian" "stretch";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_buster() {
	apt-get update;
    install "debian" "buster";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_bullseye() {
	apt-get update;
	# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93D6889F9F0E78D5
    # wget -qO - https://armbian.github.io/configng/KEY.gpg | sudo apt-key add -
	# gpg --export 93D6889F9F0E78D5 | sudo tee /etc/apt/trusted.gpg.d/armbian.gpg
	# apt-key net-update
	# apt-key update
	# apt-get update;

    install "debian" "bullseye";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps

}

build_bookworm() {
    apt-get update;
    install "debian" "bookworm";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps
}

build_trixie() {
    apt-get update;
    install "debian" "trixie";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps

}

build_sid() {
    apt-get update;
    install "debian" "sid";
    create_dirs;
    led_trigger;
    board_determiner;
    git_repos;
	grant_permissions;

	enable_gpio_interfaces
	create_usr_and_grps

}




Main() {
	case $RELEASE in
		stretch)
			build_stretch;
			;;
		buster)
			build_buster;
			;;
		jammy)
			build_jammy;
			;;
		xenial)
			build_xenial;
			;;
		bookworm)
			build_bookworm;
			;;
		bullseye)
			build_bullseye;
			;;
		bionic)
			build_bionic;
			;;
		focal)
			build_focal;
			;;
		noble)
			build_noble;
			;;
		sid)
			build;
			;;
		trixie)
			build;
			;;
	esac
} 
# Main


InstallOpenMediaVault() {
	# This routine is based on idea/code courtesy Benny Stark. For fixes,
	# discussion and feature requests please refer to
	# https://forum.armbian.com/index.php?/topic/2644-openmediavault-3x-customize-imagesh/

	echo root:openmediavault | chpasswd
	rm /root/.not_logged_in_yet
	. /etc/default/cpufrequtils
	export LANG=C LC_ALL="de_DE.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	case ${RELEASE} in
		jessie)
			OMV_Name="erasmus"
			OMV_EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all3.deb"
			;;
		stretch)
			OMV_Name="arrakis"
			OMV_EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all4.deb"
			;;
	esac

	# Add OMV source.list and Update System
	cat > /etc/apt/sources.list.d/openmediavault.list <<- EOF
	deb https://openmediavault.github.io/packages/ ${OMV_Name} main
	## Uncomment the following line to add software from the proposed repository.
	deb https://openmediavault.github.io/packages/ ${OMV_Name}-proposed main

	## This software is not part of OpenMediaVault, but is offered by third-party
	## developers as a service to OpenMediaVault users.
	# deb https://openmediavault.github.io/packages/ ${OMV_Name} partner
	EOF

	# Add OMV and OMV Plugin developer keys, add Cloudshell 2 repo for XU4
	if [ "${BOARD}" = "odroidxu4" ]; then
		add-apt-repository -y ppa:kyle1117/ppa
		sed -i 's/jessie/xenial/' /etc/apt/sources.list.d/kyle1117-ppa-jessie.list
	fi
	mount --bind /dev/null /proc/mdstat
	apt-get update
	apt-get --yes --force-yes --allow-unauthenticated install openmediavault-keyring
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7AA630A1EDEE7D73
	apt-get update

	# install debconf-utils, postfix and OMV
	HOSTNAME="${BOARD}"
	debconf-set-selections <<< "postfix postfix/mailname string ${HOSTNAME}"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
	apt-get --yes --force-yes --allow-unauthenticated  --fix-missing --no-install-recommends \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install \
		debconf-utils postfix
	# move newaliases temporarely out of the way (see Ubuntu bug 1531299)
	cp -p /usr/bin/newaliases /usr/bin/newaliases.bak && ln -sf /bin/true /usr/bin/newaliases
	sed -i -e "s/^::1         localhost.*/::1         ${HOSTNAME} localhost ip6-localhost ip6-loopback/" \
		-e "s/^127.0.0.1   localhost.*/127.0.0.1   ${HOSTNAME} localhost/" /etc/hosts
	sed -i -e "s/^mydestination =.*/mydestination = ${HOSTNAME}, localhost.localdomain, localhost/" \
		-e "s/^myhostname =.*/myhostname = ${HOSTNAME}/" /etc/postfix/main.cf
	apt-get --yes --force-yes --allow-unauthenticated  --fix-missing --no-install-recommends \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install \
		openmediavault

	# install OMV extras, enable folder2ram and tweak some settings
	FILE=$(mktemp)
	wget "$OMV_EXTRAS_URL" -qO $FILE && dpkg -i $FILE

	/usr/sbin/omv-update
	# Install flashmemory plugin and netatalk by default, use nice logo for the latter,
	# tweak some OMV settings
	. /usr/share/openmediavault/scripts/helper-functions
	apt-get -y -q install openmediavault-netatalk openmediavault-flashmemory
	AFP_Options="mimic model = Macmini"
	SMB_Options="min receivefile size = 16384\nwrite cache size = 524288\ngetwd cache = yes\nsocket options = TCP_NODELAY IPTOS_LOWDELAY"
	xmlstarlet ed -L -u "/config/services/afp/extraoptions" -v "$(echo -e "${AFP_Options}")" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/smb/extraoptions" -v "$(echo -e "${SMB_Options}")" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/flashmemory/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/ssh/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/services/ssh/permitrootlogin" -v "0" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/time/ntp/enable" -v "1" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/time/timezone" -v "UTC" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/network/dns/hostname" -v "${HOSTNAME}" /etc/openmediavault/config.xml
	xmlstarlet ed -L -u "/config/system/monitoring/perfstats/enable" -v "0" /etc/openmediavault/config.xml
	echo -e "OMV_CPUFREQUTILS_GOVERNOR=${GOVERNOR}" >>/etc/default/openmediavault
	echo -e "OMV_CPUFREQUTILS_MINSPEED=${MIN_SPEED}" >>/etc/default/openmediavault
	echo -e "OMV_CPUFREQUTILS_MAXSPEED=${MAX_SPEED}" >>/etc/default/openmediavault
	for i in netatalk samba flashmemory ssh ntp timezone interfaces cpufrequtils monit collectd rrdcached ; do
		/usr/sbin/omv-mkconf $i
	done
	/sbin/folder2ram -enablesystemd || true
	sed -i 's|-j /var/lib/rrdcached/journal/ ||' /etc/init.d/rrdcached

	# Fix multiple sources entry on ARM with OMV4
	sed -i '/stretch-backports/d' /etc/apt/sources.list

	# rootfs resize to 7.3G max and adding omv-initsystem to firstrun -- q&d but shouldn't matter
	echo 15500000s >/root/.rootfs_resize
	sed -i '/systemctl\ disable\ armbian-firstrun/i \
	mv /usr/bin/newaliases.bak /usr/bin/newaliases \
	export DEBIAN_FRONTEND=noninteractive \
	sleep 3 \
	apt-get install -f -qq python-pip python-setuptools || exit 0 \
	pip install -U tzupdate \
	tzupdate \
	read TZ </etc/timezone \
	/usr/sbin/omv-initsystem \
	xmlstarlet ed -L -u "/config/system/time/timezone" -v "${TZ}" /etc/openmediavault/config.xml \
	/usr/sbin/omv-mkconf timezone \
	lsusb | egrep -q "0b95:1790|0b95:178a|0df6:0072" || sed -i "/ax88179_178a/d" /etc/modules' /usr/lib/armbian/armbian-firstrun
	sed -i '/systemctl\ disable\ armbian-firstrun/a \
	sleep 30 && sync && reboot' /usr/lib/armbian/armbian-firstrun

	# add USB3 Gigabit Ethernet support
	echo -e "r8152\nax88179_178a" >>/etc/modules

	# Special treatment for ODROID-XU4 (and later Amlogic S912, RK3399 and other big.LITTLE
	# based devices). Move all NAS daemons to the big cores. With ODROID-XU4 a lot
	# more tweaks are needed. CS2 repo added, CS1 workaround added, coherent_pool=1M
	# set: https://forum.odroid.com/viewtopic.php?f=146&t=26016&start=200#p197729
	# (latter not necessary any more since we fixed it upstream in Armbian)
	case ${BOARD} in
		odroidxu4)
			HMP_Fix='; taskset -c -p 4-7 $i '
			# Cloudshell stuff (fan, lcd, missing serials on 1st CS2 batch)
			echo "H4sIAKdXHVkCA7WQXWuDMBiFr+eveOe6FcbSrEIH3WihWx0rtVbUFQqCqAkYGhJn
			tF1x/vep+7oebDfh5DmHwJOzUxwzgeNIpRp9zWRegDPznya4VDlWTXXbpS58XJtD
			i7ICmFBFxDmgI6AXSLgsiUop54gnBC40rkoVA9rDG0SHHaBHPQx16GN3Zs/XqxBD
			leVMFNAz6n6zSWlEAIlhEw8p4xTyFtwBkdoJTVIJ+sz3Xa9iZEMFkXk9mQT6cGSQ
			QL+Cr8rJJSmTouuuRzfDtluarm1aLVHksgWmvanm5sbfOmY3JEztWu5tV9bCXn4S
			HB8RIzjoUbGvFvPw/tmr0UMr6bWSBupVrulY2xp9T1bruWnVga7DdAqYFgkuCd3j
			vORUDQgej9HPJxmDDv+3WxblBSuYFH8oiNpHz8XvPIkU9B3JVCJ/awIAAA==" \
			| tr -d '[:blank:]' | base64 --decode | gunzip -c >/usr/local/sbin/cloudshell2-support.sh
			chmod 755 /usr/local/sbin/cloudshell2-support.sh
			apt install -y i2c-tools odroid-cloudshell cloudshell2-fan
			sed -i '/systemctl\ disable\ armbian-firstrun/i \
			lsusb | grep -q -i "05e3:0735" && sed -i "/exit\ 0/i echo 20 > /sys/class/block/sda/queue/max_sectors_kb" /etc/rc.local \
			/usr/sbin/i2cdetect -y 1 | grep -q "60: 60" && /usr/local/sbin/cloudshell2-support.sh' /usr/lib/armbian/armbian-firstrun
			;;
		bananapim3)
			HMP_Fix='; taskset -c -p 4-7 $i '
			;;
		edge*|ficus|firefly-rk3399|nanopct4|nanopim4|nanopineo4|renegade-elite|roc-rk3399-pc|rockpro64|station-p1)
			HMP_Fix='; taskset -c -p 4-5 $i '
			;;
	esac
	echo "* * * * * root for i in \`pgrep \"ftpd|nfsiod|smbd|afpd|cnid\"\` ; do ionice -c1 -p \$i ${HMP_Fix}; done >/dev/null 2>&1" \
		>/etc/cron.d/make_nas_processes_faster
	chmod 600 /etc/cron.d/make_nas_processes_faster

	# add SATA port multiplier hint if appropriate
	[ "${LINUXFAMILY}" = "sunxi" ] && \
		echo -e "#\n# If you want to use a SATA PM add \"ahci_sunxi.enable_pmp=1\" to bootargs above" \
		>>/boot/boot.cmd

	# Filter out some log messages
	echo ':msg, contains, "do ionice -c1" ~' >/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "action " ~' >>/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "netsnmp_assert" ~' >>/etc/rsyslog.d/omv-armbian.conf
	echo ':msg, contains, "Failed to initiate sched scan" ~' >>/etc/rsyslog.d/omv-armbian.conf

	# Fix little python bug upstream Debian 9 obviously ignores
	if [ -f /usr/lib/python3.5/weakref.py ]; then
		wget -O /usr/lib/python3.5/weakref.py \
		https://raw.githubusercontent.com/python/cpython/9cd7e17640a49635d1c1f8c2989578a8fc2c1de6/Lib/weakref.py
	fi

	# clean up and force password change on first boot
	umount /proc/mdstat
	chage -d 0 root
} # InstallOpenMediaVault

UnattendedStorageBenchmark() {
	# Function to create Armbian images ready for unattended storage performance testing.
	# Useful to use the same OS image with a bunch of different SD cards or eMMC modules
	# to test for performance differences without wasting too much time.

	rm /root/.not_logged_in_yet

	apt-get -qq install time

	wget -qO /usr/local/bin/sd-card-bench.sh https://raw.githubusercontent.com/ThomasKaiser/sbc-bench/master/sd-card-bench.sh
	chmod 755 /usr/local/bin/sd-card-bench.sh

	sed -i '/^exit\ 0$/i \
	/usr/local/bin/sd-card-bench.sh &' /etc/rc.local
} # UnattendedStorageBenchmark

InstallAdvancedDesktop()
{
	apt-get install -yy transmission libreoffice libreoffice-style-tango meld remmina thunderbird kazam avahi-daemon
	[[ -f /usr/share/doc/avahi-daemon/examples/sftp-ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/
	[[ -f /usr/share/doc/avahi-daemon/examples/ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/
	apt clean
} # InstallAdvancedDesktop

Main "$@"