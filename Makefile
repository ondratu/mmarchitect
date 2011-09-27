PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\)-.*).*/\1/p"))"

VALAC = valac
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644

# Set debug or release mode
CONFIGS = debug release

ifeq (,$(findstring $(CONFIG),$(CONFIGS)))
    CONFIG = release
endif

ifeq (,$(findstring debug,$(CONFIG)))
    CFLAGS += -O2 -march=i686 -DNDEBUG

    ifndef PREFIX
        PREFIX = /usr/local
    endif
        
else
    VALAFLAGS += -g --save-temps
    CFLAGS += -DDEBUG=1
    PREFIX = $(shell pwd)/test
endif

CFLAGS += -DPREFIX='"$(PREFIX)"' -DVERSION='"$(VERSION)"' \
	-DGETTEXT_PACKAGE='"$(PROGRAM)"' \
	-DLANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'


ifdef CFLAGS
    VALAFLAGS += $(foreach flag,$(CFLAGS),-X $(flag))
endif

EXT_PKGS = \
	gmodule-2.0 \
	gdk-2.0 \
	gtk+-2.0 \
	gee-1.0 \
	cairo \
	libxml-2.0
#	librsvg-2.0 \

SRC = $(wildcard src/*.vala)
OUTPUT=$(PROGRAM)

all: $(OUTPUT)

release:
	make all CONFIG=release

pkgcheck:
	@echo Checking packages $(EXT_PKGS)
	@pkg-config --print-errors --exists $(EXT_PKGS)

$(OUTPUT): $(SRC) pkgcheck
	@echo Compiling Vala code...
	$(VALAC) $(VALAFLAGS) \
		$(foreach pkg,$(EXT_PKGS),--pkg=$(pkg)) \
		$(SRC) -o $(OUTPUT)

install:
	@echo DESTDIR = $(DESTDIR)
	@echo PREFIX = $(PREFIX)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/share/$(PROGRAM)/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(PREFIX)/share/$(PROGRAM)/icons
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/$(PROGRAM).svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	mkdir -p $(DESTDIR)$(PREFIX)/share/$(PROGRAM)/ui
	$(INSTALL_DATA) ui/* $(DESTDIR)$(PREFIX)/share/$(PROGRAM)/ui
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/$(PROGRAM).desktop $(DESTDIR)$(PREFIX)/share/applications

clean:
	$(RM) $(OUTPUT)
	$(RM) *~ *.bak *.c src/*.c src/*~
