PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\).*).*/\1/p"))"

VALAC ?= valac
VALAC_MIN_VERSION = 0.12.1
INSTALL ?= install

INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644

BUILD_DIR ?= .build

HAVE_CONFIG = $(wildcard configure.mk)
CONF = $(shell (if [ -f configure.mk ]; then echo 1; else echo 0; fi;))

CFLAGS ?= -g -O2
VALAFLAGS ?= --save-temps

ifeq ($(OS), Windows_NT)
    LDFLAGS += -Wl,-subsystem,windows
    VALAFLAGS += -D WINDOWS
    INSTALL_AS_COPY = 1
    UX ?= C:\vala-0.12.0\bin\\
endif

ifdef DEBUG
    INSTALL_AS_COPY = 1
    VALAFLAGS += -D DEBUG
endif

ifndef INSTALL_AS_COPY
    PREFIX ?= /usr/local
    DATA=$(PREFIX)/share/$(PROGRAM)
else
    PREFIX =
    DATA = ./
endif

ifeq ($(OS), Windows_NT)
    CFLAGS += -DGETTEXT_PACKAGE=\"\\"\"$(PROGRAM)\\"\"\" \
	-DLANG_SUPPORT_DIR=\"\\"\"$(SYSTEM_LANG_DIR)\\"\"\"
else
    CFLAGS += -DGETTEXT_PACKAGE=\'\"$(PROGRAM)\"\' \
	-DLANG_SUPPORT_DIR=\'\"$(SYSTEM_LANG_DIR)\"\'
endif

ifdef CFLAGS
    VALAFLAGS += $(foreach flag,$(CFLAGS),-X $(flag))
endif

EXT_PKGS = \
	gmodule-2.0 \
	gdk-2.0 \
	gtk+-2.0 \
	cairo \
	libxml-2.0
#	gee-1.0 \

