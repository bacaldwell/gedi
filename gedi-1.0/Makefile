PROJECT := gedi
VERSION := $(shell perl -ne 'print,exit if s/^\s*VERSION:\s*(\S*).*/\1/i' META)
RELEASE := $(shell perl -ne 'print,exit if s/^\s*RELEASE:\s*(\S*).*/\1/i' META)
RPM     := $(shell if [ -x "/usr/bin/rpmbuild" ]; then echo rpmbuild; \
	                else echo rpm; fi)
TMP     := /tmp/tmp-$(PROJECT)

IGNORE  := --exclude .svn

SUBVERSION := https://gedi-tools.svn.sourceforge.net/svnroot/gedi-tools

rpm: $(PROJECT).spec
	$(MAKE) clean
	@mkdir -p $(TMP)/BUILD $(TMP)/SPECS $(TMP)/SOURCES $(TMP)/tmp $(TMP)/RPMS $(TMP)/SRPMS ; \
	if [ -z "$$tag" ] ; then \
	   tag=$(PROJECT)-$(VERSION)-$(RELEASE) ; \
	fi ; \
	echo "Fetching $$tag from subversion" ; \
	if [ "$$tag" = "HEAD" ] ; then \
	   (cd $(TMP)/BUILD ; svn co $(SUBVERSION)/trunk/$(PROJECT)) ; \
	   rel="`date +%y%m%d%H%M`" ; \
	elif [ "$$tag" = "LOCAL" ] ; then \
           mkdir ${TMP}/BUILD/${PROJECT} ; \
           cp -a * ${TMP}/BUILD/${PROJECT} ; \
	   rel=`perl -ne 'print,exit if s/^\s*RELEASE:\s*(\S*).*/\1/i' \
	         $(TMP)/BUILD/$(PROJECT)/META` ; \
	else \
	   (cd $(TMP)/BUILD ; svn co $(SUBVERSION)/tags/$$tag/$(PROJECT)) ; \
	   rel=`perl -ne 'print,exit if s/^\s*RELEASE:\s*(\S*).*/\1/i' \
	         $(TMP)/BUILD/$(PROJECT)/META` ; \
	fi ; \
	name=`perl -ne 'print,exit if s/^\s*NAME:\s*(\S*).*/\1/i' \
	      $(TMP)/BUILD/$(PROJECT)/META` ; \
	ver=`perl -ne 'print,exit if s/^\s*VERSION:\s*(\S*).*/\1/i' \
	      $(TMP)/BUILD/$(PROJECT)/META` ; \
	pkg=$$name-$$ver-$$rel ; \
	mv $(TMP)/BUILD/$(PROJECT) $(TMP)/BUILD/$$name-$$ver ; \
	(cd $(TMP)/BUILD/$$name-$$ver ; \
	    sed -e "s/^\([  ]*Name:\).*/\1 $$name/i" \
	        -e "s/^\([  ]*Version:\).*/\1 $$ver/i" \
	        -e "s/^\([  ]*Release:\).*/\1 $$rel/i" \
	        -e "s/^\([  ]*Source0\?:\).*/\1 $$pkg.tar.gz/i" \
	        < $(PROJECT).spec > $(TMP)/SPECS/$(PROJECT).spec); \
	(cd $(TMP)/BUILD && \
	    tar -cz $(IGNORE) -f $(TMP)/SOURCES/$$pkg.tar.gz $$name-$$ver); \
	$(RPM) --define "_topdir $(TMP)" --define "_tmppath $(TMP)/tmp" -ba \
	    $(TMP)/SPECS/$(PROJECT).spec ; \
	cp -p $(TMP)/SRPMS/$(PROJECT)-*.src.rpm $(TMP)/RPMS/*/$(PROJECT)-*.rpm . ; \
	cp -p $(TMP)/SOURCES/$$pkg.tar.gz . ; \
	rm -rf $(TMP)

clean:
	-rm -rf $(TMP)
