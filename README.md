# openwrt-oem-defaults
OpenWrt modifications for better usability

Currently OpenWrt is not as user-friendly as OEM firmwares.
Many of the functions require deep knowledge and quite hard to achieve.
I really don't like this approach and I want to provide the way
to simplify initial setup and basic configuration.

First of all, official OpenWrt releases after installation
on the end user devices doesn't have WiFi. So you need
to plug your notebook/computer via wire and configure OpenWrt.

Some members of OpenWrt team don't want to modify this behaviour
(http://lists.openwrt.org/pipermail/openwrt-devel/2019-November/025738.html),
and I've decided to create a separate repository and scripts
which follows oem firmware data and set up OpenWrt likewise.

## Installing

### Word of caution:

#### It is important to understand that nobody but you are responsible to check OEM partition data.

Scripts in this repository just extracts data without much verification.
Validate data on OEM partition or you're can face consequences.

#### Firmware with scripts from this repo cannot be official.

They built by third party, with optional modifications. My patches are not
a part of OpenWrt.


