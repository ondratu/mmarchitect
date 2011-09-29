PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\)-.*).*/\1/p"))"

VALAC ?= valac
VALAC_MIN_VERSION = 0.12.1
INSTALL ?= install

INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644

CONF = $(shell (if [ -f configure.mk ]; then echo 1; else echo 0; fi;))

ifndef DEBUG
    CFLAGS += -O2 -march=i686 -DNDEBUG

    PREFIX ?= /usr/local
    DATA=$(PREFIX)/share/$(PROGRAM)
        
else
    VALAFLAGS += -g --save-temps
    CFLAGS += -DDEBUG=1
    PREFIX =
    DATA = ./
endif

CFLAGS += -DGETTEXT_PACKAGE=\'\"$(PROGRAM)\"\' \
	-DLANG_SUPPORT_DIR=\'\"$(SYSTEM_LANG_DIR)\"\'


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

SRC = $(wildcard src/*.vala)
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

$(OUTPUT): $(SRC) Makefile configure.mk
	@echo Compiling Vala code...
	$(VALAC) $(VALAFLAGS) \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(SRC) -o $(OUTPUT)

ifndef DEBUG
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
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/$(PROGRAM).desktop $(DESTDIR)$(PREFIX)/share/applications

uninstall:
	@echo "Uninstalling $(PROGRAM) from $(DESTDIR)$(PREFIX) ..."
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	$(RM) -r $(DESTDIR)$(DATA)/$(PROGRAM)
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
endif # end DEBUG

else
$(OUTPUT):
	@if [ ! -f configure.mk ]; then echo "You must run make configure first"; exit 1; fi;
endif # end is configure.mk

clean:
	@echo "Cleaning ..."
	@$(RM) $(OUTPUT)
	@$(RM) configure.mk src/config.vala
	@$(RM) *~ *.bak *.c src/*.c src/*~
	@$(RM) -rf ./_deb_
	@(dh_clean || echo 'Never mind, it is ok ;)')
