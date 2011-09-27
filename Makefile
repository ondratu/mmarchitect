PROGRAM = mmarchitect
VERSION = "$(shell (head -1 debian/changelog | sed -n -e "s/.*(\(.*\)-.*).*/\1/p"))"

# Set debug or release mode
CONFIGS = debug release

ifeq (,$(findstring $(CONFIG),$(CONFIGS)))
    CONFIG = debug
endif

ifeq (,$(findstring debug,$(CONFIG)))
    CFLAGS += -O2 -march=i686 -DNDEBUG

    ifndef PREFIX
        PREFIX = /usr/local
    endif
        
else
    VALAFLAGS += -g --save-temps
    CFLAGS += -DDEBUG=1
    PREFIX = .
endif

CFLAGS += -DPREFIX='"$(PREFIX)"' -DVERSION='"$(VERSION)"' \
	-DGETTEXT_PACKAGE='"$(PROGRAM)"' \
	-DLANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'


ifdef CFLAGS
    VALAFLAGS += $(foreach flag,$(CFLAGS),-X $(flag))
endif

VALAC = valac

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
 
clean:
	$(RM) $(OUTPUT)
	$(RM) *~ *.bak *.c src/*.c src/*~
