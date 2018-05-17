include include.mk

ifeq ($(OS), Windows_NT)
    GLOCALE = c:\\vala-0.12.0\\share\\locale
    GLOCALES = $(shell ls $(GLOCALE))
endif

# must be greater then
VALAC_MIN_MAJOR = 0
VALAC_MIN_MINOR = 12

VALAC_MAJOR = $(shell valac --version | cut -d ' ' -f 2 | cut -d '.' -f 1)
VALAC_MINOR = $(shell valac --version | cut -d ' ' -f 2 | cut -d '.' -f 2)
VALAC_VER_OK = $(shell [ $(VALAC_MAJOR) -ge $(VALAC_MIN_MAJOR) -o $(VALAC_MAJOR) -eq $(VALAC_MIN_MAJOR) -a $(VALAC_MINOR) -ge $(VALAC_MIN_MINOR) ] && echo "true")


SUBDIRS = src po icons ui
TOPTARGETS = all clean install uninstall

all: $(SUBDIRS)
$(TOPTARGETS): $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

pkg-check:
	@printf "Checking packages\n"
	$(SILENT)$(foreach pkg, $(EXT_PKGS), \
	    printf "  CHECK $(pkg)"; \
	    pkg-config --print-errors --exists $(pkg) && printf "   \tOK\n";)

vala-check:
	@printf "Vala version $(shell $(VALAC) --version)"
ifeq ($(VALAC_VER_OK), true)
	@printf "\tOK\n"
else
	@printf "\t FAILED\n"
	@printf "  You need vala newer than $(VALAC_MIN_MAJOR).$(VALAC_MIN_MINOR)\n"
	false
endif

check: vala-check pkg-check

misc/$(PROGRAM).res: misc/$(PROGRAM).rc
	windres misc/$(PROGRAM).rc -O coff -o misc/$(PROGRAM).res

ifdef WINDOWS
misc/locales.iss:
	@rm -f $@
# 	&& chars and echo on end of line is cause windows cmd don't know ; as end of command
	$(SILENT)$(foreach lc, $(GLOCALES),\
		printf "Source: \"$(GLOCALE)\\$(lc)\\LC_MESSAGES\\*\"; DestDir: \"{app}\\share\\locale\\$(lc)\\LC_MESSAGES\"\n" >> $@ &&) \
		printf "$@ was created ...\n"
endif

install:
	@printf "Installing $(PROGRAM) to $(DESTDIR)$(PREFIX) ...\n"
	#mkdir -p $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	#$(INSTALL_DATA) glib-2.0/schemas/apps.$(PROGRAM).gschema.xml $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/$(PROGRAM).desktop $(DESTDIR)$(PREFIX)/share/applications
	mkdir -p $(DESTDIR)$(PREFIX)/share/mime/packages
	$(INSTALL_DATA) misc/$(PROGRAM).xml $(DESTDIR)$(PREFIX)/share/mime/packages
	#@echo "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real installation!"
	@printf "Do not forget to run update-mime-database after real installation!\n"

uninstall:
	@printf "Uninstalling $(PROGRAM) from $(DESTDIR)$(PREFIX) ...\n"
	$(RM) -r $(DESTDIR)$(DATADIR)
	#$(RM) $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas/apps.$(PROGRAM).gschema.xml
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
	$(RM) $(DESTDIR)$(PREFIX)/share/mime/packages/$(PROGRAM).xml
	#printf "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real uninstallation!"
	@printf "Do not forget to run update-mime-database after real uninstallation!\n"

$(PROGRAM)-setup-$(VERSION).exe: $(PROGRAM) misc/$(PROGRAM).iss misc/locales.iss
	iscc misc\$(PROGRAM).iss
	$(UX)mv setup.exe $(PROGRAM)-setup-$(VERSION).exe

installer: $(PROGRAM)-setup-$(VERSION).exe

# for debug only
#mmarchitect.sh:
#	XDG_DATA_DIRS=./ glib-compile-schemas ./glib-2.0/schemas
#	echo "XDG_DATA_DIRS=./ ./mmarchitect" >> mmarchitect.sh
#	chmod a+x mmarchitect.sh

clean:
	@printf "Cleaning ...\n"
	@$(RM) misc/locales.iss
	@$(RM) misc/$(PROGRAM).res
	@$(RM) $(PROGRAM)-setup-$(VERSION).exe

../$(PROGRAM)-$(VERSION).tar.bz2: clean
	@printf "Creating source package ../$(PROGRAM)-$(VERSION).tar.bz2 ...\n"
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)
	@$(UX)mkdir -p ../$(PROGRAM)-$(VERSION)
	@$(UX)cp -a src ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a ui ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a po ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a misc ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a icons ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../$(PROGRAM)-$(VERSION)/po && $(MAKE) update-pot)
	@(cd ../ && tar cjf $(PROGRAM)-$(VERSION).tar.bz2 $(PROGRAM)-$(VERSION))
	@(cd ../ && sha1sum $(PROGRAM)-$(VERSION).tar.bz2 > $(PROGRAM)-$(VERSION).tar.bz2.sha1)
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)

../$(PROGRAM)-c-$(VERSION).tar.bz2: clean
	@printf "Creating source package ../$(PROGRAM)-c-$(VERSION).tar.bz2 ...\n"
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)
	@$(UX)mkdir -p ../$(PROGRAM)-c-$(VERSION)
	@$(UX)cp -a src ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a ui ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a po ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a misc ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a icons ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-c-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../$(PROGRAM)-c-$(VERSION)/po && $(MAKE) update-pot)
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) $(SRC_C))
	@(cd ../ && tar cjf $(PROGRAM)-c-$(VERSION).tar.bz2 $(PROGRAM)-c-$(VERSION))
	@(cd ../ && sha1sum $(PROGRAM)-c-$(VERSION).tar.bz2 > $(PROGRAM)-c-$(VERSION).tar.bz2.sha1)
	@$(RM) -rf ../$(PROGRAM)-c-$(VERSION)


source: ../$(PROGRAM)-$(VERSION).tar.bz2

c-source: ../$(PROGRAM)-c-$(VERSION).tar.bz2

.PHONY: $(TOPTARGETS) $(SUBDIRS)
