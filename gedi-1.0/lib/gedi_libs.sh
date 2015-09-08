#!/bin/sh
################################################################################
# $Id:$
#################################################################################  Copyright (C) 2004-2006 The Regents of the University of California.
#  Produced at Lawrence Livermore National Laboratory (cf, DISCLAIMER).'
#  This module written by Jim Garlick <garlick@llnl.gov>
#  Based on code in mkinitrd_gedi and init by Makia Minich <makia@llnl.gov>
#  UCRL-CODE-155916
#
#  This file is part of GeDI, a diskless image management tool.
#  For details, see <http://www.llnl.gov/linux/gedi/>.
#
#  GeDI is free software; you can redistribute it and/or modify it under
#  the terms of the GNU General Public License as published by the Free
#  Software Foundation; either version 2 of the License, or (at your option)
#  any later version.
#
#  GeDI is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#
#  You should have received a copy of the GNU General Public License along
#  with GeDI; if not, write to the Free Software Foundation, Inc.,
#  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA.
################################################################################

# single load system
if [ -z "$_GEDI_LIBRARIES" ] ; then
_GEDI_LIBRARIES="loaded"

[ -z ${PROG} ] && PROG=${0/*\//}

gedi_depmod() {
   modinfo $1 | awk '/depends/ {gsub(",", " "); sub($1 FS FS "*",""); print}'
   return $?
}

gedi_ismodloaded() {
   lsmod | grep -q "^$1[[:space:]]"
   return $?
}

gedi_modprobe() {
   local moddir=$1 mod=$2
   shift; shift
   local modpath dep opts=$*

   modpath=$(find ${moddir} -name ${mod}.ko)
   if [ -z "${modpath}" ] ; then
      echo "${PROG}: module ${mod} not found" >&2
      return 1
   fi

   for dep in $(gedi_depmod ${modpath}) ; do
      gedi_modprobe $moddir $dep
   done
   if ( ! gedi_ismodloaded $mod ) ; then
      echo "${PROG}: loading $modpath $opts" >&2
      insmod $modpath $opts
   fi

   return 0
}

gedi_eth2mac() {
   ifconfig $1 | awk '/HWaddr/ {print $NF}'
   return $?
}

gedi_mac2eth() {
   ifconfig -a | awk "/$1/ {print \$1}"
   return $?
}

gedi_mountnfs() {
   if [ ! -d $2 ] ; then
      echo "${PROG}: mount point $2 does not exist" >&2
   else
      while ( ! grep -q $1 /proc/mounts ) ; do
         [ -n "$3" ] && OPTS="-o $3"
         mount -n -t nfs $OPTS $1 $2
         grep -q $1 /proc/mounts || sleep 5
      done
   fi
   return 0
}

gedi_ethmodules() {
   local pat mod pcimap=$1/modules.pcimap

   if [ ! -r $pcimap ] ; then
      echo "${PROG}: $pcimap not found" >&2
      return 1
   fi

   lspci -n | awk '/(0200|0680):/ {sub(/ Class/,""); split($3,a,":"); \
                            printf("0x%08s[[:space:]]0x%08s\n", a[1], a[2])}' |
   while read pat ; do
      mod=""
      while [ -z "$mod" ] && [ -n "$pat" ] ; do
         mod=$(awk "/$pat/ {print \$1 ; exit}" ${pcimap})
         pat=${pat:0:${#pat}-1}
      done

      case "$mod" in
         Card*) mod=forcedeth ;;
      esac
      echo -n "$mod "
   done
   return 0
}

gedi_ethdevs() {
   echo $(awk '/eth.*:/ {sub(/:.*/, ""); print $1}' /proc/net/dev)
   return $?
}

