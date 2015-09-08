Name:	    gedi
Version:	1.0
Release:	1_ccs%{?dist}
Summary:	GeDI System Setup
Group: Applications/Devel
BuildArch: noarch
#Prefix: %{ROOT}

#Group:		
License:	GPLv2
#URL:		
Packager:   Blake Caldwell <blakec@ornl.gov>
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Source0:    gedi-1.0.tar.gz

#commented out documentation build
#FIXME: for RHEL7
#Buildrequires: texlive-latex
Requires:   yum-utils

%description
These areis the tools needed to set up a diskless system.

%package client
Summary: GeDI Client Utils
Group: Applications/Devel
Requires:   dracut >= 033-161.el7
Requires:   dracut-network >= 033-161.el7_0.173
Conflicts: gedi-yum-client-dracut
%description client
This should be installed inside of your image, provides ability to make a
ramdisk and some other stuff.

%changelog
* Wed Apr 08 2015 Blake Caldwell <blakec@ornl.gov> - 1.0
- Changed paths for RHEL7 compatibility
* Wed Aug 06 2014 Blake Caldwell <blakec@ornl.gov> - 0.1
- New packaging of RPM previously named gedi-yum
* Mon Jul 9 2012 Dustin Leverman <leverman@ornl.gov>
- Added Dillow's dracut-gedi config files for RHEL6:
- disabled ./create-variable for /etc/sysconfig/gedi and used Dillow's
- disabled custom init script.
- disabled create_union_rpm
- disabled unionfs src copy
- disabled %config(noreplace) /etc/rc.readonly
* Fri Nov 19 2010 Clay England <england@ornl.gov>
- added no unionfs to mkinitrd_gedi
- added numeric ids to rysnc
- made the find for eth module deps broader
- added disableexcludes to create_nfsroot_yum
- added install of deps when all NIC drivers are installed
- enlarged /etc ram disk
- added /etc/gedi/scripts magic
* Wed Oct 12 2010 Clay England <england@ornl.gov>
- added yum changes renamed package to gedi-yum
* Wed Jan 22 2003 Makia Minich <makia@llnl.gov>
- Created this rpm

%prep
%setup -q -n %{name}-%{version}

%build
#make -C doc

%install
[ "${RPM_BUILD_ROOT}" != "/" ] && rm -rf $RPM_BUILD_ROOT

#for dir in local nfsroot patches pxelinux.cfg RPMS scripts tools lib YUM-RPMS; do
#   mkdir -p -m 0755 ${RPM_BUILD_ROOT}%{ROOT}/$dir
#   if [ -d "$dir" ] ; then
#      cp -a $dir ${RPM_BUILD_ROOT}%{ROOT}
#   fi
#done
#ln -sf config_services ${RPM_BUILD_ROOT}%{ROOT}/tools/MAC_Update

# etc files
#mkdir -p -m 0755 ${RPM_BUILD_ROOT}/etc/gedi
#cp etc/* ${RPM_BUILD_ROOT}/etc/gedi

# And now for the client files
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/usr/lib/gedi
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/99zz-gedi-strip
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/sbin
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/etc/sysconfig
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/etc/gedi.d
mkdir -p -m 0755 ${RPM_BUILD_ROOT}/boot/pxe

install -m 755 pxelinux.0 ${RPM_BUILD_ROOT}/boot/pxe/
install -m 755 client/image/gedi-preinit ${RPM_BUILD_ROOT}/
install -m 755 client/image/etc/gedi.d/00-make-writable ${RPM_BUILD_ROOT}/etc/gedi.d/
install -m 755 client/image/etc/gedi.d/20-netcfg ${RPM_BUILD_ROOT}/etc/gedi.d/
install -m 644 client/image/etc/gedi.d/functions ${RPM_BUILD_ROOT}/etc/gedi.d/
install -m 644 client/image/etc/sysconfig/gedi ${RPM_BUILD_ROOT}/etc/sysconfig/
install -m 755 client/scripts/mkinitrd_gedi ${RPM_BUILD_ROOT}/sbin/
install -m 755 client/scripts/update_pxe_files \
   ${RPM_BUILD_ROOT}/usr/lib/gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/50gedi/check \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/50gedi/gedi-init.sh \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/50gedi/install \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 644 client/image/usr/lib/dracut/modules.d/50gedi/nsswitch.conf \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/50gedi/placeholder \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/50gedi/zz-gedi-default-root.sh \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/50gedi/
install -m 755 client/image/usr/lib/dracut/modules.d/99zz-gedi-strip/check \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/99zz-gedi-strip/
install -m 755 client/image/usr/lib/dracut/modules.d/99zz-gedi-strip/install \
   ${RPM_BUILD_ROOT}/usr/lib/dracut/modules.d/99zz-gedi-strip/

%clean
rm -rf %{buildroot}


%files client
%defattr(-,root,root,-)
#%doc README
%config(noreplace) /etc/sysconfig/gedi
%config(noreplace) /gedi-preinit
#%config(noreplace) /etc/sysconfig/readonly-root
#%config(noreplace) /etc/rc.readonly
/usr/lib/gedi
#/usr/lib/unionfs
/sbin/mkinitrd_gedi
/boot/pxe
/etc/gedi.d
/usr/lib/dracut/modules.d/50gedi
/usr/lib/dracut/modules.d/99zz-gedi-strip
