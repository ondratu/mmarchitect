PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\)-.*).*/\1/p"))"

VALAC = valac
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644


ifndef DEBUG
    CFLAGS += -O2 -march=i686 -DNDEBUG

    ifndef PREFIX
        PREFIX = /usr/local
    endif
    DATA=$(PREFIX)/share/$(PROGRAM)
        
else
    VALAFLAGS += -g --save-temps
    CFLAGS += -DDEBUG=1
    PREFIX =
    DATA = ./
endif

CFLAGS += -DDATA='"$(DATA)"' -DVERSION='"$(VERSION)"' \
	-DGETTEXT_PACKAGE='"$(PROGRAM)"' \
	-DLANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'


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

debug:
	make DEBUG=1

pkgcheck:
	@echo Checking packages $(EXT_PKGS)
	@pkg-config --print-errors --exists $(EXT_PKGS)

$(OUTPUT): $(SRC) pkgcheck Makefile
	@echo Compiling Vala code...
	$(VALAC) $(VALAFLAGS) \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(SRC) -o $(OUTPUT)

ifndef DEBUG
install:
	make do-install

do-install:
	@echo "Installing ..."
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
	@echo "Installing ..."
	$(RM) $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	$(RM) -r $(DESTDIR)$(DATA)/$(PROGRAM)
	$(RM) $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(PROGRAM).svg
	$(RM) $(DESTDIR)$(PREFIX)/share/applications/$(PROGRAM).desktop
endif

clean:
	@echo "Cleaning ..."
	@$(RM) $(OUTPUT)
	@$(RM) *~ *.bak *.c src/*.c src/*~
	@$(RM) -rf ./_deb_
	@(dh_clean || echo 'Never mind, it is ok ;)')
