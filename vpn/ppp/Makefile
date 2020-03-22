# vim:set noexpandtab :

ROOTDIR := /tmp/rootdir
INSTALLDIR := /private/etc/ppp
CMD := ip-up
PKG := $(CMD).pkg
PKGID := net.pretendco.pkgbuild

.PHONY: clean
clean:
	@/bin/rm -rf $(PKG) $(ROOTDIR)

.PHONY: install
install:
	@/bin/cp $(CMD) $(INSTALLDIR)
	@/usr/sbin/chown 0:0 $(INSTALLDIR)/$(CMD)
	@/bin/chmod 555 $(INSTALLDIR)/$(CMD)

.PHONY: pkg
pkg: $(PKG)

$(PKG): $(CMD)
	@/bin/mkdir -p $(ROOTDIR)$(INSTALLDIR)
	@/bin/cp $(CMD) $(ROOTDIR)$(INSTALLDIR)
	@/bin/chmod 555 $(ROOTDIR)$(INSTALLDIR)/$(CMD)
	@/usr/bin/pkgbuild --identifier $(PKGID) --root $(ROOTDIR) $(PKG)
