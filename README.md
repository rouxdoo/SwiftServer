# SwiftServer

This is a small, lightweight server written in SWIFT for Linux.
It's designed to work on a raspberry pi (tested on a 3B+) to
control the official 7" display sold by the rPi Foundation

This has only been tested on Raspbian Stretch.

This server uses a swift framework called ElementalController
by Rob Reuss:
https://github.com/robreuss/ElementalController

This server is designed as the server-side complement to
my iOS utility called piDisplay:
https://itunes.apple.com/us/app/pidisplay/id1448654670?mt=8

The included installer.sh will download several components:
* rpi-backlight
* Swift language: swift-4.1.1-RELEASE

The installer will install above on your pi then proceed to
build SwiftServer. Finally, it wil install a systemd profile
allowing the server to autorun at boot.

You can stop the SwiftServer process by:
systemctl stop swiftserver

You can prevent it from starting at boot by:
systemctl disable swiftserver

