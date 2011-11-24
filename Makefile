PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\)-.*).*/\1/p"))"

VALAC ?= valac
VALAC_MIN_VERSION = 0.12.1
INSTALL ?= install
#CC = gcc-4.3

INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644

BUILD_DIR ?= .build

CONF = $(shell (if [ -f configure.mk ]; then echo 1; else echo 0; fi;))

CFLAGS ?= -g -O2

ifndef DEBUG
    #CFLAGS += -DNDEBUG

    PREFIX ?= /usr/local
    DATA=$(PREFIX)/share/$(PROGRAM)
        
else
    #CFLAGS += -DDEBUG=1
    PREFIX =
    DATA = ./
endif

CFLAGS += -DGETTEXT_PACKAGE=\'\"$(PROGRAM)\"\' \
	-DLANG_SUPPORT_DIR=\'\"$(SYSTEM_LANG_DIR)\"\'

VALAFLAGS = --save-temps

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
#	librsvg-2.0 \

VALA_STAMP := $(BUILD_DIR)/.stamp
SRC_VALA = $(wildcard src/*.vala)
SRC_C = $(foreach file,$(subst src,$(BUILD_DIR),$(SRC_VALA)),$(file:.vala=.c))
OBJS = $(SRC_C:%.c=%.o)

PKG_CFLAGS = $(shell pkg-config --cflags $(EXT_PKGS))
PKG_LDFLAGS = $(shell pkg-config --libs $(EXT_PKGS)) 

OUTPUT=$(PROGRAM)

all: $(OUTPUT)

pkgcheck:
	@echo Checking packages $(EXT_PKGS)
	@pkg-config --print-errors --exists $(EXT_PKGS)

valacheck:
	@echo -n "Min Vala support version is $(VALAC_MIN_VERSION)"
	@echo ", you are using $(shell $(VALAC) --version)"

configure:
	@make clean
	@make do-configure

do-configure: valacheck pkgcheck
	@echo "Generating src/config.vala ..."
	@echo 'const string DATA = "$(DATA)";' > src/config.vala
	@echo 'const string PROGRAM = "$(PROGRAM)";' >> src/config.vala
	@echo 'const string VERSION = $(VERSION);' >> src/config.vala
	@echo "Generating configure.mk ..."
	@echo PREFIX = $(PREFIX) > configure.mk
	@echo DATA = $(DATA) >> configure.mk
	@echo CFLAGS = $(CFLAGS) >> configure.mk
	@echo VALAFLAGS = $(VALAFLAGS) >> configure.mk

help:
	@echo \
            "make [RULE] [OPTIONS] \n" \
            "   RULES are: \n" \
            "       configure   - configure build enviroment\n" \
            "       all         - (default rule) build binaries\n" \
            "       clean       - clean all files from configure and all rule \n" \
            "       install     - install binaries to system\n" \
            "       uninstall   - uninstall binaries from system\n" \
            "\n" \
            "   OPTIONS are :\n" \
            "       PREFIX      - for installation \n" \
            "       DEBUG       - for debug build (installation is not possible) \n" \
            "       CFLAGS      - additional CFLAGS \n" \
            "       VALAC       - vala compiler \n" \
            "       INSTALL     - install binary \n" \
            ""


ifeq (1, $(CONF))
    include configure.mk

$(VALA_STAMP): $(SRC_VALA) Makefile configure.mk
	@echo Compiling Vala code...
	@mkdir -p $(BUILD_DIR)
	$(VALAC) --ccode --directory=$(BUILD_DIR) --basedir=src \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(VALAFLAGS) \
		$(SRC_VALA)
	@touch $@

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
	mkdir -p $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	$(INSTALL_DATA) glib-2.0/schemas/apps.$(PROGRAM).gschema.xml $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/$(PROGRAM).desktop $(DESTDIR)$(PREFIX)/share/applications
	@echo "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real installation!"

uninstall:
	@echo "Uninstalling $(PROGRAM) from $(DESTDIR)$(PREFIX) ..."
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	$(RM) -r $(DESTDIR)$(DATA)/$(PROGRAM)
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	$(RM) $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas/apps.$(PROGRAM).gschema.xml
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
	@echo "Do not forget to run glib-compile-schemas $(DESTDIR)$(PREFIX)/share/glib-2.0/schemas after real uninstallation!"

# for debug only
mmarchitect.sh:
	XDG_DATA_DIRS=./ glib-compile-schemas ./glib-2.0/schemas
	echo "XDG_DATA_DIRS=./ ./mmarchitect" >> mmarchitect.sh
	chmod a+x mmarchitect.sh

else
$(OUTPUT):
	@if [ ! -f configure.mk ]; then echo "You must run make configure first"; exit 1; fi;
endif # end is configure.mk

clean:
	@echo "Cleaning ..."
	@$(RM) $(OUTPUT)
	@$(RM) -rf $(BUILD_DIR)
	@$(RM) -f configure.mk src/config.vala
	@$(RM) -f *~ src/*~
	@$(RM) -f mmarchitect.sh
	@(dh_clean || echo 'Never mind, it is ok ;)')
