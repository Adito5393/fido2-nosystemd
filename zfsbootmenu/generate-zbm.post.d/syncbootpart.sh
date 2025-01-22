#!/bin/bash

## This script can be used by generate-zbm to keep two or more ESPs in sync 
## after an EFI is built. Place the script in the directory defined by:
##
##   Global.PostHooksDir
##
## Runs https://github.com/Adito5393/SyncDiskPart
# https://packages.medo64.com/deb/dists/stable/main/binary-all/syncbootpart_1.0.0_all.deb
# sha256:801b9789c92a818540d81398275e16369a2ec192a41deaf5ae986d3473889c3d

command -v syncbootpart >/dev/null 2>&1 && syncbootpart -v
