function run_after_build__enable_hwiface() {
	echo "${RED}INFO: ${CYAN} ENABLING ALL HARDWARE INTERFACES!"
	if [[ "$hwboard" == "bananapim2berry" || "$hwboard" == "bananapim2ultra" ]]; then
		echo -e "fdt_overlays=sun8i-r40-i2c2 sun8i-r40-i2c3 sun8i-r40-spi-spidev0 sun8i-r40-spi-spidev1 sun8i-r40-uart2" >> /boot/armbianEnv.txt
	else
		echo "${RED}ERROR: CANT ENABLE HARDWARE INTERFACES RIGHT NOW, DEVICETREEOVERLAYS FOR THIS BOARD ARE CURRENTLY NOT SUPPORTED!"
	fi
}