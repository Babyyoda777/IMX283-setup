#!/bin/bash
set -e

mkdir -p ${HOME}/bin

SOURCE=$(pwd)
echo "Script run from ${SOURCE}"

TEMP=$(mktemp -d)
echo "Build folder: ${TEMP}"
cd ${TEMP}

sudo apt-get remove --purge -y rpicam-apps-lite rpicam-apps
sudo apt-get remove --purge -y libcamera-dev libepoxy-dev libopencv-dev

sudo apt-get install -y linux-headers-$(uname -r) dkms

sudo apt-get install -y libjpeg-dev libtiff5-dev libpng-dev
sudo apt-get install -y libavcodec-dev libavdevice-dev libavformat-dev libswresample-dev

sudo apt-get install -y python3-pip python3-jinja2
sudo apt-get install -y libboost-dev
sudo apt-get install -y libgnutls28-dev openssl libtiff5-dev pybind11-dev
sudo apt-get install -y meson cmake ninja-build
sudo apt-get install -y python3-yaml python3-ply

sudo apt-get install -y cmake libboost-program-options-dev libdrm-dev libexif-dev

mkdir overclock
cd overclock
cp "${SOURCE}/rp1-300mhz.dtso" .
cp "${SOURCE}/install-rp1-overclock.sh" .
sudo bash ./install-rp1-overclock.sh
cd ..

git clone https://github.com/will127534/imx585-v4l2-driver.git
cd imx585-v4l2-driver/
./setup.sh
cd ..

git clone https://github.com/raspberrypi/libcamera.git
cd libcamera
git apply "${SOURCE}/libcamera.patch"
meson setup build --buildtype=release \
  -Dpipelines=rpi/vc4,rpi/pisp \
  -Dipas=rpi/vc4,rpi/pisp \
  -Dv4l2=enabled \
  -Dgstreamer=disabled \
  -Dtest=false \
  -Dlc-compliance=disabled \
  -Dcam=disabled \
  -Dqcam=disabled \
  -Ddocumentation=disabled \
  -Dpycamera=disabled
ninja -C build -j 2
sudo ninja -C build install
cd ..

git clone https://github.com/babyyoda777/rpicam-apps.git
cd rpicam-apps/
meson setup build \
  -Denable_libav=enabled \
  -Denable_drm=enabled \
  -Denable_egl=disabled \
  -Denable_qt=disabled \
  -Denable_opencv=disabled \
  -Denable_tflite=disabled \
  -Denable_hailo=disabled
meson compile -C build -j 2
sudo meson install -C build
cd ..

sudo ldconfig
rpicam-hello --version
rpicam-hello --list-cameras

cat /boot/firmware/config.txt | \
  sed -e "s/camera_auto_detect=1/camera_auto_detect=0\ndtoverlay=imx585/g" \
  > config.txt

sudo cp -vf config.txt /boot/firmware/



sudo reboot
