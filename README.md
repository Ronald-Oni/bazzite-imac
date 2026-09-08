# Bazzite for iMac

This repository is based on the official Bazzite Universal Blue Project [bootc](https://github.com/bootc-dev/bootc) image. It adds specific driver support for the iMac 2017 - 2019 hardware.
Especcially the following Fixes are implemented:
- Audio driver fror Audio Chip Cirrus Logic (CS4208 or CS8409)
- W-Lan driver for Broadcom-Chips (BCM43602) in the iMac will automatically loaded in boot sequence
- Bluetooth fix deactivates ERTM (Enhanced Retransmission Mode) to allow connection to equipment like X-Box gamecontroller without connection abort.

Because this repository is linked to the original Bazzite repository, updates are automatically applied and rolled out to your system. All included fixes are retained.

# Community

If you have questions about this template after following the instructions, try the following spaces:
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions) - This is not an Universal Blue managed space, but is an excellent resource if you run into issues with building bootc images.

# How to Use

It is recommended to select and install a original Bazzite image from usb drive which matches best to your hardware and demands first. Select your prefernece here:
https://docs.bazzite.gg/General/Installation_Guide/

Once the iMac starts up for the first time, run the rebase command to switch to this Version which included fixes:
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ronald-oni/bazzite-imac:latest



