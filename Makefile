PROGRAM = mmarchitect
VERSION = $(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\).*).*/\1/p"))

VALAC ?= valac
VALAC_MIN_VERSION = 0.12.1
INSTALL ?= install

INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644

BUILD_DIR ?= .build
LANG_DIR ?= .langs

HAVE_CONFIG = $(wildcard configure.mk)
CONF = $(shell (if [ -f configure.mk ]; then printf 1; else printf 0; fi;))

CFLAGS ?= -g -O2
VALAFLAGS ?= --save-temps

V ?= 0
ifeq ($(V), 0)
    silent=@
else
    silent=
endif

ifeq ($(OS), Windows_NT)
    LDFLAGS += -Wl,-subsystem,windows
    VALAFLAGS += -D WINDOWS
    WINDOWS = 1
    UX ?= C:\\vala-0.12.0\\bin\\
    GLOCALE = c:\\vala-0.12.0\\share\\locale
    GLOCALES = $(shell ls $(GLOCALE))
else
    # missing dependence to math library
    LDFLAGS += -lm
    #CFLAGS += -Dlocaltime_r=localtime
endif

ifndef DEBUG
  ifndef WINDOWS
    PREFIX ?= /usr/local
    DATA = $(PREFIX)/share/$(PROGRAM)
    LOCALE_DIR ?= $(PREFIX)/share/locale
  else
    PREFIX =
    DATA = ../share/$(PROGRAM)
    LOCALE_DIR = ../share/locale
  endif
else # debug is set
    VALAFLAGS += -g -D DEBUG
    PREFIX =
    DATA = ./
    LOCALE_DIR = ./$(LANG_DIR)
endif

CFLAGS += -DGETTEXT_PACKAGE='\"$(PROGRAM)\"'
VALAFLAGS += $(foreach flag,$(CFLAGS),-X $(flag))

EXT_PKGS = \
	gmodule-2.0 \
	gdk-3.0 \
	gtk+-3.0 \
	cairo \
	libxml-2.0 \
	gee-1.0 \
        librsvg-2.0

