dtc -I dts -O dtb -o sun8i-r40-bananapi-m2-ultra.dtb sun8i-r40-bananapi-m2-ultra.dts
sudo armbian-add-overlay sun8i-r40-bananapi-m2-ultra.dts
sudo reboot