VALA_STAMP := $(BUILD_DIR)/.stamp
SRC_VALA = $(wildcard src/*.vala)
SRC_C = $(foreach file,$(subst src,$(BUILD_DIR),$(SRC_VALA)),$(file:.vala=.c))
OBJS = $(SRC_C:%.c=%.o)

PKG_CFLAGS = $(shell pkg-config --cflags $(EXT_PKGS))
PKG_LDFLAGS = $(shell pkg-config --libs $(EXT_PKGS)) 

OUTPUT=$(PROGRAM)

all: $(OUTPUT)

pkgcheck:
	@$(UX)echo "Checking packages $(EXT_PKGS)"
	@pkg-config --print-errors --exists $(EXT_PKGS)

valacheck:
	@$(UX)echo -n "Min Vala support version is $(VALAC_MIN_VERSION)"
	@$(UX)echo ", you are using $(shell $(VALAC) --version)"

configure:
	@$(MAKE) clean
	@$(MAKE) do-configure

do-configure: valacheck pkgcheck
	@$(UX)echo "Generating src/config.vala ..."
	@$(UX)echo "const string DATA = \"$(DATA)\";" > src/config.vala
	@$(UX)echo "const string PROGRAM = \"$(PROGRAM)\";" >> src/config.vala
	@$(UX)echo "const string VERSION = \"$(VERSION)\";" >> src/config.vala
	@$(UX)echo "Generating configure.mk ..."
	@$(UX)echo PREFIX = $(PREFIX) > configure.mk
	@$(UX)echo DATA = $(DATA) >> configure.mk
	@$(UX)echo CFLAGS = $(CFLAGS) >> configure.mk
	@$(UX)echo VALAFLAGS = $(VALAFLAGS) >> configure.mk

help:
	@$(UX)echo \
            "make [RULE] [OPTIONS] \n" \
            "   RULES are: \n" \
            "       all         - (default rule) build binaries\n" \
            "       clean       - clean all files from configure and all rule \n" \
            "       pkgcheck    - check libraries for c compiling\n" \
            "       valacheck   - information about vala support version\n" \
            "       configure   - configure build enviroment\n" \
            "       install     - install binaries to system\n" \
            "       uninstall   - uninstall binaries from system\n" \
            "       source      - create source tarball ../$(PROGRAM)-$(VERSION).tar.bz2\n" \
            "       c-source    - create c source ready tarball ../$(PROGRAM)-c-$(VERSION).tar.bz2\n" \
            "\n" \
            "   OPTIONS are :\n" \
            "       PREFIX      - for installation \n" \
            "       DEBUG       - for debug build (installation is not possible) \n" \
            "       CFLAGS      - additional CFLAGS \n" \
            "       VALAC       - vala compiler \n" \
            "       INSTALL     - install tool\n" \
            ""


ifneq ($(strip $(HAVE_CONFIG)),)
    include configure.mk

$(VALA_STAMP): $(SRC_VALA) Makefile configure.mk
	@$(UX)echo "Compiling Vala code..."
	@$(UX)mkdir -p $(BUILD_DIR)
	$(VALAC) --ccode --directory=$(BUILD_DIR) --basedir=src \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(VALAFLAGS) \
		$(SRC_VALA)
	@echo "" > $@

$(SRC_C): $(VALA_STAMP)
	@

$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.c
	$(CC) -MMD $(CFLAGS) $(PKG_CFLAGS) -c $< -o $@

$(OUTPUT): $(OBJS)
	$(CC) -o $(OUTPUT) $(OBJS) $(LDFLAGS) $(PKG_LDFLAGS)

# object depences creates by $(CC) -MMD
-include $(OBJS:.o=.d)

install:
	@echo "Installing $(PROGRAM) to $(DESTDIR)$(PREFIX) ..."
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(DATA)/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(DATA)/icons
	mkdir -p $(DESTDIR)$(DATA)/ui
	$(INSTALL_DATA) ui/* $(DESTDIR)$(DATA)/ui
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/$(PROGRAM).svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	#mkdir -p $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	#$(INSTALL_DATA) glib-2.0/schemas/apps.$(PROGRAM).gschema.xml $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/$(PROGRAM).desktop $(DESTDIR)$(PREFIX)/share/applications
	mkdir -p $(DESTDIR)$(PREFIX)/share/mime/packages
	$(INSTALL_DATA) misc/$(PROGRAM).xml $(DESTDIR)$(PREFIX)/share/mime/packages
	#@echo "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real installation!"
	@echo "Do not forget to run update-mime-database after real installation!"

uninstall:
	@echo "Uninstalling $(PROGRAM) from $(DESTDIR)$(PREFIX) ..."
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	$(RM) -r $(DESTDIR)$(DATA)/$(PROGRAM)
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	#$(RM) $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas/apps.$(PROGRAM).gschema.xml
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
	$(RM) $(DESTDIR)$(PREFIX)/share/mime/packages/$(PROGRAM).xml
	#@echo "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real uninstallation!"
	@echo "Do not forget to run update-mime-database after real uninstallation!"

# for debug only
#mmarchitect.sh:
#	XDG_DATA_DIRS=./ glib-compile-schemas ./glib-2.0/schemas
#	echo "XDG_DATA_DIRS=./ ./mmarchitect" >> mmarchitect.sh
#	chmod a+x mmarchitect.sh

else
$(OUTPUT):
	@if [ ! -f configure.mk ]; then echo "You must run make configure first"; exit 1; fi;
endif # end is configure.mk

clean:
	@$(UX)echo "Cleaning ..."
	@$(RM) $(OUTPUT)
	@$(RM) -r $(BUILD_DIR)
	@$(RM) configure.mk src/config.vala
	@$(RM) *~ src/*~
	@$(RM) mmarchitect.sh
	@dh_clean || $(UX)echo 'Never mind, it is ok ;)'

../$(PROGRAM)-$(VERSION).tar.bz2: clean
	@$(UX)echo "Creating source package ../$(PROGRAM)-$(VERSION).tar.bz2 ..."
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)
	@$(UX)mkdir -p ../$(PROGRAM)-$(VERSION)
	@$(UX)cp -a src ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a ui ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a misc ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a icons ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a debian ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../ && tar cjf $(PROGRAM)-$(VERSION).tar.bz2 $(PROGRAM)-$(VERSION))
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)

../$(PROGRAM)-c-$(VERSION).tar.bz2: clean
	@$(UX)echo "Creating source package ../$(PROGRAM)-c-$(VERSION).tar.bz2 ..."
	@$(RM) -rf ../$(PROGRAM)-$(VERSION)
	@$(UX)mkdir -p ../$(PROGRAM)-c-$(VERSION)
	@$(UX)cp -a src ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a ui ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a misc ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a icons ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a debian ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a Makefile ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)cp -a README* ../$(PROGRAM)-c-$(VERSION)/
	@$(UX)find ../$(PROGRAM)-c-$(VERSION) -type d -name .svn | $(UX)xargs $(RM) -rf
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) configure)
	@(cd ../$(PROGRAM)-c-$(VERSION) && $(MAKE) $(SRC_C))
	@(cd ../ && tar cjf $(PROGRAM)-c-$(VERSION).tar.bz2 $(PROGRAM)-c-$(VERSION))
	@$(RM) -rf ../$(PROGRAM)-c-$(VERSION)


source: ../$(PROGRAM)-$(VERSION).tar.bz2

c-source: ../$(PROGRAM)-c-$(VERSION).tar.bz2
