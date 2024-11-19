
function led_trigger() {
	echo "${GREEN}INFO: Settingup onBOARD LED Trigger to: ${RED}RED: ${BLUE}CPU0 ${GREEN}GREEN: ${CYAN}heartbeat!"

	case $BOARD in 
		bananapim2ultra)
			echo "${GREEN}INFO: ${CYAN}Copying LED-Trigger from overlay to /etc/init.d !"
			cp -r $led_trigger_file $initd_led_trigger_service
			grant_permissions;
			echo "Enable init.d Service!"
			sleep 1
			manage_service "set_led_trigger.sh" "defaults"
			;;
		bananapim2berry)
			echo "${GREEN}INFO: ${CYAN}Copying LED-Trigger from overlay to /etc/init.d !"
			cp -r $led_trigger_file $initd_led_trigger_service
			grant_permissions;
			echo "Enable init.d Service!"
			sleep 1
			manage_service "set_led_trigger.sh" "defaults"
			;;
		bananapi)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapicm4io)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim1plus)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim2)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim2plus)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim2pro)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim2s)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim2zero)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim3)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim4zero)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim5)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim7)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapim64)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapipro)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapir2)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		bananapir2pro)
			led_trigger_file="/tmp/overlay/scripts/bpi-m2u-m2b/set_led_trigger.sh"
			;;
		*)
			echo "Configuring: $BOARD "
			echo "Board not supported"
			;;
		esac
}