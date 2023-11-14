#!/bin/bash

# Check and append mac80211 if not present
grep -qxF 'mac80211' /etc/modules || echo "mac80211" >> /etc/modules

# Check and append bes2600 if not present
grep -qxF 'bes2600' /etc/modules || echo "bes2600" >> /etc/modules

depmod
