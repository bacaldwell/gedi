#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# If we don't have a root from the command line, default to dhcp
if [ -z "$root" ]; then
    root=dhcp
fi
