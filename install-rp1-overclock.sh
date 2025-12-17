dtc -@ -I dts -O dtb -o rp1-300mhz.dtbo rp1-300mhz.dtso
cp ./rp1-300mhz.dtbo /boot/firmware/overlays/
grep -q "dtoverlay=rp1-300mhz" /boot/firmware/config.txt
if [ "1" == "$?" ]
then
	echo "dtoverlay=rp1-300mhz" >> /boot/firmware/config.txt
fi
