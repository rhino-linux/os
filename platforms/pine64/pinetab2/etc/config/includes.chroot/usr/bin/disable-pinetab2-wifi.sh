#!/bin/bash

# Remove the module names if present
sed -i '/mac80211/d' /etc/modules
sed -i '/bes2600/d' /etc/modules

depmod
