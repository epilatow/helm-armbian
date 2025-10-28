# Helm v2a Armbian image builder

Creates an armbian image for Helm v2a (RK3399) with:
- [Armbian Linux Build Framework](http://github.com/armbian/build)
- Ubuntu 24.04 (noble) LTS base image
- Armbian Linux 6.12.55 Kernel
- rk3399-helm-v2a.dtb: Built from linux 6.12 patches from https://github.com/epilatow/linux, branch: v6.12-helm-v2a
- [HelmSecure](https://github.com/HelmSecure/armbian-images) bootloader chain (idbloader.bin, uboot.img, and trust.bin)

Notes:
- The Helm v2a has rockchip secure boot enabled, so all components in
  the bootloader chain (idbloader.bin, uboot.img, and trust.bin) must be
  signed with a vendor private key. AFAICT this key is not publicly
  available, so we can't update any bootloader components, so we're we're
  stuck with an old and fragile version of U-Boot (2017.09-armbian).
  When building new images here we re-use those old components.

## Build Images

Prerequisites:
- Docker installed

```
./build.sh
...
LOADER=vendor/loader/helm-loader-build-38.bin
IMAGE=$(/bin/ls build/output/images/Armbian*.img | head -1)
```

## Downloads Images (if you don't want to build images)
- LOADER: [helm-loader-build-38.bin](https://github.com/epilatow/helm-armbian/releases/download/loader/helm-loader-build-38.bin)
- IMAGE: [Armbian-unofficial_25.11.0-trunk_Helm-v2a_noble_current_6.12.55_minimal.img](https://github.com/epilatow/helm-armbian/releases/download/images/Armbian-unofficial_25.11.0-trunk_Helm-v2a_noble_current_6.12.55_minimal.img)

## Install

Notes:
- Helm v2 devices contain a Rockchip rk3399 SoC. The Rockchip rkdeveloptool running on a Linux host is required to flash the image. Please follow the instructions found here for installing the rkdeveloptool on a Linux box. https://github.com/rockchip-linux/rkdeveloptool

Procedure:
- Unplug the Helm power cable for at least 10 seconds.
- Hold the Helm power button and plug in the power cable. Continue to hold the power button for at least 6 seconds after plugging in the power cable, then release it. This process will put the Helm into maskrom mode.
- Connect to the Helm via a usb-c cable from your Linux host computer to usb0 on the Helm (the usb-c ports on the right of the ethernet port when looking at the Helm from the back).
- Confirm that your Linux host has detected the Helm is maskrom mode. Running the lsusb command on the Linux host should show a device named "Fuzhou Rockchip Electronics Company RK3399 in Mask ROM mode".
- Flash the image to your Helm using these commands:

```
rkdeveloptool db $LOADER
rkdeveloptool wl 0 $IMAGE
rkdeveloptool rd
```

## Running rkdeveloptool in a docker container
```
cat | sudo docker build -t rkflash - <<-EOF
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    git build-essential pkg-config usbutils libusb-1.0-0-dev \
    autoconf automake libtool ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

# Build rkdeveloptool
RUN git clone https://github.com/rockchip-linux/rkdeveloptool /opt/rkdeveloptool && \
    cd /opt/rkdeveloptool && \
    autoreconf -i && \
    ./configure && \
    make -j"$(nproc)" && \
    cp rkdeveloptool /bin/rkdeveloptool

ENTRYPOINT ["/bin/bash"]
EOF
mkdir ~/rkflash-shared
cp $LOADER ~/rkflash-shared
cp $IMAGE ~/rkflash-shared
sudo docker run --rm -it \
    --privileged -v /dev/bus/usb:/dev/bus/usb -v /dev:/dev \
    -v "$HOME/rkflash-shared:/rkflash-shared" \
    rkflash
<... in the container ...>
cd /rkflash-shared
./rkdeveloptool db $LOADER
./rkdeveloptool wl 0 $IMAGE
./rkdeveloptool rd
```
