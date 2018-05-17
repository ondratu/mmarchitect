PROGRAM = mmarchitect
VERSION = 0.6.0

VALAC ?= valac
INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644

# silent variable
V ?= 0
ifeq ($(V), 0)
    SILENT=@
else
    SILENT=
endif

PREFIX ?= /usr/local
DATADIR ?= $(PREFIX)/share/$(PROGRAM)
LOCALEDIR ?= $(PREFIX)/share/locale

ifeq ($(OS), Windows_NT)
    WINDOWS = 1
    UX ?= C:\\vala-0.12.0\\bin\\

    PREFIX =
    DATADIR = ../share/$(PROGRAM)
    LOCALEDIR = ../share/locale
endif

EXT_PKGS = \
	gmodule-2.0 \
	gdk-3.0 \
	gtk+-3.0 \
	cairo \
	libxml-2.0 \
	gee-0.8 \
	librsvg-2.0
