#!/bin/sh

sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update
