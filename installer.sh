#!/bin/bash
#
# git clone https://github.com/rouxdoo/SwiftServer.git
#
# This is for rpi-backlight
#
cd ~/
git clone https://github.com/linusg/rpi-backlight.git
cd rpi-backlight
sudo python3 setup.py install
echo SUBSYSTEM==\"backlight\",RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power\" | sudo tee /etc/udev/rules.d/backlight-permissions.rules
#
# This is for SwiftServer
#
sudo apt-get install -y libavahi-compat-libdnssd-dev
cd ~/SwiftServer
wget https://www.dropbox.com/s/e257cvg23ghe2dt/swift-4.1.3-RPi23-RaspbianStretch.tgz
sudo tar xzf swift-4.1.3-RPi23-RaspbianStretch.tgz -C /
swift package update
swift build -c release
echo SUBSYSTEM==\"leds\",RUN+=\"/bin/chmod 666 /sys/class/leds/%k/brightness\" | sudo tee /etc/udev/rules.d/leds-permissions.rules
sudo udevadm control --reload-rules && udevadm trigger
nohup ./.build/release/SwiftServer > /dev/null&
sudo cp ./swiftserver.service /lib/systemd/system/
sudo chown root:root /lib/systemd/system/swiftserver.service
sudo systemctl daemon-reload
sudo systemctl enable swiftserver.service
