# makeUnifi

Generate Unifi SSL from CSR provided by Unifi Controller and upload the certificate back to controller.

### Usage

**Prerequisite:** *IntermediateCA must be created*

```
git clone https://github.com/jwaladiamonds/makeCA && cd makeCA

# Generate root and intermediate certificate
sudo make ca

# Update unifi certificate
cd unifi && sudo make unifi
```

Default parameters:
```
UNIFI_FQDN      := UniFi
UNIFI_COUNTRY   := New York
UNIFI_STATE     := New York
UNIFI_CITY      := New York
UNIFI_ORG       := Ubiquiti Inc.
```
If you wish to change default parameters, use the following code:
```
sudo make unifi \
    UNIFI_FQDN=unifi.controller \
    UNIFI_COUNTRY=US \
    UNIFI_STATE=CA \
    UNIFI_CITY=LA \
    UNIFI_ORG=Local Network
```

### Bonus

##### How to install Unifi Controller inside Raspberry Pi

```
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove && sudo apt-get autoclean
sudo apt-get install haveged -y
sudo apt-get install openjdk-8-jre-headless -y
sudo raspi-config
    # Select 7. Advanced Options
    # Select A3 Memory Split
    # Change 64 to 16
    # Hit 'Enter' and press `Esc` to exit

echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ubnt.com/unifi/unifi-repo.gpg
sudo apt-get update && sudo apt-get install unifi -y
sudo systemctl stop mongodb && sudo systemctl disable mongodb
sudo reboot
```