gedi_fixeth0() {
   if [ "$(gedi_mac2eth $1)" != "eth0" ] ; then
      local -a ethdevs=($(gedi_ethdevs))
      local tmpeth=eth${#ethdevs[*]}
      local oldeth=$(gedi_mac2eth $1)

      echo "${PROG}: eth0->${tmpeth}" >&2
      nameif ${tmpeth} $(gedi_eth2mac eth0)

      echo "${PROG}: ${oldeth}->eth0" >&2
      nameif eth0 $1

      echo "${PROG}: ${tmpeth}->${oldeth}" >&2
      nameif ${oldeth} $(gedi_eth2mac $tmpeth)
   fi
   return 0
}

gedi_bootmac() {
   if [ -z "${BOOTIF}" ] ; then
      . /proc/cmdline
   fi
   if [ -z "${BOOTIF}" ] ; then
      echo "${PROG}: BOOTIF is not set" >&2
      return 1
   fi
   if [ ${#BOOTIF} != 20 ] ; then
      echo "${PROG}: BOOTIF was truncated" >&2
      return 1
   fi
   echo ${BOOTIF} | awk '{sub(/^01-/, ""); gsub(/-/, ":"); print toupper($0)}'
   return 0
}

gedi_getipconf() {
   local line

   while [ -z "${ipconf_rpath}" ] ; do
      for line in $(dhclient -q -n -w -sf /bin/printenv 2>/dev/null) ; do
         local key=${line/=*/}
         local val=${line/*=/}
         case ${key} in
            new_ip_address)             export ipconf_ip=$val ;;
            new_subnet_mask)            export ipconf_netmask=$val ;;
            new_dhcp_server_identifier) export ipconf_server=$val ;;
            new_root_path)              export ipconf_rpath=$val ;;
            new_routers)                export ipconf_router=$val ;;
            new_host_name)              export ipconf_hostname=$val ;;
            new_broadcast_address)      export ipconf_bcast=$val ;;
         esac
      done
      if [ -f /var/run/dhclient.pid ] ; then
         kill -15 $(< /var/run/dhclient.pid) > /dev/null 2>&1
         rm -f /var/run/dhclient.pid
      fi
   done
   return 0
}

gedi_copymodules() {
   local imagedir=$1 srcmoddir=$2
   local dep module destmoddir=$imagedir/lib/modules
   shift; shift

   for module in $* ; do
      if [ ! -f ${destmoddir}/${module}.ko ] ; then
         find ${srcmoddir} -name "${module}.ko" -exec install {} $destmoddir \;
         if [ -f ${destmoddir}/${module}.ko ] ; then
            for dep in $(gedi_depmod ${destmoddir}/${module}.ko) ; do
               gedi_copymodules ${imagedir} ${srcmoddir} ${dep}
            done
         else
            echo "${PROG}: warning: ${module} not found" >&2
         fi
      fi
   done
   return 0
}

gedi_copymodules_allnet() {
   local imagedir=$1 srcmoddir=$2 mod

   for mod in $(find ${srcmoddir}/kernel/drivers/net -type f | \
                sed 's/.ko$//' ) ; do
      gedi_copymodules ${imagedir} ${srcmoddir} $(basename ${mod})
   done
   return 0
}

gedi_getmoddev() {
   local modconf=$1 alias=$2

   if [ -f $modconf ] ; then
      echo $(awk "/alias[[:space:]]+$alias/ {print \$NF}" $modconf)
   fi
   return 0
}

gedi_getmodopts() {
   local device modconf=$1 alias=$2

   if [ -f $modconf ] ; then
      device=$(gedi_getmoddev $modconf $alias)
      if [ -n "$device" ] ; then
         alias="(${device}|${alias})"
      fi
      echo $(awk "/options[[:space:]]+$alias/ {print \$NF}" $modconf)
   fi
   return 0
}

gedi_copyexec() {
   local destbin=$1/bin destlib=$1/lib
   local name bin lib
   shift

   mkdir -p $destbin $destlib
   for name in $* ; do
      bin=$(which $name 2>/dev/null | tail -1)
      if [ -z "$bin" ] ; then
         echo "${PROG}: warning: $name not found" >&2
      else
         install $bin $destbin
         if ( file $bin | grep -qv statically ) ; then
            for lib in $(ldd $bin | awk -F"=> " '{print $NF}' | \
                         sed "s/ (.*//" | sort | uniq) ; do
               name=$(basename $lib)
               if [ ! -f $destlib/$name ] ; then
                  if [ ! -f ${lib} ] ; then
                     echo "${PROG}: warning: $name not found" >&2
                  else
                     install ${lib} ${destlib}
                  fi
               fi
            done
         fi
      fi
   done
   return 0
}

fi