VALA_STAMP := $(BUILD_DIR)/.stamp
SRC_VALA = $(wildcard src/*.vala)
SRC_C = $(foreach file,$(subst src,$(BUILD_DIR),$(SRC_VALA)),$(file:.vala=.c))
OBJS = $(SRC_C:%.c=%.o)

FILES_UI = $(wildcard ui/*.ui)
FILES_PO = $(wildcard po/*.po)

LANG_STAMP := $(LANG_DIR)/.stamp
LANGUGAGES = cs es it

PKG_CFLAGS = $(shell pkg-config --cflags $(EXT_PKGS))
PKG_LDFLAGS = $(shell pkg-config --libs $(EXT_PKGS)) 

OUTPUT=$(PROGRAM)

all: $(OUTPUT) $(LANG_STAMP)

pkgcheck:
	@printf "Checking packages $(EXT_PKGS)\n"
	@pkg-config --print-errors --exists $(EXT_PKGS)

valacheck:
	@printf "Min Vala support version is $(VALAC_MIN_VERSION)\n"
	@printf ", you are using $(shell $(VALAC) --version)\n"

po/$(PROGRAM).pot: $(SRC_VALA) $(FILES_UI)
	@printf "updating po/$(PROGRAM).pot\n"
	$(silent)xgettext -o $@ --language=C --keyword=_ --from-code utf-8 --escape src/*.vala
	$(silent)xgettext -o $@ -j --language=Glade --keyword=translatable --from-code utf-8 ui/*.ui

$(LANG_STAMP): $(FILES_PO)
	@printf "  GETTEXT $(FILES_PO)\n"
	$(silent)$(foreach lang, $(LANGUGAGES), $(UX)mkdir -p $(LANG_DIR)/$(lang)/LC_MESSAGES && \
            msgfmt -o $(LANG_DIR)/$(lang)/LC_MESSAGES/$(PROGRAM).mo po/$(lang).po &&) printf "\tDone\n"
	@$(UX)touch $@

updatelangs: po/$(PROGRAM).pot
	@printf "merging $(FILES_PO)\n"
	$(silent)$(foreach lang, $(LANGUGAGES), $(UX)mv po/$(lang).po po/$(lang).bak && \
            msgmerge po/$(lang).bak po/$(PROGRAM).pot > po/$(lang).po;)

configure:
	@$(MAKE) clean
	@$(MAKE) do-configure

do-configure: valacheck pkgcheck
	@printf "Generating src/config.vala ...\n"
	@printf "const string DATA = \"$(DATA)\";\n" > src/config.vala
	@printf "const string PROGRAM = \"$(PROGRAM)\";\n" >> src/config.vala
	@printf "const string VERSION = \"$(VERSION)\";\n" >> src/config.vala
	@printf "const string LOCALE_DIR = \"$(LOCALE_DIR)\";\n" >> src/config.vala
	@printf "Generating configure.mk ...\n"
	@printf "PREFIX = $(PREFIX)\n" > configure.mk
	@printf "DATA = $(DATA)\n" >> configure.mk
	@printf "CFLAGS = $(CFLAGS)\n" >> configure.mk
	@printf "VALAFLAGS = $(VALAFLAGS)\n" >> configure.mk

help:
	@printf \
            "make [RULE] [OPTIONS] \n \
               RULES are: \n \
                   all         - (default rule) build binaries\n \
                   clean       - clean all files from configure and all rule \n \
                   pkgcheck    - check libraries for c compiling\n \
                   valacheck   - information about vala support version\n \
                   updatelangs - call msgmerge to all po files from LANGUGAGES list:\n \
                                 $(LANGUGAGES)\n \
                   configure   - configure build enviroment\n \
                   install     - install binaries to system\n \
                   uninstall   - uninstall binaries from system\n \
                   source      - create source tarball ../$(PROGRAM)-$(VERSION).tar.bz2\n \
                   c-source    - create c source ready tarball ../$(PROGRAM)-c-$(VERSION).tar.bz2\n \
            \n \
               OPTIONS are :\n \
                   PREFIX      - for installation \n \
                   LOCALE_DIR  - for locales installation \n \
                   DEBUG       - for debug build (installation is not possible) \n \
                   V           - if V = 1 (default is 0) then verbose mod is enabled\n \
                   CFLAGS      - additional CFLAGS \n \
                   VALAC       - vala compiler \n \
                   INSTALL     - install tool\n"


ifneq ($(strip $(HAVE_CONFIG)),)
    include configure.mk

$(VALA_STAMP): $(SRC_VALA) Makefile configure.mk
	@printf "  VALAC $(SRC_VALA)\n"
	@$(UX)mkdir -p $(BUILD_DIR)
	$(silent)$(VALAC) --ccode --directory=$(BUILD_DIR) --basedir=src \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(VALAFLAGS) \
		$(SRC_VALA)
	@$(UX)touch $@

$(SRC_C): $(VALA_STAMP)
	@

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.c
	@printf "  CC $@\n"
	$(silent)$(CC) -MMD $(CFLAGS) $(PKG_CFLAGS) -c $< -o $@

misc/$(PROGRAM).res: misc/$(PROGRAM).rc
	windres misc/$(PROGRAM).rc -O coff -o misc/$(PROGRAM).res

ifndef WINDOWS
$(OUTPUT): $(OBJS)
	@printf "  LD $@\n"
	$(silent)$(CC) -o $(OUTPUT) $(OBJS) $(LDFLAGS) $(PKG_LDFLAGS)
else
$(OUTPUT): $(OBJS) misc/$(PROGRAM).res
	$(CC) -o $(OUTPUT) $(OBJS) $(LDFLAGS) $(PKG_LDFLAGS) misc/$(PROGRAM).res

misc/locales.iss:
	@rm -f $@
# 	&& chars and echo on end of line is cause windows cmd don't know ; as end of command
	$(silent)$(foreach lc, $(GLOCALES),\
		printf "Source: \"$(GLOCALE)\\$(lc)\\LC_MESSAGES\\*\"; DestDir: \"{app}\\share\\locale\\$(lc)\\LC_MESSAGES\"\n" >> $@ &&) \
		printf "$@ was created ...\n"
endif

# object depences creates by $(CC) -MMD
-include $(OBJS:.o=.d)

install: $(OUTPUT) $(LANG_STAMP)
	@printf "Installing $(PROGRAM) to $(DESTDIR)$(PREFIX) ...\n"
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(DATA)/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(DATA)/icons
	mkdir -p $(DESTDIR)$(DATA)/ui
	$(INSTALL_DATA) ui/* $(DESTDIR)$(DATA)/ui
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/pixmaps
	$(INSTALL_DATA) icons/$(PROGRAM).svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/$(PROGRAM)_128.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps/$(PROGRAM).png
	$(INSTALL_DATA) icons/$(PROGRAM).png $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps
	$(INSTALL_DATA) icons/$(PROGRAM)_48.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/$(PROGRAM).png
	$(INSTALL_DATA) icons/$(PROGRAM)_32.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps/$(PROGRAM).png
	$(INSTALL_DATA) icons/$(PROGRAM).png $(DESTDIR)$(PREFIX)/share/pixmaps
	$(INSTALL_DATA) icons/$(PROGRAM).xpm $(DESTDIR)$(PREFIX)/share/pixmaps
	$(foreach lang,$(LANGUGAGES),`mkdir -p $(DESTDIR)$(LOCALE_DIR)/$(lang)/LC_MESSAGES ; \
            $(INSTALL_DATA) $(LANG_DIR)/$(lang)/LC_MESSAGES/$(PROGRAM).mo $(DESTDIR)$(LOCALE_DIR)/$(lang)/LC_MESSAGES`;)
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
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	$(RM) -r $(DESTDIR)$(DATA)
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/128x128/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/64x64/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/32x32/apps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/pixmaps/$(PROGRAM).png
	$(RM) $(DESTDIR)$(PREFIX)/share/pixmaps/$(PROGRAM).xpm
	$(foreach lang,$(LANGUGAGES),`$(RM) $(DESTDIR)$(LOCALE_DIR)/$(lang)/LC_MESSAGES/$(PROGRAM).mo`;)
	#$(RM) $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas/apps.$(PROGRAM).gschema.xml
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
	$(RM) $(DESTDIR)$(PREFIX)/share/mime/packages/$(PROGRAM).xml
	#printf "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real uninstallation!"
	@printf "Do not forget to run update-mime-database after real uninstallation!\n"

$(PROGRAM)-setup-$(VERSION).exe: $(PROGRAM) misc/$(PROGRAM).iss misc/locales.iss $(LANG_STAMP)
	iscc misc\$(PROGRAM).iss
	$(UX)mv setup.exe $(PROGRAM)-setup-$(VERSION).exe

installer: $(PROGRAM)-setup-$(VERSION).exe

# for debug only
#mmarchitect.sh:
#	XDG_DATA_DIRS=./ glib-compile-schemas ./glib-2.0/schemas
#	echo "XDG_DATA_DIRS=./ ./mmarchitect" >> mmarchitect.sh
#	chmod a+x mmarchitect.sh

else
$(OUTPUT):
	@if [ ! -f configure.mk ]; then printf "You must run make configure first\n"; exit 1; fi;
endif # end is configure.mk

clean: distclean
	@printf "Cleaning ...\n"
	@$(RM) $(OUTPUT)
	@$(RM) $(OUTPUT).exe
	@$(RM) -r $(BUILD_DIR) $(LANG_DIR)
	@$(RM) *~ src/*~
	@$(RM) misc/locales.iss
	@$(RM) misc/$(PROGRAM).res
	@$(RM) $(PROGRAM)-setup-$(VERSION).exe
	@dh_clean || printf 'Never mind, it is ok ;)\n'

distclean:
	@printf "Dist cleaning ...\n"
	@$(RM) configure.mk src/config.vala

../$(PROGRAM)-$(VERSION).tar.bz2: clean
	@printf "Creating source package ../$(PROGRAM)-$(VERSION).tar.bz2 ...\n"
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)
	@$(UX)mkdir -p ../$(PROGRAM)-$(VERSION)
	@$(UX)cp -a src ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a ui ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a po ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a misc ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a icons ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a debian ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../$(PROGRAM)-$(VERSION) && $(MAKE) po/$(PROGRAM).pot)
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
	@$(UX)cp -a debian ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-c-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) configure)
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) po/$(PROGRAM).pot)
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) $(SRC_C))
	@(cd ../ && tar cjf $(PROGRAM)-c-$(VERSION).tar.bz2 $(PROGRAM)-c-$(VERSION))
	@(cd ../ && sha1sum $(PROGRAM)-c-$(VERSION).tar.bz2 > $(PROGRAM)-c-$(VERSION).tar.bz2.sha1)
	@$(RM) -rf ../$(PROGRAM)-c-$(VERSION)


source: ../$(PROGRAM)-$(VERSION).tar.bz2

c-source: ../$(PROGRAM)-c-$(VERSION).tar.bz2
