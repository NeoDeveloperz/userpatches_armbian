function board_determiner() {

	echo -e "${GREEN}INFO: ${CYAN}Executing Board Determiner!... .. ."
	echo "${RED}Detected Board:${BLUE} $BOARD "
	read -p "Press any key to Copy Board-Determinier!... .. ."


	case $BOARD in
		bananapi)
			echo "Configuring: BananaPi"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapicm4io)
			echo "Configuring: BananaPi CM4IO"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim1plus)
			echo "Configuring: BananaPi M1 Plus"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim2)
			echo "Configuring: BananaPi M2"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim2berry)
			echo "${GREEN}INFO: ${RED}Building Board-Determinier for: ${CYAN}BananaPi M2 Berry"
			echo "${GREEN}INFO: ${RED}Copying Board Determiner-Files from overlay to /var/lib/bananapi !"

			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			led_trigger;

			echo "INFO: Board-Determiner Function Execution Finished!!"
			;;
		bananapim2ultra)
			echo "${GREEN}INFO: ${RED}Building Board-Determinier for: ${CYAN}BananaPi M2 Berry"
			echo "${GREEN}INFO: ${RED}Copying Board Determiner-Files from overlay to /var/lib/bananapi !"

			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			led_trigger;
			
			echo "INFO: Board-Determiner Function Execution Finished!!"
			;;
		bananapim2plus)
			echo "Configuring: BananaPi M2 Plus"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim2pro)
			echo "Configuring: BananaPi M2 Pro"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim2s)
			echo "Configuring: BananaPi M2S"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim2zero)
			echo "Configuring: BananaPi M2 Zero"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim3)
			echo "Configuring: BananaPi M3"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim4zero)
			echo "Configuring: BananaPi M4 Zero"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim5)
			echo "Configuring: BananaPi M5"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim7)
			echo "Configuring: BananaPi M7"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapim64)
			echo "Configuring: BananaPi M64"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapipro)
			echo "Configuring: BananaPi Pro"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapir2)
			echo "Configuring: BananaPi R2"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		bananapir2pro)
			echo "Configuring: BananaPi R2 Pro"
			cp -r "${include_board_determiner_directory}" "${board_determiner_directory}"
			;;
		*)
			echo "Configuring: $BOARD "
			echo "Board not supported"
			;;
		esac
}
